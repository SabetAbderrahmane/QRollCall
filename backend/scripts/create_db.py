# backend/scripts/create_db.py
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from app.db.base import create_tables


def main() -> None:
    create_tables()
    print("Database tables created successfully.")


if __name__ == "__main__":
    main()
