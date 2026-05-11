from datetime import datetime
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.class_room import ClassRoom
from app.models.class_membership import ClassMembership, MembershipRole, MembershipStatus
from app.models.user import User

class ClassRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, class_id: int) -> ClassRoom | None:
        return self.db.scalars(
            select(ClassRoom).where(ClassRoom.id == class_id)
        ).first()

    def get_by_code(self, class_code: str) -> ClassRoom | None:
        return self.db.scalars(
            select(ClassRoom).where(ClassRoom.class_code == class_code)
        ).first()

    def create(self, **kwargs) -> ClassRoom:
        cls_obj = ClassRoom(**kwargs)
        self.db.add(cls_obj)
        self.db.flush()
        
        # Add creator as teacher
        membership = ClassMembership(
            class_id=cls_obj.id,
            user_id=cls_obj.teacher_user_id,
            role=MembershipRole.TEACHER,
            status=MembershipStatus.ACTIVE,
        )
        self.db.add(membership)
        
        self.db.commit()
        self.db.refresh(cls_obj)
        return cls_obj

    def update(self, class_obj: ClassRoom, **kwargs) -> ClassRoom:
        for key, value in kwargs.items():
            if hasattr(class_obj, key):
                setattr(class_obj, key, value)
        self.db.commit()
        self.db.refresh(class_obj)
        return class_obj

    def delete(self, class_obj: ClassRoom) -> None:
        self.db.delete(class_obj)
        self.db.commit()

    def list_my_classes(self, user_id: int) -> list[ClassRoom]:
        stmt = (
            select(ClassRoom)
            .join(ClassMembership)
            .where(
                ClassMembership.user_id == user_id, 
                ClassMembership.status == MembershipStatus.ACTIVE
            )
        )
        return list(self.db.scalars(stmt).all())

    def list_created_classes(self, teacher_id: int) -> list[ClassRoom]:
        stmt = select(ClassRoom).where(ClassRoom.teacher_user_id == teacher_id)
        return list(self.db.scalars(stmt).all())

    def list_all(self, skip: int = 0, limit: int = 20) -> list[ClassRoom]:
        stmt = select(ClassRoom).offset(skip).limit(limit)
        return list(self.db.scalars(stmt).all())

    def get_membership(self, class_id: int, user_id: int) -> ClassMembership | None:
        stmt = select(ClassMembership).where(
            ClassMembership.class_id == class_id,
            ClassMembership.user_id == user_id
        )
        return self.db.scalars(stmt).first()
        
    def list_students(self, class_id: int) -> list[ClassMembership]:
        stmt = (
            select(ClassMembership)
            .options(joinedload(ClassMembership.user))
            .where(
                ClassMembership.class_id == class_id,
                ClassMembership.status != MembershipStatus.REMOVED,
                ClassMembership.status != MembershipStatus.DECLINED
            )
        )
        return list(self.db.scalars(stmt).all())

    def upsert_membership(self, class_id: int, user_id: int, role: MembershipRole, status: MembershipStatus) -> ClassMembership:
        membership = self.get_membership(class_id, user_id)
        if membership:
            membership.role = role
            membership.status = status
        else:
            membership = ClassMembership(class_id=class_id, user_id=user_id, role=role, status=status)
            self.db.add(membership)
            
        self.db.commit()
        self.db.refresh(membership)
        return membership
