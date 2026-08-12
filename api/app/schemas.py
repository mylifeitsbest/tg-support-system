"""Pydantic schemas for request/response validation."""
from datetime import datetime

from pydantic import BaseModel

from app.models import ChatStatus


# ── Users ──────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    id: int
    username: str | None = None
    first_name: str | None = None


class UserOut(BaseModel):
    id: int
    username: str | None
    first_name: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Messages ───────────────────────────────────────────────────────────────

class MessageCreate(BaseModel):
    sender: str  # "user" | "operator"
    text: str


class MessageOut(BaseModel):
    id: int
    chat_id: int
    sender: str
    text: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Chats ──────────────────────────────────────────────────────────────────

class ChatOut(BaseModel):
    id: int
    user_id: int
    status: ChatStatus
    operator_id: int | None
    locked_at: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ChatStatusUpdate(BaseModel):
    status: ChatStatus
