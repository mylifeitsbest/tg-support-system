"""Telegram initData HMAC-SHA256 auth + operator allowlist dependency."""
import hashlib
import hmac
import urllib.parse
from typing import Annotated

from fastapi import Depends, Header, HTTPException, status

from app.config import settings


def _parse_init_data(raw: str) -> dict[str, str]:
    """Parse URL-encoded initData string into a dict."""
    return dict(urllib.parse.parse_qsl(raw, keep_blank_values=True))


def _validate_init_data(init_data: str, bot_token: str) -> dict:
    """Validate Telegram WebApp initData HMAC and return parsed payload.

    Raises HTTPException 401 if signature is invalid.
    """
    params = _parse_init_data(init_data)
    received_hash = params.pop("hash", None)
    if not received_hash:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing hash")

    # Build data-check-string
    data_check = "\n".join(f"{k}={v}" for k, v in sorted(params.items()))

    # Derive secret key
    secret_key = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    expected = hmac.new(secret_key, data_check.encode(), hashlib.sha256).hexdigest()

    if not hmac.compare_digest(expected, received_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid initData")

    return params


def get_current_operator(
    authorization: Annotated[str | None, Header()] = None,
) -> int:
    """FastAPI dependency: validates initData, checks allowlist, returns operator telegram_id."""
    if not authorization or not authorization.startswith("tma "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing tma token")

    init_data_raw = authorization[4:]
    params = _validate_init_data(init_data_raw, settings.BOT_TOKEN)

    # Extract telegram user id from user JSON field
    import json

    user_raw = params.get("user", "{}")
    try:
        user_obj = json.loads(user_raw)
        tg_id = int(user_obj["id"])
    except (KeyError, ValueError, json.JSONDecodeError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Cannot parse user")

    if tg_id not in settings.operator_ids:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not an operator")

    return tg_id


OperatorDep = Annotated[int, Depends(get_current_operator)]
