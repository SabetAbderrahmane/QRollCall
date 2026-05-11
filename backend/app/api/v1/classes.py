from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import CurrentUser, DbSession
from app.core.permissions import require_active_user, require_admin
from app.models.user import User
from app.schemas.class_room import (
    ClassRoomCreate,
    ClassRoomResponse,
    ClassStudentResponse,
    ClassInvitationCreate,
    ClassInvitationResponse,
    ClassInvitationDetailsResponse
)
from app.services.class_service import ClassService

router = APIRouter(prefix="/classes", tags=["classes"])

@router.post("", response_model=ClassRoomResponse, status_code=status.HTTP_201_CREATED)
def create_class(
    data: ClassRoomCreate,
    current_user: CurrentUser,
    db: DbSession,
):
    admin_user = require_admin(current_user)
    service = ClassService(db)
    return service.create_class(data, current_user.id)

@router.get("/my", response_model=list[ClassRoomResponse])
def get_my_classes(
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    return service.list_my_classes(current_user.id)

@router.get("/created", response_model=list[ClassRoomResponse])
def get_created_classes(
    current_user: CurrentUser,
    db: DbSession,
):
    admin_user = require_admin(current_user)
    service = ClassService(db)
    return service.list_created_classes(admin_user.id)

@router.get("/{class_id}", response_model=ClassRoomResponse)
def get_class(
    class_id: int,
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    try:
        return service.get_class(class_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{class_id}/students", response_model=list[ClassStudentResponse])
def get_class_students(
    class_id: int,
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    try:
        mem = service.get_roster(class_id, current_user.id)
        return [
            ClassStudentResponse(
                membership_id=m.id,
                user_id=m.user.id,
                full_name=m.user.full_name,
                email=m.user.email,
                student_id=m.user.student_id,
                role=m.role,
                status=m.status,
                joined_at=m.joined_at,
            ) for m in mem
        ]
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))

@router.post("/{class_id}/invite", response_model=ClassInvitationResponse)
def invite_student(
    class_id: int,
    data: ClassInvitationCreate,
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    try:
        return service.create_invitation(class_id, current_user.id, data.email, data.username)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/{class_id}/invitations", response_model=list[ClassInvitationResponse])
def get_class_invitations(
    class_id: int,
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    # verify teacher ownership
    cls_obj = service.get_class(class_id)
    if cls_obj.teacher_user_id != current_user.id:
        raise HTTPException(status_code=403)
    return service.inv_repo.list_by_class(class_id)

@router.get("/me/invitations", response_model=list[ClassInvitationDetailsResponse])
def get_my_invitations(
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    invites = service.list_my_invitations(current_user)
    return [
        ClassInvitationDetailsResponse(
            **inv.__dict__,
            class_name=inv.class_room.name,
            teacher_name=inv.creator.full_name,
        ) for inv in invites
    ]

@router.post("/invitations/{invitation_id}/accept")
def accept_invitation(
    invitation_id: int,
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    try:
        service.accept_invitation(invitation_id, current_user)
        return {"success": True}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/invitations/{invitation_id}/decline")
def decline_invitation(
    invitation_id: int,
    current_user: CurrentUser,
    db: DbSession,
):
    require_active_user(current_user)
    service = ClassService(db)
    try:
        service.decline_invitation(invitation_id, current_user)
        return {"success": True}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
