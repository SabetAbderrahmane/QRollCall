# backend/app/core/exceptions.py
class AppException(Exception):
    default_message = "Application error"

    def __init__(self, message: str | None = None) -> None:
        self.message = message or self.default_message
        super().__init__(self.message)


class NotFoundError(AppException):
    default_message = "Resource not found"


class ValidationError(AppException):
    default_message = "Validation failed"


class ConflictError(AppException):
    default_message = "Resource conflict"


class AuthenticationError(AppException):
    default_message = "Authentication failed"


class AuthorizationError(AppException):
    default_message = "Not authorized"


class QRCodeError(AppException):
    default_message = "QR code operation failed"


class GeofenceError(AppException):
    default_message = "Geofence validation failed"


class ReportExportError(AppException):
    default_message = "Report export failed"


class FirebaseInitializationError(AppException):
    default_message = "Firebase initialization failed"


class DatabaseError(AppException):
    default_message = "Database operation failed"
