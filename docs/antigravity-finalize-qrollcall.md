# QRollCall Finalization Instructions for Antigravity

## Purpose

You are working inside the **QRollCall** repository.

Your task is to finalize the app into a clean thesis-ready MVP.

This is a **mobile attendance management system using QR codes**. Do not turn it into a different product. Do not invent unnecessary features. Do not rewrite the entire project unless a file is clearly broken.

The goal is to finish the missing development work, remove unfinished placeholder flows, add class/student invitation support, verify the core QR attendance flow, update documentation, and produce evidence that the system is ready for thesis demonstration.

---

## Absolute Rules

1. **Inspect before editing.**
   - First read the repository structure.
   - First inspect existing backend, mobile, docs, tests, and migrations.
   - Do not assume files are missing until you verify.

2. **Do not hallucinate features.**
   - If something is not implemented, mark it as missing.
   - If something exists, extend it instead of replacing it blindly.

3. **Work inside the QRollCall repository only.**
   - Do not modify files outside the repo.
   - Do not delete files unless explicitly necessary.
   - Do not clear caches or remove folders without approval.
   - Do not run destructive commands.

4. **Backend is source of truth for business logic.**
   - All attendance validation must be server-side.
   - The Flutter app must not be trusted for security decisions.

5. **Mobile app is Flutter.**
   - Do not generate React, HTML, CSS, Tailwind, or web frontend code.
   - All mobile UI must be Dart/Flutter.

6. **Keep the thesis MVP practical.**
   - Prioritize working flows over fancy polish.
   - Do not over-engineer.
   - Do not add complex SaaS features.

7. **Every implemented feature must include:**
   - backend code if needed
   - database migration if needed
   - tests
   - Flutter UI if user-facing
   - documentation updates

8. **Use small commits or clearly separated change groups.**
   - Suggested branch name: `feature/finalize-qrollcall-mvp`
   - Commit messages should use:
     - `feat: ...`
     - `fix: ...`
     - `test: ...`
     - `docs: ...`
     - `refactor: ...`

---

## Initial Audit Task

Before implementing anything, create:

```text
docs/finalization-audit.md
```

This file must include:

1. Current repository structure
2. Existing backend modules
3. Existing mobile screens
4. Existing database models
5. Existing migrations
6. Existing tests
7. Existing API endpoints
8. Features that already work
9. Features that are incomplete
10. Features that are missing
11. Final implementation checklist

Use exact file paths.

Mark every item as one of:

```text
IMPLEMENTED
PARTIAL
MISSING
NEEDS VERIFICATION
```

Do not continue feature implementation until this audit is complete.

---

## Core Product Definition

QRollCall must support two main roles:

### Student / Participant

A student can:

1. Sign in
2. View dashboard
3. View joined classes
4. Accept or decline class invitations
5. Scan event/session QR code
6. Submit attendance with location
7. View attendance history
8. View notifications

### Teacher / Admin / Organizer

A teacher/admin can:

1. Sign in
2. Create classes/courses
3. Invite students to classes by email or username
4. View class rosters
5. Create attendance events/sessions under a class
6. Generate and display QR code for an event/session
7. Monitor attendance
8. View present/absent students
9. Export reports if existing backend support allows it
10. Manage notifications if existing support allows it

---

## Required Final Core Flow

This full flow must work by the end:

```text
Admin logs in
→ Admin creates a class
→ Admin invites students by email or username
→ Student logs in
→ Student accepts invitation
→ Admin creates event/session under that class
→ Backend generates QR token/code
→ Student scans QR code
→ Mobile sends token + GPS coordinates to backend
→ Backend validates authenticated user, QR token, event, time window, geofence, duplicate attendance
→ Backend records attendance
→ Student sees success/failure
→ Admin sees attendance result
→ Student sees attendance history
```

This is the spine of the app. Finish this before any polish.

---

# Phase 1 — Class / Course Management

## Problem

The current app is event-based, but a real attendance system needs class rosters.

Without classes, the system can record who scanned, but it cannot reliably know who was expected to attend and therefore who is absent.

## Backend Requirements

Add class/course management.

Use safe names:

- Database table: `classes`
- Python model name: `ClassRoom` or `CourseClass`
- Avoid using `Class` as a Python model name because `class` is a reserved keyword.

### Add / verify `users.username`

If invite-by-username is required and no username field exists, add it.

Suggested user field:

```text
username
- unique
- nullable initially, unless migration/backfill is simple
- indexed
```

Ensure signup/profile sync can handle username safely if the existing auth flow supports it.

### Add model: `classes`

Suggested fields:

```text
id
name
description
class_code
teacher_user_id
location_name
default_latitude
default_longitude
default_geofence_radius_meters
is_active
created_at
updated_at
```

Rules:

- Only admins/teachers can create classes.
- Teacher/admin owns the class through `teacher_user_id`.
- `class_code` should be unique if implemented.

### Add model: `class_memberships`

Suggested fields:

```text
id
class_id
user_id
role
status
joined_at
created_at
updated_at
```

Suggested `role` values:

```text
teacher
student
assistant
```

Suggested `status` values:

```text
invited
active
removed
declined
```

Rules:

- A user should not have duplicate active membership in the same class.
- A teacher should be able to list class students.
- A student should be able to list their own joined classes.

### Add model: `class_invitations`

Suggested fields:

```text
id
class_id
invited_email
invited_username
invited_user_id
invitation_token
status
expires_at
created_by_user_id
created_at
accepted_at
declined_at
```

Suggested `status` values:

```text
pending
accepted
declined
expired
cancelled
```

Rules:

- Admin/teacher can invite by email.
- Admin/teacher can invite by username if username exists.
- Existing users should receive in-app invitation records.
- New users should be able to accept an invitation after registering with the invited email.
- Prevent duplicate pending invitations for the same class and user/email/username.
- Accepting invitation creates or activates a class membership.
- Declining invitation marks it declined.
- Only the invited user or matching email owner can accept the invitation.
- Class owner/admin can cancel pending invitations.

---

## Backend Endpoints to Add

Add a new section to `docs/api-spec.md`.

Suggested endpoints:

```text
POST   /api/v1/classes
GET    /api/v1/classes
GET    /api/v1/classes/my
GET    /api/v1/classes/{class_id}
PUT    /api/v1/classes/{class_id}
DELETE /api/v1/classes/{class_id}
```

Class roster:

```text
GET    /api/v1/classes/{class_id}/students
DELETE /api/v1/classes/{class_id}/students/{user_id}
```

Invitations:

```text
POST   /api/v1/classes/{class_id}/invite
GET    /api/v1/classes/{class_id}/invitations
GET    /api/v1/classes/invitations
POST   /api/v1/classes/invitations/{invitation_id}/accept
POST   /api/v1/classes/invitations/{invitation_id}/decline
DELETE /api/v1/classes/invitations/{invitation_id}
```

Expected request for inviting students:

```json
{
  "email": "student@example.com",
  "username": "student_username"
}
```

Allow either `email` or `username`, but not both required.

---

## Backend Tests Required

Add tests for:

1. Admin can create class
2. Student cannot create class
3. Admin can invite by email
4. Admin can invite by username
5. Duplicate invite is rejected or safely idempotent
6. Student can view pending invitation
7. Student can accept invitation
8. Student can decline invitation
9. Accepting invitation creates class membership
10. Class owner can list students
11. Unauthorized user cannot view another teacher’s private class roster
12. Deleted/removed membership no longer appears as active
13. Event can be linked to class
14. Attendance report can use class roster if implemented

---

# Phase 2 — Link Events to Classes

## Problem

Events/sessions should optionally belong to a class.

## Backend Requirements

Update event model and schema if needed:

```text
class_id
```

Rules:

- `class_id` can be nullable for standalone events.
- If `class_id` is provided, the creating admin/teacher must own or manage the class.
- Event attendance reports should support class context.
- QR generation should continue to work exactly as before.
- Attendance validation should continue to use server-side token, time window, geofence, and duplicate prevention.

## API Updates

Update event create request to allow:

```json
{
  "name": "Software Engineering Lecture 5",
  "class_id": 12,
  "start_time": "2026-05-12T10:00:00",
  "end_time": "2026-05-12T11:30:00",
  "location_name": "Building 3 Room 204",
  "latitude": 30.123,
  "longitude": 114.321,
  "geofence_radius_meters": 100,
  "qr_validity_minutes": 15
}
```

## Tests Required

1. Create standalone event still works
2. Create class-linked event works
3. Student cannot create event under class
4. Admin cannot create event under a class they do not own/manage
5. QR generation still works for class-linked event
6. Attendance marking still works for class-linked event
7. Class attendance report includes enrolled students if report logic exists

---

# Phase 3 — Flutter Mobile: Student Class Features

## Required Screens

Add or finish the student `Classes` tab.

### Student Classes Screen

Path should follow the existing mobile feature structure.

Suggested feature folder:

```text
mobile/lib/features/classes/
```

The student screen should show:

1. Joined classes
2. Pending invitations
3. Empty state if no classes
4. Pull-to-refresh
5. Error state
6. Loading state

### Pending Invitations

Each invitation card should show:

```text
Class name
Teacher/admin name
Invite date
Accept button
Decline button
```

### Class Details Screen

Show:

```text
Class name
Teacher name
Location
Upcoming events/sessions
Attendance percentage in this class if available
Recent attendance records for this class if available
```

## Integration

Replace the existing placeholder in the student bottom nav where the `Classes` tab currently says the page will be added later.

Do not leave any user-facing “will be added in next batch” placeholders for core class functionality.

---

# Phase 4 — Flutter Mobile: Teacher/Admin Class Features

## Required Screens

Add/finish admin class management.

### Admin Classes Screen

Show:

1. Classes created by current admin/teacher
2. Search/filter if simple
3. Create class button
4. Class cards with student count and upcoming event count if available

### Create Class Screen

Fields:

```text
Class name
Description
Location name
Default latitude
Default longitude
Default geofence radius
```

Optional:

```text
Class code
```

### Class Details Screen

Show:

```text
Class information
Student roster
Pending invitations
Events/sessions linked to the class
Buttons:
- Invite Student
- Create Event for This Class
- View Attendance
```

### Invite Student Screen / Dialog

Allow:

```text
Invite by email
Invite by username
```

Validation:

- At least one identifier required
- Email must be valid if used
- Username should be trimmed and normalized if used
- Show backend errors cleanly

## Integration

Replace the existing admin `Schedule` or add a proper `Classes` area.

Do not leave these placeholder messages for core admin features:

```text
Schedule page will be added in the next batch.
Admin activity/history page will be added in the next batch.
Event editing will be added in the next batch.
```

If there is not enough time to finish every admin tab, remove or hide non-functional tabs instead of showing placeholder snackbars.

---

# Phase 5 — QR and Attendance Flow Verification

## Existing Flow Must Stay Working

Do not break:

```text
Admin creates event
→ QR token/code generated
→ Student scans QR
→ Mobile sends token + location
→ Backend validates
→ Attendance saved/rejected
→ Success/failure screen shown
```

## Security Rules

Attendance must require:

1. Authenticated user
2. Active valid QR token
3. Existing event
4. Valid time window
5. Location inside geofence
6. Duplicate present attendance blocked
7. Server-side validation

The mobile app may collect location, but the backend must decide final validity.

## Tests Required

Add or verify tests for:

1. Invalid token rejected
2. Expired/outside-window token rejected
3. Outside-geofence scan rejected
4. Duplicate present attendance rejected
5. Rejected scan can be retried if the existing backend behavior supports it
6. Authenticated student can mark attendance
7. Unauthenticated user cannot mark attendance
8. Admin-only QR generation enforced

---

# Phase 6 — Reports and Absence Logic

## Problem

With class rosters, reports should be able to show not only who scanned, but who was absent.

## Backend Requirements

If existing reports already exist, extend them carefully.

For a class-linked event report, show:

```text
event_id
class_id
class_name
total_enrolled_students
present_count
absent_count
rejected_count
attendance_rate
students:
  - user_id
  - full_name
  - email
  - student_id
  - attendance_status
  - scanned_at
  - rejection_reason
```

Rules:

- Present means attendance row exists with present status.
- Rejected means attendance row exists with rejected status.
- Absent means active class membership exists but no present/rejected attendance for that event.
- Removed/declined students should not count as active enrolled students.

## Tests Required

1. Class event report includes present students
2. Class event report includes absent students
3. Rejected scans appear as rejected
4. Removed students are excluded
5. CSV/PDF export still works if supported by current backend

---

# Phase 7 — Notifications

## Minimum Required

If full Firebase Cloud Messaging is not complete, do not fake it.

Minimum acceptable MVP:

1. In-app notification record is created for class invitation
2. Student can see pending invitations/notifications
3. Student can mark notification as read
4. Attendance success/failure screen works

## Optional If Time Allows

Add real Firebase Cloud Messaging only if it fits the existing architecture safely.

Do not block the MVP on full FCM push delivery.

If FCM is not implemented, document it as:

```text
Planned future enhancement: real device push notifications through Firebase Cloud Messaging.
```

---

# Phase 8 — Real-Time Dashboard

## Minimum Required

The current polling approach is acceptable for thesis MVP if clearly documented as near real-time.

If the app currently polls every few seconds, label it as:

```text
near real-time updates using periodic polling
```

Do not falsely claim WebSocket/SSE unless implemented.

## Optional If Time Allows

Implement either:

```text
WebSocket
```

or

```text
Server-Sent Events
```

for live attendance updates.

If implemented, add:

1. Backend endpoint
2. Mobile listener
3. reconnect/error handling
4. tests if possible
5. docs update

---

# Phase 9 — UI Cleanup

## Remove Placeholder UX

Search the mobile app for placeholder text like:

```text
will be added in the next batch
will be added in a later batch
coming soon
TODO
```

For core features:

- implement the feature, or
- hide the button/tab, or
- replace with a proper MVP-safe flow.

Do not ship obvious development placeholder messages in the demo.

## Required Mobile UX States

Every new screen must have:

1. Loading state
2. Empty state
3. Error state
4. Success feedback
5. Pull-to-refresh where useful
6. Safe navigation back
7. No crashing on null data

---

# Phase 10 — Documentation Updates

Update these files if they exist:

```text
docs/api-spec.md
docs/database-schema.md
docs/architecture.md
docs/finalization-audit.md
```

Add if useful:

```text
docs/class-management.md
docs/demo-script.md
docs/testing-evidence.md
```

## `docs/demo-script.md`

Create a short thesis demo script:

```text
1. Login as admin
2. Create class
3. Invite student
4. Login as student
5. Accept invitation
6. Admin creates event under class
7. Admin opens QR code
8. Student scans QR code
9. Student sees success
10. Admin sees attendance update
11. Student opens attendance history
12. Admin opens report
```

## `docs/testing-evidence.md`

Include:

```text
Test command used
Test result summary
Manual testing checklist
Known limitations
Screenshots needed for thesis
```

Do not claim tests passed unless they actually passed.

---

# Phase 11 — Final Testing Commands

Before finishing, run relevant commands and record output summaries.

## Backend

Use the repo’s actual commands. Likely examples:

```bash
cd backend
pytest
```

If there are formatting/linting tools, run them.

## Mobile

Use the repo’s actual Flutter commands. Likely examples:

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
```

If mobile tests do not exist, create minimal tests or document that mobile tests are pending.

## Docker / Full App

If docker compose is available and safe:

```bash
docker compose up --build
```

Only do this if the repo is configured and environment variables are available.

---

# Final Deliverable

At the end, produce a final report:

```text
docs/finalization-report.md
```

It must include:

1. What was implemented
2. What files changed
3. What migrations were added
4. What tests were added
5. What tests passed
6. What manual flow was verified
7. What remains unfinished
8. Known limitations
9. Thesis demo steps
10. Any environment variables required

Do not hide unfinished work.

Use this status style:

```text
DONE
PARTIAL
BLOCKED
NOT STARTED
```

---

# Final Quality Gate

The app is not finished until these are true:

```text
[ ] Admin can create class
[ ] Admin can invite student by email
[ ] Admin can invite student by username, if username exists
[ ] Student can accept invitation
[ ] Student can see joined classes
[ ] Admin can see class roster
[ ] Admin can create event under class
[ ] QR is generated for event
[ ] Student can scan QR
[ ] Backend validates attendance
[ ] Attendance is saved
[ ] Duplicate attendance is blocked
[ ] Outside time window is rejected
[ ] Outside geofence is rejected
[ ] Student can view attendance history
[ ] Admin can view attendance result
[ ] Placeholder core tabs are removed or implemented
[ ] API docs updated
[ ] Database docs updated
[ ] Architecture docs updated
[ ] Backend tests pass
[ ] Flutter analyze passes
[ ] Finalization report created
```

---

## Important Known Limitations to Handle Honestly

If not implemented, document these as limitations instead of pretending:

```text
Real Firebase Cloud Messaging push delivery
WebSocket/SSE live dashboard
Production cloud deployment
Advanced map picker
PDF export polish
Mobile integration testing
```

Do not overclaim. A clean honest MVP is better than a fake production system.

---

# Anti-Disaster Safety Instructions

Before large edits:

```bash
git status
git branch
git log --oneline -5
```

Create a branch:

```bash
git checkout -b feature/finalize-qrollcall-mvp
```

Do not run:

```bash
rm -rf
git reset --hard
git clean -fd
```

unless the user explicitly approves.

Do not delete `.env`, database files, Firebase files, migrations, or uploaded assets.

If a command fails, stop and document the error instead of forcing random fixes.

---

# Priority Order

Follow this exact priority order:

1. Audit current repo
2. Class/course backend models + migrations
3. Class invitation backend endpoints
4. Backend tests for class/invitation logic
5. Link events to classes
6. Flutter student classes/invitations UI
7. Flutter admin class management UI
8. Verify QR attendance flow still works
9. Extend reports for class roster absences
10. Remove/hide placeholder UI
11. Update docs
12. Run tests
13. Create finalization report

Do not start visual polish before the core flow works.
