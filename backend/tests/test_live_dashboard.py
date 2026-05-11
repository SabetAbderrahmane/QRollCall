"""
test_live_dashboard.py — Phase 8 Real-Time Dashboard Verification

Covers:
  - get_live_attendance_snapshot for standalone events (only shows scanners)
  - get_live_attendance_snapshot for class-linked events (shows full roster)
  - Verify counts (present, rejected, absent) are correct in snapshot
"""
from datetime import timedelta
from app.models.attendance import AttendanceStatus
from app.models.class_membership import MembershipRole, MembershipStatus
from app.models.user import UserRole
from app.services.attendance_service import AttendanceService
from app.utils.datetime_utils import utc_now

def test_live_snapshot_standalone_event(db_session):
    """
    Standalone events should only return students who actually scanned.
    """
    from app.models.user import User
    from app.models.event import Event
    from app.models.attendance import Attendance

    # Setup Admin
    admin = User(firebase_uid="snap-admin-std", email="snap_admin_std@t.com", full_name="Admin", role=UserRole.ADMIN, is_active=True)
    db_session.add(admin)
    db_session.commit()

    # Setup Student
    student = User(firebase_uid="snap-s-std", email="s_std@t.com", full_name="Student", role=UserRole.STUDENT, is_active=True)
    db_session.add(student)
    db_session.commit()

    # Setup Event
    event = Event(
        name="Standalone Check", 
        class_id=None, 
        created_by_user_id=admin.id, 
        start_time=utc_now(),
        end_time=utc_now() + timedelta(hours=1),
        is_active=True,
        qr_code_token="snap-token-std",
        latitude=0, longitude=0, geofence_radius_meters=100
    )
    db_session.add(event)
    db_session.commit()

    service = AttendanceService(db_session)
    
    # 1. Empty snapshot
    snapshot = service.get_live_attendance_snapshot(event.id)
    assert snapshot["total_records"] == 0
    assert len(snapshot["students"]) == 0

    # 2. Add one attendance
    from app.models.attendance import Attendance
    att = Attendance(
        event_id=event.id,
        user_id=student.id,
        status=AttendanceStatus.PRESENT,
        scanned_at=utc_now(),
        device_id="dev-1",
        scan_latitude=30.0,
        scan_longitude=114.0
    )
    db_session.add(att)
    db_session.commit()

    snapshot = service.get_live_attendance_snapshot(event.id)
    assert snapshot["total_records"] == 1
    assert snapshot["present_count"] == 1
    assert len(snapshot["students"]) == 1
    assert snapshot["students"][0]["user_id"] == student.id

def test_live_snapshot_class_linked_event(db_session):
    """
    Class-linked events should return all roster students.
    """
    from app.models.user import User
    from app.models.class_room import ClassRoom
    from app.models.class_membership import ClassMembership
    from app.models.event import Event
    from app.models.attendance import Attendance

    # Setup Admin
    admin = User(firebase_uid="snap-admin", email="snap_admin@t.com", full_name="Admin", role=UserRole.ADMIN, is_active=True)
    db_session.add(admin)
    db_session.commit()

    # Setup Class
    cls = ClassRoom(name="Realtime Class", teacher_user_id=admin.id)
    db_session.add(cls)
    db_session.commit()

    # Setup Students (Roster)
    s1 = User(firebase_uid="snap-s1", email="s1@t.com", full_name="S1 Present", role=UserRole.STUDENT, is_active=True)
    s2 = User(firebase_uid="snap-s2", email="s2@t.com", full_name="S2 Rejected", role=UserRole.STUDENT, is_active=True)
    s3 = User(firebase_uid="snap-s3", email="s3@t.com", full_name="S3 Absent", role=UserRole.STUDENT, is_active=True)
    db_session.add_all([s1, s2, s3])
    db_session.commit()

    # Enroll
    for s in [s1, s2, s3]:
        m = ClassMembership(class_id=cls.id, user_id=s.id, role=MembershipRole.STUDENT, status=MembershipStatus.ACTIVE)
        db_session.add(m)
    db_session.commit()

    # Setup Event
    event = Event(
        name="Live Check", 
        class_id=cls.id, 
        created_by_user_id=admin.id, 
        start_time=utc_now(),
        end_time=utc_now() + timedelta(hours=1),
        is_active=True,
        qr_code_token="snap-token",
        latitude=0, longitude=0, geofence_radius_meters=100
    )
    db_session.add(event)
    db_session.commit()

    # s1 = PRESENT, s2 = REJECTED, s3 = NONE
    a1 = Attendance(event_id=event.id, user_id=s1.id, status=AttendanceStatus.PRESENT, scanned_at=utc_now(), device_id="d1")
    a2 = Attendance(event_id=event.id, user_id=s2.id, status=AttendanceStatus.REJECTED, scanned_at=utc_now(), device_id="d2", rejection_reason="Too far")
    db_session.add_all([a1, a2])
    db_session.commit()

    service = AttendanceService(db_session)
    snapshot = service.get_live_attendance_snapshot(event.id)

    assert snapshot["total_records"] == 3
    assert snapshot["present_count"] == 1
    assert snapshot["rejected_count"] == 1
    assert snapshot["absent_count"] == 1

    # Map students by status
    status_map = {s["user_id"]: s["status"] for s in snapshot["students"]}
    assert status_map[s1.id] == "present"
    assert status_map[s2.id] == "rejected"
    assert status_map[s3.id] == "absent"

    # Verify dummy data for absent student
    s3_data = next(s for s in snapshot["students"] if s["user_id"] == s3.id)
    assert s3_data["attendance_id"] == 0
    assert s3_data["entry_method"] == "N/A"
