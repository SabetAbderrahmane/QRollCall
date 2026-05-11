from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload
from datetime import datetime

from app.models.class_invitation import ClassInvitation, InvitationStatus

class InvitationRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, invitation_id: int) -> ClassInvitation | None:
        return self.db.scalars(
            select(ClassInvitation).where(ClassInvitation.id == invitation_id)
        ).first()
        
    def get_by_token(self, token: str) -> ClassInvitation | None:
        return self.db.scalars(
            select(ClassInvitation).where(ClassInvitation.invitation_token == token)
        ).first()

    def get_pending_for_email_username(self, class_id: int, email: str | None, username: str | None) -> ClassInvitation | None:
        stmt = select(ClassInvitation).where(
            ClassInvitation.class_id == class_id,
            ClassInvitation.status == InvitationStatus.PENDING
        )
        
        conds = []
        if email:
            conds.append(ClassInvitation.invited_email == email)
        if username:
            conds.append(ClassInvitation.invited_username == username)
            
        if not conds:
            return None
            
        # Using simple python filtering for an OR clause since it's easier and fast enough
        invitations = self.db.scalars(stmt).all()
        for inv in invitations:
            if email and inv.invited_email == email:
                return inv
            if username and inv.invited_username == username:
                return inv
                
        return None

    def list_by_class(self, class_id: int) -> list[ClassInvitation]:
        stmt = select(ClassInvitation).where(ClassInvitation.class_id == class_id)
        return list(self.db.scalars(stmt).all())

    def list_my_invitations(self, email: str, username: str | None = None) -> list[ClassInvitation]:
        stmt = select(ClassInvitation).options(joinedload(ClassInvitation.class_room), joinedload(ClassInvitation.creator)).where(
            ClassInvitation.status == InvitationStatus.PENDING
        )
        # Python-side filter for OR clause
        results = []
        for inv in self.db.scalars(stmt).all():
            if inv.invited_email == email or (username and inv.invited_username == username):
                results.append(inv)
        return results

    def create(self, **kwargs) -> ClassInvitation:
        inv = ClassInvitation(**kwargs)
        self.db.add(inv)
        self.db.commit()
        self.db.refresh(inv)
        return inv

    def update(self, invitation: ClassInvitation, **kwargs) -> ClassInvitation:
        for key, value in kwargs.items():
            if hasattr(invitation, key):
                setattr(invitation, key, value)
        self.db.commit()
        self.db.refresh(invitation)
        return invitation
