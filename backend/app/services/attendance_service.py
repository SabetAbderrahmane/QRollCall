# backend/app/services/attendance_service.py
from sqlalchemy.orm import Session

from app.core.constants import (
    ATTENDANCE_ALREADY_MARKED,
    ERROR_ATTENDANCE_NOT_FOUND,
    ERROR_EVENT_NOT_FOUND,
    ERROR_INVALID_QR_TOKEN,
    ERROR_USER_NOT_FOUND,
)
from app.models.attendance import Attendance, AttendanceStatus
from app.repositories.attendance_repository import AttendanceRepository
from app.repositories.event_repository import EventRepository
from app.repositories.user_repository import UserRepository
from app.schemas.attendance import AttendanceMarkRequest
from app.services.qr_service import qr_service
from app.utils.datetime_utils import utc_now


class AttendanceService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.attendance_repository = AttendanceRepository(db)
        self.event_repository = EventRepository(db)
        self.user_repository = UserRepository(db)

    def mark_attendance(self, payload: AttendanceMarkRequest, user_id: int) -> Attendance:
        user = self.user_repository.get_by_id(user_id)
        if user is None:
            raise ValueError(ERROR_USER_NOT_FOUND)

        event = self.event_repository.get_by_qr_token(payload.qr_code_token)
        if event is None:
            raise ValueError(ERROR_INVALID_QR_TOKEN)

        if not event.is_active:
            raise ValueError("Event is not active")

        scan_time = utc_now()
        validation = qr_service.validate_event_qr(
            event=event,
            scan_latitude=payload.scan_latitude,
            scan_longitude=payload.scan_longitude,
            scanned_at=scan_time,
        )

        status_value = AttendanceStatus.PRESENT
        rejection_reason = None

        if not validation["valid"]:
            status_value = AttendanceStatus.REJECTED
            rejection_reason = validation["reason"]

        existing_attendance = self.attendance_repository.get_by_event_and_user(
            event_id=event.id,
            user_id=user.id,
        )

        if existing_attendance is not None:
            if existing_attendance.status == AttendanceStatus.REJECTED:
                return self.attendance_repository.update_scan_result(
                    existing_attendance,
                    scanned_at=scan_time,
                    status=status_value,
                    scan_latitude=payload.scan_latitude,
                    scan_longitude=payload.scan_longitude,
                    device_id=payload.device_id,
                    rejection_reason=rejection_reason,
                )

            raise ValueError(ATTENDANCE_ALREADY_MARKED)

        return self.attendance_repository.create(
            event_id=event.id,
            user_id=user.id,
            scanned_at=scan_time,
            status=status_value,
            scan_latitude=payload.scan_latitude,
            scan_longitude=payload.scan_longitude,
            device_id=payload.device_id,
            rejection_reason=rejection_reason,
        )

    def list_attendance(
        self,
        skip: int = 0,
        limit: int = 20,
        event_id: int | None = None,
        user_id: int | None = None,
    ) -> tuple[list[Attendance], int]:
        return self.attendance_repository.list(
            skip=skip,
            limit=limit,
            event_id=event_id,
            user_id=user_id,
        )

    def get_attendance(self, attendance_id: int) -> Attendance | None:
        return self.attendance_repository.get_by_id(attendance_id)

    def require_attendance(self, attendance_id: int) -> Attendance:
        attendance = self.get_attendance(attendance_id)
        if attendance is None:
            raise ValueError(ERROR_ATTENDANCE_NOT_FOUND)
        return attendance

    def get_event_stats(self, event_id: int) -> dict:
        event = self.event_repository.get_by_id(event_id)
        if event is None:
            raise ValueError(ERROR_EVENT_NOT_FOUND)

        return self.attendance_repository.stats_by_event(event_id)

    def get_live_attendance_snapshot(self, event_id: int) -> dict:
        event = self.event_repository.get_by_id(event_id)
        if event is None:
            raise ValueError(ERROR_EVENT_NOT_FOUND)

        items, _ = self.attendance_repository.list(
            skip=0,
            limit=200,
            event_id=event_id,
        )
        stats = self.attendance_repository.stats_by_event(event_id)

        students = []

        for attendance in items:
            user = attendance.user

            if hasattr(attendance.status, "value"):
                status_value = attendance.status.value
            else:
                status_value = str(attendance.status)

            device_id = attendance.device_id
            entry_method = "In-app QR"
            if device_id is None or str(device_id).strip() == "":
                entry_method = "Manual Entry"

            students.append(
                {
                    "attendance_id": attendance.id,
                    "user_id": user.id,
                    "full_name": user.full_name,
                    "email": user.email,
                    "student_id": user.student_id,
                    "profile_image_url": user.profile_image_url,
                    "status": status_value,
                    "scanned_at": attendance.scanned_at,
                    "entry_method": entry_method,
                    "device_id": device_id,
                    "rejection_reason": attendance.rejection_reason,
                }
            )

        return {
            "event_id": event.id,
            "event_name": event.name,
            "location_name": event.location_name,
            "start_time": event.start_time,
            "end_time": event.end_time,
            "is_active": event.is_active,
            "total_records": stats["total_records"],
            "present_count": stats["present_count"],
            "absent_count": stats["absent_count"],
            "rejected_count": stats["rejected_count"],
            "students": students,
        }

    def update_attendance(self, attendance: Attendance, **kwargs) -> Attendance:
        return self.attendance_repository.update(attendance, **kwargs)

    def delete_attendance(self, attendance: Attendance) -> None:
        self.attendance_repository.delete(attendance)