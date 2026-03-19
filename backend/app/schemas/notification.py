from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.notification import NotificationType


class NotificationBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    message: str = Field(..., min_length=1)
    notification_type: NotificationType = NotificationType.REMINDER
    event_id: Optional[int] = Field(default=None, ge=1)


class NotificationCreate(NotificationBase):
    user_id: int = Field(..., ge=1)


class NotificationUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=255)
    message: Optional[str] = Field(default=None, min_length=1)
    notification_type: Optional[NotificationType] = None
    is_read: Optional[bool] = None
    event_id: Optional[int] = Field(default=None, ge=1)


class NotificationResponse(NotificationBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    is_read: bool
    created_at: datetime
    updated_at: datetime


class NotificationListResponse(BaseModel):
    items: list[NotificationResponse]
    total: int


class MarkNotificationReadRequest(BaseModel):
    is_read: bool = True
