import abc
import base64
import hashlib
import hmac
import json
import time
from dataclasses import dataclass
from typing import Any, Callable

from fastapi import Depends, Header, status

from api.app.core.config import settings
from api.app.core.errors import AppException, ErrorCode


@dataclass
class UserClaims:
    user_id: str
    role: str
    phone: str | None = None
    office_id: str | None = None
    name: str | None = None


def b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def b64url_decode(s: str) -> bytes:
    padding = 4 - (len(s) % 4)
    if padding and padding < 4:
        s += "=" * padding
    return base64.urlsafe_b64decode(s.encode("ascii"))


class AuthProvider(abc.ABC):
    @abc.abstractmethod
    def verify_token(self, token: str) -> UserClaims:
        raise NotImplementedError

    @abc.abstractmethod
    def create_token(self, claims: UserClaims, expires_in_seconds: int = 86400) -> str:
        raise NotImplementedError


class DevAuth(AuthProvider):
    def __init__(self, secret: str | None = None):
        self.secret: str = str(secret or getattr(settings, "JWT_SECRET", "dev-jwt-secret-queueless-123456"))


    def create_token(self, claims: UserClaims, expires_in_seconds: int = 86400) -> str:
        header = {"alg": "HS256", "typ": "JWT"}
        now = int(time.time())
        payload: dict[str, Any] = {
            "sub": claims.user_id,
            "role": claims.role,
            "phone": claims.phone,
            "office_id": claims.office_id,
            "name": claims.name,
            "iat": now,
            "exp": now + expires_in_seconds,
        }

        header_b64 = b64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
        payload_b64 = b64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
        signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
        sig = hmac.new(self.secret.encode("utf-8"), signing_input, hashlib.sha256).digest()
        sig_b64 = b64url_encode(sig)
        return f"{header_b64}.{payload_b64}.{sig_b64}"

    def verify_token(self, token: str) -> UserClaims:
        try:
            parts = token.split(".")
            if len(parts) != 3:
                raise AppException(ErrorCode.UNAUTHORIZED, "Invalid token structure", status.HTTP_401_UNAUTHORIZED)
            header_b64, payload_b64, sig_b64 = parts
            signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
            expected_sig = hmac.new(self.secret.encode("utf-8"), signing_input, hashlib.sha256).digest()
            actual_sig = b64url_decode(sig_b64)
            if not hmac.compare_digest(expected_sig, actual_sig):
                raise AppException(ErrorCode.UNAUTHORIZED, "Invalid token signature", status.HTTP_401_UNAUTHORIZED)

            payload_raw = b64url_decode(payload_b64).decode("utf-8")
            payload = json.loads(payload_raw)

            exp = payload.get("exp")
            if exp and time.time() > exp:
                raise AppException(ErrorCode.UNAUTHORIZED, "Token has expired", status.HTTP_401_UNAUTHORIZED)

            return UserClaims(
                user_id=payload["sub"],
                role=payload.get("role", "CITIZEN"),
                phone=payload.get("phone"),
                office_id=payload.get("office_id"),
                name=payload.get("name"),
            )
        except AppException:
            raise
        except Exception as e:
            raise AppException(ErrorCode.UNAUTHORIZED, f"Token verification failed: {e}", status.HTTP_401_UNAUTHORIZED) from e



_dev_auth_instance = DevAuth()


def get_auth_provider() -> AuthProvider:
    return _dev_auth_instance


def get_current_user(
    authorization: str | None = Header(None),
    auth_provider: AuthProvider = Depends(get_auth_provider),
) -> UserClaims:
    if not authorization:
        raise AppException(ErrorCode.UNAUTHORIZED, "Missing Authorization header", status.HTTP_401_UNAUTHORIZED)
    if not authorization.startswith("Bearer "):
        raise AppException(ErrorCode.UNAUTHORIZED, "Invalid Authorization scheme", status.HTTP_401_UNAUTHORIZED)
    token = authorization[7:].strip()
    return auth_provider.verify_token(token)


def require_role(allowed_roles: list[str]) -> Callable[[UserClaims], UserClaims]:
    def dependency(user: UserClaims = Depends(get_current_user)) -> UserClaims:
        if user.role not in allowed_roles:
            raise AppException(
                ErrorCode.FORBIDDEN,
                f"Role '{user.role}' is not authorized for this resource",
                status.HTTP_403_FORBIDDEN,
            )
        return user

    return dependency


def require_office_access(user: UserClaims, target_office_id: str) -> None:
    """Verifies that the user has permission to act within the specified office."""
    if user.role == "SUPER_ADMIN":
        return
    if user.office_id != target_office_id:
        raise AppException(
            ErrorCode.CROSS_OFFICE_ACCESS_DENIED,
            f"User assigned to office '{user.office_id}' cannot access office '{target_office_id}'",
            status.HTTP_403_FORBIDDEN,
        )
