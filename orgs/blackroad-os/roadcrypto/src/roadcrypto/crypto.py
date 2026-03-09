"""
RoadCrypto - Cryptography Utilities for BlackRoad
Encryption, hashing, signing, and key management.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple, Union
import base64
import hashlib
import hmac
import json
import logging
import os
import secrets
import struct
import threading
import uuid

logger = logging.getLogger(__name__)


class Algorithm(str, Enum):
    """Cryptographic algorithms."""
    AES_256_GCM = "aes-256-gcm"
    AES_256_CBC = "aes-256-cbc"
    CHACHA20_POLY1305 = "chacha20-poly1305"


class HashAlgorithm(str, Enum):
    """Hash algorithms."""
    SHA256 = "sha256"
    SHA384 = "sha384"
    SHA512 = "sha512"
    BLAKE2B = "blake2b"
    BLAKE2S = "blake2s"


class KeyType(str, Enum):
    """Key types."""
    SYMMETRIC = "symmetric"
    PUBLIC = "public"
    PRIVATE = "private"


@dataclass
class CryptoKey:
    """A cryptographic key."""
    id: str
    key_type: KeyType
    algorithm: str
    key_data: bytes
    created_at: datetime = field(default_factory=datetime.now)
    expires_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def is_expired(self) -> bool:
        if self.expires_at:
            return datetime.now() > self.expires_at
        return False

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "type": self.key_type.value,
            "algorithm": self.algorithm,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "expired": self.is_expired
        }


@dataclass
class EncryptedData:
    """Encrypted data container."""
    ciphertext: bytes
    nonce: bytes
    tag: Optional[bytes] = None
    algorithm: str = "aes-256-gcm"
    key_id: Optional[str] = None

    def to_bytes(self) -> bytes:
        """Serialize to bytes."""
        data = {
            "ciphertext": base64.b64encode(self.ciphertext).decode(),
            "nonce": base64.b64encode(self.nonce).decode(),
            "tag": base64.b64encode(self.tag).decode() if self.tag else None,
            "algorithm": self.algorithm,
            "key_id": self.key_id
        }
        return json.dumps(data).encode()

    @classmethod
    def from_bytes(cls, data: bytes) -> "EncryptedData":
        """Deserialize from bytes."""
        obj = json.loads(data)
        return cls(
            ciphertext=base64.b64decode(obj["ciphertext"]),
            nonce=base64.b64decode(obj["nonce"]),
            tag=base64.b64decode(obj["tag"]) if obj.get("tag") else None,
            algorithm=obj.get("algorithm", "aes-256-gcm"),
            key_id=obj.get("key_id")
        )


@dataclass
class Signature:
    """Digital signature."""
    signature: bytes
    algorithm: str
    key_id: str
    timestamp: datetime = field(default_factory=datetime.now)

    def to_bytes(self) -> bytes:
        return json.dumps({
            "signature": base64.b64encode(self.signature).decode(),
            "algorithm": self.algorithm,
            "key_id": self.key_id,
            "timestamp": self.timestamp.isoformat()
        }).encode()


class KeyGenerator:
    """Generate cryptographic keys."""

    @staticmethod
    def generate_symmetric_key(size: int = 32) -> bytes:
        """Generate a random symmetric key."""
        return secrets.token_bytes(size)

    @staticmethod
    def generate_key_pair() -> Tuple[bytes, bytes]:
        """Generate a public/private key pair (simulated)."""
        # In production, use cryptography library
        private = secrets.token_bytes(32)
        public = hashlib.sha256(private).digest()
        return private, public

    @staticmethod
    def derive_key(
        password: str,
        salt: bytes = None,
        iterations: int = 100000,
        key_length: int = 32
    ) -> Tuple[bytes, bytes]:
        """Derive key from password using PBKDF2."""
        if salt is None:
            salt = secrets.token_bytes(16)

        key = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode(),
            salt,
            iterations,
            dklen=key_length
        )
        return key, salt


class Hasher:
    """Hash data."""

    @staticmethod
    def hash(data: bytes, algorithm: HashAlgorithm = HashAlgorithm.SHA256) -> bytes:
        """Hash data."""
        if algorithm == HashAlgorithm.SHA256:
            return hashlib.sha256(data).digest()
        elif algorithm == HashAlgorithm.SHA384:
            return hashlib.sha384(data).digest()
        elif algorithm == HashAlgorithm.SHA512:
            return hashlib.sha512(data).digest()
        elif algorithm == HashAlgorithm.BLAKE2B:
            return hashlib.blake2b(data).digest()
        elif algorithm == HashAlgorithm.BLAKE2S:
            return hashlib.blake2s(data).digest()
        else:
            return hashlib.sha256(data).digest()

    @staticmethod
    def hash_hex(data: bytes, algorithm: HashAlgorithm = HashAlgorithm.SHA256) -> str:
        """Hash data and return hex string."""
        return Hasher.hash(data, algorithm).hex()

    @staticmethod
    def hash_password(password: str, salt: bytes = None) -> Tuple[str, str]:
        """Hash password with salt."""
        if salt is None:
            salt = secrets.token_bytes(16)

        key, _ = KeyGenerator.derive_key(password, salt)
        return base64.b64encode(key).decode(), base64.b64encode(salt).decode()

    @staticmethod
    def verify_password(password: str, hash_b64: str, salt_b64: str) -> bool:
        """Verify password against hash."""
        salt = base64.b64decode(salt_b64)
        key, _ = KeyGenerator.derive_key(password, salt)
        return base64.b64encode(key).decode() == hash_b64


class SimpleCipher:
    """Simple encryption/decryption (XOR-based for demo, use real crypto in production)."""

    @staticmethod
    def encrypt(plaintext: bytes, key: bytes) -> EncryptedData:
        """Encrypt data."""
        nonce = secrets.token_bytes(12)

        # Derive encryption key using nonce
        enc_key = hashlib.sha256(key + nonce).digest()

        # XOR encryption (demo only - use AES-GCM in production)
        ciphertext = bytes(
            p ^ enc_key[i % len(enc_key)]
            for i, p in enumerate(plaintext)
        )

        # Generate authentication tag
        tag = hmac.new(key, ciphertext + nonce, hashlib.sha256).digest()[:16]

        return EncryptedData(
            ciphertext=ciphertext,
            nonce=nonce,
            tag=tag,
            algorithm="demo-xor-hmac"
        )

    @staticmethod
    def decrypt(encrypted: EncryptedData, key: bytes) -> bytes:
        """Decrypt data."""
        # Verify authentication tag
        expected_tag = hmac.new(
            key, encrypted.ciphertext + encrypted.nonce, hashlib.sha256
        ).digest()[:16]

        if not hmac.compare_digest(encrypted.tag, expected_tag):
            raise ValueError("Authentication failed")

        # Derive encryption key
        enc_key = hashlib.sha256(key + encrypted.nonce).digest()

        # XOR decryption
        plaintext = bytes(
            c ^ enc_key[i % len(enc_key)]
            for i, c in enumerate(encrypted.ciphertext)
        )

        return plaintext


class Signer:
    """Sign and verify data."""

    @staticmethod
    def sign(data: bytes, key: bytes) -> Signature:
        """Sign data using HMAC."""
        signature = hmac.new(key, data, hashlib.sha256).digest()
        return Signature(
            signature=signature,
            algorithm="hmac-sha256",
            key_id=hashlib.sha256(key).hexdigest()[:16]
        )

    @staticmethod
    def verify(data: bytes, signature: Signature, key: bytes) -> bool:
        """Verify signature."""
        expected = hmac.new(key, data, hashlib.sha256).digest()
        return hmac.compare_digest(signature.signature, expected)


class KeyStore:
    """Store and manage keys."""

    def __init__(self):
        self.keys: Dict[str, CryptoKey] = {}
        self._lock = threading.Lock()

    def store(self, key: CryptoKey) -> None:
        """Store a key."""
        with self._lock:
            self.keys[key.id] = key

    def get(self, key_id: str) -> Optional[CryptoKey]:
        """Get a key by ID."""
        key = self.keys.get(key_id)
        if key and key.is_expired:
            logger.warning(f"Key {key_id} has expired")
        return key

    def delete(self, key_id: str) -> bool:
        """Delete a key."""
        with self._lock:
            if key_id in self.keys:
                del self.keys[key_id]
                return True
            return False

    def rotate(self, key_id: str) -> Optional[CryptoKey]:
        """Rotate a key (create new, mark old as expired)."""
        old_key = self.keys.get(key_id)
        if not old_key:
            return None

        # Create new key
        new_key = CryptoKey(
            id=str(uuid.uuid4()),
            key_type=old_key.key_type,
            algorithm=old_key.algorithm,
            key_data=KeyGenerator.generate_symmetric_key(),
            metadata={"rotated_from": key_id}
        )

        # Expire old key
        old_key.expires_at = datetime.now()
        old_key.metadata["rotated_to"] = new_key.id

        with self._lock:
            self.keys[new_key.id] = new_key

        return new_key

    def list_keys(self, include_expired: bool = False) -> List[Dict[str, Any]]:
        """List all keys."""
        keys = list(self.keys.values())
        if not include_expired:
            keys = [k for k in keys if not k.is_expired]
        return [k.to_dict() for k in keys]


class TokenGenerator:
    """Generate secure tokens."""

    @staticmethod
    def generate_token(length: int = 32) -> str:
        """Generate a random token."""
        return secrets.token_urlsafe(length)

    @staticmethod
    def generate_api_key(prefix: str = "br") -> str:
        """Generate an API key."""
        return f"{prefix}_{secrets.token_urlsafe(32)}"

    @staticmethod
    def generate_otp(length: int = 6) -> str:
        """Generate a numeric OTP."""
        return ''.join(str(secrets.randbelow(10)) for _ in range(length))

    @staticmethod
    def generate_totp_secret() -> str:
        """Generate a TOTP secret."""
        return base64.b32encode(secrets.token_bytes(20)).decode()


class CryptoManager:
    """High-level crypto management."""

    def __init__(self):
        self.key_store = KeyStore()
        self.cipher = SimpleCipher()
        self.signer = Signer()
        self.hasher = Hasher()

    def create_key(
        self,
        algorithm: str = "aes-256-gcm",
        expires_in: timedelta = None,
        metadata: Dict[str, Any] = None
    ) -> CryptoKey:
        """Create a new symmetric key."""
        key = CryptoKey(
            id=str(uuid.uuid4()),
            key_type=KeyType.SYMMETRIC,
            algorithm=algorithm,
            key_data=KeyGenerator.generate_symmetric_key(),
            expires_at=datetime.now() + expires_in if expires_in else None,
            metadata=metadata or {}
        )
        self.key_store.store(key)
        return key

    def encrypt(
        self,
        plaintext: Union[str, bytes],
        key_id: str = None,
        key: bytes = None
    ) -> EncryptedData:
        """Encrypt data."""
        if isinstance(plaintext, str):
            plaintext = plaintext.encode()

        if key_id:
            crypto_key = self.key_store.get(key_id)
            if not crypto_key:
                raise ValueError(f"Key {key_id} not found")
            key = crypto_key.key_data

        if not key:
            raise ValueError("No key provided")

        encrypted = self.cipher.encrypt(plaintext, key)
        encrypted.key_id = key_id
        return encrypted

    def decrypt(
        self,
        encrypted: EncryptedData,
        key_id: str = None,
        key: bytes = None
    ) -> bytes:
        """Decrypt data."""
        if key_id or encrypted.key_id:
            crypto_key = self.key_store.get(key_id or encrypted.key_id)
            if not crypto_key:
                raise ValueError("Key not found")
            key = crypto_key.key_data

        if not key:
            raise ValueError("No key provided")

        return self.cipher.decrypt(encrypted, key)

    def sign(self, data: Union[str, bytes], key_id: str) -> Signature:
        """Sign data."""
        if isinstance(data, str):
            data = data.encode()

        crypto_key = self.key_store.get(key_id)
        if not crypto_key:
            raise ValueError(f"Key {key_id} not found")

        return self.signer.sign(data, crypto_key.key_data)

    def verify(self, data: Union[str, bytes], signature: Signature, key_id: str) -> bool:
        """Verify signature."""
        if isinstance(data, str):
            data = data.encode()

        crypto_key = self.key_store.get(key_id)
        if not crypto_key:
            return False

        return self.signer.verify(data, signature, crypto_key.key_data)

    def hash(
        self,
        data: Union[str, bytes],
        algorithm: HashAlgorithm = HashAlgorithm.SHA256
    ) -> str:
        """Hash data and return hex string."""
        if isinstance(data, str):
            data = data.encode()
        return self.hasher.hash_hex(data, algorithm)

    def hash_password(self, password: str) -> Dict[str, str]:
        """Hash a password."""
        hash_b64, salt_b64 = self.hasher.hash_password(password)
        return {"hash": hash_b64, "salt": salt_b64}

    def verify_password(self, password: str, stored: Dict[str, str]) -> bool:
        """Verify a password."""
        return self.hasher.verify_password(password, stored["hash"], stored["salt"])

    def rotate_key(self, key_id: str) -> Optional[str]:
        """Rotate a key and return new key ID."""
        new_key = self.key_store.rotate(key_id)
        return new_key.id if new_key else None

    def generate_token(self) -> str:
        """Generate a secure token."""
        return TokenGenerator.generate_token()

    def generate_api_key(self, prefix: str = "br") -> str:
        """Generate an API key."""
        return TokenGenerator.generate_api_key(prefix)


# Example usage
def example_usage():
    """Example crypto usage."""
    manager = CryptoManager()

    # Create a key
    key = manager.create_key(expires_in=timedelta(days=30))
    print(f"Created key: {key.id}")

    # Encrypt data
    plaintext = "Hello, World! This is secret data."
    encrypted = manager.encrypt(plaintext, key_id=key.id)
    print(f"Encrypted: {len(encrypted.ciphertext)} bytes")

    # Decrypt data
    decrypted = manager.decrypt(encrypted, key_id=key.id)
    print(f"Decrypted: {decrypted.decode()}")

    # Sign data
    signature = manager.sign("Important message", key.id)
    print(f"Signed with algorithm: {signature.algorithm}")

    # Verify signature
    valid = manager.verify("Important message", signature, key.id)
    print(f"Signature valid: {valid}")

    # Hash data
    hash_value = manager.hash("data to hash")
    print(f"Hash: {hash_value}")

    # Password hashing
    stored = manager.hash_password("mypassword123")
    valid = manager.verify_password("mypassword123", stored)
    print(f"Password valid: {valid}")

    # Generate tokens
    token = manager.generate_token()
    api_key = manager.generate_api_key("prod")
    print(f"Token: {token}")
    print(f"API Key: {api_key}")

