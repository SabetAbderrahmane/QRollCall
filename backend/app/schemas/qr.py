# backend/app/schemas/qr.py
from datetime import datetime

from pydantic import BaseModel, Field


class QRCodePayload(BaseModel):
    event_id: int = Field(..., ge=1)
    event_name: str = Field(..., min_length=1, max_length=255)
    start_time: datetime
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    geofence_radius_meters: int = Field(..., ge=1, le=10000)
    qr_validity_minutes: int = Field(..., ge=1, le=1440)
    token: str = Field(..., min_length=1, max_length=255)


class QRCodeGenerateRequest(BaseModel):
    event_id: int = Field(..., ge=1)


class QRCodeGenerateResponse(BaseModel):
    event_id: int
    token: str
    qr_code_image_path: str
    payload: QRCodePayload


class QRCodeValidateRequest(BaseModel):
    token: str = Field(..., min_length=1, max_length=255)
    scan_latitude: float = Field(..., ge=-90, le=90)
    scan_longitude: float = Field(..., ge=-180, le=180)
    scanned_at: datetime | None = None
    user_id: int | None = Field(default=None, ge=1)


class QRCodeValidateResponse(BaseModel):
    valid: bool
    event_id: int | None = None
    reason: str | None = None
    within_time_window: bool
    within_geofence: bool


class QRCodeImageResponse(BaseModel):
    event_id: int
    token: str
    image_path: str
