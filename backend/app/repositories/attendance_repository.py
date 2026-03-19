# backend/app/repositories/attendance_repository.py
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.attendance import Attendance, AttendanceStatus


class AttendanceRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, **kwargs) -> Attendance:
        attendance = Attendance(**kwargs)
        self.db.add(attendance)
        self.db.commit()
        self.db.refresh(attendance)
        return attendance

    def get_by_id(self, attendance_id: int) -> Attendance | None:
        return self.db.get(Attendance, attendance_id)

    def get_by_event_and_user(self, event_id: int, user_id: int) -> Attendance | None:
        return self.db.scalar(
            select(Attendance).where(
                Attendance.event_id == event_id,
                Attendance.user_id == user_id,
            )
        )

    def list(
        self,
        skip: int = 0,
        limit: int = 20,
        event_id: int | None = None,
        user_id: int | None = None,
    ) -> tuple[list[Attendance], int]:
        query = select(Attendance)
        count_query = select(func.count(Attendance.id))

        if event_id is not None:
            query = query.where(Attendance.event_id == event_id)
            count_query = count_query.where(Attendance.event_id == event_id)

        if user_id is not None:
            query = query.where(Attendance.user_id == user_id)
            count_query = count_query.where(Attendance.user_id == user_id)

        items = self.db.scalars(
            query.order_by(Attendance.scanned_at.desc()).offset(skip).limit(limit)
        ).all()
        total = self.db.scalar(count_query) or 0
        return items, total

    def stats_by_event(self, event_id: int) -> dict:
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

        return {
            "event_id": event_id,
            "total_records": total_records,
            "present_count": present_count,
            "absent_count": absent_count,
            "rejected_count": rejected_count,
        }

    def update(self, attendance: Attendance, **kwargs) -> Attendance:
        for field, value in kwargs.items():
            setattr(attendance, field, value)

        self.db.commit()
        self.db.refresh(attendance)
        return attendance

    def delete(self, attendance: Attendance) -> None:
        self.db.delete(attendance)
        self.db.commit()
