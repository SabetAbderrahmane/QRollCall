from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.core.exceptions import (
    AppException,
    AuthenticationError,
    AuthorizationError,
    ConflictError,
    DatabaseError,
    FirebaseInitializationError,
    NotFoundError,
    ValidationError,
)


def _app_exception_status_code(exc: AppException) -> int:
    if isinstance(exc, AuthenticationError):
        return status.HTTP_401_UNAUTHORIZED
    if isinstance(exc, AuthorizationError):
        return status.HTTP_403_FORBIDDEN
    if isinstance(exc, NotFoundError):
        return status.HTTP_404_NOT_FOUND
    if isinstance(exc, ConflictError):
        return status.HTTP_409_CONFLICT
    if isinstance(exc, ValidationError):
        return status.HTTP_400_BAD_REQUEST
    if isinstance(exc, FirebaseInitializationError):
        return status.HTTP_500_INTERNAL_SERVER_ERROR
    if isinstance(exc, DatabaseError):
        return status.HTTP_500_INTERNAL_SERVER_ERROR
    return status.HTTP_400_BAD_REQUEST


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def handle_app_exception(
        request: Request,
        exc: AppException,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=_app_exception_status_code(exc),
            content={
                "success": False,
                "error": exc.message,
                "path": str(request.url.path),
            },
        )

    @app.exception_handler(SQLAlchemyError)
    async def handle_sqlalchemy_exception(
        request: Request,
        exc: SQLAlchemyError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "success": False,
                "error": "Database operation failed",
                "path": str(request.url.path),
            },
        )