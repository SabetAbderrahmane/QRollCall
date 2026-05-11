from datetime import datetime
from pydantic import BaseModel, ConfigDict

from app.models.class_membership import MembershipRole, MembershipStatus

class ClassRoomBase(BaseModel):
    name: str
    description: str | None = None
    location_name: str | None = None
    default_latitude: float | None = None
    default_longitude: float | None = None
    default_geofence_radius_meters: int = 100
    class_code: str | None = None

class ClassRoomCreate(ClassRoomBase):
    pass

class ClassRoomUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    location_name: str | None = None
    default_latitude: float | None = None
    default_longitude: float | None = None
    default_geofence_radius_meters: int | None = None
    is_active: bool | None = None

class ClassRoomResponse(ClassRoomBase):
    id: int
    teacher_user_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class ClassMembershipResponse(BaseModel):
    id: int
    class_id: int
    user_id: int
    role: MembershipRole
    status: MembershipStatus
    joined_at: datetime

    model_config = ConfigDict(from_attributes=True)

class ClassStudentResponse(BaseModel):
    membership_id: int
    user_id: int
    full_name: str
    email: str
    student_id: str | None
    role: MembershipRole
    status: MembershipStatus
    joined_at: datetime

class ClassInvitationCreate(BaseModel):
    email: str | None = None
    username: str | None = None

class ClassInvitationResponse(BaseModel):
    id: int
    class_id: int
    invited_email: str | None
    invited_username: str | None
    status: str
    expires_at: datetime
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class ClassInvitationDetailsResponse(ClassInvitationResponse):
    class_name: str
    teacher_name: str
