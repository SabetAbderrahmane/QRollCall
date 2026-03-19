from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import UserRole


class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    phone_number: Optional[str] = Field(default=None, max_length=30)
    student_id: Optional[str] = Field(default=None, max_length=64)
    profile_image_url: Optional[str] = Field(default=None, max_length=500)


class UserCreate(UserBase):
    firebase_uid: str = Field(..., min_length=1, max_length=128)
    role: UserRole = UserRole.STUDENT
    is_active: bool = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, min_length=2, max_length=255)
    phone_number: Optional[str] = Field(default=None, max_length=30)
    student_id: Optional[str] = Field(default=None, max_length=64)
    profile_image_url: Optional[str] = Field(default=None, max_length=500)
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    firebase_uid: str
    role: UserRole
    is_active: bool
    created_at: datetime
    updated_at: datetime


class UserListResponse(BaseModel):
    items: list[UserResponse]
    total: int


class UserRoleUpdate(BaseModel):
    role: UserRole
