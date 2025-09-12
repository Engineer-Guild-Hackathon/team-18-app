# apns.py
# APNs（Apple Push Notification service）へ最小構成で通知を送るユーティリティ
# 依存: httpx[http2], pyjwt, cryptography

import time
from typing import Tuple, Dict, Any, Optional

import httpx
import jwt  # PyJWT

from settings import (
    APNS_KEY_ID,
    APNS_TEAM_ID,
    APNS_BUNDLE_ID,
    APNS_USE_SANDBOX,
    get_apns_private_key_pem,  # .env からAPNs秘密鍵(PEM文字列)を取得
)

# ---- JWTの簡易キャッシュ（APNsは最長1時間有効）----
_cached_token: Optional[str] = None
_cached_token_exp: float = 0.0


def _get_jwt() -> str:
    """
    APNsプロバイダトークン（JWT, ES256）を生成して返す。
    期限内ならキャッシュを返す。
    """
    global _cached_token, _cached_token_exp
    now = time.time()

    # 期限まで10分以上残っていればキャッシュを返す
    if _cached_token and now < _cached_token_exp - 600:
        return _cached_token

    private_key_pem = get_apns_private_key_pem()
    # ヘッダに kid（Key ID）を入れる必要がある
    token = jwt.encode(
        {"iss": APNS_TEAM_ID, "iat": int(now)},
        private_key_pem,
        algorithm="ES256",
        headers={"kid": APNS_KEY_ID},
    )
    _cached_token = token
    _cached_token_exp = now + 3600  # 1時間
    return token


def _host() -> str:
    return "api.sandbox.push.apple.com" if APNS_USE_SANDBOX else "api.push.apple.com"


# ---- 送信本体（最小） ----
def send_push(
    device_token: str,
    title: str,
    body: str,
    deeplink: Optional[str] = None,
    apns_id: Optional[str] = None,  # 冪等性キーに使える（任意）
) -> Tuple[bool, Dict[str, Any]]:
    """
    APNsへアラート通知を送る（最小構成）。
    戻り値: (成功/失敗, 詳細dict)
      - 成功例: (True, {"status": 200})
      - 失敗例: (False, {"status": 410, "reason": "Unregistered"})
    """
    url = f"https://{_host()}/3/device/{device_token}"
    token = _get_jwt()

    headers: Dict[str, str] = {
        "authorization": f"bearer {token}",
        "apns-topic": APNS_BUNDLE_ID,   # Bundle ID
        "apns-push-type": "alert",      # iOS 13+ 必須
        # "apns-priority": "10",        # 即時配信（必要なら）
    }
    if apns_id:
        headers["apns-id"] = apns_id

    payload: Dict[str, Any] = {
        "aps": {
            "alert": {"title": title, "body": body},
            "sound": "default",
        }
    }
    # ディープリンク等、アプリ側でハンドリングするカスタムキー
    if deeplink:
        payload["deeplink"] = deeplink

    with httpx.Client(http2=True, timeout=10.0) as client:
        resp = client.post(url, json=payload, headers=headers)

    if resp.status_code in (200, 202):
        return True, {"status": resp.status_code}

    # エラー詳細（APNsは {"reason": "..."} を返す）
    reason = ""
    try:
        reason = resp.json().get("reason", "")
    except Exception:
        reason = resp.text[:200]

    return False, {"status": resp.status_code, "reason": reason}
