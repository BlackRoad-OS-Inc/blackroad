"""
RoadSecret - Secrets Management for BlackRoad
Secure storage and retrieval of secrets and credentials.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional, Union
import base64
import hashlib
import hmac
import json
import os
import logging

logger = logging.getLogger(__name__)


class SecretError(Exception):
    pass


class SecretNotFoundError(SecretError):
    pass


class SecretExpiredError(SecretError):
    pass


@dataclass
class Secret:
    name: str
    value: str
    created_at: datetime = field(default_factory=datetime.now)
    expires_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    version: int = 1

    @property
    def is_expired(self) -> bool:
        if self.expires_at is None:
            return False
        return datetime.now() > self.expires_at

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "value": self.value,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "metadata": self.metadata,
            "version": self.version
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Secret":
        return cls(
            name=data["name"],
            value=data["value"],
            created_at=datetime.fromisoformat(data["created_at"]),
            expires_at=datetime.fromisoformat(data["expires_at"]) if data.get("expires_at") else None,
            metadata=data.get("metadata", {}),
            version=data.get("version", 1)
        )


class Encryptor:
    def __init__(self, key: bytes):
        self.key = key

    def encrypt(self, plaintext: str) -> str:
        data = plaintext.encode()
        nonce = os.urandom(16)
        cipher_key = hashlib.pbkdf2_hmac("sha256", self.key, nonce, 100000)
        encrypted = bytes(a ^ b for a, b in zip(data, (cipher_key * (len(data) // 32 + 1))[:len(data)]))
        result = nonce + encrypted
        return base64.b64encode(result).decode()

    def decrypt(self, ciphertext: str) -> str:
        data = base64.b64decode(ciphertext)
        nonce = data[:16]
        encrypted = data[16:]
        cipher_key = hashlib.pbkdf2_hmac("sha256", self.key, nonce, 100000)
        decrypted = bytes(a ^ b for a, b in zip(encrypted, (cipher_key * (len(encrypted) // 32 + 1))[:len(encrypted)]))
        return decrypted.decode()


class SecretStore:
    def __init__(self, encryption_key: str = None):
        self.secrets: Dict[str, List[Secret]] = {}
        self.encryptor = Encryptor(encryption_key.encode()) if encryption_key else None

    def set(self, name: str, value: str, ttl: int = None, metadata: Dict = None) -> Secret:
        expires_at = None
        if ttl:
            expires_at = datetime.now() + timedelta(seconds=ttl)

        if self.encryptor:
            value = self.encryptor.encrypt(value)

        version = 1
        if name in self.secrets and self.secrets[name]:
            version = self.secrets[name][-1].version + 1

        secret = Secret(
            name=name,
            value=value,
            expires_at=expires_at,
            metadata=metadata or {},
            version=version
        )

        if name not in self.secrets:
            self.secrets[name] = []
        self.secrets[name].append(secret)

        return secret

    def get(self, name: str, version: int = None) -> str:
        if name not in self.secrets or not self.secrets[name]:
            raise SecretNotFoundError(f"Secret '{name}' not found")

        if version:
            for secret in self.secrets[name]:
                if secret.version == version:
                    if secret.is_expired:
                        raise SecretExpiredError(f"Secret '{name}' v{version} has expired")
                    value = secret.value
                    if self.encryptor:
                        value = self.encryptor.decrypt(value)
                    return value
            raise SecretNotFoundError(f"Secret '{name}' v{version} not found")

        secret = self.secrets[name][-1]
        if secret.is_expired:
            raise SecretExpiredError(f"Secret '{name}' has expired")

        value = secret.value
        if self.encryptor:
            value = self.encryptor.decrypt(value)
        return value

    def delete(self, name: str) -> bool:
        if name in self.secrets:
            del self.secrets[name]
            return True
        return False

    def rotate(self, name: str, new_value: str, ttl: int = None) -> Secret:
        if name not in self.secrets:
            raise SecretNotFoundError(f"Secret '{name}' not found")
        
        old_secret = self.secrets[name][-1]
        return self.set(name, new_value, ttl, old_secret.metadata)

    def list(self, include_expired: bool = False) -> List[str]:
        result = []
        for name, versions in self.secrets.items():
            if include_expired or not versions[-1].is_expired:
                result.append(name)
        return result

    def exists(self, name: str) -> bool:
        return name in self.secrets and bool(self.secrets[name])

    def get_metadata(self, name: str) -> Dict[str, Any]:
        if name not in self.secrets or not self.secrets[name]:
            raise SecretNotFoundError(f"Secret '{name}' not found")
        return self.secrets[name][-1].metadata

    def versions(self, name: str) -> List[int]:
        if name not in self.secrets:
            return []
        return [s.version for s in self.secrets[name]]

    def export(self, path: str) -> None:
        data = {}
        for name, versions in self.secrets.items():
            data[name] = [s.to_dict() for s in versions]
        with open(path, "w") as f:
            json.dump(data, f, indent=2)

    def import_from(self, path: str) -> int:
        with open(path, "r") as f:
            data = json.load(f)
        count = 0
        for name, versions in data.items():
            self.secrets[name] = [Secret.from_dict(v) for v in versions]
            count += len(versions)
        return count


class EnvSecretProvider:
    def __init__(self, prefix: str = "SECRET_"):
        self.prefix = prefix

    def get(self, name: str) -> Optional[str]:
        return os.environ.get(f"{self.prefix}{name.upper()}")

    def set(self, name: str, value: str) -> None:
        os.environ[f"{self.prefix}{name.upper()}"] = value

    def list(self) -> List[str]:
        result = []
        for key in os.environ:
            if key.startswith(self.prefix):
                result.append(key[len(self.prefix):].lower())
        return result


def generate_key(length: int = 32) -> str:
    return base64.b64encode(os.urandom(length)).decode()


def hash_secret(value: str, salt: str = None) -> str:
    salt = salt or os.urandom(16).hex()
    hashed = hashlib.pbkdf2_hmac("sha256", value.encode(), salt.encode(), 100000)
    return f"{salt}${base64.b64encode(hashed).decode()}"


def verify_secret(value: str, hashed: str) -> bool:
    salt, stored_hash = hashed.split("$", 1)
    new_hash = hashlib.pbkdf2_hmac("sha256", value.encode(), salt.encode(), 100000)
    return hmac.compare_digest(stored_hash, base64.b64encode(new_hash).decode())


def example_usage():
    store = SecretStore(encryption_key="my-secret-key-12345678901234567890")

    store.set("db_password", "super_secret_123", metadata={"env": "prod"})
    store.set("api_key", "key_abc123", ttl=3600)

    print(f"DB Password: {store.get('db_password')}")
    print(f"API Key: {store.get('api_key')}")

    store.rotate("db_password", "new_password_456")
    print(f"New DB Password: {store.get('db_password')}")
    print(f"Versions: {store.versions('db_password')}")

    print(f"\nAll secrets: {store.list()}")

    hashed = hash_secret("my_password")
    print(f"\nHashed: {hashed}")
    print(f"Verified: {verify_secret('my_password', hashed)}")

