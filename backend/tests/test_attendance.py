# backend/tests/test_attendance.py
from datetime import timedelta

from app.models.event import Event
from app.models.user import User, UserRole
from app.services.auth_service import AuthService
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


def create_student(
    db_session,
    *,
    firebase_uid: str = "attendance-student-firebase-uid",
    email: str = "student_attendance@test.com",
    full_name: str = "Student Attendance",
) -> User:
    student = User(
        firebase_uid=firebase_uid,
        email=email,
        full_name=full_name,
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


def test_mark_attendance_success(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    student = create_student(db_session)
    event = create_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "student-success-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    payload = {
        "qr_code_token": event.qr_code_token,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "test-device-1",
    }

    response = client.post(
        "/api/v1/attendance/mark",
        json=payload,
        headers=auth_headers("student-success-token"),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["event_id"] == event.id
    assert data["user_id"] == student.id
    assert data["status"] == "present"


def test_mark_attendance_duplicate_present_still_conflicts(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    student = create_student(db_session)
    event = create_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "student-duplicate-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    payload = {
        "qr_code_token": event.qr_code_token,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "test-device-2",
    }

    first_response = client.post(
        "/api/v1/attendance/mark",
        json=payload,
        headers=auth_headers("student-duplicate-token"),
    )
    second_response = client.post(
        "/api/v1/attendance/mark",
        json=payload,
        headers=auth_headers("student-duplicate-token"),
    )

    assert first_response.status_code == 201
    assert second_response.status_code == 409
    assert second_response.json()["detail"] == "Attendance already marked for this user and event"


def test_rejected_scan_can_be_retried_and_become_present(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    student = create_student(db_session)
    event = create_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "student-retry-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    rejected_payload = {
        "qr_code_token": event.qr_code_token,
        "scan_latitude": 31.000,
        "scan_longitude": 115.000,
        "device_id": "retry-device-1",
    }
    valid_payload = {
        "qr_code_token": event.qr_code_token,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "retry-device-2",
    }

    rejected_response = client.post(
        "/api/v1/attendance/mark",
        json=rejected_payload,
        headers=auth_headers("student-retry-token"),
    )
    assert rejected_response.status_code == 201
    assert rejected_response.json()["status"] == "rejected"

    retry_response = client.post(
        "/api/v1/attendance/mark",
        json=valid_payload,
        headers=auth_headers("student-retry-token"),
    )

    assert retry_response.status_code == 201
    data = retry_response.json()
    assert data["event_id"] == event.id
    assert data["user_id"] == student.id
    assert data["status"] == "present"
    assert data["rejection_reason"] is None
    assert data["device_id"] == "retry-device-2"


def test_student_cannot_list_another_users_attendance(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    student_1 = create_student(
        db_session,
        firebase_uid="student-1-uid",
        email="student1@test.com",
        full_name="Student One",
    )
    student_2 = create_student(
        db_session,
        firebase_uid="student-2-uid",
        email="student2@test.com",
        full_name="Student Two",
    )
    event = create_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "student-one-token": {
                "uid": student_1.firebase_uid,
                "email": student_1.email,
                "name": student_1.full_name,
            }
        },
    )

    payload = {
        "qr_code_token": event.qr_code_token,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "student-one-device",
    }

    mark_response = client.post(
        "/api/v1/attendance/mark",
        json=payload,
        headers=auth_headers("student-one-token"),
    )
    assert mark_response.status_code == 201

    response = client.get(
        f"/api/v1/attendance?user_id={student_2.id}",
        headers=auth_headers("student-one-token"),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "You do not have permission to access this resource"


def test_attendance_stats_is_admin_only(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    student = create_student(db_session)
    event = create_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "student-stats-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            },
            "admin-stats-token": {
                "uid": admin.firebase_uid,
                "email": admin.email,
                "name": admin.full_name,
            },
        },
    )

    student_response = client.get(
        f"/api/v1/attendance/stats/{event.id}",
        headers=auth_headers("student-stats-token"),
    )
    assert student_response.status_code == 403
    assert student_response.json()["detail"] == "Admin access required"

    admin_response = client.get(
        f"/api/v1/attendance/stats/{event.id}",
        headers=auth_headers("admin-stats-token"),
    )
    assert admin_response.status_code == 200
    assert admin_response.json()["event_id"] == event.id