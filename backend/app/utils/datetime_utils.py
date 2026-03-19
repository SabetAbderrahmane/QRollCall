# backend/app/utils/datetime_utils.py
from datetime import datetime, timedelta, timezone


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def ensure_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def calculate_qr_window(
    start_time: datetime,
    validity_minutes: int,
) -> tuple[datetime, datetime]:
    normalized_start = ensure_utc(start_time)
    valid_from = normalized_start - timedelta(minutes=validity_minutes)
    valid_to = normalized_start + timedelta(minutes=validity_minutes)
    return valid_from, valid_to


def is_within_time_window(
    scan_time: datetime,
    start_time: datetime,
    validity_minutes: int,
) -> bool:
    normalized_scan_time = ensure_utc(scan_time)
    valid_from, valid_to = calculate_qr_window(start_time, validity_minutes)
    return valid_from <= normalized_scan_time <= valid_to


def format_iso(value: datetime | None) -> str | None:
    if value is None:
        return None
    return ensure_utc(value).isoformat()
