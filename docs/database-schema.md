# QRollCall Database Schema

## Overview
The backend currently uses SQLAlchemy models for the main entities:
- `users`
- `events`
- `attendances`
- `notifications`
- `classes`
- `class_memberships`
- `class_invitations`


---

## users

Purpose:
Stores authenticated system users.

Key fields:
- `id` primary key
- `firebase_uid` unique
- `username` unique nullable
- `email` unique
- `full_name`
- `role` enum: `admin | student`
- `is_active`
- `phone_number`
- `student_id` unique nullable

- `profile_image_url`
- `created_at`
- `updated_at`

Relationships:
- one-to-many with `events` through `created_by_user_id`
- one-to-many with `attendances`

---

## events

Purpose:
Stores attendance events/classes/sessions.

Key fields:
- `id` primary key
- `name`
- `description`
- `start_time`
- `end_time`
- `location_name`
- `latitude`
- `longitude`
- `geofence_radius_meters`
- `qr_code_token` unique
- `qr_code_image_path`
- `qr_validity_minutes`
- `is_active`
- `class_id` foreign key to `classes.id` nullable
- `created_by_user_id` foreign key to `users.id`
- `created_at`
- `updated_at`


Relationships:
- many-to-one with `users`
- one-to-many with `attendances`

---

## attendances

Purpose:
Stores attendance results for a user at an event.

Key fields:
- `id` primary key
- `event_id` foreign key
- `user_id` foreign key
- `scanned_at`
- `status` enum: `present | absent | rejected`
- `scan_latitude`
- `scan_longitude`
- `device_id`
- `rejection_reason`
- `created_at`
- `updated_at`

Constraints:
- unique `(event_id, user_id)`

Behavior note:
- rejected scans update the same attendance row on retry
- present attendance cannot be duplicated

---

## notifications

Purpose:
Stores in-app notification records.

Key fields:
- `id` primary key
- `user_id` foreign key
- `event_id` nullable foreign key
- `title`
- `message`
- `notification_type`
- `is_read`
- `created_at`
- `updated_at`

---

## classes

Purpose:
Groups students for centralized course management.

Key fields:
- `id` primary key
- `name`
- `class_code` unique
- `teacher_user_id` foreign key
- `description`
- `location_name`
- `bounds_latitude_min/max`
- `bounds_longitude_min/max`

---

## class_memberships

Purpose:
Links students to classes.

Key fields:
- `id` primary key
- `class_id` foreign key
- `user_id` foreign key
- `role` (STUDENT | TEACHER)
- `status` (ACTIVE | INACTIVE)

---

## class_invitations

Purpose:
Handles formal invitations to join a class.

Key fields:
- `id` primary key
- `class_id` foreign key
- `creator_id` foreign key
- `invited_user_id` foreign key nullable (if user exists)
- `invited_email` nullable
- `invited_username` nullable
- `status` (PENDING | ACCEPTED | DECLINED | EXPIRED)

- attendance marking must derive `user_id` from the authenticated user
- event creation must derive `created_by_user_id` from the authenticated admin
- route-level authorization determines which records each user can access