# models.py
from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, Date, ForeignKey, Enum, UniqueConstraint,
    Index
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

# =========================
# 認証 / アカウント周り
# =========================

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)

    # アカウント設定
    is_active = Column(Boolean, default=True, nullable=False)
    timezone = Column(String(50), default="Asia/Tokyo", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # リレーション
    summaries = relationship("DailySummary", back_populates="user", cascade="all, delete-orphan")
    devices = relationship("UserDevice", back_populates="user", cascade="all, delete-orphan")
    followers = relationship("Follow", back_populates="followee", foreign_keys="Follow.followee_id", cascade="all, delete-orphan")
    followings = relationship("Follow", back_populates="follower", foreign_keys="Follow.follower_id", cascade="all, delete-orphan")


class UserDevice(Base):
    """
    APNs等のプッシュ通知送信用デバイストークンを保持するレコード（ユーザー1:N端末）
    """
    __tablename__ = "user_devices"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    platform = Column(Enum("iOS", "Android", "Web", name="device_platform"), nullable=False, default="iOS")
    device_token = Column(String(255), unique=True, nullable=False)
    last_seen_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user = relationship("User", back_populates="devices")


class Follow(Base):
    """
    ユーザー間のフォロー
    follower_id が フォローする側（＝フォロワー）
    followee_id が フォローされる側（＝フォロー対象）

    例：Alice が Bob をフォローしている
    → follower_id = alice.id／followee_id = bob.id

    使い分けメモ：
    そのユーザーをフォローしている人一覧 = Follow.followee_id == user.id
    そのユーザーがフォローしている人一覧 = Follow.follower_id == user.id
    """
    __tablename__ = "follows"
    id = Column(Integer, primary_key=True)
    follower_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    followee_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        UniqueConstraint("follower_id", "followee_id", name="uq_follows_pair"), #  自分をフォロー出来ないようにする
        Index("ix_follow_followee", "followee_id"),
    )

    follower = relationship("User", back_populates="followings", foreign_keys=[follower_id])
    followee = relationship("User", back_populates="followers", foreign_keys=[followee_id])

# =========================
# 日次要約（その日のまとめ）
# =========================

class DailySummary(Base):
    """
    ユーザーの要約
    200文字以内はアプリ側バリデーション＋APIでもチェック推奨。
    """
    __tablename__ = "daily_summaries"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    summary_date = Column(Date, nullable=False, index=True)  # ユーザーのタイムゾーン基準の日付
    summary_text = Column(String(400), nullable=False)       # 安全側に余裕。APIで200文字制限

    # 提出タイミング
    notified_at = Column(DateTime(timezone=True))            # 通知実行時刻
    window_start = Column(DateTime(timezone=True))           # 例: 18:00
    window_end = Column(DateTime(timezone=True))             # 例: 21:00
    submitted_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 1日1件の制約はいったんなし
    # __table_args__ = (
    #     UniqueConstraint("user_id", "summary_date", name="uq_user_summary_per_day"),
    # )

    user = relationship("User", back_populates="summaries")
    ai_generations = relationship("AIGeneration", back_populates="summary", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="summary", cascade="all, delete-orphan")

# =========================
# 通知ログ
# =========================

class NotificationEvent(Base):
    __tablename__ = "notification_events"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    scheduled_start = Column(DateTime(timezone=True), nullable=False)  # ウィンドウ開始
    scheduled_end = Column(DateTime(timezone=True), nullable=False)    # ウィンドウ終了
    sent_at = Column(DateTime(timezone=True))                          # 実送信
    reason = Column(String(100))                                       # ルール/実験名など
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

# =========================
# AI生成文とユーザー操作
# =========================

class AIGeneration(Base):
    __tablename__ = "ai_generations"

    id = Column(Integer, primary_key=True)
    summary_id = Column(Integer, ForeignKey("daily_summaries.id", ondelete="CASCADE"), nullable=False, index=True)
    model = Column(String(100), nullable=False)             # 使用モデル名
    prompt_fingerprint = Column(String(64), index=True)     # 入力プロンプトの要約ハッシュなど
    generated_text = Column(String, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    summary = relationship("DailySummary", back_populates="ai_generations")
    votes = relationship("AIVote", back_populates="ai", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="ai", cascade="all, delete-orphan")
    impressions = relationship("AIImpression", back_populates="ai", cascade="all, delete-orphan")


class AIVote(Base):
    __tablename__ = "ai_votes"

    id = Column(Integer, primary_key=True)
    ai_id = Column(Integer, ForeignKey("ai_generations.id", ondelete="CASCADE"), nullable=False, index=True)
    voter_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    label = Column(Enum("correct", "incorrect", "unknown", name="vote_label"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        UniqueConstraint("ai_id", "voter_id", name="uq_vote_once_per_user_ai"),
        Index("ix_vote_label", "label"),
    )

    ai = relationship("AIGeneration", back_populates="votes")
    voter = relationship("User")


class AIImpression(Base):
    __tablename__ = "ai_impressions"

    id = Column(Integer, primary_key=True)
    ai_id = Column(Integer, ForeignKey("ai_generations.id", ondelete="CASCADE"), nullable=False, index=True)
    viewer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    kind = Column(Enum("impression", "open", "share", name="impression_kind"), nullable=False, default="impression")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        Index("ix_impressions_ai_viewer_time", "ai_id", "viewer_id", "created_at"),
    )

    ai = relationship("AIGeneration", back_populates="impressions")
    viewer = relationship("User")

# =========================
# 議論（リプライ/スレッド）
# =========================

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    ai_id = Column(Integer, ForeignKey("ai_generations.id", ondelete="CASCADE"), index=True)
    summary_id = Column(Integer, ForeignKey("daily_summaries.id", ondelete="CASCADE"), index=True)
    author_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    body = Column(String, nullable=False)
    parent_id = Column(Integer, ForeignKey("comments.id", ondelete="CASCADE"), index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    author = relationship("User")
    ai = relationship("AIGeneration", back_populates="comments")
    summary = relationship("DailySummary", back_populates="comments")
    parent = relationship("Comment", remote_side=[id])
