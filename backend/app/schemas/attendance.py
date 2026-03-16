from pydantic import BaseModel
from datetime import datetime

class AttendanceBase(BaseModel):
    user_id: int
    event_id: int
    scanned_at: datetime
    status: str  # "present", "late", "absent"

    class Config:
        from_attributes = True  # To allow serialization from SQLAlchemy models

class AttendanceResponse(AttendanceBase):
    id: int  # ID for the attendance record

    class Config:
        orm_mode = True  # Enable ORM compatibility
