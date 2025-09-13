# main.py
from fastapi import FastAPI
from database import engine
from models import Base
from api.users import router as users_router
from api.summaries import router as summaries_router
from api.ai import router as ai_router
from api.comments import router as comments_router
from api.devices import router as devices_router
from api.notify import router as notify_router

app = FastAPI()

# DBの作成(存在しなければ)
Base.metadata.create_all(bind=engine)

# 各ルータを登録
app.include_router(users_router,     prefix="/auth",      tags=["auth"])
app.include_router(devices_router,   prefix="/auth",      tags=["auth"])
app.include_router(summaries_router, prefix="/summaries", tags=["summaries"])
app.include_router(ai_router,        prefix="/ai",        tags=["ai"])
app.include_router(comments_router,  prefix="/comments",  tags=["comments"])
app.include_router(notify_router,    prefix="/notify",    tags=["notify"])

# ヘルスチェック用の簡易エンドポイント
@app.get("/")
def root():
    return {"ok": True}
