"""Smoke tests for API routes."""
import pytest
import urllib.parse
import json
import hashlib
import hmac

def get_test_init_data(operator_id: int) -> str:
    user = json.dumps({"id": operator_id}, separators=(",", ":"))
    data = f"auth_date=123456\nuser={user}"
    secret = hmac.new(b"WebAppData", b"1234567890:AAtest_token_for_tests_only_not_real", hashlib.sha256).digest()
    hash_val = hmac.new(secret, data.encode(), hashlib.sha256).hexdigest()
    params = {"auth_date": "123456", "user": user, "hash": hash_val}
    return urllib.parse.urlencode(params)


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


@pytest.mark.asyncio
async def test_operator_auth_failed(client):
    # Missing header
    resp = await client.get("/chats")
    assert resp.status_code == 401
    
    # Invalid initData
    resp = await client.get("/chats", headers={"Authorization": "tma invalid"})
    assert resp.status_code == 401

    # Valid initData but not in allowlist (allowlist only has 999)
    bad_operator_data = get_test_init_data(888)
    resp = await client.get("/chats", headers={"Authorization": f"tma {bad_operator_data}"})
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_operator_list_chats_and_messages(client):
    init_data = get_test_init_data(999)
    headers = {"Authorization": f"tma {init_data}"}
    
    # Create chat
    await client.post("/users", json={"id": 444, "username": "u", "first_name": "U"})
    chat_resp = await client.post("/chats", json={"id": 444, "username": "u", "first_name": "U"})
    chat_id = chat_resp.json()["id"]

    # Send message
    await client.post(f"/chats/{chat_id}/messages", json={"sender": "user", "text": "test_msg"})

    # List chats
    resp = await client.get("/chats", headers=headers)
    assert resp.status_code == 200
    assert len(resp.json()) >= 1

    # List messages
    resp = await client.get(f"/chats/{chat_id}/messages", headers=headers)
    assert resp.status_code == 200
    messages = resp.json()
    assert len(messages) == 1
    assert messages[0]["text"] == "test_msg"


@pytest.mark.asyncio
async def test_operator_claim_and_status(client):
    init_data = get_test_init_data(999)
    headers = {"Authorization": f"tma {init_data}"}
    
    # Create chat
    await client.post("/users", json={"id": 555, "username": "u", "first_name": "U"})
    chat_resp = await client.post("/chats", json={"id": 555, "username": "u", "first_name": "U"})
    chat_id = chat_resp.json()["id"]

    # Claim chat
    resp = await client.post(f"/chats/{chat_id}/claim", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "in_progress"
    assert resp.json()["operator_id"] == 999
    
    # Update status
    resp = await client.patch(f"/chats/{chat_id}/status", json={"status": "closed"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "closed"


@pytest.mark.asyncio
async def test_operator_claim_conflict(client):
    init_data_1 = get_test_init_data(999)
    headers_1 = {"Authorization": f"tma {init_data_1}"}
    
    # Temporarily add another operator to settings for testing
    import app.config
    app.config.settings.OPERATOR_ALLOWLIST += ",777"
    init_data_2 = get_test_init_data(777)
    headers_2 = {"Authorization": f"tma {init_data_2}"}

    # Create chat
    await client.post("/users", json={"id": 666, "username": "u", "first_name": "U"})
    chat_resp = await client.post("/chats", json={"id": 666, "username": "u", "first_name": "U"})
    chat_id = chat_resp.json()["id"]

    # First operator claims
    resp1 = await client.post(f"/chats/{chat_id}/claim", headers=headers_1)
    assert resp1.status_code == 200

    # Second operator claims
    resp2 = await client.post(f"/chats/{chat_id}/claim", headers=headers_2)
    assert resp2.status_code == 409
