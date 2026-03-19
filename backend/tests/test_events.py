# backend/tests/test_events.py
from datetime import timedelta

from app.models.user import User, UserRole
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


def test_create_event(client, db_session):
    admin = create_admin(db_session)

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
        "created_by_user_id": admin.id,
    }

    response = client.post("/api/v1/events", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == payload["name"]
    assert data["created_by_user_id"] == admin.id
    assert "qr_code_token" in data


def test_list_events(client, db_session):
    admin = create_admin(db_session)

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
        "created_by_user_id": admin.id,
    }

    client.post("/api/v1/events", json=payload)
    response = client.get("/api/v1/events")

    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


def test_get_event_not_found(client):
    response = client.get("/api/v1/events/999999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Event not found"
# backend/tests/test_events.py
from datetime import timedelta

from app.models.user import User, UserRole
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


def test_create_event(client, db_session):
    admin = create_admin(db_session)

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
        "created_by_user_id": admin.id,
    }

    response = client.post("/api/v1/events", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == payload["name"]
    assert data["created_by_user_id"] == admin.id
    assert "qr_code_token" in data


def test_list_events(client, db_session):
    admin = create_admin(db_session)

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
        "created_by_user_id": admin.id,
    }

    client.post("/api/v1/events", json=payload)
    response = client.get("/api/v1/events")

    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


def test_get_event_not_found(client):
    response = client.get("/api/v1/events/999999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Event not found"
