from app.models.notification import Notification
from app.repositories.notification_repository import NotificationRepository
from app.schemas.notification import NotificationCreate, NotificationUpdate


class NotificationService:
    def __init__(self, repository: NotificationRepository) -> None:
        self.repository = repository

    def create_notification(self, payload: NotificationCreate) -> Notification:
        return self.repository.create(
            user_id=payload.user_id,
            event_id=payload.event_id,
            title=payload.title,
            message=payload.message,
            notification_type=payload.notification_type,
            is_read=False,
        )

    def list_notifications(
        self,
        skip: int = 0,
        limit: int = 20,
        user_id: int | None = None,
        is_read: bool | None = None,
        event_id: int | None = None,
    ) -> tuple[list[Notification], int]:
        return self.repository.list(
            skip=skip,
            limit=limit,
            user_id=user_id,
            is_read=is_read,
            event_id=event_id,
        )

    def get_notification(self, notification_id: int) -> Notification | None:
        return self.repository.get_by_id(notification_id)

    def update_notification(
        self,
        notification: Notification,
        payload: NotificationUpdate,
    ) -> Notification:
        update_data = payload.model_dump(exclude_unset=True)
        return self.repository.update(notification, **update_data)

    def mark_read(
        self,
        notification: Notification,
        is_read: bool = True,
    ) -> Notification:
        return self.repository.mark_read(notification, is_read=is_read)

    def delete_notification(self, notification: Notification) -> None:
        self.repository.delete(notification)

    def delete_user_notifications(self, user_id: int) -> int:
        return self.repository.delete_by_user(user_id)