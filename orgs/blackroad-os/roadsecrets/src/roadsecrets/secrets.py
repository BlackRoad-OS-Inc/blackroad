"""
RoadSecrets - Secrets Management for BlackRoad
Secure storage, rotation, and access control for sensitive data.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import base64
import hashlib
import hmac
import json
import logging
import os
import secrets as stdlib_secrets
import threading
import time

logger = logging.getLogger(__name__)


class SecretType(str, Enum):
    """Types of secrets."""
    API_KEY = "api_key"
    PASSWORD = "password"
    CERTIFICATE = "certificate"
    SSH_KEY = "ssh_key"
    DATABASE_CREDENTIAL = "database_credential"
    OAUTH_TOKEN = "oauth_token"
    ENCRYPTION_KEY = "encryption_key"
    GENERIC = "generic"


class SecretStatus(str, Enum):
    """Secret status."""
    ACTIVE = "active"
    ROTATED = "rotated"
    REVOKED = "revoked"
    EXPIRED = "expired"


@dataclass
class SecretVersion:
    """A version of a secret."""
    version: int
    value: str  # Encrypted
    created_at: datetime
    created_by: str
    status: SecretStatus = SecretStatus.ACTIVE
    expires_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Secret:
    """A secret with versioning."""
    id: str
    name: str
    secret_type: SecretType
    description: str = ""
    versions: Dict[int, SecretVersion] = field(default_factory=dict)
    current_version: int = 0
    rotation_days: Optional[int] = None
    last_accessed: Optional[datetime] = None
    access_count: int = 0
    tags: Set[str] = field(default_factory=set)
    allowed_principals: Set[str] = field(default_factory=set)
    created_at: datetime = field(default_factory=datetime.now)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "type": self.secret_type.value,
            "description": self.description,
            "current_version": self.current_version,
            "rotation_days": self.rotation_days,
            "tags": list(self.tags),
            "created_at": self.created_at.isoformat()
        }


@dataclass
class AccessLog:
    """Log of secret access."""
    secret_id: str
    principal: str
    action: str
    version: int
    timestamp: datetime
    ip_address: Optional[str] = None
    success: bool = True


class Encryptor:
    """Simple encryption for secrets."""

    def __init__(self, master_key: Optional[str] = None):
        self.master_key = master_key or os.environ.get("SECRET_MASTER_KEY", "default-key-change-me")
        self._key = hashlib.sha256(self.master_key.encode()).digest()

    def encrypt(self, plaintext: str) -> str:
        """Encrypt a value."""
        # Simple XOR encryption for demo (use AES in production)
        nonce = stdlib_secrets.token_bytes(16)
        key_stream = self._derive_key_stream(nonce, len(plaintext))
        
        encrypted = bytes(a ^ b for a, b in zip(plaintext.encode(), key_stream))
        return base64.b64encode(nonce + encrypted).decode()

    def decrypt(self, ciphertext: str) -> str:
        """Decrypt a value."""
        data = base64.b64decode(ciphertext)
        nonce = data[:16]
        encrypted = data[16:]
        
        key_stream = self._derive_key_stream(nonce, len(encrypted))
        decrypted = bytes(a ^ b for a, b in zip(encrypted, key_stream))
        return decrypted.decode()

    def _derive_key_stream(self, nonce: bytes, length: int) -> bytes:
        """Derive key stream from nonce."""
        stream = b""
        counter = 0
        while len(stream) < length:
            block = hmac.new(
                self._key,
                nonce + counter.to_bytes(4, 'big'),
                hashlib.sha256
            ).digest()
            stream += block
            counter += 1
        return stream[:length]


class SecretStore:
    """Store for secrets."""

    def __init__(self, encryptor: Encryptor):
        self.encryptor = encryptor
        self.secrets: Dict[str, Secret] = {}
        self.access_logs: List[AccessLog] = []
        self._lock = threading.Lock()

    def create(
        self,
        name: str,
        value: str,
        secret_type: SecretType = SecretType.GENERIC,
        description: str = "",
        rotation_days: Optional[int] = None,
        tags: Set[str] = None,
        created_by: str = "system"
    ) -> Secret:
        """Create a new secret."""
        secret_id = hashlib.md5(f"{name}{datetime.now()}".encode()).hexdigest()[:16]
        
        encrypted_value = self.encryptor.encrypt(value)
        
        version = SecretVersion(
            version=1,
            value=encrypted_value,
            created_at=datetime.now(),
            created_by=created_by
        )
        
        secret = Secret(
            id=secret_id,
            name=name,
            secret_type=secret_type,
            description=description,
            versions={1: version},
            current_version=1,
            rotation_days=rotation_days,
            tags=tags or set()
        )
        
        with self._lock:
            self.secrets[secret_id] = secret
        
        logger.info(f"Created secret: {name}")
        return secret

    def get(self, secret_id: str, principal: str = "system", version: Optional[int] = None) -> Optional[str]:
        """Get a secret value."""
        secret = self.secrets.get(secret_id)
        if not secret:
            return None

        # Check access
        if secret.allowed_principals and principal not in secret.allowed_principals:
            self._log_access(secret_id, principal, "get", 0, success=False)
            logger.warning(f"Access denied to secret {secret_id} for {principal}")
            return None

        ver = version or secret.current_version
        secret_version = secret.versions.get(ver)
        
        if not secret_version:
            return None

        if secret_version.status != SecretStatus.ACTIVE:
            logger.warning(f"Secret version {ver} is not active")

        # Update access tracking
        secret.last_accessed = datetime.now()
        secret.access_count += 1
        
        self._log_access(secret_id, principal, "get", ver)
        
        return self.encryptor.decrypt(secret_version.value)

    def rotate(self, secret_id: str, new_value: str, rotated_by: str = "system") -> Optional[int]:
        """Rotate a secret to a new value."""
        secret = self.secrets.get(secret_id)
        if not secret:
            return None

        # Mark old version as rotated
        old_version = secret.versions.get(secret.current_version)
        if old_version:
            old_version.status = SecretStatus.ROTATED

        # Create new version
        new_version_num = secret.current_version + 1
        encrypted_value = self.encryptor.encrypt(new_value)
        
        new_version = SecretVersion(
            version=new_version_num,
            value=encrypted_value,
            created_at=datetime.now(),
            created_by=rotated_by
        )
        
        with self._lock:
            secret.versions[new_version_num] = new_version
            secret.current_version = new_version_num

        self._log_access(secret_id, rotated_by, "rotate", new_version_num)
        logger.info(f"Rotated secret {secret_id} to version {new_version_num}")
        
        return new_version_num

    def revoke(self, secret_id: str, version: Optional[int] = None) -> bool:
        """Revoke a secret or specific version."""
        secret = self.secrets.get(secret_id)
        if not secret:
            return False

        if version:
            ver = secret.versions.get(version)
            if ver:
                ver.status = SecretStatus.REVOKED
        else:
            for ver in secret.versions.values():
                ver.status = SecretStatus.REVOKED

        logger.info(f"Revoked secret {secret_id}")
        return True

    def delete(self, secret_id: str) -> bool:
        """Delete a secret."""
        with self._lock:
            if secret_id in self.secrets:
                del self.secrets[secret_id]
                return True
        return False

    def list_secrets(self, tags: Optional[Set[str]] = None) -> List[Secret]:
        """List secrets optionally filtered by tags."""
        secrets = list(self.secrets.values())
        
        if tags:
            secrets = [s for s in secrets if tags.intersection(s.tags)]
        
        return secrets

    def _log_access(self, secret_id: str, principal: str, action: str, version: int, success: bool = True):
        """Log access to secret."""
        log = AccessLog(
            secret_id=secret_id,
            principal=principal,
            action=action,
            version=version,
            timestamp=datetime.now(),
            success=success
        )
        self.access_logs.append(log)


class SecretGenerator:
    """Generate secure secrets."""

    @staticmethod
    def password(length: int = 32, special_chars: bool = True) -> str:
        """Generate secure password."""
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        if special_chars:
            chars += "!@#$%^&*()-_=+"
        return ''.join(stdlib_secrets.choice(chars) for _ in range(length))

    @staticmethod
    def api_key(prefix: str = "sk") -> str:
        """Generate API key."""
        return f"{prefix}_{stdlib_secrets.token_hex(32)}"

    @staticmethod
    def token(length: int = 32) -> str:
        """Generate random token."""
        return stdlib_secrets.token_urlsafe(length)

    @staticmethod
    def hex_key(length: int = 32) -> str:
        """Generate hex key."""
        return stdlib_secrets.token_hex(length)


class RotationScheduler:
    """Schedule secret rotation."""

    def __init__(self, store: SecretStore):
        self.store = store
        self.rotation_handlers: Dict[str, Callable[[Secret], str]] = {}
        self._running = False

    def register_handler(self, secret_id: str, handler: Callable[[Secret], str]) -> None:
        """Register rotation handler for secret."""
        self.rotation_handlers[secret_id] = handler

    def check_rotation_needed(self, secret: Secret) -> bool:
        """Check if secret needs rotation."""
        if not secret.rotation_days:
            return False

        current = secret.versions.get(secret.current_version)
        if not current:
            return False

        age = (datetime.now() - current.created_at).days
        return age >= secret.rotation_days

    async def run_rotation_check(self) -> List[str]:
        """Check and rotate secrets needing rotation."""
        rotated = []
        
        for secret in self.store.secrets.values():
            if self.check_rotation_needed(secret):
                handler = self.rotation_handlers.get(secret.id)
                if handler:
                    try:
                        new_value = handler(secret)
                        self.store.rotate(secret.id, new_value, "scheduler")
                        rotated.append(secret.id)
                    except Exception as e:
                        logger.error(f"Rotation failed for {secret.id}: {e}")
                else:
                    logger.warning(f"No rotation handler for {secret.id}")

        return rotated


class SecretsManager:
    """High-level secrets management."""

    def __init__(self, master_key: Optional[str] = None):
        self.encryptor = Encryptor(master_key)
        self.store = SecretStore(self.encryptor)
        self.generator = SecretGenerator()
        self.scheduler = RotationScheduler(self.store)

    def create_secret(
        self,
        name: str,
        value: str,
        secret_type: SecretType = SecretType.GENERIC,
        **kwargs
    ) -> Secret:
        """Create a secret."""
        return self.store.create(name, value, secret_type, **kwargs)

    def get_secret(self, secret_id: str, principal: str = "system") -> Optional[str]:
        """Get secret value."""
        return self.store.get(secret_id, principal)

    def rotate_secret(self, secret_id: str, new_value: str) -> Optional[int]:
        """Rotate a secret."""
        return self.store.rotate(secret_id, new_value)

    def generate_and_store(
        self,
        name: str,
        generator_type: str = "password",
        **kwargs
    ) -> Secret:
        """Generate and store a new secret."""
        if generator_type == "password":
            value = self.generator.password()
            secret_type = SecretType.PASSWORD
        elif generator_type == "api_key":
            value = self.generator.api_key(kwargs.get("prefix", "sk"))
            secret_type = SecretType.API_KEY
        elif generator_type == "token":
            value = self.generator.token()
            secret_type = SecretType.GENERIC
        else:
            value = self.generator.hex_key()
            secret_type = SecretType.ENCRYPTION_KEY

        return self.store.create(name, value, secret_type, **kwargs)

    def list_secrets(self, tags: Optional[Set[str]] = None) -> List[Dict[str, Any]]:
        """List secrets (metadata only)."""
        return [s.to_dict() for s in self.store.list_secrets(tags)]

    def grant_access(self, secret_id: str, principal: str) -> bool:
        """Grant access to a secret."""
        secret = self.store.secrets.get(secret_id)
        if secret:
            secret.allowed_principals.add(principal)
            return True
        return False

    def revoke_access(self, secret_id: str, principal: str) -> bool:
        """Revoke access to a secret."""
        secret = self.store.secrets.get(secret_id)
        if secret:
            secret.allowed_principals.discard(principal)
            return True
        return False

    def get_audit_log(self, secret_id: Optional[str] = None, limit: int = 100) -> List[Dict]:
        """Get audit log."""
        logs = self.store.access_logs
        
        if secret_id:
            logs = [l for l in logs if l.secret_id == secret_id]
        
        return [
            {
                "secret_id": l.secret_id,
                "principal": l.principal,
                "action": l.action,
                "version": l.version,
                "timestamp": l.timestamp.isoformat(),
                "success": l.success
            }
            for l in logs[-limit:]
        ]


# Example usage
def example_usage():
    """Example secrets management usage."""
    manager = SecretsManager(master_key="my-secure-master-key")

    # Create secrets
    db_secret = manager.create_secret(
        name="database-password",
        value="super-secret-password",
        secret_type=SecretType.DATABASE_CREDENTIAL,
        description="Production database password",
        rotation_days=30,
        tags={"production", "database"}
    )

    print(f"Created secret: {db_secret.id}")

    # Generate and store API key
    api_secret = manager.generate_and_store(
        name="api-key-main",
        generator_type="api_key",
        prefix="br"
    )

    print(f"Generated API key secret: {api_secret.id}")

    # Get secret
    password = manager.get_secret(db_secret.id)
    print(f"Retrieved password: {password[:10]}...")

    # Rotate
    new_version = manager.rotate_secret(db_secret.id, "new-super-secret-password")
    print(f"Rotated to version: {new_version}")

    # List secrets
    secrets = manager.list_secrets()
    print(f"Total secrets: {len(secrets)}")

    # Audit log
    audit = manager.get_audit_log(db_secret.id)
    print(f"Audit entries: {len(audit)}")
