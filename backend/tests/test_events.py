# backend/tests/test_events.py
from datetime import timedelta

from app.models.user import User, UserRole
from app.services.auth_service import AuthService
from app.utils.datetime_utils import utc_now


def create_admin(db_session) -> User:
    admin = User(
        firebase_uid="test-admin-firebase-uid",
        email="admin_events@test.com",
        full_name="Admin Events",
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
        firebase_uid="test-student-firebase-uid",
        email="student_events@test.com",
        full_name="Student Events",
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


def authorize(monkeypatch, claims: dict, token: str = "test-token") -> dict[str, str]:
    expected_authorization = f"Bearer {token}"

    def mock_verify_firebase_token(self, authorization):
        assert authorization == expected_authorization
        return claims

    monkeypatch.setattr(
        AuthService,
        "verify_firebase_token",
        mock_verify_firebase_token,
    )

    return {"Authorization": expected_authorization}


def test_create_event(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    headers = authorize(
        monkeypatch,
        {
            "uid": admin.firebase_uid,
            "email": admin.email,
            "name": admin.full_name,
        },
        token="admin-create-event-token",
    )

    payload = {
        "name": "Software Engineering Class",
        "description": "Weekly attendance event",
        "start_time": (utc_now() + timedelta(hours=1)).isoformat(),
        "end_time": (utc_now() + timedelta(hours=2)).isoformat(),
        "location_name": "Room B201",
        "latitude": 30.549,
        "longitude": 114.342,
        "geofence_radius_meters": 100,
        "qr_validity_minutes": 15,
        "is_active": True,
    }

    response = client.post("/api/v1/events", json=payload, headers=headers)

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == payload["name"]
    assert data["created_by_user_id"] == admin.id
    assert "qr_code_token" in data


def test_create_event_requires_admin(client, db_session, monkeypatch):
    student = create_student(db_session)
    headers = authorize(
        monkeypatch,
        {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        },
        token="student-create-event-token",
    )

    payload = {
        "name": "Unauthorized Event",
        "description": "Should fail for student",
        "start_time": (utc_now() + timedelta(hours=1)).isoformat(),
        "end_time": (utc_now() + timedelta(hours=2)).isoformat(),
        "location_name": "Room C101",
        "latitude": 30.549,
        "longitude": 114.342,
        "geofence_radius_meters": 100,
        "qr_validity_minutes": 15,
        "is_active": True,
    }

    response = client.post("/api/v1/events", json=payload, headers=headers)

    assert response.status_code == 403
    assert response.json()["detail"] == "Admin access required"


def test_list_events(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    headers = authorize(
        monkeypatch,
        {
            "uid": admin.firebase_uid,
            "email": admin.email,
            "name": admin.full_name,
        },
        token="admin-list-events-token",
    )

    payload = {
        "name": "Mobile App Development",
        "description": "Lecture attendance",
        "start_time": (utc_now() + timedelta(hours=1)).isoformat(),
        "end_time": (utc_now() + timedelta(hours=2)).isoformat(),
        "location_name": "Lab 3",
        "latitude": 30.549,
        "longitude": 114.342,
        "geofence_radius_meters": 120,
        "qr_validity_minutes": 20,
        "is_active": True,
    }

    create_response = client.post("/api/v1/events", json=payload, headers=headers)
    assert create_response.status_code == 201

    response = client.get("/api/v1/events", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


def test_get_event_not_found(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    headers = authorize(
        monkeypatch,
        {
            "uid": admin.firebase_uid,
            "email": admin.email,
            "name": admin.full_name,
        },
        token="admin-get-missing-event-token",
    )

    response = client.get("/api/v1/events/999999", headers=headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "Event not found"