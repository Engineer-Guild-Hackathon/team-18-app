# api/users.py
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel, EmailStr, SecretStr, constr
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import SessionLocal
from models import User

router = APIRouter()
security = HTTPBasic(auto_error=True)  # Basic認証（毎回ログイン）
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


# =========================
# DBセッション依存
# =========================
def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# =========================
# Pydantic Schemas
# =========================
class SignupIn(BaseModel):
    email: EmailStr
    password: SecretStr
    username: constr(strip_whitespace=True, min_length=3, max_length=50)
    full_name: Optional[constr(max_length=255)] = None


class MeOut(BaseModel):
    id: int
    email: EmailStr
    username: str
    full_name: Optional[str]
    is_active: bool
    timezone: str


# =========================
# Utils
# =========================
def hash_password(raw: str) -> str:
    return pwd_ctx.hash(raw)


def verify_password(raw: str, hashed: str) -> bool:
    return pwd_ctx.verify(raw, hashed)


def authenticate_basic(creds: HTTPBasicCredentials, db: Session) -> User:
    """
    Basic認証で渡された username/password を検証。
    username には email を渡す運用にしてください。
    """
    user = db.query(User).filter(User.email == creds.username.lower()).first()
    if not user or not verify_password(creds.password, user.hashed_password):
        # 401を返すとブラウザは再認証を促す。iOSネイティブでも問題なし。
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_423_LOCKED, detail="Account locked")
    return user


# =========================
# Endpoints
# =========================
@router.post("/signup", status_code=201)
def signup(payload: SignupIn, db: Session = Depends(get_db)):
    """
    新規ユーザー登録。成功時は最低限のプロフィールを返す。
    """
    if db.query(User).filter(User.email == payload.email.lower()).first():
        raise HTTPException(status_code=409, detail="Email already exists")
    if db.query(User).filter(User.username == payload.username).first():
        raise HTTPException(status_code=409, detail="Username already exists")

    user = User(
        email=payload.email.lower(),
        username=payload.username,
        hashed_password=hash_password(payload.password.get_secret_value()),
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {
        "user": {
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "is_active": user.is_active,
            "timezone": user.timezone,
        }
    }


@router.get("/login")
def login(
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    """
    Basic認証でのログイン。成功時はユーザー情報を返すだけ（トークン等は発行しない）。
    iOS側は毎回 Authorization: Basic base64(email:password) を付与してアクセス。
    """
    user = authenticate_basic(creds, db)
    return {"ok": True, "user": {"id": user.id, "email": user.email, "username": user.username}}


@router.get("/me", response_model=MeOut)
def me(
    creds: HTTPBasicCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    """
    自分のプロフィール取得（Basic認証必須）。
    """
    user = authenticate_basic(creds, db)
    return MeOut(
        id=user.id,
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        is_active=user.is_active,
        timezone=user.timezone,
    )



"""
# エンドポイント一覧（いま実装してる分）

* `POST /auth/signup` … 新規登録（JSON）
* `GET  /auth/login` … Basic認証でログイン（毎回）
* `GET  /auth/me` … Basic認証で自分情報取得

---

## 1) サインアップ（POST /auth/signup）

### PowerShell（Windows）

```powershell
curl -X POST http://127.0.0.1:8000/auth/signup `
  -H "Content-Type: application/json" `
  -d "{""email"": ""alice@example.com"", ""password"": ""StrongPassw0rd!"", ""username"": ""alice"", ""full_name"": ""Alice""}"
```

### 期待レスポンス(201)

```json
{
  "user": {
    "id": 1,
    "email": "alice@example.com",
    "username": "alice",
    "full_name": "Alice",
    "is_active": true,
    "timezone": "Asia/Tokyo"
  }
}
```

エラー例: 409（メール/ユーザー名の重複）, 422（バリデーション）

---

## 2) ログイン（GET /auth/login）

Basic認証で **email\:password** を送ります。

### PowerShell（`-u`が使える）

```powershell
curl http://127.0.0.1:8000/auth/login -u alice@example.com:StrongPassw0rd!
```

### 期待レスポンス(200)

```json
{
  "ok": true,
  "user": { "id": 1, "email": "alice@example.com", "username": "alice" }
}
```

エラー例: 401（メール/パスワード不一致）, 423（ロック）

---

## 3) 自分情報（GET /auth/me）

こちらも Basic 認証が必要です。

### PowerShell

```powershell
curl http://127.0.0.1:8000/auth/me -u alice@example.com:StrongPassw0rd!
```

### 期待レスポンス(200)

```json
{
  "id": 1,
  "email": "alice@example.com",
  "username": "alice",
  "full_name": "Alice",
  "is_active": true,
  "timezone": "Asia/Tokyo"
}
```

---

## iOS（Swift）から叩く例

### Basicヘッダの作成

```swift
func basicAuth(email: String, password: String) -> String {
    let creds = "\(email):\(password)"
    let data = creds.data(using: .utf8)!.base64EncodedString()
    return "Basic \(data)"
}
```

### /auth/login

```swift
var req = URLRequest(url: URL(string: "http://127.0.0.1:8000/auth/login")!)
req.httpMethod = "GET"
req.addValue(basicAuth(email: "alice@example.com", password: "StrongPassw0rd!"),
             forHTTPHeaderField: "Authorization")

URLSession.shared.dataTask(with: req) { data, resp, err in
    print(String(data: data ?? Data(), encoding: .utf8) ?? "")
}.resume()
```

### /auth/signup

```swift
struct SignupIn: Codable {
    let email: String
    let password: String
    let username: String
    let full_name: String?
}

var req = URLRequest(url: URL(string: "http://127.0.0.1:8000/auth/signup")!)
req.httpMethod = "POST"
req.addValue("application/json", forHTTPHeaderField: "Content-Type")

let body = SignupIn(email: "alice@example.com",
                    password: "StrongPassw0rd!",
                    username: "alice",
                    full_name: "Alice")
req.httpBody = try! JSONEncoder().encode(body)

URLSession.shared.dataTask(with: req) { data, resp, err in
    print(String(data: data ?? Data(), encoding: .utf8) ?? "")
}.resume()
```

---

## Swagger UI（手で試したい時）

ブラウザで開く → `http://127.0.0.1:8000/docs`
（/auth/login と /auth/me は「Authorize」ボタンではなく、画面右上の「Authorize」→`Basic`はありません。**Try it out**時に `Authorize` がないので、Basicヘッダを直接付けられないUIです。ログイン/Meは `curl` や Postman で試すのが楽です）

---
"""