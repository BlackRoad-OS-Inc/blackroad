"""
RoadSessions - Session Management System for BlackRoad
Secure session handling with multiple backends and device tracking.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import asyncio
import hashlib
import hmac
import json
import logging
import os
import secrets
import threading
import time

logger = logging.getLogger(__name__)


class SessionBackend(str, Enum):
    """Session storage backends."""
    MEMORY = "memory"
    REDIS = "redis"
    DATABASE = "database"
    COOKIE = "cookie"


class SessionStatus(str, Enum):
    """Session status."""
    ACTIVE = "active"
    EXPIRED = "expired"
    REVOKED = "revoked"
    LOCKED = "locked"


@dataclass
class DeviceInfo:
    """Device information for session."""
    device_id: str
    device_type: str  # desktop, mobile, tablet
    browser: Optional[str] = None
    os: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    location: Optional[Dict[str, Any]] = None
    first_seen: datetime = field(default_factory=datetime.now)
    last_seen: datetime = field(default_factory=datetime.now)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "device_id": self.device_id,
            "device_type": self.device_type,
            "browser": self.browser,
            "os": self.os,
            "ip_address": self.ip_address,
            "user_agent": self.user_agent,
            "location": self.location,
            "first_seen": self.first_seen.isoformat(),
            "last_seen": self.last_seen.isoformat()
        }


@dataclass
class Session:
    """A user session."""
    session_id: str
    user_id: str
    created_at: datetime
    expires_at: datetime
    last_activity: datetime
    status: SessionStatus = SessionStatus.ACTIVE
    device: Optional[DeviceInfo] = None
    data: Dict[str, Any] = field(default_factory=dict)
    refresh_token: Optional[str] = None
    parent_session_id: Optional[str] = None  # For refresh chains
    metadata: Dict[str, Any] = field(default_factory=dict)

    def is_expired(self) -> bool:
        return datetime.now() > self.expires_at

    def is_active(self) -> bool:
        return self.status == SessionStatus.ACTIVE and not self.is_expired()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "session_id": self.session_id,
            "user_id": self.user_id,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat(),
            "last_activity": self.last_activity.isoformat(),
            "status": self.status.value,
            "device": self.device.to_dict() if self.device else None,
            "data": self.data,
            "metadata": self.metadata
        }


class SessionIDGenerator:
    """Generate secure session IDs."""

    def __init__(self, secret_key: Optional[str] = None):
        self.secret_key = secret_key or os.environ.get("SESSION_SECRET", secrets.token_hex(32))

    def generate(self) -> str:
        """Generate a new session ID."""
        random_bytes = secrets.token_bytes(32)
        timestamp = str(time.time()).encode()
        signature = hmac.new(
            self.secret_key.encode(),
            random_bytes + timestamp,
            hashlib.sha256
        ).hexdigest()
        return f"{secrets.token_urlsafe(32)}.{signature[:16]}"

    def validate(self, session_id: str) -> bool:
        """Validate session ID format."""
        if not session_id or "." not in session_id:
            return False
        parts = session_id.split(".")
        return len(parts) == 2 and len(parts[0]) > 20


class SessionStore:
    """In-memory session storage."""

    def __init__(self, max_sessions_per_user: int = 10):
        self.sessions: Dict[str, Session] = {}
        self.user_sessions: Dict[str, Set[str]] = {}  # user_id -> session_ids
        self.refresh_tokens: Dict[str, str] = {}  # refresh_token -> session_id
        self.max_sessions_per_user = max_sessions_per_user
        self._lock = threading.RLock()

    def save(self, session: Session) -> None:
        """Save a session."""
        with self._lock:
            self.sessions[session.session_id] = session

            if session.user_id not in self.user_sessions:
                self.user_sessions[session.user_id] = set()
            self.user_sessions[session.user_id].add(session.session_id)

            if session.refresh_token:
                self.refresh_tokens[session.refresh_token] = session.session_id

            # Enforce max sessions per user
            self._enforce_session_limit(session.user_id)

    def _enforce_session_limit(self, user_id: str) -> None:
        """Remove oldest sessions if limit exceeded."""
        session_ids = self.user_sessions.get(user_id, set())
        if len(session_ids) > self.max_sessions_per_user:
            sessions = [self.sessions[sid] for sid in session_ids if sid in self.sessions]
            sessions.sort(key=lambda s: s.last_activity)

            to_remove = len(sessions) - self.max_sessions_per_user
            for session in sessions[:to_remove]:
                self.delete(session.session_id)

    def get(self, session_id: str) -> Optional[Session]:
        """Get session by ID."""
        return self.sessions.get(session_id)

    def get_by_refresh_token(self, refresh_token: str) -> Optional[Session]:
        """Get session by refresh token."""
        session_id = self.refresh_tokens.get(refresh_token)
        if session_id:
            return self.sessions.get(session_id)
        return None

    def get_user_sessions(self, user_id: str) -> List[Session]:
        """Get all sessions for a user."""
        session_ids = self.user_sessions.get(user_id, set())
        return [self.sessions[sid] for sid in session_ids if sid in self.sessions]

    def delete(self, session_id: str) -> bool:
        """Delete a session."""
        with self._lock:
            session = self.sessions.pop(session_id, None)
            if session:
                self.user_sessions.get(session.user_id, set()).discard(session_id)
                if session.refresh_token:
                    self.refresh_tokens.pop(session.refresh_token, None)
                return True
            return False

    def delete_user_sessions(self, user_id: str) -> int:
        """Delete all sessions for a user."""
        with self._lock:
            session_ids = self.user_sessions.pop(user_id, set())
            count = 0
            for session_id in session_ids:
                session = self.sessions.pop(session_id, None)
                if session:
                    if session.refresh_token:
                        self.refresh_tokens.pop(session.refresh_token, None)
                    count += 1
            return count

    def cleanup_expired(self) -> int:
        """Remove expired sessions."""
        with self._lock:
            expired = [sid for sid, s in self.sessions.items() if s.is_expired()]
            for session_id in expired:
                self.delete(session_id)
            return len(expired)


class SessionManager:
    """High-level session management."""

    def __init__(
        self,
        store: Optional[SessionStore] = None,
        session_ttl: int = 3600,  # 1 hour
        refresh_ttl: int = 86400 * 7,  # 7 days
        idle_timeout: int = 1800,  # 30 minutes
        enable_refresh: bool = True,
        single_session: bool = False
    ):
        self.store = store or SessionStore()
        self.id_generator = SessionIDGenerator()
        self.session_ttl = session_ttl
        self.refresh_ttl = refresh_ttl
        self.idle_timeout = idle_timeout
        self.enable_refresh = enable_refresh
        self.single_session = single_session
        self._hooks: Dict[str, List[Callable]] = {
            "created": [],
            "refreshed": [],
            "destroyed": [],
            "expired": []
        }

    def add_hook(self, event: str, hook: Callable[[Session], None]) -> None:
        """Add session lifecycle hook."""
        if event in self._hooks:
            self._hooks[event].append(hook)

    def _trigger_hooks(self, event: str, session: Session) -> None:
        """Trigger lifecycle hooks."""
        for hook in self._hooks.get(event, []):
            try:
                hook(session)
            except Exception as e:
                logger.error(f"Session hook error: {e}")

    def create(
        self,
        user_id: str,
        device: Optional[DeviceInfo] = None,
        data: Optional[Dict[str, Any]] = None,
        ttl: Optional[int] = None
    ) -> Session:
        """Create a new session."""
        # Revoke existing sessions if single session mode
        if self.single_session:
            self.revoke_all(user_id)

        now = datetime.now()
        session_ttl = ttl or self.session_ttl

        session = Session(
            session_id=self.id_generator.generate(),
            user_id=user_id,
            created_at=now,
            expires_at=now + timedelta(seconds=session_ttl),
            last_activity=now,
            device=device,
            data=data or {},
            refresh_token=secrets.token_urlsafe(32) if self.enable_refresh else None
        )

        self.store.save(session)
        self._trigger_hooks("created", session)

        logger.info(f"Session created for user {user_id}")
        return session

    def get(self, session_id: str) -> Optional[Session]:
        """Get and validate a session."""
        session = self.store.get(session_id)

        if not session:
            return None

        if session.is_expired():
            session.status = SessionStatus.EXPIRED
            self._trigger_hooks("expired", session)
            self.store.delete(session_id)
            return None

        if session.status != SessionStatus.ACTIVE:
            return None

        # Check idle timeout
        idle_time = (datetime.now() - session.last_activity).total_seconds()
        if idle_time > self.idle_timeout:
            session.status = SessionStatus.EXPIRED
            self._trigger_hooks("expired", session)
            self.store.delete(session_id)
            return None

        return session

    def touch(self, session_id: str) -> bool:
        """Update session last activity."""
        session = self.get(session_id)
        if session:
            session.last_activity = datetime.now()
            self.store.save(session)
            return True
        return False

    def refresh(self, refresh_token: str) -> Optional[Session]:
        """Refresh a session using refresh token."""
        old_session = self.store.get_by_refresh_token(refresh_token)

        if not old_session:
            return None

        if old_session.status == SessionStatus.REVOKED:
            return None

        # Create new session
        new_session = self.create(
            user_id=old_session.user_id,
            device=old_session.device,
            data=old_session.data.copy()
        )
        new_session.parent_session_id = old_session.session_id

        # Revoke old session
        old_session.status = SessionStatus.REVOKED
        self.store.save(old_session)

        self._trigger_hooks("refreshed", new_session)
        return new_session

    def revoke(self, session_id: str) -> bool:
        """Revoke a session."""
        session = self.store.get(session_id)
        if session:
            session.status = SessionStatus.REVOKED
            self.store.save(session)
            self._trigger_hooks("destroyed", session)
            self.store.delete(session_id)
            return True
        return False

    def revoke_all(self, user_id: str) -> int:
        """Revoke all sessions for a user."""
        sessions = self.store.get_user_sessions(user_id)
        for session in sessions:
            session.status = SessionStatus.REVOKED
            self._trigger_hooks("destroyed", session)
        return self.store.delete_user_sessions(user_id)

    def revoke_device(self, user_id: str, device_id: str) -> int:
        """Revoke all sessions for a specific device."""
        sessions = self.store.get_user_sessions(user_id)
        count = 0
        for session in sessions:
            if session.device and session.device.device_id == device_id:
                self.revoke(session.session_id)
                count += 1
        return count

    def get_active_sessions(self, user_id: str) -> List[Session]:
        """Get all active sessions for a user."""
        sessions = self.store.get_user_sessions(user_id)
        return [s for s in sessions if s.is_active()]

    def get_session_data(self, session_id: str, key: str, default: Any = None) -> Any:
        """Get session data value."""
        session = self.get(session_id)
        if session:
            return session.data.get(key, default)
        return default

    def set_session_data(self, session_id: str, key: str, value: Any) -> bool:
        """Set session data value."""
        session = self.get(session_id)
        if session:
            session.data[key] = value
            self.store.save(session)
            return True
        return False

    def extend(self, session_id: str, additional_seconds: int) -> bool:
        """Extend session expiration."""
        session = self.get(session_id)
        if session:
            session.expires_at += timedelta(seconds=additional_seconds)
            self.store.save(session)
            return True
        return False

    def lock(self, session_id: str) -> bool:
        """Lock a session (require re-auth)."""
        session = self.store.get(session_id)
        if session:
            session.status = SessionStatus.LOCKED
            self.store.save(session)
            return True
        return False

    def unlock(self, session_id: str) -> bool:
        """Unlock a locked session."""
        session = self.store.get(session_id)
        if session and session.status == SessionStatus.LOCKED:
            session.status = SessionStatus.ACTIVE
            session.last_activity = datetime.now()
            self.store.save(session)
            return True
        return False

    def cleanup(self) -> int:
        """Cleanup expired sessions."""
        return self.store.cleanup_expired()

    def get_stats(self) -> Dict[str, Any]:
        """Get session statistics."""
        all_sessions = list(self.store.sessions.values())
        active = sum(1 for s in all_sessions if s.is_active())
        expired = sum(1 for s in all_sessions if s.is_expired())

        return {
            "total_sessions": len(all_sessions),
            "active_sessions": active,
            "expired_sessions": expired,
            "unique_users": len(self.store.user_sessions),
            "sessions_per_user": len(all_sessions) / max(len(self.store.user_sessions), 1)
        }


class SessionMiddleware:
    """Middleware for session handling in web frameworks."""

    def __init__(
        self,
        manager: SessionManager,
        cookie_name: str = "session_id",
        cookie_secure: bool = True,
        cookie_httponly: bool = True,
        cookie_samesite: str = "lax"
    ):
        self.manager = manager
        self.cookie_name = cookie_name
        self.cookie_secure = cookie_secure
        self.cookie_httponly = cookie_httponly
        self.cookie_samesite = cookie_samesite

    def get_session_id(self, request: Any) -> Optional[str]:
        """Extract session ID from request."""
        # Check cookie
        if hasattr(request, "cookies"):
            session_id = request.cookies.get(self.cookie_name)
            if session_id:
                return session_id

        # Check Authorization header
        if hasattr(request, "headers"):
            auth = request.headers.get("Authorization", "")
            if auth.startswith("Session "):
                return auth[8:]

        return None

    def get_cookie_options(self, session: Session) -> Dict[str, Any]:
        """Get cookie options for response."""
        return {
            "key": self.cookie_name,
            "value": session.session_id,
            "httponly": self.cookie_httponly,
            "secure": self.cookie_secure,
            "samesite": self.cookie_samesite,
            "max_age": int((session.expires_at - datetime.now()).total_seconds())
        }


class ConcurrentSessionLimiter:
    """Limit concurrent sessions per user."""

    def __init__(self, manager: SessionManager, max_concurrent: int = 5):
        self.manager = manager
        self.max_concurrent = max_concurrent

    def check_limit(self, user_id: str) -> bool:
        """Check if user can create new session."""
        active = self.manager.get_active_sessions(user_id)
        return len(active) < self.max_concurrent

    def enforce_limit(self, user_id: str) -> int:
        """Enforce limit by revoking oldest sessions."""
        active = self.manager.get_active_sessions(user_id)
        if len(active) <= self.max_concurrent:
            return 0

        # Sort by last activity, revoke oldest
        active.sort(key=lambda s: s.last_activity)
        to_revoke = len(active) - self.max_concurrent

        for session in active[:to_revoke]:
            self.manager.revoke(session.session_id)

        return to_revoke


# Example usage
def example_usage():
    """Example session management usage."""
    manager = SessionManager(
        session_ttl=3600,
        idle_timeout=1800,
        enable_refresh=True
    )

    # Add hook
    manager.add_hook("created", lambda s: print(f"Session created: {s.session_id}"))

    # Create session
    device = DeviceInfo(
        device_id="device-123",
        device_type="desktop",
        browser="Chrome",
        ip_address="192.168.1.1"
    )

    session = manager.create(
        user_id="user-456",
        device=device,
        data={"role": "admin"}
    )

    print(f"Session ID: {session.session_id}")
    print(f"Refresh Token: {session.refresh_token}")

    # Validate session
    valid = manager.get(session.session_id)
    print(f"Session valid: {valid is not None}")

    # Get session data
    role = manager.get_session_data(session.session_id, "role")
    print(f"User role: {role}")

    # Refresh session
    if session.refresh_token:
        new_session = manager.refresh(session.refresh_token)
        print(f"New session: {new_session.session_id}")

    # Get stats
    print(f"Stats: {manager.get_stats()}")
