"""
RoadSession - Session Management for BlackRoad
Secure sessions with storage backends and expiration.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import asyncio
import base64
import hashlib
import hmac
import json
import logging
import os
import secrets
import threading
import time

logger = logging.getLogger(__name__)


class SessionState(str, Enum):
    """Session state."""
    ACTIVE = "active"
    EXPIRED = "expired"
    INVALIDATED = "invalidated"


@dataclass
class Session:
    """A user session."""
    id: str
    user_id: Optional[str] = None
    data: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    accessed_at: datetime = field(default_factory=datetime.now)
    expires_at: Optional[datetime] = None
    state: SessionState = SessionState.ACTIVE
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def is_expired(self) -> bool:
        if self.state == SessionState.EXPIRED:
            return True
        if self.expires_at and datetime.now() > self.expires_at:
            return True
        return False

    def get(self, key: str, default: Any = None) -> Any:
        return self.data.get(key, default)

    def set(self, key: str, value: Any) -> None:
        self.data[key] = value
        self.accessed_at = datetime.now()

    def delete(self, key: str) -> bool:
        if key in self.data:
            del self.data[key]
            return True
        return False

    def clear(self) -> None:
        self.data.clear()

    def touch(self) -> None:
        """Update access time."""
        self.accessed_at = datetime.now()

    def invalidate(self) -> None:
        """Invalidate the session."""
        self.state = SessionState.INVALIDATED
        self.data.clear()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "data": self.data,
            "created_at": self.created_at.isoformat(),
            "accessed_at": self.accessed_at.isoformat(),
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "state": self.state.value
        }


class SessionStore:
    """Base session store."""

    async def get(self, session_id: str) -> Optional[Session]:
        raise NotImplementedError

    async def set(self, session: Session) -> None:
        raise NotImplementedError

    async def delete(self, session_id: str) -> bool:
        raise NotImplementedError

    async def cleanup(self) -> int:
        """Clean up expired sessions."""
        raise NotImplementedError


class MemorySessionStore(SessionStore):
    """In-memory session store."""

    def __init__(self):
        self.sessions: Dict[str, Session] = {}
        self._lock = threading.Lock()

    async def get(self, session_id: str) -> Optional[Session]:
        with self._lock:
            session = self.sessions.get(session_id)
            if session and not session.is_expired:
                session.touch()
                return session
            return None

    async def set(self, session: Session) -> None:
        with self._lock:
            self.sessions[session.id] = session

    async def delete(self, session_id: str) -> bool:
        with self._lock:
            if session_id in self.sessions:
                del self.sessions[session_id]
                return True
            return False

    async def cleanup(self) -> int:
        with self._lock:
            expired = [
                sid for sid, s in self.sessions.items()
                if s.is_expired
            ]
            for sid in expired:
                del self.sessions[sid]
            return len(expired)

    async def get_user_sessions(self, user_id: str) -> List[Session]:
        """Get all sessions for a user."""
        with self._lock:
            return [
                s for s in self.sessions.values()
                if s.user_id == user_id and not s.is_expired
            ]


class SessionIDGenerator:
    """Generate secure session IDs."""

    def __init__(self, length: int = 32):
        self.length = length

    def generate(self) -> str:
        """Generate a new session ID."""
        return secrets.token_urlsafe(self.length)


class SessionSigner:
    """Sign and verify session data."""

    def __init__(self, secret_key: str, algorithm: str = "sha256"):
        self.secret_key = secret_key.encode()
        self.algorithm = algorithm

    def sign(self, data: str) -> str:
        """Sign data and return signature."""
        signature = hmac.new(
            self.secret_key,
            data.encode(),
            self.algorithm
        ).hexdigest()
        return f"{data}.{signature}"

    def verify(self, signed_data: str) -> Optional[str]:
        """Verify signed data and return original data."""
        try:
            data, signature = signed_data.rsplit(".", 1)
            expected = hmac.new(
                self.secret_key,
                data.encode(),
                self.algorithm
            ).hexdigest()

            if hmac.compare_digest(signature, expected):
                return data
            return None
        except ValueError:
            return None


class SessionConfig:
    """Session configuration."""

    def __init__(
        self,
        secret_key: str = None,
        session_lifetime: timedelta = timedelta(hours=24),
        cookie_name: str = "session_id",
        cookie_secure: bool = True,
        cookie_httponly: bool = True,
        cookie_samesite: str = "lax",
        renew_threshold: float = 0.5
    ):
        self.secret_key = secret_key or secrets.token_hex(32)
        self.session_lifetime = session_lifetime
        self.cookie_name = cookie_name
        self.cookie_secure = cookie_secure
        self.cookie_httponly = cookie_httponly
        self.cookie_samesite = cookie_samesite
        self.renew_threshold = renew_threshold


class SessionManager:
    """High-level session management."""

    def __init__(
        self,
        store: SessionStore = None,
        config: SessionConfig = None
    ):
        self.store = store or MemorySessionStore()
        self.config = config or SessionConfig()
        self.id_generator = SessionIDGenerator()
        self.signer = SessionSigner(self.config.secret_key)
        self._hooks: Dict[str, List[Callable]] = {}

    async def create(
        self,
        user_id: str = None,
        data: Dict[str, Any] = None,
        ip_address: str = None,
        user_agent: str = None
    ) -> Session:
        """Create a new session."""
        session_id = self.id_generator.generate()
        expires_at = datetime.now() + self.config.session_lifetime

        session = Session(
            id=session_id,
            user_id=user_id,
            data=data or {},
            expires_at=expires_at,
            ip_address=ip_address,
            user_agent=user_agent
        )

        await self.store.set(session)
        await self._emit("create", session)

        return session

    async def get(self, session_id: str) -> Optional[Session]:
        """Get a session by ID."""
        session = await self.store.get(session_id)

        if session and self._should_renew(session):
            await self.renew(session)

        return session

    async def get_signed(self, signed_id: str) -> Optional[Session]:
        """Get session from signed ID."""
        session_id = self.signer.verify(signed_id)
        if session_id:
            return await self.get(session_id)
        return None

    def sign_id(self, session_id: str) -> str:
        """Sign a session ID."""
        return self.signer.sign(session_id)

    async def update(self, session: Session) -> None:
        """Update a session."""
        session.accessed_at = datetime.now()
        await self.store.set(session)
        await self._emit("update", session)

    async def destroy(self, session_id: str) -> bool:
        """Destroy a session."""
        session = await self.store.get(session_id)
        if session:
            session.invalidate()
            await self.store.delete(session_id)
            await self._emit("destroy", session)
            return True
        return False

    async def renew(self, session: Session) -> Session:
        """Renew a session with new expiry."""
        session.expires_at = datetime.now() + self.config.session_lifetime
        session.accessed_at = datetime.now()
        await self.store.set(session)
        await self._emit("renew", session)
        return session

    async def regenerate(self, session: Session) -> Session:
        """Regenerate session with new ID (for security)."""
        old_id = session.id

        # Create new session
        new_session = Session(
            id=self.id_generator.generate(),
            user_id=session.user_id,
            data=session.data.copy(),
            expires_at=datetime.now() + self.config.session_lifetime,
            ip_address=session.ip_address,
            user_agent=session.user_agent
        )

        # Delete old, save new
        await self.store.delete(old_id)
        await self.store.set(new_session)
        await self._emit("regenerate", new_session, old_id)

        return new_session

    def _should_renew(self, session: Session) -> bool:
        """Check if session should be renewed."""
        if not session.expires_at:
            return False

        remaining = (session.expires_at - datetime.now()).total_seconds()
        total = self.config.session_lifetime.total_seconds()

        return remaining < (total * self.config.renew_threshold)

    async def destroy_user_sessions(self, user_id: str) -> int:
        """Destroy all sessions for a user."""
        if isinstance(self.store, MemorySessionStore):
            sessions = await self.store.get_user_sessions(user_id)
            for session in sessions:
                await self.destroy(session.id)
            return len(sessions)
        return 0

    async def cleanup(self) -> int:
        """Clean up expired sessions."""
        return await self.store.cleanup()

    def on(self, event: str, handler: Callable) -> None:
        """Register event handler."""
        if event not in self._hooks:
            self._hooks[event] = []
        self._hooks[event].append(handler)

    async def _emit(self, event: str, *args) -> None:
        """Emit event to handlers."""
        for handler in self._hooks.get(event, []):
            result = handler(*args)
            if asyncio.iscoroutine(result):
                await result

    def get_cookie_config(self) -> Dict[str, Any]:
        """Get cookie configuration."""
        return {
            "name": self.config.cookie_name,
            "secure": self.config.cookie_secure,
            "httponly": self.config.cookie_httponly,
            "samesite": self.config.cookie_samesite,
            "max_age": int(self.config.session_lifetime.total_seconds())
        }


class SessionMiddleware:
    """Session middleware for web frameworks."""

    def __init__(self, manager: SessionManager):
        self.manager = manager

    async def load_session(self, request: Dict[str, Any]) -> Optional[Session]:
        """Load session from request."""
        cookie_name = self.manager.config.cookie_name
        signed_id = request.get("cookies", {}).get(cookie_name)

        if signed_id:
            return await self.manager.get_signed(signed_id)

        return None

    async def create_session(
        self,
        request: Dict[str, Any],
        user_id: str = None,
        data: Dict = None
    ) -> Session:
        """Create session for request."""
        return await self.manager.create(
            user_id=user_id,
            data=data,
            ip_address=request.get("ip_address"),
            user_agent=request.get("user_agent")
        )

    def set_cookie(self, response: Dict[str, Any], session: Session) -> None:
        """Set session cookie on response."""
        signed_id = self.manager.sign_id(session.id)
        config = self.manager.get_cookie_config()

        cookie_value = (
            f"{config['name']}={signed_id}; "
            f"Max-Age={config['max_age']}; "
            f"SameSite={config['samesite']}"
        )

        if config["secure"]:
            cookie_value += "; Secure"
        if config["httponly"]:
            cookie_value += "; HttpOnly"

        response.setdefault("headers", {})["Set-Cookie"] = cookie_value


# Example usage
async def example_usage():
    """Example session usage."""
    config = SessionConfig(
        secret_key="my-secret-key",
        session_lifetime=timedelta(hours=2),
        cookie_name="my_session"
    )

    manager = SessionManager(config=config)

    # Register hooks
    manager.on("create", lambda s: print(f"Session created: {s.id}"))
    manager.on("destroy", lambda s: print(f"Session destroyed: {s.id}"))

    # Create session
    session = await manager.create(
        user_id="user-123",
        data={"role": "admin", "preferences": {"theme": "dark"}},
        ip_address="192.168.1.1",
        user_agent="Mozilla/5.0"
    )

    print(f"Created session: {session.id}")
    print(f"Expires at: {session.expires_at}")

    # Sign the ID for cookie
    signed_id = manager.sign_id(session.id)
    print(f"Signed ID: {signed_id}")

    # Get session
    retrieved = await manager.get(session.id)
    print(f"Retrieved user: {retrieved.user_id}")

    # Update session data
    session.set("last_page", "/dashboard")
    await manager.update(session)

    # Regenerate (for login/logout security)
    new_session = await manager.regenerate(session)
    print(f"Regenerated: {session.id} -> {new_session.id}")

    # Destroy session
    await manager.destroy(new_session.id)

    # Cleanup expired
    cleaned = await manager.cleanup()
    print(f"Cleaned up {cleaned} expired sessions")

    # Middleware example
    middleware = SessionMiddleware(manager)

    # Simulate request
    request = {
        "cookies": {"my_session": signed_id},
        "ip_address": "192.168.1.1",
        "user_agent": "Mozilla/5.0"
    }

    loaded = await middleware.load_session(request)
    print(f"Loaded from middleware: {loaded}")

