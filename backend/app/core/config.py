from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    APP_NAME: str = "QR-Attend API"
    APP_VERSION: str = "1.0.0"
    APP_ENV: str = "development"
    DEBUG: bool = True

    API_V1_PREFIX: str = "/api/v1"

    SECRET_KEY: str = "change-me-in-production"

    DATABASE_URL: str | None = None
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_NAME: str = "qr_attend"
    DB_USER: str = "postgres"
    DB_PASSWORD: str = "postgres"

    CORS_ORIGINS: str = "http://localhost:3000,http://127.0.0.1:3000"

    FIREBASE_CREDENTIALS_PATH: str | None = None

    QR_IMAGE_DIR: str = str(BASE_DIR / "storage" / "qr_codes")
    DEFAULT_QR_VALIDITY_MINUTES: int = 15
    DEFAULT_GEOFENCE_RADIUS_METERS: int = 100

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    @property
    def database_url(self) -> str:
        if self.DATABASE_URL and self.DATABASE_URL.strip():
            return self.DATABASE_URL.strip()

        return (
            f"postgresql+psycopg2://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

    @property
    def cors_allow_all(self) -> bool:
        return self.CORS_ORIGINS.strip() == "*"

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_allow_all:
            return ["*"]

        origins = [
            origin.strip()
            for origin in self.CORS_ORIGINS.split(",")
            if origin.strip()
        ]
        return origins

    @property
    def is_production(self) -> bool:
        return self.APP_ENV.lower() == "production"


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    Path(settings.QR_IMAGE_DIR).mkdir(parents=True, exist_ok=True)
    return settings