from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import auth, credentials

from app.core.config import get_settings
from app.core.exceptions import AuthenticationError, FirebaseInitializationError

settings = get_settings()


class FirebaseService:
    def __init__(self) -> None:
        self._initialized = False

    def initialize(self) -> None:
        if firebase_admin._apps:
            self._initialized = True
            return

        credentials_path = settings.FIREBASE_CREDENTIALS_PATH
        if not credentials_path:
            raise FirebaseInitializationError(
                "FIREBASE_CREDENTIALS_PATH is not configured"
            )

        cred_file = Path(credentials_path)
        if not cred_file.exists():
            raise FirebaseInitializationError(
                f"Firebase credentials file not found: {cred_file}"
            )

        cred = credentials.Certificate(str(cred_file))
        firebase_admin.initialize_app(cred)
        self._initialized = True

    def verify_id_token(self, token: str) -> dict[str, Any]:
        self.initialize()

        try:
            return auth.verify_id_token(
                token,
                clock_skew_seconds=10,
            )
        except Exception as exc:
            raise AuthenticationError(f"Invalid Firebase token: {exc}") from exc

    def get_user(self, uid: str):
        self.initialize()

        try:
            return auth.get_user(uid)
        except Exception as exc:
            raise AuthenticationError(f"Unable to fetch Firebase user: {exc}") from exc

    def create_custom_token(
        self,
        uid: str,
        claims: dict[str, Any] | None = None,
    ) -> str:
        self.initialize()

        try:
            token = auth.create_custom_token(uid, developer_claims=claims or {})
            return token.decode("utf-8")
        except Exception as exc:
            raise AuthenticationError(
                f"Unable to create Firebase custom token: {exc}"
            ) from exc

    def revoke_refresh_tokens(self, uid: str) -> None:
        self.initialize()

        try:
            auth.revoke_refresh_tokens(uid)
        except Exception as exc:
            raise AuthenticationError(
                f"Unable to revoke Firebase refresh tokens: {exc}"
            ) from exc


firebase_service = FirebaseService()
