# backend/app/api/v1/reports.py
from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import DbSession
from app.schemas.report import (
    DashboardSummaryResponse,
    EventAttendanceSummary,
    ExportReportRequest,
    ExportReportResponse,
    UserAttendanceSummary,
)
from app.services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["reports"])


def _raise_report_http_error(message: str) -> None:
    status_code = (
        status.HTTP_404_NOT_FOUND
        if "not found" in message.lower()
        else status.HTTP_400_BAD_REQUEST
    )
    raise HTTPException(status_code=status_code, detail=message)


@router.get("/dashboard", response_model=DashboardSummaryResponse)
def get_dashboard_summary(db: DbSession) -> DashboardSummaryResponse:
    service = ReportService(db)
    return service.get_dashboard_summary()


@router.get("/events/{event_id}", response_model=EventAttendanceSummary)
def get_event_report(event_id: int, db: DbSession) -> EventAttendanceSummary:
    service = ReportService(db)

    try:
        return service.get_event_summary(event_id)
    except ValueError as exc:
        _raise_report_http_error(str(exc))


@router.get("/users/{user_id}", response_model=UserAttendanceSummary)
def get_user_report(user_id: int, db: DbSession) -> UserAttendanceSummary:
    service = ReportService(db)

    try:
        return service.get_user_summary(user_id)
    except ValueError as exc:
        _raise_report_http_error(str(exc))


@router.post("/export", response_model=ExportReportResponse)
def export_report(
    payload: ExportReportRequest,
    db: DbSession,
) -> ExportReportResponse:
    service = ReportService(db)

    try:
        if payload.event_id is not None:
            return service.export_event_report(payload.event_id, payload.format)
        return service.export_user_report(payload.user_id, payload.format)
    except ValueError as exc:
        _raise_report_http_error(str(exc))


@router.get("/export/event/{event_id}", response_model=ExportReportResponse)
def export_event_report(
    event_id: int,
    db: DbSession,
    format: str = Query(..., pattern="^(csv|pdf)$"),
) -> ExportReportResponse:
    service = ReportService(db)

    try:
        return service.export_event_report(event_id, format)
    except ValueError as exc:
        _raise_report_http_error(str(exc))


@router.get("/export/user/{user_id}", response_model=ExportReportResponse)
def export_user_report(
    user_id: int,
    db: DbSession,
    format: str = Query(..., pattern="^(csv|pdf)$"),
) -> ExportReportResponse:
    service = ReportService(db)

    try:
        return service.export_user_report(user_id, format)
    except ValueError as exc:
        _raise_report_http_error(str(exc))
