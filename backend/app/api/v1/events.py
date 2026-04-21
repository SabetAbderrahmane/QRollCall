# backend/app/api/v1/events.py
from fastapi import APIRouter, Query, status

from app.api.deps import CurrentUser, DbSession
from app.core.constants import ERROR_EVENT_NOT_FOUND
from app.core.permissions import require_active_user, require_admin
from app.schemas.event import EventCreate, EventListResponse, EventResponse, EventUpdate
from app.services.event_service import EventService

router = APIRouter(prefix="/events", tags=["events"])


def _raise_event_http_error(message: str) -> None:
    from fastapi import HTTPException

    status_code = (
        status.HTTP_404_NOT_FOUND
        if message == ERROR_EVENT_NOT_FOUND or "not found" in message.lower()
        else status.HTTP_400_BAD_REQUEST
    )
    raise HTTPException(status_code=status_code, detail=message)


@router.post("", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
def create_event(
    payload: EventCreate,
    db: DbSession,
    current_user: CurrentUser,
) -> EventResponse:
    admin_user = require_admin(current_user)
    service = EventService(db)

    try:
        event = service.create_event(payload, creator_user_id=admin_user.id)
    except ValueError as exc:
        _raise_event_http_error(str(exc))

    return EventResponse.model_validate(event)


@router.get("", response_model=EventListResponse)
def list_events(
    db: DbSession,
    current_user: CurrentUser,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    active_only: bool = Query(default=False),
    created_by_user_id: int | None = Query(default=None, ge=1),
) -> EventListResponse:
    require_active_user(current_user)
    service = EventService(db)
    items, total = service.list_events(
        skip=skip,
        limit=limit,
        search=search,
        active_only=active_only,
        created_by_user_id=created_by_user_id,
    )
    return EventListResponse(items=items, total=total)


@router.get("/{event_id}", response_model=EventResponse)
def get_event(
    event_id: int,
    db: DbSession,
    current_user: CurrentUser,
) -> EventResponse:
    require_active_user(current_user)
    service = EventService(db)

    try:
        event = service.require_event(event_id)
    except ValueError as exc:
        _raise_event_http_error(str(exc))

    return EventResponse.model_validate(event)


@router.put("/{event_id}", response_model=EventResponse)
def update_event(
    event_id: int,
    payload: EventUpdate,
    db: DbSession,
    current_user: CurrentUser,
) -> EventResponse:
    require_admin(current_user)
    service = EventService(db)

    try:
        event = service.require_event(event_id)
        updated_event = service.update_event(event, payload)
    except ValueError as exc:
        _raise_event_http_error(str(exc))

    return EventResponse.model_validate(updated_event)


@router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_event(
    event_id: int,
    db: DbSession,
    current_user: CurrentUser,
) -> None:
    require_admin(current_user)
    service = EventService(db)

    try:
        event = service.require_event(event_id)
        service.delete_event(event)
    except ValueError as exc:
        _raise_event_http_error(str(exc))