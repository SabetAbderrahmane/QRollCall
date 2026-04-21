# backend/app/services/event_service.py
from secrets import token_urlsafe

from sqlalchemy.orm import Session

from app.core.constants import ERROR_CREATOR_NOT_FOUND, ERROR_EVENT_NOT_FOUND
from app.models.event import Event
from app.repositories.event_repository import EventRepository
from app.repositories.user_repository import UserRepository
from app.schemas.event import EventCreate, EventUpdate
from app.services.qr_service import qr_service


class EventService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.event_repository = EventRepository(db)
        self.user_repository = UserRepository(db)

    def create_event(self, payload: EventCreate, creator_user_id: int) -> Event:
        creator = self.user_repository.get_by_id(creator_user_id)
        if creator is None:
            raise ValueError(ERROR_CREATOR_NOT_FOUND)

        return self.event_repository.create(
            name=payload.name,
            description=payload.description,
            start_time=payload.start_time,
            end_time=payload.end_time,
            location_name=payload.location_name,
            latitude=payload.latitude,
            longitude=payload.longitude,
            geofence_radius_meters=payload.geofence_radius_meters,
            qr_code_token=token_urlsafe(32),
            qr_code_image_path=None,
            qr_validity_minutes=payload.qr_validity_minutes,
            is_active=payload.is_active,
            created_by_user_id=creator_user_id,
        )

    def list_events(
        self,
        skip: int = 0,
        limit: int = 20,
        search: str | None = None,
        active_only: bool = False,
        created_by_user_id: int | None = None,
    ) -> tuple[list[Event], int]:
        return self.event_repository.list(
            skip=skip,
            limit=limit,
            search=search,
            active_only=active_only,
            created_by_user_id=created_by_user_id,
        )

    def get_event(self, event_id: int) -> Event | None:
        return self.event_repository.get_by_id(event_id)

    def require_event(self, event_id: int) -> Event:
        event = self.get_event(event_id)
        if event is None:
            raise ValueError(ERROR_EVENT_NOT_FOUND)
        return event

    def update_event(self, event: Event, payload: EventUpdate) -> Event:
        update_data = payload.model_dump(exclude_unset=True)
        return self.event_repository.update(event, **update_data)

    def delete_event(self, event: Event) -> None:
        self.event_repository.delete(event)

    def generate_qr_for_event(self, event: Event) -> Event:
        image_path = qr_service.generate_qr_image(event)
        return self.event_repository.set_qr_image_path(event, image_path)

    def get_or_generate_qr_for_event(self, event_id: int) -> Event:
        event = self.require_event(event_id)

        if not event.qr_code_image_path:
            event = self.generate_qr_for_event(event)

        return event

    def get_event_by_qr_token(self, token: str) -> Event | None:
        return self.event_repository.get_by_qr_token(token)