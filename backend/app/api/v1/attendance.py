# backend/app/api/v1/attendance.py
from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import DbSession
from app.core.constants import (
    ATTENDANCE_ALREADY_MARKED,
    ERROR_EVENT_NOT_FOUND,
    ERROR_INVALID_QR_TOKEN,
    ERROR_USER_NOT_FOUND,
)
from app.schemas.attendance import (
    AttendanceListResponse,
    AttendanceMarkRequest,
    AttendanceResponse,
    AttendanceStatsResponse,
)
from app.services.attendance_service import AttendanceService

router = APIRouter(prefix="/attendance", tags=["attendance"])


def _raise_attendance_http_error(message: str) -> None:
    normalized = message.lower()

    if message in {ERROR_USER_NOT_FOUND, ERROR_EVENT_NOT_FOUND, ERROR_INVALID_QR_TOKEN}:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message)

    if message == ATTENDANCE_ALREADY_MARKED:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=message)

    if "not found" in normalized:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message)

    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=message)


@router.post("/mark", response_model=AttendanceResponse, status_code=status.HTTP_201_CREATED)
def mark_attendance(payload: AttendanceMarkRequest, db: DbSession) -> AttendanceResponse:
    service = AttendanceService(db)

    try:
        attendance = service.mark_attendance(payload)
    except ValueError as exc:
        _raise_attendance_http_error(str(exc))

    return AttendanceResponse.model_validate(attendance)


@router.get("", response_model=AttendanceListResponse)
def list_attendance(
    db: DbSession,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=200),
    event_id: int | None = Query(default=None, ge=1),
    user_id: int | None = Query(default=None, ge=1),
) -> AttendanceListResponse:
    service = AttendanceService(db)
    items, total = service.list_attendance(
        skip=skip,
        limit=limit,
        event_id=event_id,
        user_id=user_id,
    )
    return AttendanceListResponse(items=items, total=total)


@router.get("/stats/{event_id}", response_model=AttendanceStatsResponse)
def get_attendance_stats(event_id: int, db: DbSession) -> AttendanceStatsResponse:
    service = AttendanceService(db)

    try:
        stats = service.get_event_stats(event_id)
    except ValueError as exc:
        _raise_attendance_http_error(str(exc))

    return AttendanceStatsResponse(**stats)
