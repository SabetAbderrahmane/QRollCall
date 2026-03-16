import qrcode
from io import BytesIO
from fastapi.responses import StreamingResponse

def create_qr_token(event_id: int) -> StreamingResponse:
    """
    Generate a QR code for an event and return it as a StreamingResponse.
    The QR code will contain the event's ID.
    """
    data = f"event_id={event_id}"

    # Generate the QR code
    qr = qrcode.make(data)
    
    # Save the QR code as an image in memory
    img_io = BytesIO()
    qr.save(img_io, "PNG")  # Correctly specify the format ("PNG")
    img_io.seek(0)

    # Return the QR code as a response (image/png format)
    return StreamingResponse(img_io, media_type="image/png")
