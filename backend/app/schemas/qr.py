from pydantic import BaseModel

class QRTokenResponse(BaseModel):
    event_id: int
    qr_token: str  # The QR code image will be served as a response, but here we can store token or URL for the image.

    class Config:
        orm_mode = True  # Tells Pydantic to work with SQLAlchemy models if needed
