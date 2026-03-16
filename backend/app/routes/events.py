from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models.event import Event
from app.models.attendance import Attendance
from app.models.user import User
from app.schemas.event import EventCreate, EventRead  # Pydantic models for creating/reading events
from app.schemas.qr import QRTokenResponse
from app.core.database import get_db
from app.utils.security import create_qr_token  # Function to generate QR code
from datetime import datetime

router = APIRouter(prefix="/events", tags=["events"])

# POST /events - Create an event
@router.post("", response_model=EventRead, status_code=status.HTTP_201_CREATED)
def create_event(
    payload: EventCreate,
    db: Session = Depends(get_db),
) -> EventRead:
    if payload.ends_at <= payload.starts_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Event end time must be after start time.",
        )

    event = Event(
        title=payload.title,
        description=payload.description,
        location=payload.location,
        starts_at=payload.starts_at,
        ends_at=payload.ends_at,
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return EventRead.model_validate(event)  # Convert SQLAlchemy model to Pydantic model


# GET /events - List all events
@router.get("", response_model=list[EventRead])
def list_events(
    db: Session = Depends(get_db),
) -> list[EventRead]:
    events = db.query(Event).all()
    return [EventRead.model_validate(event) for event in events]  # Convert to Pydantic models


# GET /events/{event_id} - Get a single event by ID
@router.get("/{event_id}", response_model=EventRead)
def get_event(
    event_id: int,
    db: Session = Depends(get_db),
) -> EventRead:
    event = db.get(Event, event_id)
    if event is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found.",
        )
    return EventRead.model_validate(event)  # Convert SQLAlchemy model to Pydantic model


# POST /events/{event_id}/qr - Generate QR for event
@router.post("/{event_id}/qr", response_model=QRTokenResponse)
def generate_event_qr(
    event_id: int,
    db: Session = Depends(get_db),
) -> QRTokenResponse:
    event = db.get(Event, event_id)
    if event is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found.",
        )

    qr_token = create_qr_token(event_id=event.id)
    return QRTokenResponse(event_id=event.id, qr_token=qr_token)


# POST /events/{event_id}/scan - Mark attendance for an event
@router.post("/{event_id}/scan", response_model=Attendance)
def scan_qr(event_id: int, user_id: int, db: Session = Depends(get_db)):
    # Check if event exists
    event = db.get(Event, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check if user exists
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if the user already scanned for this event
    existing_attendance = db.query(Attendance).filter_by(event_id=event_id, user_id=user_id).first()
    if existing_attendance:
        raise HTTPException(status_code=400, detail="User already attended this event")
    
    # Mark attendance
    attendance = Attendance(
        user_id=user_id,
        event_id=event_id,
        scanned_at=datetime.utcnow(),
        status="present",  # Mark attendance as "present", "late", or "absent"
    )
    db.add(attendance)
    db.commit()
    db.refresh(attendance)
    
    return attendance
