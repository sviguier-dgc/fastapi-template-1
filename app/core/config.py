import logging

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    ENV: str = "local"
    LOG_LEVEL: int = logging.INFO
    LOG_NAME: str = "fastapi_template"
    PROJECT_NAME: str = "FastApi template"

    API_PREFIX: str = "/api"
    BACKEND_CORS_ORIGINS: list[str] = ["http://localhost:5173", "http://localhost:3000"]

    SQLALCHEMY_DATABASE_URI: str = (
        "postgresql+asyncpg://postgres:postgres@localhost:5434/fastapi_template_db"
    )
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    GITHUB_ACCESS_TOKEN: str | None = None
    GCLOUD_PROJECT_ID: str | None = "sandbox-sviguier"

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
