"""HTTP client for calling the API from the bot."""
import logging

import aiohttp

from app.config import settings

logger = logging.getLogger(__name__)
_session: aiohttp.ClientSession | None = None


def get_session() -> aiohttp.ClientSession:
    global _session
    if _session is None or _session.closed:
        _session = aiohttp.ClientSession(base_url=settings.API_BASE_URL)
    return _session


async def upsert_user(user_id: int, username: str | None, first_name: str | None) -> dict:
    async with get_session().post(
        "/users",
        json={"id": user_id, "username": username, "first_name": first_name},
    ) as resp:
        resp.raise_for_status()
        return await resp.json()


async def create_chat(user_id: int, username: str | None, first_name: str | None) -> dict:
    async with get_session().post(
        "/chats",
        json={"id": user_id, "username": username, "first_name": first_name},
    ) as resp:
        resp.raise_for_status()
        return await resp.json()


async def send_message(chat_id: int, sender: str, text: str) -> dict:
    async with get_session().post(
        f"/chats/{chat_id}/messages",
        json={"sender": sender, "text": text},
    ) as resp:
        resp.raise_for_status()
        return await resp.json()


async def get_messages(chat_id: int) -> list[dict]:
    async with get_session().get(f"/chats/{chat_id}/messages") as resp:
        resp.raise_for_status()
        return await resp.json()
