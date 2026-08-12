"""Conftest: override DATABASE_URL to in-memory SQLite, create tables before tests."""
import os

import pytest

# Set env before any app import so Settings picks them up
os.environ["BOT_TOKEN"] = "1234567890:AAtest_token_for_tests_only_not_real"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["OPERATOR_ALLOWLIST"] = "999"

from httpx import ASGITransport, AsyncClient  # noqa: E402

from app.database import Base, engine  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
async def create_tables():
    """Create all tables once per test session in the in-memory DB."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
