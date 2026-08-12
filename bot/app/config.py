from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    BOT_TOKEN: str
    API_BASE_URL: str = "http://localhost:8000"

    class Config:
        env_file = ".env"


settings = Settings()
