from datetime import timedelta

from app.models.attendance import Attendance, AttendanceStatus
from app.models.event import Event
from app.models.user import User, UserRole
from app.utils.datetime_utils import utc_now


def create_report_admin(db_session) -> User:
    admin = User(
        firebase_uid="report-admin-firebase-uid",
        email="report_admin@test.com",
        full_name="Report Admin",
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


def create_report_student(db_session) -> User:
    student = User(
        firebase_uid="report-student-firebase-uid",
        email="report_student@test.com",
        full_name="Report Student",
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


def create_report_event(db_session, admin_id: int) -> Event:
    start_time = utc_now()
    event = Event(
        name="Report Event",
        description="Report test event",
        start_time=start_time,
        end_time=start_time + timedelta(hours=1),
        location_name="Report Hall",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=100,
        qr_code_token="report-event-token",
        qr_code_image_path=None,
        qr_validity_minutes=15,
        is_active=True,
        created_by_user_id=admin_id,
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)
    return event


def create_report_attendance(db_session, event_id: int, user_id: int) -> Attendance:
    attendance = Attendance(
        event_id=event_id,
        user_id=user_id,
        scanned_at=utc_now(),
        status=AttendanceStatus.PRESENT,
        scan_latitude=30.549,
        scan_longitude=114.342,
        device_id="report-device",
        rejection_reason=None,
    )
    db_session.add(attendance)
    db_session.commit()
    db_session.refresh(attendance)
    return attendance


def test_dashboard_report(client, db_session):
    admin = create_report_admin(db_session)
    student = create_report_student(db_session)
    event = create_report_event(db_session, admin.id)
    create_report_attendance(db_session, event.id, student.id)

    response = client.get("/api/v1/reports/dashboard")

    assert response.status_code == 200
    data = response.json()
    assert data["total_users"] >= 2
    assert data["total_events"] >= 1
    assert data["total_attendance_records"] >= 1
    assert data["total_present"] >= 1


def test_event_report(client, db_session):
    admin = create_report_admin(db_session)
    student = create_report_student(db_session)
    event = create_report_event(db_session, admin.id)
    create_report_attendance(db_session, event.id, student.id)

    response = client.get(f"/api/v1/reports/events/{event.id}")

    assert response.status_code == 200
    data = response.json()
    assert data["event_id"] == event.id
    assert data["event_name"] == event.name
    assert data["present_count"] >= 1


def test_export_event_report_csv(client, db_session):
    admin = create_report_admin(db_session)
    student = create_report_student(db_session)
    event = create_report_event(db_session, admin.id)
    create_report_attendance(db_session, event.id, student.id)

    response = client.get(f"/api/v1/reports/export/event/{event.id}?format=csv")

    assert response.status_code == 200
    data = response.json()
    assert data["format"] == "csv"
    assert data["file_name"].endswith(".csv")
    assert "storage/reports/" in data["file_path"]