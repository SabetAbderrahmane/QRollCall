# backend/app/schemas/auth.py
from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import UserRole


class FirebaseTokenVerifyResponse(BaseModel):
    valid: bool
    firebase_uid: str
    user_id: int
    email: EmailStr
    role: UserRole


class SyncUserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    firebase_uid: str
    email: EmailStr
    full_name: str
    role: UserRole
    is_active: bool


class CurrentUserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    firebase_uid: str
    email: EmailStr
    full_name: str
    role: UserRole
    is_active: bool
    phone_number: str | None = None
    student_id: str | None = None
    profile_image_url: str | None = None


class AuthorizationHeaderPayload(BaseModel):
    authorization: str = Field(..., min_length=8)


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class BackendTokenRequest(BaseModel):
    user_id: int = Field(..., ge=1)
    email: EmailStr
    role: UserRole
