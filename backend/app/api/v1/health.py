from pathlib import Path

from fastapi import APIRouter, Response, status
from sqlalchemy import text

from app.api.deps import DbSession
from app.core.config import get_settings

router = APIRouter(prefix="/health", tags=["health"])
settings = get_settings()


def _storage_check() -> dict:
    qr_dir = Path(settings.QR_IMAGE_DIR)

    try:
        qr_dir.mkdir(parents=True, exist_ok=True)
        return {
            "available": True,
            "path": str(qr_dir).replace("\\", "/"),
        }
    except Exception as exc:
        return {
            "available": False,
            "path": str(qr_dir).replace("\\", "/"),
            "error": str(exc),
        }


@router.get("")
def health_check() -> dict:
    storage = _storage_check()

    return {
        "success": True,
        "status": "healthy",
        "service": settings.APP_NAME,
        "environment": settings.APP_ENV,
        "checks": {
            "qr_storage": storage,
            "firebase": {
                "configured": bool(settings.FIREBASE_CREDENTIALS_PATH),
            },
        },
    }


@router.get("/ready")
def readiness_check(
    response: Response,
    db: DbSession,
) -> dict:
    try:
        db.execute(text("SELECT 1"))
        database = {"available": True}
    except Exception as exc:
        database = {
            "available": False,
            "error": str(exc),
        }

    storage = _storage_check()

    ready = database["available"] and storage["available"]
    response.status_code = (
        status.HTTP_200_OK if ready else status.HTTP_503_SERVICE_UNAVAILABLE
    )

    return {
        "success": ready,
        "status": "ready" if ready else "not_ready",
        "service": settings.APP_NAME,
        "checks": {
            "database": database,
            "qr_storage": storage,
            "firebase": {
                "configured": bool(settings.FIREBASE_CREDENTIALS_PATH),
            },
        },
    }


@router.get("/live")
def liveness_check() -> dict:
    return {
        "success": True,
        "status": "alive",
        "service": settings.APP_NAME,
    }