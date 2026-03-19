# backend/app/repositories/notification_repository.py
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.notification import Notification


class NotificationRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, **kwargs) -> Notification:
        notification = Notification(**kwargs)
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def get_by_id(self, notification_id: int) -> Notification | None:
        return self.db.get(Notification, notification_id)

    def list(
        self,
        skip: int = 0,
        limit: int = 20,
        user_id: int | None = None,
        is_read: bool | None = None,
        event_id: int | None = None,
    ) -> tuple[list[Notification], int]:
        query = select(Notification)
        count_query = select(func.count(Notification.id))

        if user_id is not None:
            query = query.where(Notification.user_id == user_id)
            count_query = count_query.where(Notification.user_id == user_id)

        if is_read is not None:
            query = query.where(Notification.is_read.is_(is_read))
            count_query = count_query.where(Notification.is_read.is_(is_read))

        if event_id is not None:
            query = query.where(Notification.event_id == event_id)
            count_query = count_query.where(Notification.event_id == event_id)

        items = self.db.scalars(
            query.order_by(Notification.created_at.desc()).offset(skip).limit(limit)
        ).all()
        total = self.db.scalar(count_query) or 0
        return items, total

    def mark_read(self, notification: Notification, is_read: bool = True) -> Notification:
        notification.is_read = is_read
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def update(self, notification: Notification, **kwargs) -> Notification:
        for field, value in kwargs.items():
            setattr(notification, field, value)

        self.db.commit()
        self.db.refresh(notification)
        return notification

    def delete(self, notification: Notification) -> None:
        self.db.delete(notification)
        self.db.commit()

    def delete_by_user(self, user_id: int) -> int:
        items = self.db.scalars(
            select(Notification).where(Notification.user_id == user_id)
        ).all()
        deleted_count = len(items)

        for item in items:
            self.db.delete(item)

        self.db.commit()
        return deleted_count
