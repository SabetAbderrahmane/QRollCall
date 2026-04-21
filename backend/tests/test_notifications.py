from app.models.notification import Notification, NotificationType
from app.models.user import User, UserRole
from app.services.auth_service import AuthService


def create_admin(db_session) -> User:
    admin = User(
        firebase_uid="notification-admin-firebase-uid",
        email="notification_admin@test.com",
        full_name="Notification Admin",
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
    firebase_uid: str,
    email: str,
    full_name: str,
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


def create_notification(
    db_session,
    *,
    user_id: int,
    title: str = "Test Notification",
    message: str = "This is a test notification",
    notification_type: NotificationType = NotificationType.REMINDER,
    is_read: bool = False,
) -> Notification:
    notification = Notification(
        user_id=user_id,
        event_id=None,
        title=title,
        message=message,
        notification_type=notification_type,
        is_read=is_read,
    )
    db_session.add(notification)
    db_session.commit()
    db_session.refresh(notification)
    return notification


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


def test_admin_can_create_notification(client, db_session, monkeypatch):
    admin = create_admin(db_session)
    student = create_student(
        db_session,
        firebase_uid="notification-student-1-uid",
        email="notification_student1@test.com",
        full_name="Notification Student One",
    )

    install_auth_mock(
        monkeypatch,
        {
            "notification-admin-create-token": {
                "uid": admin.firebase_uid,
                "email": admin.email,
                "name": admin.full_name,
            }
        },
    )

    payload = {
        "user_id": student.id,
        "title": "Event Reminder",
        "message": "Your class starts in 10 minutes",
        "notification_type": "reminder",
        "event_id": None,
    }

    response = client.post(
        "/api/v1/notifications",
        json=payload,
        headers=auth_headers("notification-admin-create-token"),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["user_id"] == student.id
    assert data["title"] == "Event Reminder"
    assert data["notification_type"] == "reminder"
    assert data["is_read"] is False


def test_user_lists_only_own_notifications(client, db_session, monkeypatch):
    student = create_student(
        db_session,
        firebase_uid="notification-student-2-uid",
        email="notification_student2@test.com",
        full_name="Notification Student Two",
    )
    other_student = create_student(
        db_session,
        firebase_uid="notification-student-3-uid",
        email="notification_student3@test.com",
        full_name="Notification Student Three",
    )

    own_notification = create_notification(
        db_session,
        user_id=student.id,
        title="Own Notification",
    )
    create_notification(
        db_session,
        user_id=other_student.id,
        title="Other Notification",
    )

    install_auth_mock(
        monkeypatch,
        {
            "notification-student-list-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    response = client.get(
        "/api/v1/notifications",
        headers=auth_headers("notification-student-list-token"),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == own_notification.id
    assert data["items"][0]["user_id"] == student.id


def test_user_cannot_access_another_users_notification(client, db_session, monkeypatch):
    student = create_student(
        db_session,
        firebase_uid="notification-student-4-uid",
        email="notification_student4@test.com",
        full_name="Notification Student Four",
    )
    other_student = create_student(
        db_session,
        firebase_uid="notification-student-5-uid",
        email="notification_student5@test.com",
        full_name="Notification Student Five",
    )
    other_notification = create_notification(
        db_session,
        user_id=other_student.id,
        title="Private Notification",
    )

    install_auth_mock(
        monkeypatch,
        {
            "notification-student-access-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    response = client.get(
        f"/api/v1/notifications/{other_notification.id}",
        headers=auth_headers("notification-student-access-token"),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "You do not have permission to access this resource"


def test_owner_can_mark_notification_read(client, db_session, monkeypatch):
    student = create_student(
        db_session,
        firebase_uid="notification-student-6-uid",
        email="notification_student6@test.com",
        full_name="Notification Student Six",
    )
    notification = create_notification(
        db_session,
        user_id=student.id,
        is_read=False,
    )

    install_auth_mock(
        monkeypatch,
        {
            "notification-owner-read-token": {
                "uid": student.firebase_uid,
                "email": student.email,
                "name": student.full_name,
            }
        },
    )

    response = client.patch(
        f"/api/v1/notifications/{notification.id}/read",
        json={"is_read": True},
        headers=auth_headers("notification-owner-read-token"),
    )

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == notification.id
    assert data["user_id"] == student.id
    assert data["is_read"] is True