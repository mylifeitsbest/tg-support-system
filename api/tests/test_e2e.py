"""End-to-end integration test: full message lifecycle.

Simulates the complete flow:
  User writes bot → API stores message → Operator sees chat →
  Operator claims → Operator replies → API notifies bot → User receives.
"""
import pytest
from unittest.mock import patch, AsyncMock, MagicMock


def _make_mock_client():
    """Create a mock httpx.AsyncClient that tracks .post() calls."""
    mock_post = AsyncMock()
    mock_client = AsyncMock()
    mock_client.post = mock_post
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    return mock_client, mock_post


@pytest.mark.asyncio
async def test_e2e_user_to_operator_to_user(client):
    """Full lifecycle: user message → operator claim → operator reply → bot callback."""

    # ── 1. User writes to the bot: bot registers user & creates chat ──
    user_resp = await client.post(
        "/users", json={"id": 100500, "username": "alice", "first_name": "Alice"}
    )
    assert user_resp.status_code == 201

    chat_resp = await client.post(
        "/chats", json={"id": 100500, "username": "alice", "first_name": "Alice"}
    )
    assert chat_resp.status_code == 201
    chat_id = chat_resp.json()["id"]
    assert chat_resp.json()["status"] == "open"

    # ── 2. Bot forwards user message to API ──
    msg_resp = await client.post(
        f"/chats/{chat_id}/messages",
        json={"sender": "user", "text": "Привет, мне нужна помощь!"},
    )
    assert msg_resp.status_code == 201
    assert msg_resp.json()["sender"] == "user"

    # ── 3. Operator opens MiniApp → sees chats list ──
    from tests.test_routes import get_test_init_data

    init_data = get_test_init_data(999)
    op_headers = {"Authorization": f"tma {init_data}"}

    chats_resp = await client.get("/chats", headers=op_headers)
    assert chats_resp.status_code == 200
    chat_ids = [c["id"] for c in chats_resp.json()]
    assert chat_id in chat_ids

    # ── 4. Operator opens chat → sees messages ──
    msgs_resp = await client.get(f"/chats/{chat_id}/messages", headers=op_headers)
    assert msgs_resp.status_code == 200
    assert len(msgs_resp.json()) == 1
    assert msgs_resp.json()[0]["text"] == "Привет, мне нужна помощь!"

    # ── 5. Operator claims chat ──
    claim_resp = await client.post(f"/chats/{chat_id}/claim", headers=op_headers)
    assert claim_resp.status_code == 200
    assert claim_resp.json()["status"] == "in_progress"
    assert claim_resp.json()["operator_id"] == 999

    # ── 6. Operator sends reply → API notifies bot via callback ──
    mock_client, mock_post = _make_mock_client()
    with patch("app.routes.httpx.AsyncClient", return_value=mock_client):
        reply_resp = await client.post(
            f"/chats/{chat_id}/messages",
            json={"sender": "operator", "text": "Здравствуйте! Чем могу помочь?"},
        )
        assert reply_resp.status_code == 201
        assert reply_resp.json()["sender"] == "operator"

        # Verify the bot callback was attempted
        mock_post.assert_awaited_once()
        call_args = mock_post.call_args
        url = call_args[0][0] if call_args[0] else call_args.kwargs.get("url", "")
        payload = call_args.kwargs.get("json") or (call_args[1].get("json") if len(call_args) > 1 else None)
        assert payload["chat_id"] == 100500  # user's telegram ID
        assert payload["text"] == "Здравствуйте! Чем могу помочь?"

    # ── 7. Verify full message history ──
    final_msgs = await client.get(f"/chats/{chat_id}/messages", headers=op_headers)
    assert final_msgs.status_code == 200
    history = final_msgs.json()
    assert len(history) == 2
    assert history[0]["sender"] == "user"
    assert history[1]["sender"] == "operator"

    # ── 8. Operator closes chat ──
    close_resp = await client.patch(
        f"/chats/{chat_id}/status",
        json={"status": "closed"},
        headers=op_headers,
    )
    assert close_resp.status_code == 200
    assert close_resp.json()["status"] == "closed"


@pytest.mark.asyncio
async def test_claim_race_condition(client):
    """Two operators claim the same chat — second one gets 409."""
    import app.config

    original = app.config.settings.OPERATOR_ALLOWLIST

    # Ensure both operators are in the allowlist
    app.config.settings.OPERATOR_ALLOWLIST = "999,888"

    from tests.test_routes import get_test_init_data

    headers_a = {"Authorization": f"tma {get_test_init_data(999)}"}
    headers_b = {"Authorization": f"tma {get_test_init_data(888)}"}

    # Setup
    await client.post("/users", json={"id": 700, "username": "race", "first_name": "Race"})
    chat = await client.post("/chats", json={"id": 700, "username": "race", "first_name": "Race"})
    chat_id = chat.json()["id"]

    # Operator A claims — should succeed
    r1 = await client.post(f"/chats/{chat_id}/claim", headers=headers_a)
    assert r1.status_code == 200
    assert r1.json()["operator_id"] == 999

    # Operator B claims same chat — should get 409
    r2 = await client.post(f"/chats/{chat_id}/claim", headers=headers_b)
    assert r2.status_code == 409

    # Operator A re-claims own chat — should succeed (idempotent)
    r3 = await client.post(f"/chats/{chat_id}/claim", headers=headers_a)
    assert r3.status_code == 200

    # Restore
    app.config.settings.OPERATOR_ALLOWLIST = original


@pytest.mark.asyncio
async def test_operator_reply_without_claim(client):
    """Operator can send message even without claiming (no auth on message endpoint)."""
    await client.post("/users", json={"id": 701, "username": "nc", "first_name": "NC"})
    chat = await client.post("/chats", json={"id": 701, "username": "nc", "first_name": "NC"})
    chat_id = chat.json()["id"]

    mock_client, mock_post = _make_mock_client()
    with patch("app.routes.httpx.AsyncClient", return_value=mock_client):
        resp = await client.post(
            f"/chats/{chat_id}/messages",
            json={"sender": "operator", "text": "Быстрый ответ"},
        )
        assert resp.status_code == 201
        mock_post.assert_awaited_once()
