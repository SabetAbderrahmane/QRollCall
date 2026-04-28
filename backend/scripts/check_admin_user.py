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
    rows = db.execute(
        text("""
            SELECT id, email, full_name, role, is_active, firebase_uid
            FROM users
            WHERE lower(email) = lower(:email)
        """),
        {"email": TARGET_EMAIL},
    ).mappings().all()

    if not rows:
        print("User not found.")
    else:
        for row in rows:
            print(dict(row))
finally:
    db.close()