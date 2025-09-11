# api/ai.py
from datetime import datetime, timezone
from typing import List, Optional, Literal, Dict

from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel, constr
from sqlalchemy.orm import Session
from sqlalchemy import func
from passlib.context import CryptContext

from database import SessionLocal
from models import (
    User, DailySummary, AIGeneration, AIVote, Follow, AIImpression
)

router = APIRouter()
security = HTTPBasic(auto_error=True)
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ---- DB ----
def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ---- Auth helpers ----
def verify_password(raw: str, hashed: str) -> bool:
    return pwd_ctx.verify(raw, hashed)

def authenticate(creds: HTTPBasicCredentials, db: Session) -> User:
    user = db.query(User).filter(User.email == creds.username.lower()).first()
    if not user or not verify_password(creds.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_423_LOCKED, detail="Account locked")
    return user

# ---- Schemas ----
class GenerateIn(BaseModel):
    summary_id: int
    model: constr(min_length=1, max_length=100) = "stub"
    generated_text: constr(min_length=1, max_length=4000)
    prompt_fingerprint: Optional[constr(max_length=64)] = None
    deactivate_others: bool = True  # 既存のactiveを落としてこれを採用

class AIGenOut(BaseModel):
    id: int
    summary_id: int
    model: str
    generated_text: str
    is_active: bool
    created_at: str

class VoteIn(BaseModel):
    ai_id: int
    label: Literal["correct", "incorrect", "unknown"]

class VoteOut(BaseModel):
    ai_id: int
    counts: Dict[str, int]  # {"correct": 10, "incorrect": 3, "unknown": 1}
    my_vote: Optional[str]

class ImpressionIn(BaseModel):
    ai_id: int
    kind: Literal["impression", "open", "share"] = "impression"

class FeedItemOut(BaseModel):
    ai_id: int
    summary_id: int
    summary_text: str
    user_id: int
    username: str
    generated_text: str
    created_at: str
    counts: Dict[str, int]  # 投票集計

class FeedOut(BaseModel):
    items: List[FeedItemOut]

# ---- Utils ----
def vote_counts(db: Session, ai_id: int) -> Dict[str, int]:
    rows = (
        db.query(AIVote.label, func.count(AIVote.id))
        .filter(AIVote.ai_id == ai_id)
        .group_by(AIVote.label)
        .all()
    )
    base = {"correct": 0, "incorrect": 0, "unknown": 0}
    for label, c in rows:
        base[label] = c
    return base

# ---- Endpoints ----
@router.post("/generate", response_model=AIGenOut, status_code=201)
def generate_ai_text(
    payload: GenerateIn,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    """
    要約に紐づくAI文章を保存する。
    ※ 生成自体は外部で行い、ここでは結果を保存する想定（最小構成）。
    """
    user = authenticate(creds, db)

    summary = db.query(DailySummary).get(payload.summary_id)
    if not summary:
        raise HTTPException(status_code=404, detail="Summary not found")
    if summary.user_id != user.id:
        raise HTTPException(status_code=403, detail="Not your summary")

    if payload.deactivate_others:
        db.query(AIGeneration).filter(
            AIGeneration.summary_id == summary.id,
            AIGeneration.is_active == True
        ).update({"is_active": False})

    ai = AIGeneration(
        summary_id=summary.id,
        model=payload.model,
        prompt_fingerprint=payload.prompt_fingerprint,
        generated_text=payload.generated_text,
        is_active=True,
    )
    db.add(ai)
    db.commit()
    db.refresh(ai)
    return AIGenOut(
        id=ai.id,
        summary_id=ai.summary_id,
        model=ai.model,
        generated_text=ai.generated_text,
        is_active=ai.is_active,
        created_at=ai.created_at.isoformat() if ai.created_at else "",
    )





@router.get("/items/{ai_id}", response_model=FeedItemOut)
def get_ai_detail(ai_id: int, creds: HTTPBasicCredentials = Depends(security), db: Session = Depends(get_db)):
    user = authenticate(creds, db)
    ai = db.query(AIGeneration).get(ai_id)
    if not ai:
        raise HTTPException(status_code=404, detail="AI text not found")

    s = db.query(DailySummary).get(ai.summary_id)
    u = db.query(User).get(s.user_id)
    counts = vote_counts(db, ai.id)

    return FeedItemOut(
        ai_id=ai.id,
        summary_id=ai.summary_id,
        summary_text=s.summary_text,
        user_id=u.id,
        username=u.username,
        generated_text=ai.generated_text,
        created_at=ai.created_at.isoformat() if ai.created_at else "",
        counts=counts,
    )

@router.post("/vote", response_model=VoteOut)
def vote_ai(
    payload: VoteIn,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    ai = db.query(AIGeneration).get(payload.ai_id)
    if not ai:
        raise HTTPException(status_code=404, detail="AI text not found")

    # 既存投票は上書き（ユニーク制約: ai_id + voter_id）
    existing = (
        db.query(AIVote)
        .filter(AIVote.ai_id == ai.id, AIVote.voter_id == user.id)
        .first()
    )
    if existing:
        existing.label = payload.label
        db.add(existing)
    else:
        db.add(AIVote(ai_id=ai.id, voter_id=user.id, label=payload.label))
    db.commit()

    counts = vote_counts(db, ai.id)
    return VoteOut(ai_id=ai.id, counts=counts, my_vote=payload.label)

@router.post("/impressions")
def record_impression(
    payload: ImpressionIn,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    ai = db.query(AIGeneration).get(payload.ai_id)
    if not ai:
        raise HTTPException(status_code=404, detail="AI text not found")
    db.add(AIImpression(ai_id=ai.id, viewer_id=user.id, kind=payload.kind))
    db.commit()
    return {"ok": True}

@router.get("/feed", response_model=FeedOut)
def feed(
    scope: str = Query("all", description="all or following"),
    include_self: bool = Query(False),
    limit: int = Query(20, ge=1, le=100),
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    """
    シンプルなフィード：
    - scope=all       : 全体の最新（is_activeなAI）
    - scope=following : 自分がフォローしているユーザーの最新
    """
    scope = (scope or "all").strip().lower()
    if scope not in {"all", "following"}:
        raise HTTPException(status_code=400, detail="scope must be 'all' or 'following'")
    user = authenticate(creds, db)

    q = db.query(AIGeneration).filter(AIGeneration.is_active == True)
    if scope == "following":
        followee_ids = [
            f.followee_id
            for f in db.query(Follow).filter(Follow.follower_id == user.id).all()
        ]
        if followee_ids:
            q = q.join(DailySummary, DailySummary.id == AIGeneration.summary_id)\
                 .filter(DailySummary.user_id.in_(followee_ids))
        else:
            return FeedOut(items=[])

    if not include_self:
        q = q.join(DailySummary, DailySummary.id == AIGeneration.summary_id)\
             .filter(DailySummary.user_id != user.id)

    rows = q.order_by(AIGeneration.created_at.desc()).limit(limit).all()

    items: List[FeedItemOut] = []
    for ai in rows:
        s = db.query(DailySummary).get(ai.summary_id)
        u = db.query(User).get(s.user_id)
        counts = vote_counts(db, ai.id)
        items.append(
            FeedItemOut(
                ai_id=ai.id,
                summary_id=s.id,
                summary_text=s.summary_text,
                user_id=u.id,
                username=u.username,
                generated_text=ai.generated_text,
                created_at=ai.created_at.isoformat() if ai.created_at else "",
                counts=counts,
            )
        )
        # インプレッションを記録（簡易）
        db.add(AIImpression(ai_id=ai.id, viewer_id=user.id, kind="impression"))
    db.commit()

    return FeedOut(items=items)

@router.get("/mine/today", response_model=Optional[AIGenOut])
def my_ai_today(
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    """
    今日の自分の要約に紐づく active なAI文章を1件返す（なければnull）
    """
    user = authenticate(creds, db)
    # 今日の要約
    # ここは簡易的に「最新日付の要約」を今日扱いにします（厳密なTZ日付判定は省略）。
    s = (
        db.query(DailySummary)
        .filter(DailySummary.user_id == user.id)
        .order_by(DailySummary.summary_date.desc())
        .first()
    )
    if not s:
        return None
    ai = (
        db.query(AIGeneration)
        .filter(AIGeneration.summary_id == s.id, AIGeneration.is_active == True)
        .order_by(AIGeneration.created_at.desc())
        .first()
    )
    if not ai:
        return None
    return AIGenOut(
        id=ai.id,
        summary_id=ai.summary_id,
        model=ai.model,
        generated_text=ai.generated_text,
        is_active=ai.is_active,
        created_at=ai.created_at.isoformat() if ai.created_at else "",
    )






"""
# 動作チェック（curl例）

※ Basicは `-u email:password`

---

# ai.py のコマンド

### 1) AI文章を保存（生成結果を登録）

```powershell
curl -X POST "http://127.0.0.1:8000/ai/generate" -u alice@example.com:StrongPassw0rd! -H "Content-Type: application/json" -d '{ "summary_id": 1, "generated_text": "URLSessionは非同期でレスポンスを受け取り、CodableでJSONを安全にデコードできる。", "model": "stub" }'
```

### 2) AI詳細を取得

```powershell
curl "http://127.0.0.1:8000/ai/items/1" -u alice@example.com:StrongPassw0rd!
```

### 3) 投票（correct / incorrect / unknown）

```powershell
curl -X POST "http://127.0.0.1:8000/ai/vote" -u alice@example.com:StrongPassw0rd! -H "Content-Type: application/json" -d '{ "ai_id": 1, "label": "correct" }'
```

### 4) インプレッションを記録（impression / open / share）

```powershell
curl -X POST "http://127.0.0.1:8000/ai/impressions" -u alice@example.com:StrongPassw0rd! -H "Content-Type: application/json" -d '{ "ai_id": 1, "kind": "open" }'
```

### 5) フィード取得

```powershell
# 全体
curl "http://127.0.0.1:8000/ai/feed?scope=all&limit=20" -u alice@example.com:StrongPassw0rd!
# フォロー中のみ
curl "http://127.0.0.1:8000/ai/feed?scope=following&limit=20" -u alice@example.com:StrongPassw0rd!
# 自分の投稿も含める
curl "http://127.0.0.1:8000/ai/feed?scope=all&limit=20&include_self=true" -u alice@example.com:StrongPassw0rd!
```

### 6) 今日の自分のAI（存在すれば1件、無ければnull）

```powershell
curl "http://127.0.0.1:8000/ai/mine/today" -u alice@example.com:StrongPassw0rd!
```

"""