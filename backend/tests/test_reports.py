from datetime import timedelta

from app.models.attendance import Attendance, AttendanceStatus
from app.models.event import Event
from app.models.user import User, UserRole
from app.services.auth_service import AuthService
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


def install_auth_mock(monkeypatch, token_claims_map: dict[str, dict]) -> None:
    def mock_verify_firebase_token(self, authorization):
        assert authorization is not None
        scheme, token = authorization.split(" ", 1)
        assert scheme == "Bearer"
        assert token in token_claims_map
        return token_claims_map[token]

    monkeypatch.setattr(
        AuthService,
        "verify_firebase_token",
        mock_verify_firebase_token,
    )


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_dashboard_report_is_admin_only(client, db_session, monkeypatch):
    admin = create_report_admin(db_session)
    student = create_report_student(db_session)
    event = create_report_event(db_session, admin.id)
    create_report_attendance(db_session, event.id, student.id)

    install_auth_mock(
        monkeypatch,
        {
            "report-admin-token": {
                "uid": admin.firebase_uid,
                "email": admin.email,
                "name": admin.full_name,
            },
            "report-student-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            },
        },
    )

    student_response = client.get(
        "/api/v1/reports/dashboard",
        headers=auth_headers("report-student-token"),
    )
    assert student_response.status_code == 403
    assert student_response.json()["detail"] == "Admin access required"

    admin_response = client.get(
        "/api/v1/reports/dashboard",
        headers=auth_headers("report-admin-token"),
    )
    assert admin_response.status_code == 200
    data = admin_response.json()
    assert data["total_users"] >= 2
    assert data["total_events"] >= 1
    assert data["total_attendance_records"] >= 1
    assert data["total_present"] >= 1


def test_event_report_requires_admin(client, db_session, monkeypatch):
    admin = create_report_admin(db_session)
    student = create_report_student(db_session)
    event = create_report_event(db_session, admin.id)
    create_report_attendance(db_session, event.id, student.id)

    install_auth_mock(
        monkeypatch,
        {
            "event-report-admin-token": {
                "uid": admin.firebase_uid,
                "email": admin.email,
                "name": admin.full_name,
            },
            "event-report-student-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            },
        },
    )

    student_response = client.get(
        f"/api/v1/reports/events/{event.id}",
        headers=auth_headers("event-report-student-token"),
    )
    assert student_response.status_code == 403
    assert student_response.json()["detail"] == "Admin access required"

    admin_response = client.get(
        f"/api/v1/reports/events/{event.id}",
        headers=auth_headers("event-report-admin-token"),
    )
    assert admin_response.status_code == 200
    data = admin_response.json()
    assert data["event_id"] == event.id
    assert data["event_name"] == event.name
    assert data["present_count"] >= 1


def test_export_event_report_csv_requires_admin(client, db_session, monkeypatch):
    admin = create_report_admin(db_session)
    student = create_report_student(db_session)
    event = create_report_event(db_session, admin.id)
    create_report_attendance(db_session, event.id, student.id)

    install_auth_mock(
        monkeypatch,
        {
            "export-report-admin-token": {
                "uid": admin.firebase_uid,
                "email": admin.email,
                "name": admin.full_name,
            },
            "export-report-student-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            },
        },
    )

    student_response = client.get(
        f"/api/v1/reports/export/event/{event.id}?format=csv",
        headers=auth_headers("export-report-student-token"),
    )
    assert student_response.status_code == 403
    assert student_response.json()["detail"] == "Admin access required"

    admin_response = client.get(
        f"/api/v1/reports/export/event/{event.id}?format=csv",
        headers=auth_headers("export-report-admin-token"),
    )
    assert admin_response.status_code == 200
    data = admin_response.json()
    assert data["format"] == "csv"
    assert data["file_name"].endswith(".csv")
    assert "storage/reports/" in data["file_path"]