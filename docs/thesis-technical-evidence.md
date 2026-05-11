# Thesis Technical Evidence
*Auto-generated assessment of the QRollCall repository*

## 1. Project Structure Summary
The project is built as a typical monorepo containing both the backend and mobile applications, alongside configuration and infrastructure documentation:
- `backend/`: Python-based FastAPI web service managing business logic and database.
- `mobile/`: Flutter-based mobile application.
- `docs/`: Technical documentation and design artifacts.
- `infra/`: Infrastructure components (e.g., Docker configuration).
- `tools/`: Utility scripts.
- `docker-compose.yml`: For managing local services and databases.

## 2. Backend Architecture Summary
The backend is built with **FastAPI** (`backend/app/main.py`) and adheres to a multi-layer Service-Oriented Architecture (SOA):
- **API (Routers):** Located in `backend/app/api/v1/`, handling request validation and payload mapping via Pydantic (`backend/app/schemas/`).
- **Services:** High-level business logic located in `backend/app/services/` (e.g., `attendance_service.py`, `qr_service.py`, `auth_service.py`).
- **Repositories:** Data access layer mapping objects to backend databases (e.g., `AttendanceRepository`).
- **Models:** SQLAlchemy ORM models (`backend/app/models/`).
- **Core / Utils:** Common project constants, configuration, and helpers like `datetime_utils` and `geo`.

## 3. Mobile Flutter Architecture Summary
The mobile codebase (`mobile/pubspec.yaml`, `mobile/lib/`) uses **Flutter** with a feature-driven folder structure:
- **Feature Modules:** Each major user activity resides in its own isolated module under `lib/features/` (e.g., `auth/`, `home/`, `live_attendance/`, `qr_scanner/`).
- **State Management:** Relies primarily on the `provider` package (`provider: ^6.1.5`).
- **Core Integrations:** Integrates specific SDKs for essential tasks: `mobile_scanner` for reading QRs, `geolocator` for fetching GPS coordinates, and `firebase_auth` & `google_sign_in` for user identity context.
- **Models:** Data objects defined in `lib/models/`.

## 4. Database/Schema Summary
The database employs PostgreSQL/SQLite manipulated via SQLAlchemy and Alembic migrations. The core schema contains:
- **User (`models/user.py`):** Holds users identified by `firebase_uid`. Defines roles (`UserRole.ADMIN`, `UserRole.STUDENT`) and profile fields like `email`, `student_id`, and `full_name`.
- **Event (`models/event.py`):** Holds event metadata (`start_time`, `end_time`, `location_name`), QR validity constants (`qr_validity_minutes`), and strict geofencing coordinates (`latitude`, `longitude`, `geofence_radius_meters`).
- **Attendance (`models/attendance.py`):** Links `event_id` and `user_id`. Tracks scanning status (`PRESENT`, `ABSENT`, `REJECTED`), scan coordinates (`scan_latitude`, `scan_longitude`), timestamp, and capturing metadata like `device_id` and `rejection_reason`.

## 5. Authentication Flow
Authentication is federated through Firebase:
1. **Client-side:** The Flutter app signs in users using `firebase_auth` and retrieves a Firebase ID token.
2. **Server-side Validation:** Mobile passes the token in the `Authorization: Bearer <token>` header. The backend extracts it and invokes `AuthService.verify_firebase_token`.
3. **Database Syncing:** Upon successful verification, `sync_user_from_authorization` dynamically fetches or creates a shadow DB user mapping the `firebase_uid` and claims (`email`, `name`, `picture`).

## 6. QR Generation and Validation Flow
- **Generation:** Handled strictly by admins. The `QRService` (`backend/app/services/qr_service.py`) utilizes the python `qrcode` library to generate an image. The payload encodes the unique `qr_code_token` coupled with the event.
- **Validation:** On scan, the token is sent to the backend. `QRService.validate_event_qr()` matches the token with an event context and explicitly tests for both location bounds and time bounds.

## 7. Attendance Scan Flow
1. A student uses the `qr_scanner` feature module on mobile to capture the token.
2. The payload (token + user's GPS data via `geolocator` plugin + `device_id`) is POSTed to the `/api/v1/attendance/mark` endpoint.
3. `AttendanceService.mark_attendance()` retrieves the student info, checks if the event is active, and issues a validation challenge.
4. **Resolution:** If the validation passes, the status becomes `AttendanceStatus.PRESENT`. If the validation fails (due to geofence or time gaps), the status is explicitly set to `AttendanceStatus.REJECTED` along with a reason. The system blocks duplicate `PRESENT` marks but permits retrying a `REJECTED` attempt.

## 8. Anti-fraud Rules Implemented or Planned
- **Implemented:**
  - **Time Validity Check:** Overdue scans are rejected if they exceed `qr_validity_minutes` natively stored in the `Event` record.
  - **Location/Geofencing Check:** Haversine radius validation (`geofence_service.py`: `is_within_radius`) ensures the user's scan coordinates map securely within the `geofence_radius_meters`.
- **Planned / Not Found:**
  - **Strict Device Filtering:** Though `device_id` is collected and saved in the schema, automated server-level blocking logic mapping one student explicitly to one device ID preventing parallel scans is not fully implemented.
  - **Dynamic OR Rotational QRs:** Current configurations lean towards static QRs validating for an interval timeframe. No periodic hashing implementations (like TOTP embedded QRs) were detected in `qr_service.py`.

## 9. Existing Test Files and What They Verify
Backend testing is constructed around pytest (`backend/tests/`):
- `test_attendance.py`: Validates logic flows explicitly concerning attendance marking paths (e.g., duplicate presentation blocks, retry capabilities over previous rejections). Tests visibility scoping (students attempting to list others).
- `test_qr_validation.py`: Asserts authorization requirements (denying students QR generation). Confirms payload validation accuracy respecting mocked geofences and timestamp boundaries.
- `test_auth.py`, `test_events.py`, `test_health.py`, `test_notifications.py`, `test_reports.py`: Verify basic authorization mappings, CRUD structures for events, and standard component health checks.
- Mobile Testing (`mobile/test/`): Currently scarce; `widget_test.dart` holds a default stub meaning rigorous frontend interface test suites remain unstarted or excluded.

## 10. Gaps Between Current Repo and Thesis Proposal
Based on typical robust anti-fraud identity platforms evaluated in thesis concepts:
- **Biometric Attestation Validation Missing:** Current presence validation heavily relies on possession (Token/Device) plus context (Geo/Time) but is missing inherent physical verification (e.g., Face/Fingerprint triggers before hitting the scanner) mapped securely to the backend.
- **Lack of Device Lockout Rules:** As indicated in the Anti-fraud parameters, device signatures (`device_id`) are passed mostly for analytics rather than hard lockdown blocking (e.g., soft fraud detection).
- **Mobile Environment Auditing:** There are no evident jailbreak, app-cloning, or mock-GPS spoofing mitigations implemented in the Flutter environment parameters.
