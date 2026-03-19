# backend/app/services/report_service.py
from collections import defaultdict
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.constants import REPORT_FORMAT_CSV, REPORT_FORMAT_PDF, SUPPORTED_REPORT_FORMATS
from app.models.attendance import Attendance, AttendanceStatus
from app.models.event import Event
from app.models.user import User
from app.schemas.report import (
    AttendanceTrendPoint,
    DashboardSummaryResponse,
    EventAttendanceSummary,
    ExportReportResponse,
    UserAttendanceSummary,
)
from app.utils.csv_export import write_csv_file
from app.utils.pdf_export import write_simple_pdf


class ReportService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.export_dir = Path("storage/reports")
        self.export_dir.mkdir(parents=True, exist_ok=True)

    def get_event_summary(self, event_id: int) -> EventAttendanceSummary:
        event = self.db.get(Event, event_id)
        if event is None:
            raise ValueError("Event not found")

        total_records = self.db.scalar(
            select(func.count(Attendance.id)).where(Attendance.event_id == event_id)
        ) or 0

        present_count = self.db.scalar(
            select(func.count(Attendance.id)).where(
                Attendance.event_id == event_id,
                Attendance.status == AttendanceStatus.PRESENT,
            )
        ) or 0

        absent_count = self.db.scalar(
            select(func.count(Attendance.id)).where(
                Attendance.event_id == event_id,
                Attendance.status == AttendanceStatus.ABSENT,
            )
        ) or 0

        rejected_count = self.db.scalar(
            select(func.count(Attendance.id)).where(
                Attendance.event_id == event_id,
                Attendance.status == AttendanceStatus.REJECTED,
            )
        ) or 0

        attendance_percentage = (
            (present_count / total_records) * 100 if total_records > 0 else 0.0
        )

        return EventAttendanceSummary(
            event_id=event.id,
            event_name=event.name,
            start_time=event.start_time,
            total_records=total_records,
            present_count=present_count,
            absent_count=absent_count,
            rejected_count=rejected_count,
            attendance_percentage=round(attendance_percentage, 2),
        )

    def get_user_summary(self, user_id: int) -> UserAttendanceSummary:
        user = self.db.get(User, user_id)
        if user is None:
            raise ValueError("User not found")

        total_events = self.db.scalar(select(func.count(Event.id))) or 0

        attended_events = self.db.scalar(
            select(func.count(Attendance.id)).where(
                Attendance.user_id == user_id,
                Attendance.status == AttendanceStatus.PRESENT,
            )
        ) or 0

        missed_events = max(total_events - attended_events, 0)
        attendance_percentage = (
            (attended_events / total_events) * 100 if total_events > 0 else 0.0
        )

        return UserAttendanceSummary(
            user_id=user.id,
            full_name=user.full_name,
            email=user.email,
            total_events=total_events,
            attended_events=attended_events,
            missed_events=missed_events,
            attendance_percentage=round(attendance_percentage, 2),
        )

    def get_dashboard_summary(self) -> DashboardSummaryResponse:
        total_users = self.db.scalar(select(func.count(User.id))) or 0
        total_events = self.db.scalar(select(func.count(Event.id))) or 0
        total_attendance_records = self.db.scalar(select(func.count(Attendance.id))) or 0

        total_present = self.db.scalar(
            select(func.count(Attendance.id)).where(
                Attendance.status == AttendanceStatus.PRESENT
            )
        ) or 0

        total_absent = self.db.scalar(
            select(func.count(Attendance.id)).where(
                Attendance.status == AttendanceStatus.ABSENT
            )
        ) or 0

        total_rejected = self.db.scalar(
            select(func.count(Attendance.id)).where(
                Attendance.status == AttendanceStatus.REJECTED
            )
        ) or 0

        return DashboardSummaryResponse(
            total_users=total_users,
            total_events=total_events,
            total_attendance_records=total_attendance_records,
            total_present=total_present,
            total_absent=total_absent,
            total_rejected=total_rejected,
            low_attendance_users=self._count_low_attendance_users(),
            recent_trends=self._build_recent_trends(),
        )

    def export_event_report(self, event_id: int, format: str) -> ExportReportResponse:
        self._validate_format(format)
        summary = self.get_event_summary(event_id)

        if format == REPORT_FORMAT_CSV:
            file_path = write_csv_file(
                file_path=self.export_dir / f"event_{event_id}_report.csv",
                headers=[
                    "event_id",
                    "event_name",
                    "start_time",
                    "total_records",
                    "present_count",
                    "absent_count",
                    "rejected_count",
                    "attendance_percentage",
                ],
                rows=[
                    [
                        str(summary.event_id),
                        summary.event_name,
                        summary.start_time.isoformat(),
                        str(summary.total_records),
                        str(summary.present_count),
                        str(summary.absent_count),
                        str(summary.rejected_count),
                        str(summary.attendance_percentage),
                    ]
                ],
            )
        else:
            file_path = write_simple_pdf(
                file_path=self.export_dir / f"event_{event_id}_report.pdf",
                title="Event Attendance Report",
                lines=[
                    f"Event ID: {summary.event_id}",
                    f"Event Name: {summary.event_name}",
                    f"Start Time: {summary.start_time.isoformat()}",
                    f"Total Records: {summary.total_records}",
                    f"Present: {summary.present_count}",
                    f"Absent: {summary.absent_count}",
                    f"Rejected: {summary.rejected_count}",
                    f"Attendance Percentage: {summary.attendance_percentage}%",
                ],
            )

        return ExportReportResponse(
            format=format,
            file_name=Path(file_path).name,
            file_path=file_path,
        )

    def export_user_report(self, user_id: int, format: str) -> ExportReportResponse:
        self._validate_format(format)
        summary = self.get_user_summary(user_id)

        if format == REPORT_FORMAT_CSV:
            file_path = write_csv_file(
                file_path=self.export_dir / f"user_{user_id}_report.csv",
                headers=[
                    "user_id",
                    "full_name",
                    "email",
                    "total_events",
                    "attended_events",
                    "missed_events",
                    "attendance_percentage",
                ],
                rows=[
                    [
                        str(summary.user_id),
                        summary.full_name,
                        summary.email,
                        str(summary.total_events),
                        str(summary.attended_events),
                        str(summary.missed_events),
                        str(summary.attendance_percentage),
                    ]
                ],
            )
        else:
            file_path = write_simple_pdf(
                file_path=self.export_dir / f"user_{user_id}_report.pdf",
                title="User Attendance Report",
                lines=[
                    f"User ID: {summary.user_id}",
                    f"Full Name: {summary.full_name}",
                    f"Email: {summary.email}",
                    f"Total Events: {summary.total_events}",
                    f"Attended Events: {summary.attended_events}",
                    f"Missed Events: {summary.missed_events}",
                    f"Attendance Percentage: {summary.attendance_percentage}%",
                ],
            )

        return ExportReportResponse(
            format=format,
            file_name=Path(file_path).name,
            file_path=file_path,
        )

    @staticmethod
    def _validate_format(format: str) -> None:
        if format not in SUPPORTED_REPORT_FORMATS:
            raise ValueError("Unsupported report format")

    def _count_low_attendance_users(self, threshold_percent: float = 75.0) -> int:
        users = self.db.scalars(select(User)).all()
        total_events = self.db.scalar(select(func.count(Event.id))) or 0

        if total_events == 0:
            return 0

        count = 0
        for user in users:
            attended_events = self.db.scalar(
                select(func.count(Attendance.id)).where(
                    Attendance.user_id == user.id,
                    Attendance.status == AttendanceStatus.PRESENT,
                )
            ) or 0
            percentage = (attended_events / total_events) * 100
            if percentage < threshold_percent:
                count += 1

        return count

    def _build_recent_trends(self) -> list[AttendanceTrendPoint]:
        rows = self.db.scalars(
            select(Attendance).order_by(Attendance.scanned_at.desc()).limit(100)
        ).all()

        grouped: dict[str, int] = defaultdict(int)
        for row in rows:
            label = row.scanned_at.strftime("%Y-%m-%d")
            grouped[label] += 1

        return [
            AttendanceTrendPoint(label=label, value=value)
            for label, value in sorted(grouped.items())
        ][-7:]
