# backend/app/repositories/event_repository.py
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.event import Event


class EventRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, **kwargs) -> Event:
        event = Event(**kwargs)
        self.db.add(event)
        self.db.commit()
        self.db.refresh(event)
        return event

    def get_by_id(self, event_id: int) -> Event | None:
        return self.db.get(Event, event_id)

    def get_by_qr_token(self, token: str) -> Event | None:
        return self.db.scalar(select(Event).where(Event.qr_code_token == token))

    def list(
        self,
        skip: int = 0,
        limit: int = 20,
        search: str | None = None,
        active_only: bool = False,
        created_by_user_id: int | None = None,
    ) -> tuple[list[Event], int]:
        query = select(Event)
        count_query = select(func.count(Event.id))

        if search:
            pattern = f"%{search.strip()}%"
            query = query.where(Event.name.ilike(pattern))
            count_query = count_query.where(Event.name.ilike(pattern))

        if active_only:
            query = query.where(Event.is_active.is_(True))
            count_query = count_query.where(Event.is_active.is_(True))

        if created_by_user_id is not None:
            query = query.where(Event.created_by_user_id == created_by_user_id)
            count_query = count_query.where(Event.created_by_user_id == created_by_user_id)

        items = self.db.scalars(
            query.order_by(Event.start_time.desc()).offset(skip).limit(limit)
        ).all()
        total = self.db.scalar(count_query) or 0
        return items, total

    def update(self, event: Event, **kwargs) -> Event:
        for field, value in kwargs.items():
            setattr(event, field, value)

        self.db.commit()
        self.db.refresh(event)
        return event

    def set_qr_image_path(self, event: Event, image_path: str) -> Event:
        event.qr_code_image_path = image_path
        self.db.commit()
        self.db.refresh(event)
        return event

    def delete(self, event: Event) -> None:
        self.db.delete(event)
        self.db.commit()
