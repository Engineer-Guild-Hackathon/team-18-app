# api/devices.py
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel, constr
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import SessionLocal
from models import User, UserDevice

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

# Schema
class DeviceRegisterIn(BaseModel):
    platform: constr(strip_whitespace=True, min_length=1) = "iOS"
    device_token: constr(strip_whitespace=True, min_length=10)

@router.post("/device/register", status_code=201)
def register_device(
    payload: DeviceRegisterIn,
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    user = authenticate(creds, db)

    # device_token はユニーク制約。既存があれば更新、無ければ作成。
    dev = db.query(UserDevice).filter(UserDevice.device_token == payload.device_token).first()
    if dev:
        dev.user_id = user.id
        dev.platform = payload.platform
        dev.last_seen_at = datetime.now(timezone.utc)
        db.add(dev)
        db.commit()
        db.refresh(dev)
        return {"ok": True, "updated": True}
    else:
        dev = UserDevice(
            user_id=user.id,
            platform=payload.platform,
            device_token=payload.device_token,
            last_seen_at=datetime.now(timezone.utc),
        )
        db.add(dev)
        db.commit()
        return {"ok": True, "created": True}
