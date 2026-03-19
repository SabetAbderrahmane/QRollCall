from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Enum as SqlEnum, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship


from app.models.base import BaseModel


class AttendanceStatus(str, Enum):
    PRESENT = "present"
    ABSENT = "absent"
    REJECTED = "rejected"


class Attendance(BaseModel):
    __tablename__ = "attendances"
    __table_args__ = (
        UniqueConstraint("event_id", "user_id", name="uq_attendance_event_user"),
    )

    event_id: Mapped[int] = mapped_column(
        ForeignKey("events.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    scanned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )
    status: Mapped[AttendanceStatus] = mapped_column(
        SqlEnum(AttendanceStatus, name="attendance_status"),
        nullable=False,
        default=AttendanceStatus.PRESENT,
    )

    scan_latitude: Mapped[float | None] = mapped_column(nullable=True)
    scan_longitude: Mapped[float | None] = mapped_column(nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(String(255), nullable=True)

    event = relationship("Event", back_populates="attendances")
    user = relationship("User", back_populates="attendances")

    def __repr__(self) -> str:
        return (
            f"<Attendance id={self.id} event_id={self.event_id} "
            f"user_id={self.user_id} status={self.status}>"
        )
