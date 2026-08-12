"""Smoke tests for API routes."""
import pytest

@pytest.mark.asyncio
async def test_health(client):
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_upsert_user(client):
    resp = await client.post("/users", json={"id": 111, "username": "test", "first_name": "Test"})
    assert resp.status_code == 201
    data = resp.json()
    assert data["id"] == 111


@pytest.mark.asyncio
async def test_create_chat(client):
    # Create user first
    await client.post("/users", json={"id": 222, "username": "u", "first_name": "U"})
    resp = await client.post("/chats", json={"id": 222, "username": "u", "first_name": "U"})
    assert resp.status_code == 201
    assert resp.json()["user_id"] == 222
    assert resp.json()["status"] == "open"


@pytest.mark.asyncio
async def test_post_message(client):
    await client.post("/users", json={"id": 333, "username": "m", "first_name": "M"})
    chat_resp = await client.post("/chats", json={"id": 333, "username": "m", "first_name": "M"})
    chat_id = chat_resp.json()["id"]

    resp = await client.post(
        f"/chats/{chat_id}/messages", json={"sender": "user", "text": "hello"}
    )
    assert resp.status_code == 201
    assert resp.json()["text"] == "hello"


@pytest.mark.asyncio
async def test_chat_not_found(client):
    resp = await client.post("/chats/9999/messages", json={"sender": "user", "text": "x"})
    assert resp.status_code == 404
