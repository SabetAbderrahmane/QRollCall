from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import mapped_column, relationship
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String)
    hashed_password = mapped_column(String)
    is_active = Column(Boolean, default=True)

    # Relationship to attendance
    attendances = relationship("Attendance", back_populates="user")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, full_name={self.full_name})>"
