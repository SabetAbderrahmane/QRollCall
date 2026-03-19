from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentUser, DbSession
from app.core.permissions import require_admin, require_same_user_or_admin
from app.repositories.user_repository import UserRepository
from app.schemas.user import (
    UserCreate,
    UserListResponse,
    UserResponse,
    UserRoleUpdate,
    UserUpdate,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    payload: UserCreate,
    db: DbSession,
    current_user: CurrentUser,
) -> UserResponse:
    require_admin(current_user)
    repository = UserRepository(db)

    if repository.exists_by_email_or_firebase_uid(payload.email, payload.firebase_uid):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email or firebase_uid already exists",
        )

    if payload.student_id:
        existing_student = repository.get_by_student_id(payload.student_id)
        if existing_student is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User with this student_id already exists",
            )

    user = repository.create(
        firebase_uid=payload.firebase_uid,
        email=payload.email,
        full_name=payload.full_name,
        role=payload.role,
        is_active=payload.is_active,
        phone_number=payload.phone_number,
        student_id=payload.student_id,
        profile_image_url=payload.profile_image_url,
    )
    return UserResponse.model_validate(user)


@router.get("", response_model=UserListResponse)
def list_users(
    db: DbSession,
    current_user: CurrentUser,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
) -> UserListResponse:
    require_admin(current_user)
    repository = UserRepository(db)
    items, total = repository.list(skip=skip, limit=limit, search=search)
    return UserListResponse(items=items, total=total)


@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    db: DbSession,
    current_user: CurrentUser,
) -> UserResponse:
    require_same_user_or_admin(current_user, user_id)
    repository = UserRepository(db)
    user = repository.get_by_id(user_id)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return UserResponse.model_validate(user)


@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: DbSession,
    current_user: CurrentUser,
) -> UserResponse:
    require_same_user_or_admin(current_user, user_id)
    repository = UserRepository(db)
    user = repository.get_by_id(user_id)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    update_data = payload.model_dump(exclude_unset=True)

    if "student_id" in update_data and update_data["student_id"]:
        existing_student = repository.get_by_student_id(update_data["student_id"])
        if existing_student is not None and existing_student.id != user_id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User with this student_id already exists",
            )

    updated_user = repository.update(user, **update_data)
    return UserResponse.model_validate(updated_user)


@router.patch("/{user_id}/role", response_model=UserResponse)
def update_user_role(
    user_id: int,
    payload: UserRoleUpdate,
    db: DbSession,
    current_user: CurrentUser,
) -> UserResponse:
    require_admin(current_user)
    repository = UserRepository(db)
    user = repository.get_by_id(user_id)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    updated_user = repository.update(user, role=payload.role)
    return UserResponse.model_validate(updated_user)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: DbSession,
    current_user: CurrentUser,
) -> None:
    require_admin(current_user)
    repository = UserRepository(db)
    user = repository.get_by_id(user_id)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    repository.delete(user)
