from datetime import datetime
from pathlib import Path
from typing import Any

import qrcode

from app.core.config import get_settings
from app.core.constants import (
    ATTENDANCE_REJECTION_GEOFENCE,
    ATTENDANCE_REJECTION_TIME_WINDOW,
    ERROR_INVALID_QR_TOKEN,
)
from app.models.event import Event
from app.schemas.qr import QRCodePayload
from app.utils.datetime_utils import is_within_time_window, utc_now
from app.utils.geo import is_within_radius
from app.utils.qr_payload import build_qr_payload, build_qr_payload_json

settings = get_settings()


class QRService:
    def build_payload(self, event: Event) -> QRCodePayload:
        return build_qr_payload(event)

    def generate_qr_image(self, event: Event) -> str:
        image_dir = Path(settings.QR_IMAGE_DIR)
        image_dir.mkdir(parents=True, exist_ok=True)

        file_name = f"event_{event.id}.png"
        file_path = image_dir / file_name

        qr = qrcode.QRCode(version=1, box_size=10, border=4)
        qr.add_data(build_qr_payload_json(event))
        qr.make(fit=True)

        image = qr.make_image(fill_color="black", back_color="white")
        image.save(file_path)

        return str(file_path).replace("\\", "/")

    def validate_event_qr(
        self,
        event: Event | None,
        scan_latitude: float,
        scan_longitude: float,
        scanned_at: datetime | None = None,
    ) -> dict[str, Any]:
        if event is None:
            return {
                "valid": False,
                "event_id": None,
                "reason": ERROR_INVALID_QR_TOKEN,
                "within_time_window": False,
                "within_geofence": False,
            }

        scan_time = scanned_at or utc_now()
        within_time_window = is_within_time_window(
            scan_time=scan_time,
            start_time=event.start_time,
            validity_minutes=event.qr_validity_minutes,
        )

        within_geofence = is_within_radius(
            scan_latitude=scan_latitude,
            scan_longitude=scan_longitude,
            target_latitude=event.latitude,
            target_longitude=event.longitude,
            radius_meters=event.geofence_radius_meters,
        )

        reason = None
        valid = True

        if not within_time_window:
            valid = False
            reason = ATTENDANCE_REJECTION_TIME_WINDOW
        elif not within_geofence:
            valid = False
            reason = ATTENDANCE_REJECTION_GEOFENCE

        return {
            "valid": valid,
            "event_id": event.id,
            "reason": reason,
            "within_time_window": within_time_window,
            "within_geofence": within_geofence,
        }


qr_service = QRService()

