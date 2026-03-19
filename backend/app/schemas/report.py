# backend/app/schemas/report.py
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, model_validator


class EventAttendanceSummary(BaseModel):
    event_id: int
    event_name: str
    start_time: datetime
    total_records: int
    present_count: int
    absent_count: int
    rejected_count: int
    attendance_percentage: float = Field(..., ge=0, le=100)


class UserAttendanceSummary(BaseModel):
    user_id: int
    full_name: str
    email: str
    total_events: int
    attended_events: int
    missed_events: int
    attendance_percentage: float = Field(..., ge=0, le=100)


class AttendanceTrendPoint(BaseModel):
    label: str
    value: int = Field(..., ge=0)


class ReportFilter(BaseModel):
    event_id: Optional[int] = Field(default=None, ge=1)
    user_id: Optional[int] = Field(default=None, ge=1)
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None

    @model_validator(mode="after")
    def validate_date_range(self):
        if (
            self.start_date is not None
            and self.end_date is not None
            and self.end_date < self.start_date
        ):
            raise ValueError("end_date must be greater than or equal to start_date")
        return self


class ExportReportRequest(BaseModel):
    format: str = Field(..., pattern="^(csv|pdf)$")
    event_id: Optional[int] = Field(default=None, ge=1)
    user_id: Optional[int] = Field(default=None, ge=1)

    @model_validator(mode="after")
    def validate_target(self):
        if self.event_id is None and self.user_id is None:
            raise ValueError("Either event_id or user_id must be provided")
        if self.event_id is not None and self.user_id is not None:
            raise ValueError("Provide either event_id or user_id, not both")
        return self


class ExportReportResponse(BaseModel):
    format: str
    file_name: str
    file_path: str


class DashboardSummaryResponse(BaseModel):
    total_users: int = Field(..., ge=0)
    total_events: int = Field(..., ge=0)
    total_attendance_records: int = Field(..., ge=0)
    total_present: int = Field(..., ge=0)
    total_absent: int = Field(..., ge=0)
    total_rejected: int = Field(..., ge=0)
    low_attendance_users: int = Field(..., ge=0)
    recent_trends: list[AttendanceTrendPoint]
