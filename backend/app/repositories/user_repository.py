# backend/app/repositories/user_repository.py
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, **kwargs) -> User:
        user = User(**kwargs)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_id(self, user_id: int) -> User | None:
        return self.db.get(User, user_id)

    def get_by_email(self, email: str) -> User | None:
        return self.db.scalar(select(User).where(User.email == email))

    def get_by_firebase_uid(self, firebase_uid: str) -> User | None:
        return self.db.scalar(
            select(User).where(User.firebase_uid == firebase_uid)
        )

    def get_by_student_id(self, student_id: str) -> User | None:
        return self.db.scalar(select(User).where(User.student_id == student_id))

    def exists_by_email_or_firebase_uid(self, email: str, firebase_uid: str) -> bool:
        user = self.db.scalar(
            select(User).where(
                or_(User.email == email, User.firebase_uid == firebase_uid)
            )
        )
        return user is not None

    def list(
        self,
        skip: int = 0,
        limit: int = 20,
        search: str | None = None,
    ) -> tuple[list[User], int]:
        query = select(User)
        count_query = select(func.count(User.id))

        if search:
            pattern = f"%{search.strip()}%"
            filters = or_(
                User.full_name.ilike(pattern),
                User.email.ilike(pattern),
                User.student_id.ilike(pattern),
            )
            query = query.where(filters)
            count_query = count_query.where(filters)

        items = self.db.scalars(
            query.order_by(User.id.desc()).offset(skip).limit(limit)
        ).all()
        total = self.db.scalar(count_query) or 0
        return items, total

    def update(self, user: User, **kwargs) -> User:
        for field, value in kwargs.items():
            setattr(user, field, value)

        self.db.commit()
        self.db.refresh(user)
        return user

    def delete(self, user: User) -> None:
        self.db.delete(user)
        self.db.commit()
