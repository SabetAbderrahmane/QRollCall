from datetime import datetime, timedelta
import secrets
from sqlalchemy.orm import Session

from app.models.class_room import ClassRoom
from app.models.class_membership import ClassMembership, MembershipRole, MembershipStatus
from app.models.class_invitation import ClassInvitation, InvitationStatus
from app.models.notification import NotificationType
from app.models.user import User

from app.repositories.class_repository import ClassRepository
from app.repositories.invitation_repository import InvitationRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.user_repository import UserRepository
from app.schemas.class_room import ClassRoomCreate, ClassRoomUpdate
from app.utils.datetime_utils import utc_now

class ClassService:
    def __init__(self, db: Session):
        self.db = db
        self.class_repo = ClassRepository(db)
        self.inv_repo = InvitationRepository(db)
        self.user_repo = UserRepository(db)
        self.notif_repo = NotificationRepository(db)

    def create_class(self, data: ClassRoomCreate, teacher_id: int) -> ClassRoom:
        return self.class_repo.create(
            name=data.name,
            description=data.description,
            location_name=data.location_name,
            default_latitude=data.default_latitude,
            default_longitude=data.default_longitude,
            default_geofence_radius_meters=data.default_geofence_radius_meters,
            class_code=data.class_code,
            teacher_user_id=teacher_id
        )

    def get_class(self, class_id: int) -> ClassRoom:
        cls_obj = self.class_repo.get_by_id(class_id)
        if not cls_obj:
            raise ValueError("Class not found")
        return cls_obj

    def list_my_classes(self, user_id: int) -> list[ClassRoom]:
        return self.class_repo.list_my_classes(user_id)

    def list_created_classes(self, teacher_id: int) -> list[ClassRoom]:
        return self.class_repo.list_created_classes(teacher_id)

    def get_roster(self, class_id: int, requesting_user_id: int) -> list[ClassMembership]:
        # Verify permissions: must be an active member
        mem = self.class_repo.get_membership(class_id, requesting_user_id)
        if not mem or mem.status != MembershipStatus.ACTIVE:
            raise ValueError("Not authorized to view roster")
        return self.class_repo.list_students(class_id)

    def create_invitation(self, class_id: int, creator_id: int, target_email: str | None, target_username: str | None) -> ClassInvitation:
        cls_obj = self.get_class(class_id)
        if cls_obj.teacher_user_id != creator_id:
            raise ValueError("Only the teacher can invite students")
            
        if not target_email and not target_username:
            raise ValueError("Must provide email or username")
            
        # Check existing pending invite
        existing = self.inv_repo.get_pending_for_email_username(class_id, target_email, target_username)
        if existing:
            return existing

        target_user = None
        if target_email:
            target_user = self.user_repo.get_by_email(target_email)
        elif target_username:
            target_user = self.user_repo.get_by_firebase_uid(target_username) # fallback, maybe build ge_by_username
            
        invitation = self.inv_repo.create(
            class_id=class_id,
            invited_email=target_email,
            invited_username=target_username,
            invited_user_id=target_user.id if target_user else None,
            invitation_token=secrets.token_urlsafe(32),
            status=InvitationStatus.PENDING,
            expires_at=utc_now() + timedelta(days=7),
            created_by_user_id=creator_id
        )

        # ── Persist an in-app notification so the student sees it immediately ──
        if target_user is not None:
            cls_obj_name = self.class_repo.get_by_id(class_id).name if cls_obj else "a class"
            self.notif_repo.create(
                user_id=target_user.id,
                event_id=None,
                title="Class Invitation",
                message=f"You have been invited to join \"{cls_obj_name}\". Open the app to accept or decline.",
                notification_type=NotificationType.CLASS_INVITATION,
                is_read=False,
            )

        return invitation

    def list_my_invitations(self, user: User) -> list[ClassInvitation]:
        return self.inv_repo.list_my_invitations(user.email, user.username)

    def accept_invitation(self, invitation_id: int, user: User) -> ClassMembership:
        inv = self.inv_repo.get_by_id(invitation_id)
        if not inv or inv.status != InvitationStatus.PENDING:
            raise ValueError("Invalid or expired invitation")
            
        if inv.expires_at < utc_now():
            self.inv_repo.update(inv, status=InvitationStatus.EXPIRED)
            raise ValueError("Invitation expired")

        # Validate ownership of invite
        is_owner = False
        if inv.invited_email == user.email:
            is_owner = True
        elif user.username and inv.invited_username == user.username:
            is_owner = True
        elif inv.invited_user_id == user.id:
            is_owner = True
            
        if not is_owner:
            raise ValueError("Not authorized to accept this invitation")

        self.inv_repo.update(inv, status=InvitationStatus.ACCEPTED, accepted_at=utc_now())
        return self.class_repo.upsert_membership(
            class_id=inv.class_id, 
            user_id=user.id, 
            role=MembershipRole.STUDENT, 
            status=MembershipStatus.ACTIVE
        )

    def decline_invitation(self, invitation_id: int, user: User) -> None:
        inv = self.inv_repo.get_by_id(invitation_id)
        if not inv or inv.status != InvitationStatus.PENDING:
            raise ValueError("Invalid or expired invitation")
            
        self.inv_repo.update(inv, status=InvitationStatus.DECLINED, declined_at=utc_now())
