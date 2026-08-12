from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite+aiosqlite:///./support.db"
    BOT_TOKEN: str
    OPERATOR_ALLOWLIST: str = ""  # comma-separated Telegram user IDs

    class Config:
        env_file = ".env"

    @property
    def operator_ids(self) -> list[int]:
        return [int(x.strip()) for x in self.OPERATOR_ALLOWLIST.split(",") if x.strip()]


settings = Settings()
