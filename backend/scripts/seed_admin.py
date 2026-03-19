# backend/scripts/seed_admin.py
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.user import User, UserRole


def main() -> None:
    db = SessionLocal()

    try:
        existing_admin = db.scalar(
            select(User).where(User.email == "admin@qrattend.com")
        )
        if existing_admin is not None:
            print("Admin user already exists.")
            return

        admin = User(
            firebase_uid="seed-admin-firebase-uid",
            email="admin@qrattend.com",
            full_name="System Admin",
            role=UserRole.ADMIN,
            is_active=True,
            phone_number="+10000000000",
            student_id=None,
            profile_image_url=None,
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)

        print(f"Admin created successfully. ID={admin.id}, email={admin.email}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
