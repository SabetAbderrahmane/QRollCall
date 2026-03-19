# backend/app/api/v1/qr.py
from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession
from app.core.constants import ERROR_EVENT_NOT_FOUND
from app.schemas.qr import (
    QRCodeGenerateRequest,
    QRCodeGenerateResponse,
    QRCodeImageResponse,
    QRCodeValidateRequest,
    QRCodeValidateResponse,
)
from app.services.event_service import EventService
from app.services.qr_service import qr_service

router = APIRouter(prefix="/qr", tags=["qr"])


@router.post(
    "/generate",
    response_model=QRCodeGenerateResponse,
    status_code=status.HTTP_201_CREATED,
)
def generate_qr_code(
    payload: QRCodeGenerateRequest,
    db: DbSession,
) -> QRCodeGenerateResponse:
    event_service = EventService(db)

    try:
        event = event_service.require_event(payload.event_id)
        event = event_service.generate_qr_for_event(event)
    except ValueError as exc:
        message = str(exc)
        status_code = (
            status.HTTP_404_NOT_FOUND
            if message == ERROR_EVENT_NOT_FOUND
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=message) from exc

    return QRCodeGenerateResponse(
        event_id=event.id,
        token=event.qr_code_token,
        qr_code_image_path=event.qr_code_image_path or "",
        payload=qr_service.build_payload(event),
    )


@router.get("/event/{event_id}", response_model=QRCodeImageResponse)
def get_event_qr_code(event_id: int, db: DbSession) -> QRCodeImageResponse:
    event_service = EventService(db)

    try:
        event = event_service.get_or_generate_qr_for_event(event_id)
    except ValueError as exc:
        message = str(exc)
        status_code = (
            status.HTTP_404_NOT_FOUND
            if message == ERROR_EVENT_NOT_FOUND
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=message) from exc

    return QRCodeImageResponse(
        event_id=event.id,
        token=event.qr_code_token,
        image_path=event.qr_code_image_path or "",
    )


@router.post("/validate", response_model=QRCodeValidateResponse)
def validate_qr_code(
    payload: QRCodeValidateRequest,
    db: DbSession,
) -> QRCodeValidateResponse:
    event_service = EventService(db)
    event = event_service.get_event_by_qr_token(payload.token)

    result = qr_service.validate_event_qr(
        event=event,
        scan_latitude=payload.scan_latitude,
        scan_longitude=payload.scan_longitude,
        scanned_at=payload.scanned_at,
    )

    return QRCodeValidateResponse(**result)
