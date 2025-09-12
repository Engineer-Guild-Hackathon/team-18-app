# api/summaries.py
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel, constr
from sqlalchemy.orm import Session
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError  # Python 3.9+

from database import SessionLocal
from models import DailySummary, User

# Basic認証（毎回）
security = HTTPBasic(auto_error=True)

# DBセッション依存
def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ここだけで使う最小のパスワード検証（users.pyに揃えたい場合は共通化してOK）
from passlib.context import CryptContext
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
def verify_password(raw: str, hashed: str) -> bool:
    return pwd_ctx.verify(raw, hashed)

def authenticate(creds: HTTPBasicCredentials, db: Session) -> User:
    user = db.query(User).filter(User.email == creds.username.lower()).first()
    if not user or not verify_password(creds.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_423_LOCKED, detail="Account locked")
    return user

# ===== Schemas =====
class SummaryCreateIn(BaseModel):
    # アプリ仕様：200文字以内
    summary_text: constr(min_length=1, max_length=200)

class SummaryOut(BaseModel):
    id: int
    summary_date: str
    summary_text: str

class SummaryListOut(BaseModel):
    items: List[SummaryOut]

# ===== Helpers =====
def user_today_date(user: User) -> datetime.date:
    """ユーザーのタイムゾーンで“今日”の日付を返す。ZoneInfoが見つからなければUTCにフォールバック。"""
    try:
        tz = ZoneInfo(user.timezone)
    except ZoneInfoNotFoundError:
        tz = timezone.utc
    return datetime.now(tz).date()

# ===== Router =====
router = APIRouter()

@router.post("", response_model=SummaryOut, status_code=201)
def create_summary(
    payload: SummaryCreateIn,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    today = user_today_date(user)

    # 1ユーザー1日1件の制約（既に存在したら409）いったん制約なし
    # exists = (
    #     db.query(DailySummary)
    #     .filter(DailySummary.user_id == user.id, DailySummary.summary_date == today)
    #     .first()
    # )
    # if exists:
    #     raise HTTPException(status_code=409, detail="Summary for today already exists")

    summary = DailySummary(
        user_id=user.id,
        summary_date=today,
        summary_text=payload.summary_text,
        # notified_at / window_start / window_end は今回は未使用なのでNoneのまま
    )
    db.add(summary)
    db.commit()
    db.refresh(summary)

    return SummaryOut(id=summary.id, summary_date=str(summary.summary_date), summary_text=summary.summary_text)

@router.get("/today", response_model=SummaryOut)
def get_today_summary(
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    today = user_today_date(user)
    summary = (
        db.query(DailySummary)
        .filter(DailySummary.user_id == user.id, DailySummary.summary_date == today)
        .first()
    )
    if not summary:
        raise HTTPException(status_code=404, detail="Summary for today not found")
    return SummaryOut(id=summary.id, summary_date=str(summary.summary_date), summary_text=summary.summary_text)

@router.get("/me", response_model=SummaryListOut)
def list_my_summaries(
    limit: int = 20,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    rows = (
        db.query(DailySummary)
        .filter(DailySummary.user_id == user.id)
        .order_by(DailySummary.summary_date.desc())
        .limit(max(1, min(limit, 100)))
        .all()
    )
    return SummaryListOut(
        items=[SummaryOut(id=r.id, summary_date=str(r.summary_date), summary_text=r.summary_text) for r in rows]
    )




"""
# 動作確認（curl）

## 1) その日のまとめを作成（200文字以内）

```powershell
curl -X POST http://127.0.0.1:8000/summaries -u alice@example.com:StrongPassw0rd! -H "Content-Type: application/json" -d "{""summary_text"": ""今日はiOSのURLSessionとCodableを学んだ。サンプルAPIを叩いてJSONのデコードまで実装。""}"
```

* 2回目に同日にPOSTすると `409 Conflict` が返るはずです（1日1件）。

## 2) 今日のまとめを取得

```powershell
curl http://127.0.0.1:8000/summaries/today -u alice@example.com:StrongPassw0rd!
```

## 3) 自分のまとめ一覧（新しい日付から最大20件）

```powershell
curl "http://127.0.0.1:8000/summaries/me?limit=20" -u alice@example.com:StrongPassw0rd!
```

---


"""