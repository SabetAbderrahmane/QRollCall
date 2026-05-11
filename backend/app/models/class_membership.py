from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Enum as SqlEnum, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel
from app.utils.datetime_utils import utc_now


class MembershipRole(str, Enum):
    TEACHER = "teacher"
    STUDENT = "student"
    ASSISTANT = "assistant"


class MembershipStatus(str, Enum):
    INVITED = "invited"
    ACTIVE = "active"
    REMOVED = "removed"
    DECLINED = "declined"


class ClassMembership(BaseModel):
    __tablename__ = "class_memberships"
    __table_args__ = (
        UniqueConstraint("class_id", "user_id", name="uq_class_membership_user"),
    )

    class_id: Mapped[int] = mapped_column(
        ForeignKey("classes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    role: Mapped[MembershipRole] = mapped_column(
        SqlEnum(MembershipRole, name="membership_role"),
        nullable=False,
        default=MembershipRole.STUDENT,
    )
    
    status: Mapped[MembershipStatus] = mapped_column(
        SqlEnum(MembershipStatus, name="membership_status"),
        nullable=False,
        default=MembershipStatus.ACTIVE,
    )

    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=utc_now,
    )

    class_room = relationship("ClassRoom", back_populates="memberships")
    user = relationship("User")

    def __repr__(self) -> str:
        return f"<ClassMembership class_id={self.class_id} user_id={self.user_id} role={self.role}>"
