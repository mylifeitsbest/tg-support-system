"""In-memory user → chat_id mapping (MVP). Replace with Redis/DB for multi-instance."""
user_chat_map: dict[int, int] = {}
