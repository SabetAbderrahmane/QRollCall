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

db = SessionLocal()

try:
    user = db.execute(
        text("""
            SELECT id, email, full_name, role, is_active
            FROM users
            WHERE lower(email) = lower(:email)
            ORDER BY id
        """),
        {"email": TARGET_EMAIL},
    ).mappings().all()

    print("=== USERS ===")
    for row in user:
        print(dict(row))

    rows = db.execute(
        text("""
            SELECT
              a.id,
              a.user_id,
              a.event_id,
              a.status,
              a.scanned_at,
              e.name AS event_name
            FROM attendances a
            JOIN events e ON e.id = a.event_id
            JOIN users u ON u.id = a.user_id
            WHERE lower(u.email) = lower(:email)
            ORDER BY a.scanned_at DESC
        """),
        {"email": TARGET_EMAIL},
    ).mappings().all()

    print("\n=== ATTENDANCE ROWS ===")
    print(f"count = {len(rows)}")
    for row in rows:
        print(dict(row))

except Exception as exc:
    print(exc)
    raise
finally:
    db.close()