from app.models.user import User
from app.services.auth_service import AuthService


def test_verify_token_requires_header(client):
    response = client.get("/api/v1/auth/verify")
    assert response.status_code == 401
    assert response.json()["detail"] == "Missing Authorization header"


def test_sync_user_from_token_success(client, monkeypatch):
    claims = {
        "uid": "firebase-test-uid",
        "email": "auth_user@test.com",
        "name": "Auth Test User",
        "phone_number": "+1234567890",
        "picture": "https://example.com/profile.png",
    }

    def mock_verify_firebase_token(self, authorization):
        assert authorization == "Bearer fake-token"
        return claims

    monkeypatch.setattr(
        AuthService,
        "verify_firebase_token",
        mock_verify_firebase_token,
    )

    response = client.post(
        "/api/v1/auth/sync-user",
        headers={"Authorization": "Bearer fake-token"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["firebase_uid"] == claims["uid"]
    assert data["email"] == claims["email"]
    assert data["full_name"] == claims["name"]
    assert data["role"] == "student"
    assert data["is_active"] is True


def test_get_current_user_success(client, monkeypatch):
    claims = {
        "uid": "firebase-me-uid",
        "email": "me_user@test.com",
        "name": "Me User",
        "phone_number": None,
        "picture": None,
    }

    def mock_verify_firebase_token(self, authorization):
        assert authorization == "Bearer fake-me-token"
        return claims

    monkeypatch.setattr(
        AuthService,
        "verify_firebase_token",
        mock_verify_firebase_token,
    )

    sync_response = client.post(
        "/api/v1/auth/sync-user",
        headers={"Authorization": "Bearer fake-me-token"},
    )
    assert sync_response.status_code == 200

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer fake-me-token"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["firebase_uid"] == claims["uid"]
    assert data["email"] == claims["email"]
    assert data["full_name"] == claims["name"]