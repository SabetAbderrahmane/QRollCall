# QRollCall API Specification

## Base URL
`/api/v1`

## Authentication
Most protected endpoints require:

`Authorization: Bearer <firebase_id_token>`

Authentication and authorization rules:
- Student/participant users can mark their own attendance and view their own attendance/notifications.
- Admin users can manage events, generate QR codes, access reports, and create notifications.

---

## Health

### `GET /health`
Basic root health endpoint.

### `GET /api/v1/health`
Returns service health metadata and non-blocking dependency information.

Response fields:
- `success`
- `status`
- `service`
- `environment`
- `checks.qr_storage`
- `checks.firebase`

### `GET /api/v1/health/ready`
Readiness probe.

Readiness depends on:
- database query succeeds
- QR storage directory is available

Returns:
- `200 OK` when ready
- `503 Service Unavailable` when not ready

### `GET /api/v1/health/live`
Liveness probe.

---

## Auth

### `GET /api/v1/auth/verify`
Verifies Firebase token and ensures the corresponding backend user exists.

### `POST /api/v1/auth/sync-user`
Synchronizes Firebase user claims into the backend database.

### `GET /api/v1/auth/me`
Returns the current authenticated backend user.

---

## Users

### `POST /api/v1/users`
Admin only.

### `GET /api/v1/users`
Admin only.

### `GET /api/v1/users/{user_id}`
Owner or admin.

### `PUT /api/v1/users/{user_id}`
Owner or admin.

### `PATCH /api/v1/users/{user_id}/role`
Admin only.

### `DELETE /api/v1/users/{user_id}`
Admin only.

---

## Events

### `POST /api/v1/events`
Admin only.

Notes:
- `created_by_user_id` is derived from the authenticated admin.
- Clients must not send `created_by_user_id`.

### `GET /api/v1/events`
Authenticated users.

### `GET /api/v1/events/{event_id}`
Authenticated users.

### `PUT /api/v1/events/{event_id}`
Admin only.

### `DELETE /api/v1/events/{event_id}`
Admin only.

---

## Attendance

### `POST /api/v1/attendance/mark`
Authenticated active users.

Request body:
- `qr_code_token`
- `scan_latitude`
- `scan_longitude`
- `device_id` optional

Notes:
- `user_id` is derived from the authenticated user.
- A previously rejected scan may be retried.
- A previously present attendance record cannot be duplicated.

### `GET /api/v1/attendance`
- Admin: may filter by `user_id` and/or `event_id`
- Student: limited to their own records

### `GET /api/v1/attendance/stats/{event_id}`
Admin only.

---

## QR

### `POST /api/v1/qr/generate`
Admin only.

### `GET /api/v1/qr/event/{event_id}`
Admin only.

### `POST /api/v1/qr/validate`
Authenticated active users.

Validation checks:
- event exists
- scan is inside allowed time window
- scan is inside event geofence

---

## Notifications

### `POST /api/v1/notifications`
Admin only.

### `GET /api/v1/notifications`
- Admin: can list all or filter by user/event
- Student: only their own notifications

### `GET /api/v1/notifications/{notification_id}`
Owner or admin.

### `PUT /api/v1/notifications/{notification_id}`
Owner or admin.

### `PATCH /api/v1/notifications/{notification_id}/read`
Owner or admin.

### `DELETE /api/v1/notifications/{notification_id}`
Owner or admin.

---

## Reports

### `GET /api/v1/reports/dashboard`
Admin only.

### `GET /api/v1/reports/events/{event_id}`
Admin only.

### `GET /api/v1/reports/users/{user_id}`
Admin only.

### `POST /api/v1/reports/export`
Admin only.

### `GET /api/v1/reports/export/event/{event_id}?format=csv|pdf`
Admin only.

### `GET /api/v1/reports/export/user/{user_id}?format=csv|pdf`
Admin only.