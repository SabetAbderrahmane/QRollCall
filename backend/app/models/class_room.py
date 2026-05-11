from datetime import datetime
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class ClassRoom(BaseModel):
    __tablename__ = "classes"

    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    class_code: Mapped[str | None] = mapped_column(String(64), unique=True, index=True, nullable=True)

    teacher_user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    location_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    default_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    default_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    default_geofence_radius_meters: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=100,
    )

    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    teacher = relationship(
        "User",
        foreign_keys=[teacher_user_id],
    )
    
    events = relationship(
        "Event",
        back_populates="class_room",
    )

    memberships = relationship(
        "ClassMembership",
        back_populates="class_room",
        cascade="all, delete-orphan",
    )

    invitations = relationship(
        "ClassInvitation",
        back_populates="class_room",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<ClassRoom id={self.id} name={self.name}>"
