# api/comments.py
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel, constr
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import SessionLocal
from models import User, Comment, AIGeneration, DailySummary

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

# ---- Auth ----
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
class CommentCreateIn(BaseModel):
    body: constr(min_length=1, max_length=1000)
    ai_id: Optional[int] = None
    summary_id: Optional[int] = None
    parent_id: Optional[int] = None  # スレッド

class CommentOut(BaseModel):
    id: int
    ai_id: Optional[int]
    summary_id: Optional[int]
    author_id: int
    body: str
    parent_id: Optional[int]
    created_at: Optional[str]

# ---- Endpoints ----
@router.post("", response_model=CommentOut, status_code=201)
def create_comment(
    payload: CommentCreateIn,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    if not payload.ai_id and not payload.summary_id:
        raise HTTPException(status_code=400, detail="ai_id or summary_id required")

    if payload.ai_id:
        ai = db.query(AIGeneration).get(payload.ai_id)
        if not ai:
            raise HTTPException(status_code=404, detail="AI text not found")
    if payload.summary_id:
        s = db.query(DailySummary).get(payload.summary_id)
        if not s:
            raise HTTPException(status_code=404, detail="Summary not found")

    if payload.parent_id:
        parent = db.query(Comment).get(payload.parent_id)
        if not parent:
            raise HTTPException(status_code=404, detail="Parent comment not found")

    c = Comment(
        ai_id=payload.ai_id,
        summary_id=payload.summary_id,
        author_id=user.id,
        body=payload.body,
        parent_id=payload.parent_id
    )
    db.add(c)
    db.commit()
    db.refresh(c)
    return CommentOut(
        id=c.id,
        ai_id=c.ai_id,
        summary_id=c.summary_id,
        author_id=c.author_id,
        body=c.body,
        parent_id=c.parent_id,
        created_at=c.created_at.isoformat() if c.created_at else None,
    )

@router.get("/ai/{ai_id}", response_model=List[CommentOut])
def list_comments_for_ai(
    ai_id: int,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    authenticate(creds, db)
    rows = (
        db.query(Comment)
        .filter(Comment.ai_id == ai_id)
        .order_by(Comment.created_at.asc())
        .all()
    )
    return [
        CommentOut(
            id=r.id,
            ai_id=r.ai_id,
            summary_id=r.summary_id,
            author_id=r.author_id,
            body=r.body,
            parent_id=r.parent_id,
            created_at=r.created_at.isoformat() if r.created_at else None,
        )
        for r in rows
    ]

@router.get("/summary/{summary_id}", response_model=List[CommentOut])
def list_comments_for_summary(
    summary_id: int,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    authenticate(creds, db)
    rows = (
        db.query(Comment)
        .filter(Comment.summary_id == summary_id)
        .order_by(Comment.created_at.asc())
        .all()
    )
    return [
        CommentOut(
            id=r.id,
            ai_id=r.ai_id,
            summary_id=r.summary_id,
            author_id=r.author_id,
            body=r.body,
            parent_id=r.parent_id,
            created_at=r.created_at.isoformat() if r.created_at else None,
        )
        for r in rows
    ]

@router.delete("/{comment_id}", status_code=204)
def delete_comment(
    comment_id: int,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    c = db.query(Comment).get(comment_id)
    if not c:
        raise HTTPException(status_code=404, detail="Comment not found")
    if c.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not your comment")
    db.delete(c)
    db.commit()
    return




"""
# 動作チェック（curl例）

※ Basicは `-u email:password`


# comments.py のコマンド

### 1) コメント作成（AIに紐づけ）

```powershell
curl -X POST "http://127.0.0.1:8000/comments" -u alice@example.com:StrongPassw0rd! -H "Content-Type: application/json" -d '{ "ai_id": 1, "body": "参考になる！Appleの公式ドキュメントも良いよ。" }'
```

### 2) 返信（親コメントにぶら下げ）

```powershell
curl -X POST "http://127.0.0.1:8000/comments" -u alice@example.com:StrongPassw0rd! -H "Content-Type: application/json" -d '{ "ai_id": 1, "parent_id": 3, "body": "補足：URLSessionConfigurationの話も追加" }'
```

### 3) AIに対するコメント一覧

```powershell
curl "http://127.0.0.1:8000/comments/ai/1" -u alice@example.com:StrongPassw0rd!
```

### 4) 要約に対するコメント一覧

```powershell
curl "http://127.0.0.1:8000/comments/summary/1" -u alice@example.com:StrongPassw0rd!
```

### 5) コメント削除（自分のコメントのみ）

```powershell
curl -X DELETE "http://127.0.0.1:8000/comments/5" -u alice@example.com:StrongPassw0rd!
```

"""