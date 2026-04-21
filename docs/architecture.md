# QRollCall Architecture

## High-level structure

### Backend
Python FastAPI application located in `backend/app/`.

Main layers:
- `api/` → route handlers
- `core/` → config, exceptions, permissions, constants
- `db/` → engine/session management
- `models/` → SQLAlchemy entities
- `repositories/` → persistence operations
- `services/` → business logic
- `schemas/` → request/response models
- `utils/` → shared helpers

### Mobile
Flutter application located in `mobile/`.

### Documentation
Located in `docs/`.

---

## Request flow

Typical protected request flow:
1. client sends Firebase ID token in `Authorization` header
2. dependency layer resolves current backend user
3. route applies role/ownership rules
4. service layer executes business logic
5. repository layer persists data
6. response schema serializes the result

---

## Attendance flow

1. admin creates event
2. backend generates event-specific QR token/image
3. student scans QR
4. backend validates:
   - token exists
   - event is active
   - scan time is within validity window
   - location is within geofence
5. backend stores or updates attendance
6. duplicate present attendance is rejected

---

## Health and operations

The backend exposes:
- liveness probe
- readiness probe
- basic health metadata

Readiness requires:
- database connectivity
- QR storage availability

---

## Current security posture

Implemented:
- Firebase-backed authentication integration
- route-level admin and ownership checks
- client-supplied user identity removed from attendance mark flow
- client-supplied creator identity removed from event creation flow
- admin-only report and QR generation endpoints
- owner/admin notification access control

Hardening in this batch:
- centralized application exception handlers
- safer default CORS configuration
- repo hygiene via `.gitignore`
- operational health endpoints with dependency checks

---

## Future architecture work

Recommended next:
- WebSocket or SSE support for real-time admin dashboard
- real Firebase Cloud Messaging delivery
- stronger audit logging
- migration-based schema evolution checks
- deployment profiles for staging and production