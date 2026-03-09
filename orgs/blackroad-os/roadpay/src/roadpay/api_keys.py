"""
RoadPay API Key Management

Features:
- Generate API keys for customers
- Key rotation
- Usage tracking
- Rate limiting per key
- Scope/permissions
- Key revocation
"""

import hashlib
import secrets
import time
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from pydantic import BaseModel


class KeyScope(str, Enum):
    READ = "read"
    WRITE = "write"
    ADMIN = "admin"
    BILLING = "billing"
    WEBHOOK = "webhook"


class KeyStatus(str, Enum):
    ACTIVE = "active"
    REVOKED = "revoked"
    EXPIRED = "expired"
    RATE_LIMITED = "rate_limited"


@dataclass
class APIKey:
    id: str
    customer_id: str
    name: str
    key_prefix: str  # First 8 chars for display (sk_live_abc...)
    key_hash: str  # SHA256 hash of full key
    scopes: List[KeyScope]
    created_at: int
    expires_at: Optional[int] = None
    last_used_at: Optional[int] = None
    status: KeyStatus = KeyStatus.ACTIVE
    rate_limit: int = 1000  # requests per hour
    request_count: int = 0
    metadata: Dict[str, str] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "customer_id": self.customer_id,
            "name": self.name,
            "key_prefix": self.key_prefix,
            "scopes": [s.value for s in self.scopes],
            "created_at": self.created_at,
            "expires_at": self.expires_at,
            "last_used_at": self.last_used_at,
            "status": self.status.value,
            "rate_limit": self.rate_limit,
            "request_count": self.request_count,
            "metadata": self.metadata,
        }


class APIKeyCreate(BaseModel):
    customer_id: str
    name: str
    scopes: List[str] = ["read"]
    expires_in_days: Optional[int] = None
    rate_limit: int = 1000
    metadata: Optional[Dict[str, str]] = None


class APIKeyManager:
    """
    Manages API keys for customers.
    """

    def __init__(self, storage):
        """
        Args:
            storage: KV-like storage (Redis, KV namespace, or dict)
        """
        self.storage = storage
        self.key_prefix = "rp_"  # roadpay_
        self.live_prefix = "sk_live_"
        self.test_prefix = "sk_test_"

    async def create_key(
        self,
        customer_id: str,
        name: str,
        scopes: List[KeyScope],
        expires_in_days: Optional[int] = None,
        rate_limit: int = 1000,
        is_test: bool = False,
        metadata: Optional[Dict[str, str]] = None,
    ) -> tuple[str, APIKey]:
        """
        Generate a new API key.

        Returns:
            Tuple of (raw_key, APIKey object)
            The raw key is only returned once!
        """
        # Generate key
        prefix = self.test_prefix if is_test else self.live_prefix
        random_part = secrets.token_urlsafe(32)
        raw_key = f"{prefix}{random_part}"

        # Hash for storage
        key_hash = self._hash_key(raw_key)

        # Create key object
        key_id = f"key_{secrets.token_hex(8)}"
        now = int(time.time())

        api_key = APIKey(
            id=key_id,
            customer_id=customer_id,
            name=name,
            key_prefix=raw_key[:16],  # sk_live_abc12345
            key_hash=key_hash,
            scopes=scopes,
            created_at=now,
            expires_at=now + (expires_in_days * 86400) if expires_in_days else None,
            status=KeyStatus.ACTIVE,
            rate_limit=rate_limit,
            metadata=metadata or {},
        )

        # Store key
        await self._store_key(api_key)

        # Store hash -> key_id mapping for lookup
        await self._store_hash_mapping(key_hash, key_id)

        return raw_key, api_key

    async def validate_key(
        self,
        raw_key: str,
        required_scopes: Optional[List[KeyScope]] = None,
    ) -> tuple[bool, Optional[APIKey], Optional[str]]:
        """
        Validate an API key.

        Returns:
            Tuple of (is_valid, APIKey or None, error message or None)
        """
        # Check format
        if not raw_key.startswith(self.live_prefix) and not raw_key.startswith(self.test_prefix):
            return False, None, "Invalid key format"

        # Get key by hash
        key_hash = self._hash_key(raw_key)
        api_key = await self._get_key_by_hash(key_hash)

        if not api_key:
            return False, None, "Key not found"

        # Check status
        if api_key.status == KeyStatus.REVOKED:
            return False, api_key, "Key has been revoked"

        # Check expiration
        if api_key.expires_at and api_key.expires_at < int(time.time()):
            api_key.status = KeyStatus.EXPIRED
            await self._store_key(api_key)
            return False, api_key, "Key has expired"

        # Check rate limit
        if api_key.request_count >= api_key.rate_limit:
            return False, api_key, "Rate limit exceeded"

        # Check scopes
        if required_scopes:
            if KeyScope.ADMIN in api_key.scopes:
                pass  # Admin has all scopes
            else:
                for scope in required_scopes:
                    if scope not in api_key.scopes:
                        return False, api_key, f"Missing required scope: {scope.value}"

        # Update usage
        api_key.last_used_at = int(time.time())
        api_key.request_count += 1
        await self._store_key(api_key)

        return True, api_key, None

    async def revoke_key(self, key_id: str) -> bool:
        """
        Revoke an API key.
        """
        api_key = await self._get_key_by_id(key_id)
        if not api_key:
            return False

        api_key.status = KeyStatus.REVOKED
        await self._store_key(api_key)
        return True

    async def rotate_key(
        self,
        key_id: str,
        is_test: bool = False,
    ) -> tuple[Optional[str], Optional[APIKey]]:
        """
        Rotate an API key (create new, revoke old).

        Returns:
            Tuple of (new_raw_key, new_APIKey) or (None, None) if key not found
        """
        old_key = await self._get_key_by_id(key_id)
        if not old_key:
            return None, None

        # Create new key with same settings
        new_raw_key, new_api_key = await self.create_key(
            customer_id=old_key.customer_id,
            name=f"{old_key.name} (rotated)",
            scopes=old_key.scopes,
            rate_limit=old_key.rate_limit,
            is_test=is_test,
            metadata={
                **old_key.metadata,
                "rotated_from": old_key.id,
            },
        )

        # Revoke old key
        await self.revoke_key(key_id)

        return new_raw_key, new_api_key

    async def list_keys(
        self,
        customer_id: str,
        include_revoked: bool = False,
    ) -> List[APIKey]:
        """
        List all API keys for a customer.
        """
        keys = await self._get_customer_keys(customer_id)

        if not include_revoked:
            keys = [k for k in keys if k.status != KeyStatus.REVOKED]

        return sorted(keys, key=lambda k: k.created_at, reverse=True)

    async def get_key_usage(
        self,
        key_id: str,
        period_hours: int = 24,
    ) -> Dict[str, Any]:
        """
        Get usage statistics for a key.
        """
        api_key = await self._get_key_by_id(key_id)
        if not api_key:
            return {}

        # In production, you'd track detailed usage in a time series DB
        return {
            "key_id": key_id,
            "total_requests": api_key.request_count,
            "rate_limit": api_key.rate_limit,
            "remaining": max(0, api_key.rate_limit - api_key.request_count),
            "last_used_at": api_key.last_used_at,
            "period_hours": period_hours,
        }

    async def reset_rate_limit(self, key_id: str) -> bool:
        """
        Reset rate limit counter for a key.
        """
        api_key = await self._get_key_by_id(key_id)
        if not api_key:
            return False

        api_key.request_count = 0
        if api_key.status == KeyStatus.RATE_LIMITED:
            api_key.status = KeyStatus.ACTIVE
        await self._store_key(api_key)
        return True

    async def update_key(
        self,
        key_id: str,
        name: Optional[str] = None,
        scopes: Optional[List[KeyScope]] = None,
        rate_limit: Optional[int] = None,
        metadata: Optional[Dict[str, str]] = None,
    ) -> Optional[APIKey]:
        """
        Update key settings.
        """
        api_key = await self._get_key_by_id(key_id)
        if not api_key:
            return None

        if name:
            api_key.name = name
        if scopes:
            api_key.scopes = scopes
        if rate_limit:
            api_key.rate_limit = rate_limit
        if metadata:
            api_key.metadata.update(metadata)

        await self._store_key(api_key)
        return api_key

    # Storage helpers (implement based on your storage backend)

    def _hash_key(self, raw_key: str) -> str:
        return hashlib.sha256(raw_key.encode()).hexdigest()

    async def _store_key(self, api_key: APIKey) -> None:
        """Store key in storage."""
        key_data = api_key.to_dict()
        key_data["scopes"] = [s.value for s in api_key.scopes]
        key_data["status"] = api_key.status.value

        # Store by key ID
        await self.storage.put(f"apikey:{api_key.id}", key_data)

        # Store in customer's key list
        customer_keys = await self.storage.get(f"customer_keys:{api_key.customer_id}") or []
        if api_key.id not in customer_keys:
            customer_keys.append(api_key.id)
            await self.storage.put(f"customer_keys:{api_key.customer_id}", customer_keys)

    async def _store_hash_mapping(self, key_hash: str, key_id: str) -> None:
        """Store hash -> key_id mapping."""
        await self.storage.put(f"apikey_hash:{key_hash}", key_id)

    async def _get_key_by_id(self, key_id: str) -> Optional[APIKey]:
        """Get key by ID."""
        data = await self.storage.get(f"apikey:{key_id}")
        if not data:
            return None
        return self._dict_to_key(data)

    async def _get_key_by_hash(self, key_hash: str) -> Optional[APIKey]:
        """Get key by hash."""
        key_id = await self.storage.get(f"apikey_hash:{key_hash}")
        if not key_id:
            return None
        return await self._get_key_by_id(key_id)

    async def _get_customer_keys(self, customer_id: str) -> List[APIKey]:
        """Get all keys for a customer."""
        key_ids = await self.storage.get(f"customer_keys:{customer_id}") or []
        keys = []
        for key_id in key_ids:
            key = await self._get_key_by_id(key_id)
            if key:
                keys.append(key)
        return keys

    def _dict_to_key(self, data: Dict[str, Any]) -> APIKey:
        """Convert dict to APIKey."""
        return APIKey(
            id=data["id"],
            customer_id=data["customer_id"],
            name=data["name"],
            key_prefix=data["key_prefix"],
            key_hash=data.get("key_hash", ""),
            scopes=[KeyScope(s) for s in data["scopes"]],
            created_at=data["created_at"],
            expires_at=data.get("expires_at"),
            last_used_at=data.get("last_used_at"),
            status=KeyStatus(data["status"]),
            rate_limit=data.get("rate_limit", 1000),
            request_count=data.get("request_count", 0),
            metadata=data.get("metadata", {}),
        )


class SimpleStorage:
    """
    Simple in-memory storage for development.
    Replace with Redis/KV in production.
    """

    def __init__(self):
        self._data: Dict[str, Any] = {}

    async def get(self, key: str) -> Any:
        return self._data.get(key)

    async def put(self, key: str, value: Any) -> None:
        self._data[key] = value

    async def delete(self, key: str) -> None:
        self._data.pop(key, None)


# Middleware for API key authentication
async def api_key_auth(
    api_key_header: str,
    key_manager: APIKeyManager,
    required_scopes: Optional[List[KeyScope]] = None,
) -> APIKey:
    """
    FastAPI dependency for API key authentication.

    Usage:
        @app.get("/api/resource")
        async def get_resource(
            api_key: APIKey = Depends(lambda h=Header(..., alias="X-API-Key"): api_key_auth(h, key_manager))
        ):
            ...
    """
    from fastapi import HTTPException

    valid, api_key, error = await key_manager.validate_key(
        api_key_header,
        required_scopes=required_scopes,
    )

    if not valid:
        raise HTTPException(
            status_code=401 if error == "Key not found" else 403,
            detail=error or "Invalid API key",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    return api_key
