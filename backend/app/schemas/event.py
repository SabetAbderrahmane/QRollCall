from pydantic import BaseModel
from datetime import datetime


class EventCreate(BaseModel):
    title: str
    description: str
    location: str
    starts_at: datetime
    ends_at: datetime


class EventRead(EventCreate):
    id: int

    class Config:
        # For Pydantic V2 compatibility, ensure we can convert from SQLAlchemy models
        from_attributes = True
