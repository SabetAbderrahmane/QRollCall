from sqlalchemy import Column, Integer, ForeignKey, DateTime, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class Attendance(Base):
    __tablename__ = "attendances"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    event_id = Column(Integer, ForeignKey("events.id"))
    scanned_at = Column(DateTime)
    status = Column(String)  # "present", "absent", "late", etc.
    scan_latitude = Column(String)
    scan_longitude = Column(String)

    # Relationship to event and user
    user = relationship("User", back_populates="attendances")
    event = relationship("Event", back_populates="attendances")

    def __repr__(self):
        return f"<Attendance(id={self.id}, user_id={self.user_id}, event_id={self.event_id})>"
