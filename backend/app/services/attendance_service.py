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

        # Get all attendance records for this event
        attendance_records, _ = self.attendance_repository.list(
            skip=0,
            limit=500,  # Increased limit for live dashboard
            event_id=event_id,
        )
        # Map attendance records by user_id
        attendance_by_user = {a.user_id: a for a in attendance_records}
        
        students = []
        
        # Determine the set of users to show
        if event.class_id is not None:
            # If class-linked, show all active students in the roster
            from app.models.class_membership import ClassMembership, MembershipRole, MembershipStatus
            from sqlalchemy import select
            
            roster_members = self.db.scalars(
                select(ClassMembership).where(
                    ClassMembership.class_id == event.class_id,
                    ClassMembership.status == MembershipStatus.ACTIVE,
                    ClassMembership.role == MembershipRole.STUDENT
                )
            ).all()
            
            for membership in roster_members:
                user = membership.user
                attendance = attendance_by_user.get(user.id)
                
                if attendance:
                    status = attendance.status.value if hasattr(attendance.status, "value") else str(attendance.status)
                    scanned_at = attendance.scanned_at
                    entry_method = "In-app QR" if attendance.device_id else "Manual Entry"
                    attendance_id = attendance.id
                    device_id = attendance.device_id
                    rejection_reason = attendance.rejection_reason
                else:
                    status = "absent"
                    scanned_at = event.start_time # Use start time as placeholder
                    entry_method = "N/A"
                    attendance_id = 0 # Dummy ID for absent students
                    device_id = None
                    rejection_reason = None
                
                students.append({
                    "attendance_id": attendance_id,
                    "user_id": user.id,
                    "full_name": user.full_name,
                    "email": user.email,
                    "student_id": user.student_id,
                    "profile_image_url": user.profile_image_url,
                    "status": status,
                    "scanned_at": scanned_at,
                    "entry_method": entry_method,
                    "device_id": device_id,
                    "rejection_reason": rejection_reason,
                })
        else:
            # Standalone event: only show people who scanned
            for attendance in attendance_records:
                user = attendance.user
                status = attendance.status.value if hasattr(attendance.status, "value") else str(attendance.status)
                entry_method = "In-app QR" if attendance.device_id else "Manual Entry"
                
                students.append({
                    "attendance_id": attendance.id,
                    "user_id": user.id,
                    "full_name": user.full_name,
                    "email": user.email,
                    "student_id": user.student_id,
                    "profile_image_url": user.profile_image_url,
                    "status": status,
                    "scanned_at": attendance.scanned_at,
                    "entry_method": entry_method,
                    "device_id": attendance.device_id,
                    "rejection_reason": attendance.rejection_reason,
                })

        # Calculate counts
        present_count = sum(1 for s in students if s["status"] == "present")
        rejected_count = sum(1 for s in students if s["status"] == "rejected")
        absent_count = sum(1 for s in students if s["status"] == "absent")
        total_records = len(students)

        return {
            "event_id": event.id,
            "event_name": event.name,
            "location_name": event.location_name,
            "start_time": event.start_time,
            "end_time": event.end_time,
            "is_active": event.is_active,
            "total_records": total_records,
            "present_count": present_count,
            "absent_count": absent_count,
            "rejected_count": rejected_count,
            "students": students,
        }


    def update_attendance(self, attendance: Attendance, **kwargs) -> Attendance:
        return self.attendance_repository.update(attendance, **kwargs)

    def delete_attendance(self, attendance: Attendance) -> None:
        self.attendance_repository.delete(attendance)