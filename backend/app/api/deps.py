from typing import Annotated

from fastapi import Depends, Header
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User
from app.services.auth_service import AuthService

DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(
    db: DbSession,
    authorization: str | None = Header(default=None),
) -> User:
    service = AuthService(db)
    return service.get_current_user(authorization)


CurrentUser = Annotated[User, Depends(get_current_user)]
