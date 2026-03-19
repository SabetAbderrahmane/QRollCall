# backend/app/db/base.py
from app.db.session import engine
from app.models.base import Base


def import_all_models() -> None:
    import app.models.attendance  # noqa: F401
    import app.models.event  # noqa: F401
    import app.models.notification  # noqa: F401
    import app.models.user  # noqa: F401


def create_tables() -> None:
    import_all_models()
    Base.metadata.create_all(bind=engine)
