from typing import Annotated

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.exceptions import AuthenticationError, FirebaseInitializationError
from app.db.session import get_db
from app.models.user import User
from app.services.auth_service import AuthService

DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(
    db: DbSession,
    authorization: str | None = Header(default=None),
) -> User:
    service = AuthService(db)

    try:
        return service.get_current_user(authorization)
    except AuthenticationError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=exc.message,
        ) from exc
    except FirebaseInitializationError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=exc.message,
        ) from exc


CurrentUser = Annotated[User, Depends(get_current_user)]