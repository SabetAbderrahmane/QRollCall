from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Enum as SqlEnum, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class ClassInvitation(BaseModel):
    __tablename__ = "class_invitations"

    class_id: Mapped[int] = mapped_column(
        ForeignKey("classes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    invited_email: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    invited_username: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    
    invited_user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    invitation_token: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)

    status: Mapped[InvitationStatus] = mapped_column(
        SqlEnum(InvitationStatus, name="invitation_status"),
        nullable=False,
        default=InvitationStatus.PENDING,
    )

    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    
    created_by_user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    declined_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    class_room = relationship("ClassRoom", back_populates="invitations")
    invited_user = relationship("User", foreign_keys=[invited_user_id])
    creator = relationship("User", foreign_keys=[created_by_user_id])

    def __repr__(self) -> str:
        return f"<ClassInvitation class_id={self.class_id} token={self.invitation_token} status={self.status}>"
