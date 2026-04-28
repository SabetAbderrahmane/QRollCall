from __future__ import annotations

import sys
from pathlib import Path

CURRENT_FILE = Path(__file__).resolve()
BACKEND_ROOT = CURRENT_FILE.parents[1]

if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import text
from app.db.session import SessionLocal

TARGET_EMAIL = "admin@gmail.com"

db = SessionLocal()

try:
    before = db.execute(
        text("""
            SELECT id, email, full_name, role, is_active
            FROM users
            WHERE lower(email) = lower(:email)
            LIMIT 1
        """),
        {"email": TARGET_EMAIL},
    ).mappings().first()

    if before is None:
        print(f"User not found: {TARGET_EMAIL}")
        raise SystemExit(1)

    print("Before:")
    print(dict(before))

    db.execute(
        text("""
            UPDATE users
            SET role = 'ADMIN'
            WHERE lower(email) = lower(:email)
        """),
        {"email": TARGET_EMAIL},
    )
    db.commit()

    after = db.execute(
        text("""
            SELECT id, email, full_name, role, is_active
            FROM users
            WHERE lower(email) = lower(:email)
            LIMIT 1
        """),
        {"email": TARGET_EMAIL},
    ).mappings().first()

    print("After:")
    print(dict(after))

except Exception:
    db.rollback()
    raise
finally:
    db.close()