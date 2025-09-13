# settings.py
"""
APNs 送信に必要な設定値を環境変数から読み込む
"""

import os
import base64
from pathlib import Path
from dotenv import load_dotenv

# プロジェクト直下にある .env を読む
load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")

APNS_KEY_ID      = os.getenv("APNS_KEY_ID", "")
APNS_TEAM_ID     = os.getenv("APNS_TEAM_ID", "")
APNS_BUNDLE_ID   = os.getenv("APNS_BUNDLE_ID", "")
APNS_USE_SANDBOX = os.getenv("APNS_USE_SANDBOX", "true").lower() in ("1", "true", "yes")

# APNs秘密鍵の受け取り方（いずれか1つ。B64推奨）
APNS_KEY_P8_PATH = os.getenv("APNS_KEY_P8_PATH")     # 例: ./secrets/AuthKey_XXXX.p8
APNS_KEY_P8      = os.getenv("APNS_KEY_P8")          # PEM本文そのまま（改行含む、非推奨）
APNS_KEY_P8_B64  = os.getenv("APNS_KEY_P8_B64")      # PEMをBase64で1行化（推奨）

def get_apns_private_key_pem() -> str:
    """
    .env から APNs の秘密鍵（PEM文字列）を取得。
    優先順：APNS_KEY_P8 -> APNS_KEY_P8_B64 -> APNS_KEY_P8_PATH
    """
    if APNS_KEY_P8:
        return APNS_KEY_P8
    if APNS_KEY_P8_B64:
        return base64.b64decode(APNS_KEY_P8_B64).decode("utf-8")
    if APNS_KEY_P8_PATH:
        return Path(APNS_KEY_P8_PATH).read_text(encoding="utf-8")
    raise RuntimeError(
        "APNS key not configured: set APNS_KEY_P8 or APNS_KEY_P8_B64 or APNS_KEY_P8_PATH in .env"
    )
