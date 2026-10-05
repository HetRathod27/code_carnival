from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    AUTH_PROVIDER: str = "dev"
    JWT_SECRET: str = "dev-jwt-secret-queueless-123456"
    SUPABASE_URL: str = ""
    SUPABASE_JWT_SECRET: str = ""
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/queueless_dev"
    TEST_DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/queueless_test"
    INTERNAL_TICK_SECRET: str = "default_dev_tick_secret"
    DEFAULT_TIMEZONE: str = "Asia/Kolkata"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
