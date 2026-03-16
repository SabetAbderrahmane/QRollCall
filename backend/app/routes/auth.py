from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from app.core.database import get_db
from app.services.auth_service import hash_password, verify_password, create_access_token
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, Token
from app.schemas.user import UserResponse
from app.core.config import get_settings

settings = get_settings()


router = APIRouter()


@router.post("/register", response_model=UserResponse)
def register(
    user_request: RegisterRequest, db: Session = Depends(get_db)
):
    db_user = db.query(User).filter(User.email == user_request.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = hash_password(user_request.password)
    new_user = User(
        email=user_request.email,
        full_name=user_request.full_name,
        hashed_password=hashed_password,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.post("/login", response_model=Token)
def login(
    login_request: LoginRequest, db: Session = Depends(get_db)
):
    db_user = db.query(User).filter(User.email == login_request.email).first()
    if not db_user or not verify_password(login_request.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    access_token = create_access_token(
        data={"sub": db_user.email, "id": db_user.id, "full_name": db_user.full_name},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )

    return {"access_token": access_token, "token_type": "bearer"}
