from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.attendance import AttendanceStatus


class AttendanceMarkRequest(BaseModel):
    qr_code_token: str = Field(..., min_length=1, max_length=255)
    scan_latitude: float = Field(..., ge=-90, le=90)
    scan_longitude: float = Field(..., ge=-180, le=180)
    device_id: Optional[str] = Field(default=None, max_length=255)


class AttendanceBase(BaseModel):
    event_id: int = Field(..., ge=1)
    user_id: int = Field(..., ge=1)
    scanned_at: datetime
    status: AttendanceStatus = AttendanceStatus.PRESENT
    scan_latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    scan_longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    device_id: Optional[str] = Field(default=None, max_length=255)
    rejection_reason: Optional[str] = Field(default=None, max_length=255)


class AttendanceCreate(AttendanceBase):
    pass


class AttendanceUpdate(BaseModel):
    status: Optional[AttendanceStatus] = None
    rejection_reason: Optional[str] = Field(default=None, max_length=255)
    device_id: Optional[str] = Field(default=None, max_length=255)
    scan_latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    scan_longitude: Optional[float] = Field(default=None, ge=-180, le=180)


class AttendanceResponse(AttendanceBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    updated_at: datetime


class AttendanceListResponse(BaseModel):
    items: list[AttendanceResponse]
    total: int


class AttendanceStatsResponse(BaseModel):
    event_id: int
    total_records: int
    present_count: int
    absent_count: int
    rejected_count: int