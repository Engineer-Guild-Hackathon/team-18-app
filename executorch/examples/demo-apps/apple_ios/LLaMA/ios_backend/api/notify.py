# api/notify.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import SessionLocal
from models import User, UserDevice
from apns import send_push

router = APIRouter()
security = HTTPBasic(auto_error=True)
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

# DB
def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Auth
def verify_password(raw: str, hashed: str) -> bool:
    return pwd_ctx.verify(raw, hashed)

def authenticate(creds: HTTPBasicCredentials, db: Session) -> User:
    user = db.query(User).filter(User.email == creds.username.lower()).first()
    if not user or not verify_password(creds.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_423_LOCKED, detail="Account locked")
    return user

@router.post("/test")
def send_test_notification(
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)
    devices = db.query(UserDevice).filter(UserDevice.user_id == user.id, UserDevice.platform == "iOS").all()
    if not devices:
        raise HTTPException(status_code=404, detail="No iOS devices registered")

    title = "今日のまとめ"
    body = "今の学びを200文字で書こう"
    deeplink = "myapp://summary/today"

    results = []
    to_delete_tokens = []

    for d in devices:
        ok, info = send_push(
            device_token=d.device_token,
            title=title,
            body=body,
            deeplink=deeplink,
            apns_id=f"user-{user.id}-dev-{d.id}",
        )
        results.append({"device_token": d.device_token[:12] + "...", "ok": ok, **info})

        # 410/BadDeviceToken は削除
        if not ok and info.get("status") in (400, 410) and info.get("reason") in ("BadDeviceToken", "Unregistered"):
            to_delete_tokens.append(d.device_token)

    if to_delete_tokens:
        db.query(UserDevice).filter(UserDevice.device_token.in_(to_delete_tokens)).delete(synchronize_session=False)
        db.commit()

    return {"sent": len(results), "results": results}
