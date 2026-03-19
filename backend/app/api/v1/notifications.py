# backend/app/api/v1/notifications.py
from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import DbSession
from app.repositories.user_repository import UserRepository
from app.schemas.notification import (
    MarkNotificationReadRequest,
    NotificationCreate,
    NotificationListResponse,
    NotificationResponse,
    NotificationUpdate,
)
from app.services.notification_service import NotificationService
from app.repositories.notification_repository import NotificationRepository

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
def create_notification(
    payload: NotificationCreate,
    db: DbSession,
) -> NotificationResponse:
    user_repository = UserRepository(db)
    user = user_repository.get_by_id(payload.user_id)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    service = NotificationService(NotificationRepository(db))
    notification = service.create_notification(payload)
    return NotificationResponse.model_validate(notification)


@router.get("", response_model=NotificationListResponse)
def list_notifications(
    db: DbSession,
    user_id: int | None = Query(default=None, ge=1),
    is_read: bool | None = Query(default=None),
    event_id: int | None = Query(default=None, ge=1),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> NotificationListResponse:
    service = NotificationService(NotificationRepository(db))
    items, total = service.list_notifications(
        skip=skip,
        limit=limit,
        user_id=user_id,
        is_read=is_read,
        event_id=event_id,
    )
    return NotificationListResponse(items=items, total=total)


@router.get("/{notification_id}", response_model=NotificationResponse)
def get_notification(notification_id: int, db: DbSession) -> NotificationResponse:
    service = NotificationService(NotificationRepository(db))
    notification = service.get_notification(notification_id)

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    return NotificationResponse.model_validate(notification)


@router.put("/{notification_id}", response_model=NotificationResponse)
def update_notification(
    notification_id: int,
    payload: NotificationUpdate,
    db: DbSession,
) -> NotificationResponse:
    service = NotificationService(NotificationRepository(db))
    notification = service.get_notification(notification_id)

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    updated_notification = service.update_notification(notification, payload)
    return NotificationResponse.model_validate(updated_notification)


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(
    notification_id: int,
    payload: MarkNotificationReadRequest,
    db: DbSession,
) -> NotificationResponse:
    service = NotificationService(NotificationRepository(db))
    notification = service.get_notification(notification_id)

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    updated_notification = service.mark_read(notification, is_read=payload.is_read)
    return NotificationResponse.model_validate(updated_notification)


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_notification(notification_id: int, db: DbSession) -> None:
    service = NotificationService(NotificationRepository(db))
    notification = service.get_notification(notification_id)

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    service.delete_notification(notification)
