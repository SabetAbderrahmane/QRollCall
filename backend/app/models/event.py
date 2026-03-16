from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    location_name = Column(String)
    latitude = Column(String)
    longitude = Column(String)
    radius_meters = Column(Integer)

    # Relationship to attendance
    attendances = relationship("Attendance", back_populates="event")

    def __repr__(self):
        return f"<Event(id={self.id}, title={self.title}, start_time={self.start_time})>"
