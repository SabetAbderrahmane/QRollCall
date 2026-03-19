from fastapi import APIRouter

router = APIRouter(prefix="/health", tags=["health"])


@router.get("")
def health_check() -> dict:
    return {
        "success": True,
        "status": "healthy",
    }


@router.get("/ready")
def readiness_check() -> dict:
    return {
        "success": True,
        "status": "ready",
    }


@router.get("/live")
def liveness_check() -> dict:
    return {
        "success": True,
        "status": "alive",
    }
