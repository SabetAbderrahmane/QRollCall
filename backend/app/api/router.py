# backend/app/api/router.py
from fastapi import APIRouter

from app.api.v1.attendance import router as attendance_router
from app.api.v1.auth import router as auth_router
from app.api.v1.events import router as events_router
from app.api.v1.health import router as health_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.qr import router as qr_router
from app.api.v1.reports import router as reports_router
from app.api.v1.users import router as users_router
from app.core.config import get_settings

settings = get_settings()

api_router = APIRouter(prefix=settings.API_V1_PREFIX)

api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(events_router)
api_router.include_router(attendance_router)
api_router.include_router(qr_router)
api_router.include_router(notifications_router)
api_router.include_router(reports_router)
