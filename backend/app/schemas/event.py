from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class EventBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    description: Optional[str] = None

    start_time: datetime
    end_time: Optional[datetime] = None

    location_name: Optional[str] = Field(default=None, max_length=255)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    geofence_radius_meters: int = Field(default=100, ge=1, le=10000)

    qr_validity_minutes: int = Field(default=15, ge=1, le=1440)
    is_active: bool = True

    @field_validator("end_time")
    @classmethod
    def validate_end_time(cls, value: Optional[datetime], info):
        start_time = info.data.get("start_time")
        if value is not None and start_time is not None and value < start_time:
            raise ValueError("end_time must be greater than or equal to start_time")
        return value


class EventCreate(EventBase):
    pass


class EventUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=2, max_length=255)
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    location_name: Optional[str] = Field(default=None, max_length=255)
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    geofence_radius_meters: Optional[int] = Field(default=None, ge=1, le=10000)
    qr_validity_minutes: Optional[int] = Field(default=None, ge=1, le=1440)
    is_active: Optional[bool] = None

    @field_validator("end_time")
    @classmethod
    def validate_end_time(cls, value: Optional[datetime], info):
        start_time = info.data.get("start_time")
        if value is not None and start_time is not None and value < start_time:
            raise ValueError("end_time must be greater than or equal to start_time")
        return value


class EventResponse(EventBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    qr_code_token: str
    qr_code_image_path: Optional[str]
    created_by_user_id: int
    created_at: datetime
    updated_at: datetime


class EventListResponse(BaseModel):
    items: list[EventResponse]
    total: int