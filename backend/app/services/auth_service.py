from sqlalchemy.orm import Session

from app.core.exceptions import AuthenticationError
from app.models.user import User, UserRole
from app.repositories.user_repository import UserRepository
from app.services.firebase_service import firebase_service


class AuthService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.user_repository = UserRepository(db)

    @staticmethod
    def extract_bearer_token(authorization: str | None) -> str:
        if not authorization:
            raise AuthenticationError("Missing Authorization header")

        parts = authorization.split(" ", 1)
        if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1].strip():
            raise AuthenticationError("Invalid Authorization header")

        return parts[1].strip()

    def verify_firebase_token(self, authorization: str | None) -> dict:
        token = self.extract_bearer_token(authorization)
        return firebase_service.verify_id_token(token)

    def get_or_create_user_from_claims(self, claims: dict) -> User:
        firebase_uid = claims.get("uid")
        email = claims.get("email")
        full_name = claims.get("name") or email or "Unknown User"

        if not firebase_uid or not email:
            raise AuthenticationError(
                "Firebase token is missing required user fields"
            )

        user = self.user_repository.get_by_firebase_uid(firebase_uid)

        if user is not None:
            updates: dict[str, str] = {}

            if user.email != email:
                updates["email"] = email

            if full_name and user.full_name != full_name:
                updates["full_name"] = full_name

            phone_number = claims.get("phone_number")
            if phone_number and user.phone_number != phone_number:
                updates["phone_number"] = phone_number

            profile_image_url = claims.get("picture")
            if profile_image_url and user.profile_image_url != profile_image_url:
                updates["profile_image_url"] = profile_image_url

            if updates:
                user = self.user_repository.update(user, **updates)

            return user

        return self.user_repository.create(
            firebase_uid=firebase_uid,
            email=email,
            full_name=full_name,
            role=UserRole.STUDENT,
            is_active=True,
            phone_number=claims.get("phone_number"),
            student_id=None,
            profile_image_url=claims.get("picture"),
        )

    def sync_user_from_authorization(self, authorization: str | None) -> User:
        claims = self.verify_firebase_token(authorization)
        return self.get_or_create_user_from_claims(claims)

    def get_current_user(self, authorization: str | None) -> User:
        claims = self.verify_firebase_token(authorization)
        firebase_uid = claims.get("uid")

        if not firebase_uid:
            raise AuthenticationError("Firebase token is missing uid")

        user = self.user_repository.get_by_firebase_uid(firebase_uid)
        if user is not None:
            return user

        return self.get_or_create_user_from_claims(claims)

