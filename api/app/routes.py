"""API routers — chats and messages."""
import logging
from datetime import datetime, timezone

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import OperatorDep
from app.config import settings
from app.database import get_db
from app.models import Chat, ChatStatus, Message, TgUser
from app.schemas import ChatOut, ChatStatusUpdate, MessageCreate, MessageOut, UserCreate, UserOut

router = APIRouter()


# ── Users ──────────────────────────────────────────────────────────────────

@router.post("/users", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def upsert_user(body: UserCreate, db: AsyncSession = Depends(get_db)):
    """Bot registers or updates a Telegram user."""
    user = await db.get(TgUser, body.id)
    if user is None:
        user = TgUser(**body.model_dump())
        db.add(user)
    else:
        user.username = body.username
        user.first_name = body.first_name
    await db.commit()
    await db.refresh(user)
    return user


# ── Chats ──────────────────────────────────────────────────────────────────

@router.get("/chats", response_model=list[ChatOut])
async def list_chats(operator_id: OperatorDep, db: AsyncSession = Depends(get_db)):
    """Operator: list all chats."""
    result = await db.execute(select(Chat).order_by(Chat.updated_at.desc()))
    return result.scalars().all()


@router.post("/chats", response_model=ChatOut, status_code=status.HTTP_201_CREATED)
async def create_chat(body: UserCreate, db: AsyncSession = Depends(get_db)):
    """Bot: create a new chat for a user (also upserts the user)."""
    user = await db.get(TgUser, body.id)
    if user is None:
        user = TgUser(**body.model_dump())
        db.add(user)
        await db.flush()

    chat = Chat(user_id=body.id, status=ChatStatus.open)
    db.add(chat)
    await db.commit()
    await db.refresh(chat)
    return chat


@router.post("/chats/{chat_id}/claim", response_model=ChatOut)
async def claim_chat(chat_id: int, operator_id: OperatorDep, db: AsyncSession = Depends(get_db)):
    """Operator: claim/lock a chat. Returns 409 if already claimed by another operator."""
    chat = await db.get(Chat, chat_id)
    if chat is None:
        raise HTTPException(status_code=404, detail="Chat not found")
    if chat.operator_id is not None and chat.operator_id != operator_id:
        raise HTTPException(status_code=409, detail="Chat already claimed by another operator")

    chat.operator_id = operator_id
    chat.locked_at = datetime.now(timezone.utc)
    chat.status = ChatStatus.in_progress
    await db.commit()
    await db.refresh(chat)
    return chat


@router.patch("/chats/{chat_id}/status", response_model=ChatOut)
async def update_chat_status(
    chat_id: int, body: ChatStatusUpdate, operator_id: OperatorDep, db: AsyncSession = Depends(get_db)
):
    """Operator: change chat status."""
    chat = await db.get(Chat, chat_id)
    if chat is None:
        raise HTTPException(status_code=404, detail="Chat not found")
    chat.status = body.status
    await db.commit()
    await db.refresh(chat)
    return chat


# ── Messages ───────────────────────────────────────────────────────────────

@router.get("/chats/{chat_id}/messages", response_model=list[MessageOut])
async def list_messages(
    chat_id: int, operator_id: OperatorDep, db: AsyncSession = Depends(get_db)
):
    """Operator: get message history."""
    result = await db.execute(
        select(Message).where(Message.chat_id == chat_id).order_by(Message.created_at)
    )
    return result.scalars().all()


@router.post("/chats/{chat_id}/messages", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
async def send_message(
    chat_id: int, body: MessageCreate, db: AsyncSession = Depends(get_db)
):
    """Bot or operator: post a message to a chat. No auth required for bot sender."""
    chat = await db.get(Chat, chat_id)
    if chat is None:
        raise HTTPException(status_code=404, detail="Chat not found")

    msg = Message(chat_id=chat_id, sender=body.sender, text=body.text)
    db.add(msg)
    await db.commit()
    await db.refresh(msg)

    # If the operator sends a message, forward it to the bot via callback
    if body.sender == "operator":
        try:
            async with httpx.AsyncClient() as http:
                await http.post(
                    settings.BOT_CALLBACK_URL,
                    json={"chat_id": chat.user_id, "text": body.text},
                    timeout=5.0
                )
        except Exception as e:
            logging.error(f"Failed to notify bot for message {msg.id}: {e}")

    return msg
