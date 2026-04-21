from datetime import timedelta

from app.models.event import Event
from app.models.user import User, UserRole
from app.services.auth_service import AuthService
from app.utils.datetime_utils import utc_now


def create_qr_admin(db_session) -> User:
    admin = User(
        firebase_uid="qr-admin-firebase-uid",
        email="qr_admin@test.com",
        full_name="QR Admin",
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


def create_qr_student(db_session) -> User:
    student = User(
        firebase_uid="qr-student-firebase-uid",
        email="qr_student@test.com",
        full_name="QR Student",
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


def create_qr_event(db_session, admin_id: int) -> Event:
    start_time = utc_now()
    event = Event(
        name="QR Validation Event",
        description="QR validation test event",
        start_time=start_time,
        end_time=start_time + timedelta(hours=1),
        location_name="Validation Room",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=120,
        qr_code_token="qr-validation-token",
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


def test_admin_can_generate_qr(client, db_session, monkeypatch):
    admin = create_qr_admin(db_session)
    event = create_qr_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "qr-admin-generate-token": {
                "uid": admin.firebase_uid,
                "email": admin.email,
                "name": admin.full_name,
            }
        },
    )

    response = client.post(
        "/api/v1/qr/generate",
        json={"event_id": event.id},
        headers=auth_headers("qr-admin-generate-token"),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["event_id"] == event.id
    assert data["token"] == event.qr_code_token
    assert data["qr_code_image_path"].endswith(".png")


def test_student_cannot_generate_qr(client, db_session, monkeypatch):
    admin = create_qr_admin(db_session)
    student = create_qr_student(db_session)
    event = create_qr_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "qr-student-generate-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    response = client.post(
        "/api/v1/qr/generate",
        json={"event_id": event.id},
        headers=auth_headers("qr-student-generate-token"),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Admin access required"


def test_authenticated_user_can_validate_qr(client, db_session, monkeypatch):
    admin = create_qr_admin(db_session)
    student = create_qr_student(db_session)
    event = create_qr_event(db_session, admin.id)

    install_auth_mock(
        monkeypatch,
        {
            "qr-student-validate-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    payload = {
        "token": event.qr_code_token,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "scanned_at": utc_now().isoformat(),
    }

    response = client.post(
        "/api/v1/qr/validate",
        json=payload,
        headers=auth_headers("qr-student-validate-token"),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is True
    assert data["event_id"] == event.id
    assert data["within_time_window"] is True
    assert data["within_geofence"] is True
    assert data["reason"] is None


def test_validate_qr_requires_authentication(client, db_session):
    payload = {
        "token": "missing-token",
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "scanned_at": utc_now().isoformat(),
    }

    response = client.post("/api/v1/qr/validate", json=payload)

    assert response.status_code == 401
    assert response.json()["detail"] == "Missing Authorization header"