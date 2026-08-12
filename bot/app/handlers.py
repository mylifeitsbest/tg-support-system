"""Aiogram message handlers."""
import logging

from aiogram import Router
from aiogram.filters import CommandStart
from aiogram.types import Message

from app import api_client
from app.storage import user_chat_map

logger = logging.getLogger(__name__)
router = Router()


@router.message(CommandStart())
async def handle_start(message: Message) -> None:
    """Register user and open a support chat when they send /start."""
    user = message.from_user
    if user is None:
        return

    try:
        await api_client.upsert_user(user.id, user.username, user.first_name)
        chat = await api_client.create_chat(user.id, user.username, user.first_name)
        user_chat_map[user.id] = chat["id"]
        await message.answer(
            "👋 Привет! Ваше обращение открыто. Напишите ваш вопрос — оператор ответит."
        )
    except Exception:
        logger.exception("Failed to create chat for user %s", user.id)
        await message.answer("Произошла ошибка. Попробуйте позже.")


@router.message()
async def handle_user_message(message: Message) -> None:
    """Forward user text message to the API."""
    user = message.from_user
    if user is None or not message.text:
        return

    chat_id = user_chat_map.get(user.id)
    if chat_id is None:
        await message.answer("Сначала напишите /start чтобы открыть обращение.")
        return

    try:
        await api_client.send_message(chat_id, sender="user", text=message.text)
    except Exception:
        logger.exception("Failed to forward message for user %s", user.id)
        await message.answer("Не удалось отправить сообщение. Попробуйте ещё раз.")
