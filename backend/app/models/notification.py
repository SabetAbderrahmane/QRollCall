from enum import Enum

from sqlalchemy import Boolean, Enum as SqlEnum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel



class NotificationType(str, Enum):
    REMINDER = "reminder"
    ATTENDANCE_CONFIRMED = "attendance_confirmed"
    MISSED_EVENT = "missed_event"
    ADMIN_BROADCAST = "admin_broadcast"


class Notification(BaseModel):
    __tablename__ = "notifications"

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    event_id: Mapped[int | None] = mapped_column(
        ForeignKey("events.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)

    notification_type: Mapped[NotificationType] = mapped_column(
        SqlEnum(NotificationType, name="notification_type"),
        nullable=False,
        default=NotificationType.REMINDER,
    )

    is_read: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    user = relationship("User")
    event = relationship("Event")

    def __repr__(self) -> str:
        return (
            f"<Notification id={self.id} user_id={self.user_id} "
            f"type={self.notification_type} is_read={self.is_read}>"
        )
