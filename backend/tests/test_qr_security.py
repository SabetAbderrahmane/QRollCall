"""
test_qr_security.py — Phase 5 QR & Attendance Security Edge Cases

Covers:
  - Invalid / unknown token → rejected
  - Expired QR window → rejected
  - Outside geofence → rejected
  - Inactive event → blocked at service layer
  - Duplicate scan after PRESENT → 409 blocked
  - Unauthenticated scan → 401
"""
from datetime import timedelta

from app.models.event import Event
from app.models.user import User, UserRole
from app.services.auth_service import AuthService
from app.utils.datetime_utils import utc_now


# ─── fixtures ─────────────────────────────────────────────────────────────────

def make_admin(db_session, uid="sec-admin-uid", email="sec_admin@test.com") -> User:
    u = User(
        firebase_uid=uid,
        email=email,
        full_name="Security Admin",
        role=UserRole.ADMIN,
        is_active=True,
        phone_number=None,
        student_id=None,
        profile_image_url=None,
    )
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


def make_student(db_session, uid="sec-student-uid", email="sec_student@test.com") -> User:
    u = User(
        firebase_uid=uid,
        email=email,
        full_name="Security Student",
        role=UserRole.STUDENT,
        is_active=True,
        phone_number=None,
        student_id=None,
        profile_image_url=None,
    )
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


def make_event(
    db_session,
    admin_id: int,
    *,
    token: str = "sec-test-token",
    is_active: bool = True,
    start_time=None,
    qr_validity_minutes: int = 15,
) -> Event:
    if start_time is None:
        start_time = utc_now()
    event = Event(
        name="Security Test Event",
        description="Security edge case test",
        start_time=start_time,
        end_time=start_time + timedelta(hours=1),
        location_name="Security Lab",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=120,
        qr_code_token=token,
        qr_code_image_path=None,
        qr_validity_minutes=qr_validity_minutes,
        is_active=is_active,
        created_by_user_id=admin_id,
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)
    return event


def install_auth_mock(monkeypatch, token_claims_map: dict[str, dict]) -> None:
    def mock_verify(self, authorization):
        scheme, token = authorization.split(" ", 1)
        assert scheme == "Bearer"
        assert token in token_claims_map
        return token_claims_map[token]

    monkeypatch.setattr(AuthService, "verify_firebase_token", mock_verify)


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


# ─── Phase 5 Security Tests ───────────────────────────────────────────────────

def test_mark_attendance_invalid_token_is_rejected(client, db_session, monkeypatch):
    """An unknown QR token must be rejected with 400."""
    admin = make_admin(db_session, uid="inv-tok-admin", email="inv_tok_admin@test.com")
    student = make_student(db_session, uid="inv-tok-student", email="inv_tok_student@test.com")

    install_auth_mock(monkeypatch, {
        "inv-tok-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    response = client.post(
        "/api/v1/attendance/mark",
        json={
            "qr_code_token": "COMPLETELY-INVALID-TOKEN-XXXX",
            "scan_latitude": 30.549,
            "scan_longitude": 114.342,
            "device_id": "sec-device-1",
        },
        headers=auth_headers("inv-tok-bearer"),
    )

    assert response.status_code == 404
    assert "invalid" in response.json()["detail"].lower() or "not found" in response.json()["detail"].lower()


def test_mark_attendance_inactive_event_is_blocked(client, db_session, monkeypatch):
    """Scanning a QR for an inactive event must be rejected."""
    admin = make_admin(db_session, uid="inactive-admin-uid", email="inactive_admin@test.com")
    student = make_student(db_session, uid="inactive-student-uid", email="inactive_student@test.com")
    event = make_event(db_session, admin.id, token="inactive-event-token", is_active=False)

    install_auth_mock(monkeypatch, {
        "inactive-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    response = client.post(
        "/api/v1/attendance/mark",
        json={
            "qr_code_token": event.qr_code_token,
            "scan_latitude": 30.549,
            "scan_longitude": 114.342,
            "device_id": "sec-device-2",
        },
        headers=auth_headers("inactive-bearer"),
    )

    assert response.status_code == 400
    assert "not active" in response.json()["detail"].lower()


def test_mark_attendance_expired_qr_records_rejected(client, db_session, monkeypatch):
    """A scan against a QR whose validity window has passed must record status=rejected."""
    admin = make_admin(db_session, uid="exp-admin-uid", email="exp_admin@test.com")
    student = make_student(db_session, uid="exp-student-uid", email="exp_student@test.com")

    # Event started 30 minutes ago; QR only valid 5 minutes after start
    past_start = utc_now() - timedelta(minutes=30)
    event = make_event(
        db_session,
        admin.id,
        token="expired-qr-token",
        is_active=True,
        start_time=past_start,
        qr_validity_minutes=5,  # expired 25 minutes ago
    )

    install_auth_mock(monkeypatch, {
        "exp-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    response = client.post(
        "/api/v1/attendance/mark",
        json={
            "qr_code_token": event.qr_code_token,
            "scan_latitude": 30.549,
            "scan_longitude": 114.342,
            "device_id": "sec-device-3",
        },
        headers=auth_headers("exp-bearer"),
    )

    # The scan is created but with REJECTED status
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "rejected"
    assert data["rejection_reason"] is not None
    assert "time" in data["rejection_reason"].lower() or "window" in data["rejection_reason"].lower()


def test_mark_attendance_outside_geofence_records_rejected(client, db_session, monkeypatch):
    """A scan far outside the geofence radius must record status=rejected."""
    admin = make_admin(db_session, uid="geo-admin-uid", email="geo_admin@test.com")
    student = make_student(db_session, uid="geo-student-uid", email="geo_student@test.com")
    event = make_event(db_session, admin.id, token="geo-test-token")

    install_auth_mock(monkeypatch, {
        "geo-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    # Location far from event (different city entirely)
    response = client.post(
        "/api/v1/attendance/mark",
        json={
            "qr_code_token": event.qr_code_token,
            "scan_latitude": 40.000,   # far away
            "scan_longitude": 120.000,
            "device_id": "sec-device-4",
        },
        headers=auth_headers("geo-bearer"),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "rejected"
    assert data["rejection_reason"] is not None
    assert "geofence" in data["rejection_reason"].lower() or "location" in data["rejection_reason"].lower() or "distance" in data["rejection_reason"].lower()


def test_mark_attendance_duplicate_present_returns_409(client, db_session, monkeypatch):
    """After a PRESENT scan, a second scan for the same event must return 409."""
    admin = make_admin(db_session, uid="dup-admin-uid", email="dup_admin@test.com")
    student = make_student(db_session, uid="dup-student-uid", email="dup_student@test.com")
    event = make_event(db_session, admin.id, token="dup-sec-token")

    install_auth_mock(monkeypatch, {
        "dup-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    payload = {
        "qr_code_token": event.qr_code_token,
        "scan_latitude": 30.549,
        "scan_longitude": 114.342,
        "device_id": "dup-device",
    }

    first = client.post("/api/v1/attendance/mark", json=payload, headers=auth_headers("dup-bearer"))
    assert first.status_code == 201
    assert first.json()["status"] == "present"

    second = client.post("/api/v1/attendance/mark", json=payload, headers=auth_headers("dup-bearer"))
    assert second.status_code == 409
    assert "already marked" in second.json()["detail"].lower()


def test_mark_attendance_without_auth_returns_401(client, db_session):
    """A scan attempt without an Authorization header must return 401."""
    response = client.post(
        "/api/v1/attendance/mark",
        json={
            "qr_code_token": "any-token",
            "scan_latitude": 30.549,
            "scan_longitude": 114.342,
            "device_id": "no-auth-device",
        },
    )

    assert response.status_code == 401


def test_validate_qr_unknown_token_returns_invalid(client, db_session, monkeypatch):
    """Validating an unknown token via /qr/validate must return valid=False."""
    admin = make_admin(db_session, uid="qrval-admin-uid", email="qrval_admin@test.com")
    student = make_student(db_session, uid="qrval-student-uid", email="qrval_student@test.com")

    install_auth_mock(monkeypatch, {
        "qrval-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    response = client.post(
        "/api/v1/qr/validate",
        json={
            "token": "UNKNOWN-TOKEN-9999",
            "scan_latitude": 30.549,
            "scan_longitude": 114.342,
            "scanned_at": utc_now().isoformat(),
        },
        headers=auth_headers("qrval-bearer"),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert data["reason"] is not None


def test_validate_qr_outside_time_window_returns_invalid(client, db_session, monkeypatch):
    """Validating a QR that is past validity window returns valid=False."""
    admin = make_admin(db_session, uid="qrtime-admin", email="qrtime_admin@test.com")
    student = make_student(db_session, uid="qrtime-student", email="qrtime_student@test.com")

    past_start = utc_now() - timedelta(minutes=30)
    event = make_event(
        db_session, admin.id,
        token="qrtime-test-token",
        start_time=past_start,
        qr_validity_minutes=5  # expired 25 min ago
    )

    install_auth_mock(monkeypatch, {
        "qrtime-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    response = client.post(
        "/api/v1/qr/validate",
        json={
            "token": event.qr_code_token,
            "scan_latitude": 30.549,
            "scan_longitude": 114.342,
            "scanned_at": utc_now().isoformat(),
        },
        headers=auth_headers("qrtime-bearer"),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert data["within_time_window"] is False
