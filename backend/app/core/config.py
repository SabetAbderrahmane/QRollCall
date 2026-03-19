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

    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_NAME: str = "qr_attend"
    DB_USER: str = "postgres"
    DB_PASSWORD: str = "postgres"

    CORS_ORIGINS: str = "*"

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
        return (
            f"postgresql+psycopg2://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

    @property
    def cors_origin_list(self) -> list[str]:
        if self.CORS_ORIGINS.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    Path(settings.QR_IMAGE_DIR).mkdir(parents=True, exist_ok=True)
    return settings
