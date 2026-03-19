from app.models.event import Event
from app.schemas.qr import QRCodePayload


def build_qr_payload(event: Event) -> QRCodePayload:
    return QRCodePayload(
        event_id=event.id,
        event_name=event.name,
        start_time=event.start_time,
        latitude=event.latitude,
        longitude=event.longitude,
        geofence_radius_meters=event.geofence_radius_meters,
        qr_validity_minutes=event.qr_validity_minutes,
        token=event.qr_code_token,
    )


def build_qr_payload_json(event: Event) -> str:
    return build_qr_payload(event).model_dump_json()


def build_qr_payload_dict(event: Event) -> dict:
    return build_qr_payload(event).model_dump()