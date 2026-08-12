from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    DATABASE_URL: str = "sqlite+aiosqlite:///./support.db"
    BOT_TOKEN: str
    OPERATOR_ALLOWLIST: str = ""  # comma-separated Telegram user IDs
    BOT_CALLBACK_URL: str = "http://localhost:8001/send"

    @property
    def operator_ids(self) -> list[int]:
        return [int(x.strip()) for x in self.OPERATOR_ALLOWLIST.split(",") if x.strip()]


settings = Settings()
