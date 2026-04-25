from __future__ import annotations

import sys
from pathlib import Path

CURRENT_FILE = Path(__file__).resolve()
BACKEND_ROOT = CURRENT_FILE.parents[1]

if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import text

from app.db.session import SessionLocal

TARGET_EMAIL = "sabetabderrahmane2@gmail.com"


DELETE_SQL = """
WITH target_user AS (
    SELECT id
    FROM users
    WHERE lower(email) = lower(:email)
    LIMIT 1
),
deleted_attendances AS (
    DELETE FROM attendances
    WHERE user_id = (SELECT id FROM target_user)
      AND event_id IN (
          SELECT id
          FROM events
          WHERE qr_code_token LIKE 'seed-sabet-%'
      )
    RETURNING id
)
DELETE FROM events
WHERE qr_code_token LIKE 'seed-sabet-%'
  AND created_by_user_id = (SELECT id FROM target_user);
"""


INSERT_EVENTS_SQL = """
WITH target_user AS (
    SELECT id
    FROM users
    WHERE lower(email) = lower(:email)
    LIMIT 1
)
INSERT INTO events (
    name,
    description,
    start_time,
    end_time,
    location_name,
    latitude,
    longitude,
    geofence_radius_meters,
    qr_code_token,
    qr_code_image_path,
    qr_validity_minutes,
    is_active,
    created_by_user_id
)
SELECT
    x.name,
    x.description,
    x.start_time,
    x.end_time,
    x.location_name,
    x.latitude,
    x.longitude,
    x.geofence_radius_meters,
    x.qr_code_token,
    NULL,
    x.qr_validity_minutes,
    x.is_active,
    tu.id
FROM target_user tu
CROSS JOIN (
    VALUES
      (
        'Software Engineering Lecture',
        'Weekly lecture on requirements, design, and software architecture.',
        now() - interval '40 days',
        now() - interval '40 days' + interval '2 hours',
        'Room B201',
        36.752887,
        3.042048,
        100,
        'seed-sabet-001',
        30,
        false
      ),
      (
        'Data Structures Lab',
        'Hands-on linked lists, stacks, queues, and trees.',
        now() - interval '33 days',
        now() - interval '33 days' + interval '2 hours',
        'Lab 3',
        36.753210,
        3.041510,
        100,
        'seed-sabet-002',
        30,
        false
      ),
      (
        'Database Systems',
        'ER modeling, normalization, and SQL design session.',
        now() - interval '28 days',
        now() - interval '28 days' + interval '90 minutes',
        'Room C105',
        36.752420,
        3.043000,
        100,
        'seed-sabet-003',
        30,
        false
      ),
      (
        'Operating Systems',
        'Processes, scheduling, synchronization, and memory management.',
        now() - interval '22 days',
        now() - interval '22 days' + interval '2 hours',
        'Room A110',
        36.751900,
        3.041900,
        100,
        'seed-sabet-004',
        30,
        false
      ),
      (
        'Artificial Intelligence',
        'Intro to search, heuristics, and knowledge representation.',
        now() - interval '17 days',
        now() - interval '17 days' + interval '2 hours',
        'Room D204',
        36.753700,
        3.042600,
        100,
        'seed-sabet-005',
        30,
        false
      ),
      (
        'Computer Networks',
        'OSI model, IP addressing, routing, and switching.',
        now() - interval '12 days',
        now() - interval '12 days' + interval '90 minutes',
        'Room B107',
        36.752100,
        3.043400,
        100,
        'seed-sabet-006',
        30,
        false
      ),
      (
        'Mobile Development',
        'Flutter UI, navigation, and state management workshop.',
        now() - interval '6 days',
        now() - interval '6 days' + interval '2 hours',
        'Innovation Lab',
        36.752600,
        3.042900,
        100,
        'seed-sabet-007',
        30,
        false
      ),
      (
        'Machine Learning Basics',
        'Classification, training loops, and model evaluation.',
        now() - interval '2 days',
        now() - interval '2 days' + interval '2 hours',
        'Room E302',
        36.753050,
        3.041780,
        100,
        'seed-sabet-008',
        30,
        false
      ),
      (
        'Cloud Computing Seminar',
        'Containers, deployment, and distributed systems overview.',
        now() + interval '3 days',
        now() + interval '3 days' + interval '90 minutes',
        'Seminar Hall 2',
        36.752980,
        3.042420,
        100,
        'seed-sabet-009',
        30,
        true
      )
) AS x(
    name,
    description,
    start_time,
    end_time,
    location_name,
    latitude,
    longitude,
    geofence_radius_meters,
    qr_code_token,
    qr_validity_minutes,
    is_active
);
"""


INSERT_ATTENDANCES_SQL = """
WITH target_user AS (
    SELECT id
    FROM users
    WHERE lower(email) = lower(:email)
    LIMIT 1
),
seed_events AS (
    SELECT id, qr_code_token, start_time, latitude, longitude
    FROM events
    WHERE qr_code_token LIKE 'seed-sabet-%'
      AND created_by_user_id = (SELECT id FROM target_user)
)
INSERT INTO attendances (
    event_id,
    user_id,
    scanned_at,
    status,
    scan_latitude,
    scan_longitude,
    device_id,
    rejection_reason
)
SELECT
    e.id,
    tu.id,
    CASE
        WHEN s.status = 'PRESENT' THEN e.start_time + interval '6 minutes'
        WHEN s.status = 'REJECTED' THEN e.start_time + interval '19 minutes'
        ELSE e.start_time + interval '45 minutes'
    END,
    s.status::attendance_status,
    CASE
        WHEN s.status = 'PRESENT' THEN e.latitude + 0.000020
        WHEN s.status = 'REJECTED' THEN e.latitude + 0.004500
        ELSE NULL
    END,
    CASE
        WHEN s.status = 'PRESENT' THEN e.longitude + 0.000020
        WHEN s.status = 'REJECTED' THEN e.longitude + 0.004500
        ELSE NULL
    END,
    'seed-device-sabet',
    s.rejection_reason
FROM target_user tu
JOIN seed_events e ON TRUE
JOIN (
    VALUES
      ('seed-sabet-001', 'PRESENT',  NULL),
      ('seed-sabet-002', 'PRESENT',  NULL),
      ('seed-sabet-003', 'ABSENT',   NULL),
      ('seed-sabet-004', 'PRESENT',  NULL),
      ('seed-sabet-005', 'REJECTED', 'Outside allowed geofence'),
      ('seed-sabet-006', 'PRESENT',  NULL),
      ('seed-sabet-007', 'PRESENT',  NULL),
      ('seed-sabet-008', 'ABSENT',   NULL)
) AS s(qr_code_token, status, rejection_reason)
    ON s.qr_code_token = e.qr_code_token;
"""


VERIFY_SQL = """
SELECT
    a.id,
    a.user_id,
    e.name AS event_name,
    a.status,
    a.scanned_at,
    a.rejection_reason
FROM attendances a
JOIN events e ON e.id = a.event_id
JOIN users u ON u.id = a.user_id
WHERE lower(u.email) = lower(:email)
ORDER BY a.scanned_at DESC;
"""


def main() -> None:
    db = SessionLocal()

    try:
        user = db.execute(
            text(
                """
                SELECT id, email, full_name, role, is_active
                FROM users
                WHERE lower(email) = lower(:email)
                LIMIT 1
                """
            ),
            {"email": TARGET_EMAIL},
        ).mappings().first()

        if user is None:
            print(f"User not found: {TARGET_EMAIL}")
            return

        print("Target user:")
        print(dict(user))
        print("-" * 80)

        db.execute(text(DELETE_SQL), {"email": TARGET_EMAIL})
        db.execute(text(INSERT_EVENTS_SQL), {"email": TARGET_EMAIL})
        db.execute(text(INSERT_ATTENDANCES_SQL), {"email": TARGET_EMAIL})
        db.commit()

        rows = db.execute(text(VERIFY_SQL), {"email": TARGET_EMAIL}).mappings().all()

        print(f"Seed complete for {TARGET_EMAIL}")
        print(f"Attendance rows inserted: {len(rows)}")
        print("-" * 80)

        for row in rows:
            print(
                f"{row['id']:>3} | "
                f"{row['event_name']:<30} | "
                f"{row['status']:<8} | "
                f"{row['scanned_at']} | "
                f"{row['rejection_reason'] or ''}"
            )

    except Exception as exc:
        db.rollback()
        print("Seeding failed.")
        print(exc)
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()