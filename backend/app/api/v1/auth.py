from fastapi import APIRouter, Header, HTTPException, status

from app.api.deps import DbSession
from app.core.exceptions import AuthenticationError, FirebaseInitializationError
from app.schemas.auth import (
    CurrentUserResponse,
    FirebaseTokenVerifyResponse,
    SyncUserResponse,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


def _raise_auth_http_error(exc: Exception) -> None:
    if isinstance(exc, AuthenticationError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=exc.message,
        ) from exc

    if isinstance(exc, FirebaseInitializationError):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=exc.message,
        ) from exc

    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Authentication service error",
    ) from exc


@router.get("/verify", response_model=FirebaseTokenVerifyResponse)
def verify_firebase_token(
    db: DbSession,
    authorization: str | None = Header(default=None),
) -> FirebaseTokenVerifyResponse:
    service = AuthService(db)

    try:
        claims = service.verify_firebase_token(authorization)
        user = service.get_or_create_user_from_claims(claims)
    except Exception as exc:
        _raise_auth_http_error(exc)

    return FirebaseTokenVerifyResponse(
        valid=True,
        firebase_uid=user.firebase_uid,
        user_id=user.id,
        email=user.email,
        role=user.role,
    )


@router.post("/sync-user", response_model=SyncUserResponse)
def sync_user_from_token(
    db: DbSession,
    authorization: str | None = Header(default=None),
) -> SyncUserResponse:
    service = AuthService(db)

    try:
        user = service.sync_user_from_authorization(authorization)
    except Exception as exc:
        _raise_auth_http_error(exc)

    return SyncUserResponse.model_validate(user)


@router.get("/me", response_model=CurrentUserResponse)
def get_current_user(
    db: DbSession,
    authorization: str | None = Header(default=None),
) -> CurrentUserResponse:
    service = AuthService(db)

    try:
        user = service.get_current_user(authorization)
    except Exception as exc:
        _raise_auth_http_error(exc)

    return CurrentUserResponse.model_validate(user)