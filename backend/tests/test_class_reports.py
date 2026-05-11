"""
test_class_reports.py — Phase 6 Reports and Absence Logic Tests

Covers:
  - Class-linked event: absent is computed from roster, not explicit ABSENT rows
  - Present students are correctly counted
  - Rejected scans are shown as rejected (NOT absent)
  - Non-scanned enrolled students appear as absent
  - Students who are NOT in the class but scan are excluded from roster counts
  - Roster report endpoint returns correct per-student statuses
  - Standalone (non-class) events continue to work as before
"""
from datetime import timedelta

from app.models.attendance import Attendance, AttendanceStatus
from app.models.class_membership import ClassMembership, MembershipRole, MembershipStatus
from app.models.class_room import ClassRoom
from app.models.event import Event
from app.models.user import User, UserRole
from app.services.auth_service import AuthService
from app.utils.datetime_utils import utc_now


# ─── helpers ──────────────────────────────────────────────────────────────────

def make_admin(db_session, uid="cr-admin-uid", email="cr_admin@test.com") -> User:
    u = User(
        firebase_uid=uid, email=email, full_name="Class Report Admin",
        role=UserRole.ADMIN, is_active=True,
        phone_number=None, student_id=None, profile_image_url=None,
    )
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


def make_student(db_session, uid: str, email: str, name: str = "Student") -> User:
    u = User(
        firebase_uid=uid, email=email, full_name=name,
        role=UserRole.STUDENT, is_active=True,
        phone_number=None, student_id=None, profile_image_url=None,
    )
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


def make_class(db_session, teacher_id: int) -> ClassRoom:
    cls = ClassRoom(
        name="Software Engineering",
        description="SE course",
        teacher_user_id=teacher_id,
        is_active=True,
    )
    db_session.add(cls)
    db_session.commit()
    db_session.refresh(cls)
    return cls


def enroll(db_session, class_id: int, user_id: int) -> ClassMembership:
    mem = ClassMembership(
        class_id=class_id,
        user_id=user_id,
        role=MembershipRole.STUDENT,
        status=MembershipStatus.ACTIVE,
        joined_at=utc_now(),
    )
    db_session.add(mem)
    db_session.commit()
    db_session.refresh(mem)
    return mem


def make_class_event(db_session, admin_id: int, class_id: int, token: str = "class-ev-tok") -> Event:
    start = utc_now()
    event = Event(
        name="Class Attendance Event",
        description="Phase 6 test",
        class_id=class_id,
        start_time=start,
        end_time=start + timedelta(hours=1),
        location_name="Lecture Hall",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=150,
        qr_code_token=token,
        qr_code_image_path=None,
        qr_validity_minutes=15,
        is_active=True,
        created_by_user_id=admin_id,
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)
    return event


def make_attendance(db_session, event_id: int, user_id: int, status: AttendanceStatus) -> Attendance:
    a = Attendance(
        event_id=event_id,
        user_id=user_id,
        scanned_at=utc_now(),
        status=status,
        scan_latitude=30.549,
        scan_longitude=114.342,
        device_id="test-device",
        rejection_reason="Outside geofence" if status == AttendanceStatus.REJECTED else None,
    )
    db_session.add(a)
    db_session.commit()
    db_session.refresh(a)
    return a


def install_auth_mock(monkeypatch, token_claims_map: dict) -> None:
    def mock_verify(self, authorization):
        scheme, token = authorization.split(" ", 1)
        assert scheme == "Bearer"
        assert token in token_claims_map
        return token_claims_map[token]
    monkeypatch.setattr(AuthService, "verify_firebase_token", mock_verify)


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


# ─── Phase 6 Tests ────────────────────────────────────────────────────────────

def test_event_summary_absent_count_uses_roster_for_class_event(db_session):
    """
    For a class-linked event with 3 students enrolled:
    - 1 present, 1 rejected, 1 unscanned
    The summary absent_count should be 1 (the unscanned member), NOT 0.
    """
    from app.services.report_service import ReportService

    admin = make_admin(db_session, uid="evs-admin-uid", email="evs_admin@test.com")
    s1 = make_student(db_session, "evs-s1", "evs_s1@t.com", "Student A")
    s2 = make_student(db_session, "evs-s2", "evs_s2@t.com", "Student B")
    s3 = make_student(db_session, "evs-s3", "evs_s3@t.com", "Student C")

    cls = make_class(db_session, admin.id)
    for s in [s1, s2, s3]:
        enroll(db_session, cls.id, s.id)

    event = make_class_event(db_session, admin.id, cls.id, token="evs-class-tok")

    # s1 = PRESENT, s2 = REJECTED, s3 = no scan (absent)
    make_attendance(db_session, event.id, s1.id, AttendanceStatus.PRESENT)
    make_attendance(db_session, event.id, s2.id, AttendanceStatus.REJECTED)

    service = ReportService(db_session)
    summary = service.get_event_summary(event.id)

    assert summary.present_count == 1
    assert summary.rejected_count == 1
    assert summary.absent_count == 1  # s3 had no scan at all


def test_event_summary_absent_count_zero_when_all_present(db_session):
    """All enrolled students present → absent_count = 0."""
    from app.services.report_service import ReportService

    admin = make_admin(db_session, uid="allpres-admin", email="allpres_admin@t.com")
    s1 = make_student(db_session, "allpres-s1", "ap_s1@t.com")
    s2 = make_student(db_session, "allpres-s2", "ap_s2@t.com")

    cls = make_class(db_session, admin.id)
    enroll(db_session, cls.id, s1.id)
    enroll(db_session, cls.id, s2.id)

    event = make_class_event(db_session, admin.id, cls.id, token="allpres-tok")
    make_attendance(db_session, event.id, s1.id, AttendanceStatus.PRESENT)
    make_attendance(db_session, event.id, s2.id, AttendanceStatus.PRESENT)

    service = ReportService(db_session)
    summary = service.get_event_summary(event.id)

    assert summary.present_count == 2
    assert summary.absent_count == 0
    assert summary.attendance_percentage == 100.0


def test_event_summary_absent_count_fallback_for_standalone_event(db_session):
    """Standalone event (no class_id) still counts explicit ABSENT rows."""
    from app.models.event import Event
    from app.services.report_service import ReportService

    admin = make_admin(db_session, uid="standalone-admin", email="sa_admin@t.com")
    s1 = make_student(db_session, "standalone-s1", "sa_s1@t.com")

    start = utc_now()
    event = Event(
        name="Standalone Event",
        description="no class linked",
        class_id=None,
        start_time=start,
        end_time=start + timedelta(hours=1),
        location_name="Open Hall",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=100,
        qr_code_token="standalone-tok",
        qr_code_image_path=None,
        qr_validity_minutes=15,
        is_active=True,
        created_by_user_id=admin.id,
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    make_attendance(db_session, event.id, s1.id, AttendanceStatus.PRESENT)

    service = ReportService(db_session)
    summary = service.get_event_summary(event.id)

    # Standalone: absent is from explicit rows, present count is 1
    assert summary.present_count == 1
    assert summary.absent_count == 0  # no explicit ABSENT rows


def test_class_roster_report_returns_all_three_statuses(client, db_session, monkeypatch):
    """
    The /reports/events/{id}/class-roster endpoint must return each student's
    correct status: present, rejected, or absent.
    """
    admin = make_admin(db_session, uid="rr-admin-uid", email="rr_admin@test.com")
    s_present = make_student(db_session, "rr-spres", "rr_present@t.com", "P Student")
    s_rejected = make_student(db_session, "rr-srej", "rr_rejected@t.com", "R Student")
    s_absent = make_student(db_session, "rr-sabs", "rr_absent@t.com", "A Student")

    cls = make_class(db_session, admin.id)
    for s in [s_present, s_rejected, s_absent]:
        enroll(db_session, cls.id, s.id)

    event = make_class_event(db_session, admin.id, cls.id, token="rr-ev-tok")

    make_attendance(db_session, event.id, s_present.id, AttendanceStatus.PRESENT)
    make_attendance(db_session, event.id, s_rejected.id, AttendanceStatus.REJECTED)
    # s_absent intentionally has no scan

    install_auth_mock(monkeypatch, {
        "rr-admin-bearer": {
            "uid": admin.firebase_uid,
            "email": admin.email,
            "name": admin.full_name,
        }
    })

    resp = client.get(
        f"/api/v1/reports/events/{event.id}/class-roster",
        headers=auth_headers("rr-admin-bearer"),
    )

    assert resp.status_code == 200
    data = resp.json()

    assert data["roster_size"] == 3
    assert data["present_count"] == 1
    assert data["rejected_count"] == 1
    assert data["absent_count"] == 1
    assert data["attendance_percentage"] == round(1 / 3 * 100, 2)

    statuses_by_email = {r["email"]: r["status"] for r in data["roster"]}
    assert statuses_by_email[s_present.email] == "present"
    assert statuses_by_email[s_rejected.email] == "rejected"
    assert statuses_by_email[s_absent.email] == "absent"


def test_class_roster_report_non_class_event_returns_400(client, db_session, monkeypatch):
    """
    Calling the class-roster endpoint on a standalone event must return 400.
    """
    from app.models.event import Event

    admin = make_admin(db_session, uid="nce-admin", email="nce_admin@test.com")

    start = utc_now()
    event = Event(
        name="Non-Class Event",
        description="standalone",
        class_id=None,
        start_time=start,
        end_time=start + timedelta(hours=1),
        location_name="Hall X",
        latitude=30.549,
        longitude=114.342,
        geofence_radius_meters=100,
        qr_code_token="nce-tok",
        qr_code_image_path=None,
        qr_validity_minutes=15,
        is_active=True,
        created_by_user_id=admin.id,
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    install_auth_mock(monkeypatch, {
        "nce-admin-bearer": {
            "uid": admin.firebase_uid,
            "email": admin.email,
            "name": admin.full_name,
        }
    })

    resp = client.get(
        f"/api/v1/reports/events/{event.id}/class-roster",
        headers=auth_headers("nce-admin-bearer"),
    )

    assert resp.status_code == 400


def test_class_roster_report_requires_admin(client, db_session, monkeypatch):
    """Students must not be able to access the class roster report."""
    admin = make_admin(db_session, uid="rr-auth-admin", email="rr_auth_admin@t.com")
    student = make_student(db_session, "rr-auth-student", "rr_auth_stu@t.com")

    cls = make_class(db_session, admin.id)
    event = make_class_event(db_session, admin.id, cls.id, token="rr-auth-tok")

    install_auth_mock(monkeypatch, {
        "rr-stu-bearer": {
            "uid": student.firebase_uid,
            "email": student.email,
            "name": student.full_name,
        }
    })

    resp = client.get(
        f"/api/v1/reports/events/{event.id}/class-roster",
        headers=auth_headers("rr-stu-bearer"),
    )

    assert resp.status_code == 403
