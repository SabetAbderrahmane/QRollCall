# backend/tests/test_attendance.py
from datetime import timedelta

from app.models.event import Event
from app.models.user import User, UserRole
from app.utils.datetime_utils import utc_now


def create_admin(db_session) -> User:
    admin = User(
        firebase_uid="attendance-admin-firebase-uid",
        email="admin_attendance@test.com",
        full_name="Admin Attendance",
        role=UserRole.ADMIN,
        is_active=True,
        phone_number=None,
        student_id=None,
        profile_image_url=None,
    )
    db_session.add(admin)
    db_session.commit()
    db_session.refresh(admin)
    return admin


def create_student(db_session) -> User:
    student = User(
        firebase_uid="attendance-student-firebase-uid",
        email="student_attendance@test.com",
        full_name="Student Attendance",
        role=UserRole.STUDENT,
        is_active=True,
        phone_number=None,
        student_id=None,
        profile_image_url=None,
    )
    db_session.add(student)
    db_session.commit()
    db_session.refresh(student)
    return student


def create_event(db_session, admin_id: int) -> Event:
    event = Event(
        name="Attendance Test Event",
        description="Attendance test",
        start_time=utc_now(),
        end_time=utc_now() + timedelta(hours=1),
        location_name="Test Hall",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=150,
        qr_code_token="attendance-test-token",
        qr_code_image_path=None,
        qr_validity_minutes=15,
        is_active=True,
        created_by_user_id=admin_id,
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)
    return event


def test_mark_attendance_success(client, db_session):
    admin = create_admin(db_session)
    student = create_student(db_session)
    event = create_event(db_session, admin.id)

    payload = {
        "qr_code_token": event.qr_code_token,
        "user_id": student.id,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "test-device-1",
    }

    response = client.post("/api/v1/attendance/mark", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["event_id"] == event.id
    assert data["user_id"] == student.id
    assert data["status"] == "present"


def test_mark_attendance_duplicate(client, db_session):
    admin = create_admin(db_session)
    student = create_student(db_session)
    event = create_event(db_session, admin.id)

    payload = {
        "qr_code_token": event.qr_code_token,
        "user_id": student.id,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "test-device-2",
    }

    first_response = client.post("/api/v1/attendance/mark", json=payload)
    second_response = client.post("/api/v1/attendance/mark", json=payload)

    assert first_response.status_code == 201
    assert second_response.status_code == 409


def test_mark_attendance_invalid_qr(client, db_session):
    student = create_student(db_session)

    payload = {
        "qr_code_token": "invalid-token",
        "user_id": student.id,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "test-device-3",
    }

    response = client.post("/api/v1/attendance/mark", json=payload)

    assert response.status_code == 404
    assert response.json()["detail"] == "Invalid QR token"
