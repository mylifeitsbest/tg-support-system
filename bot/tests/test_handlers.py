from unittest.mock import AsyncMock, patch

import pytest
from aiogram.types import Chat, Message, User

from app.handlers import handle_start, handle_user_message
from app.storage import user_chat_map

@pytest.fixture
def mock_message():
    message = AsyncMock(spec=Message)
    message.from_user = User(id=123, is_bot=False, first_name="Test")
    message.text = "Hello"
    message.answer = AsyncMock()
    return message


async def test_handle_start(mock_message):
    with patch("app.api_client.upsert_user", new_callable=AsyncMock) as mock_upsert:
        with patch("app.api_client.create_chat", new_callable=AsyncMock) as mock_create:
            mock_create.return_value = {"id": 100}
            
            await handle_start(mock_message)
            
            mock_upsert.assert_awaited_once_with(123, None, "Test")
            mock_create.assert_awaited_once_with(123, None, "Test")
            assert user_chat_map[123] == 100
            mock_message.answer.assert_awaited_once()


async def test_handle_user_message_unregistered(mock_message):
    user_chat_map.clear()
    
    await handle_user_message(mock_message)
    
    mock_message.answer.assert_awaited_once()
    assert "Сначала напишите /start" in mock_message.answer.call_args[0][0]


async def test_handle_user_message_registered(mock_message):
    user_chat_map[123] = 100
    
    with patch("app.api_client.send_message", new_callable=AsyncMock) as mock_send:
        await handle_user_message(mock_message)
        
        mock_send.assert_awaited_once_with(100, sender="user", text="Hello")
