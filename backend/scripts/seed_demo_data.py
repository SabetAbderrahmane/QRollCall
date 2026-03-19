# backend/scripts/seed_demo_data.py
from datetime import timedelta

from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.attendance import Attendance, AttendanceStatus
from app.models.event import Event
from app.models.notification import Notification, NotificationType
from app.models.user import User, UserRole
from app.utils.datetime_utils import utc_now


def get_or_create_user(db, email: str, full_name: str, role: UserRole, firebase_uid: str) -> User:
    user = db.scalar(select(User).where(User.email == email))
    if user is not None:
        return user

    user = User(
        firebase_uid=firebase_uid,
        email=email,
        full_name=full_name,
        role=role,
        is_active=True,
        phone_number=None,
        student_id=None,
        profile_image_url=None,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_or_create_event(db, creator_id: int) -> Event:
    event = db.scalar(select(Event).where(Event.name == "Demo Mobile Computing Class"))
    if event is not None:
        return event

    start_time = utc_now() + timedelta(minutes=10)
    event = Event(
        name="Demo Mobile Computing Class",
        description="Demo event for backend testing",
        start_time=start_time,
        end_time=start_time + timedelta(hours=1),
        location_name="Room A101",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=100,
        qr_code_token="demo-event-qr-token",
        qr_code_image_path=None,
        qr_validity_minutes=15,
        is_active=True,
        created_by_user_id=creator_id,
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


def create_attendance_if_missing(db, event_id: int, user_id: int) -> None:
    existing = db.scalar(
        select(Attendance).where(
            Attendance.event_id == event_id,
            Attendance.user_id == user_id,
        )
    )
    if existing is not None:
        return

    attendance = Attendance(
        event_id=event_id,
        user_id=user_id,
        scanned_at=utc_now(),
        status=AttendanceStatus.PRESENT,
        scan_latitude=30.549,
        scan_longitude=114.342,
        device_id="demo-device-1",
        rejection_reason=None,
    )
    db.add(attendance)
    db.commit()


def create_notification_if_missing(db, user_id: int, event_id: int) -> None:
    existing = db.scalar(
        select(Notification).where(
            Notification.user_id == user_id,
            Notification.event_id == event_id,
            Notification.title == "Attendance confirmed",
        )
    )
    if existing is not None:
        return

    notification = Notification(
        user_id=user_id,
        event_id=event_id,
        title="Attendance confirmed",
        message="You have been marked present for the demo event.",
        notification_type=NotificationType.ATTENDANCE_CONFIRMED,
        is_read=False,
    )
    db.add(notification)
    db.commit()


def main() -> None:
    db = SessionLocal()

    try:
        admin = get_or_create_user(
            db=db,
            email="admin@qrattend.com",
            full_name="System Admin",
            role=UserRole.ADMIN,
            firebase_uid="seed-admin-firebase-uid",
        )
        student = get_or_create_user(
            db=db,
            email="student1@qrattend.com",
            full_name="Demo Student",
            role=UserRole.STUDENT,
            firebase_uid="seed-student-firebase-uid",
        )
        event = get_or_create_event(db=db, creator_id=admin.id)

        create_attendance_if_missing(db=db, event_id=event.id, user_id=student.id)
        create_notification_if_missing(db=db, user_id=student.id, event_id=event.id)

        print("Demo data seeded successfully.")
        print(f"Admin ID: {admin.id}")
        print(f"Student ID: {student.id}")
        print(f"Event ID: {event.id}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
