from datetime import timedelta

from app.models.event import Event
from app.models.user import User, UserRole
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


def test_validate_qr_success(client, db_session):
    admin = create_qr_admin(db_session)
    event = create_qr_event(db_session, admin.id)

    payload = {
        "token": event.qr_code_token,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "scanned_at": utc_now().isoformat(),
    }

    response = client.post("/api/v1/qr/validate", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is True
    assert data["event_id"] == event.id
    assert data["within_time_window"] is True
    assert data["within_geofence"] is True
    assert data["reason"] is None


def test_validate_qr_invalid_token(client):
    payload = {
        "token": "missing-token",
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "scanned_at": utc_now().isoformat(),
    }

    response = client.post("/api/v1/qr/validate", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert data["event_id"] is None
    assert data["within_time_window"] is False
    assert data["within_geofence"] is False
    assert data["reason"] == "Invalid QR token"


def test_validate_qr_outside_geofence(client, db_session):
    admin = create_qr_admin(db_session)
    event = create_qr_event(db_session, admin.id)

    payload = {
        "token": event.qr_code_token,
        "scan_latitude": 31.000,
        "scan_longitude": 115.000,
        "scanned_at": utc_now().isoformat(),
    }

    response = client.post("/api/v1/qr/validate", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert data["event_id"] == event.id
    assert data["within_time_window"] is True
    assert data["within_geofence"] is False
    assert data["reason"] == "Scan is outside the event geofence"
