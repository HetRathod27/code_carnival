from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class ErrorCode:
    UNAUTHORIZED = "UNAUTHORIZED"
    FORBIDDEN = "FORBIDDEN"
    NOT_FOUND = "NOT_FOUND"
    VALIDATION_ERROR = "VALIDATION_ERROR"
    ACTIVE_TOKEN_EXISTS = "ACTIVE_TOKEN_EXISTS"
    QUEUE_FULL_FOR_TODAY = "QUEUE_FULL_FOR_TODAY"
    OFFICE_CLOSED = "OFFICE_CLOSED"
    SERVICE_INACTIVE = "SERVICE_INACTIVE"
    PRIORITY_BLOCKED_STRIKES = "PRIORITY_BLOCKED_STRIKES"
    COUNTER_BUSY = "COUNTER_BUSY"
    COUNTER_CLOSED = "COUNTER_CLOSED"
    CANNOT_CLOSE_BUSY_COUNTER = "CANNOT_CLOSE_BUSY_COUNTER"
    INVALID_TRANSITION = "INVALID_TRANSITION"
    CROSS_OFFICE_ACCESS_DENIED = "CROSS_OFFICE_ACCESS_DENIED"
    INVALID_CHECKIN_QR = "INVALID_CHECKIN_QR"
    CONCURRENCY_ERROR = "CONCURRENCY_ERROR"
    INTERNAL_ERROR = "INTERNAL_ERROR"


class AppException(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        details: dict[str, Any] | None = None,
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)


def format_error_response(code: str, message: str, details: dict[str, Any] | None = None) -> dict[str, Any]:
    return {
        "error": {
            "code": code,
            "message": message,
            "details": details or {},
        }
    }


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=format_error_response(exc.code, exc.message, exc.details),
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        code_map = {
            401: ErrorCode.UNAUTHORIZED,
            403: ErrorCode.FORBIDDEN,
            404: ErrorCode.NOT_FOUND,
            409: "CONFLICT",
        }
        code = code_map.get(exc.status_code, "HTTP_ERROR")
        message = str(exc.detail) if exc.detail else "An HTTP error occurred"
        return JSONResponse(
            status_code=exc.status_code,
            content=format_error_response(code, message),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
        errors = exc.errors()
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=format_error_response(
                code=ErrorCode.VALIDATION_ERROR,
                message="Request validation failed",
                details={"errors": errors},
            ),
        )

    # Register handlers for domain and service errors
    from api.app.domain.state_machine import InvalidTransitionError
    from api.app.services.officer_service import OfficerOperationError
    from api.app.services.token_service import BookingError

    @app.exception_handler(BookingError)
    async def booking_error_handler(request: Request, exc: BookingError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=format_error_response(exc.code, exc.message),
        )

    @app.exception_handler(OfficerOperationError)
    async def officer_op_error_handler(request: Request, exc: OfficerOperationError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=format_error_response(exc.code, exc.message),
        )

    @app.exception_handler(InvalidTransitionError)
    async def invalid_transition_handler(request: Request, exc: InvalidTransitionError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content=format_error_response(
                code=ErrorCode.INVALID_TRANSITION,
                message=str(exc),
                details={"from_state": exc.from_state, "to_state": exc.to_state, "actor_type": exc.actor_type},
            ),
        )

