# backend/app/core/permissions.py
from fastapi import HTTPException, status

from app.models.user import User, UserRole


def require_authenticated_user(user: User | None) -> User:
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
        )
    return user


def require_active_user(user: User | None) -> User:
    user = require_authenticated_user(user)

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user account",
        )

    return user


def require_admin(user: User | None) -> User:
    user = require_active_user(user)

    if user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    return user


def require_same_user_or_admin(current_user: User | None, target_user_id: int) -> User:
    user = require_active_user(current_user)

    if user.role == UserRole.ADMIN:
        return user

    if user.id != target_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access this resource",
        )

    return user
