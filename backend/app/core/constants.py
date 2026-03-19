# backend/app/core/constants.py
API_TAG_AUTH = "auth"
API_TAG_USERS = "users"
API_TAG_EVENTS = "events"
API_TAG_ATTENDANCE = "attendance"
API_TAG_QR = "qr"
API_TAG_NOTIFICATIONS = "notifications"
API_TAG_HEALTH = "health"
API_TAG_REPORTS = "reports"

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100
MAX_EXPORT_PAGE_SIZE = 1000

DEFAULT_QR_VALIDITY_MINUTES = 15
DEFAULT_GEOFENCE_RADIUS_METERS = 100

ATTENDANCE_REJECTION_TIME_WINDOW = "Scan is outside the allowed time window"
ATTENDANCE_REJECTION_GEOFENCE = "Scan is outside the event geofence"
ATTENDANCE_ALREADY_MARKED = "Attendance already marked for this user and event"

ERROR_USER_NOT_FOUND = "User not found"
ERROR_EVENT_NOT_FOUND = "Event not found"
ERROR_ATTENDANCE_NOT_FOUND = "Attendance not found"
ERROR_NOTIFICATION_NOT_FOUND = "Notification not found"
ERROR_INVALID_QR_TOKEN = "Invalid QR token"
ERROR_CREATOR_NOT_FOUND = "Creator user not found"

ROLE_ADMIN = "admin"
ROLE_STUDENT = "student"

REPORT_FORMAT_CSV = "csv"
REPORT_FORMAT_PDF = "pdf"
SUPPORTED_REPORT_FORMATS = {REPORT_FORMAT_CSV, REPORT_FORMAT_PDF}
