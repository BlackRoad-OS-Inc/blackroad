"""
RoadToken - Token Generation for BlackRoad
Generate and validate secure tokens and JWTs.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional, Union
import base64
import hashlib
import hmac
import json
import os
import secrets
import time
import logging

logger = logging.getLogger(__name__)


class TokenError(Exception):
    pass


class TokenType(str, Enum):
    ACCESS = "access"
    REFRESH = "refresh"
    API_KEY = "api_key"
    RESET = "reset"
    VERIFY = "verify"


@dataclass
class Token:
    value: str
    type: TokenType
    expires_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    @property
    def is_expired(self) -> bool:
        if self.expires_at is None:
            return False
        return datetime.now() > self.expires_at


class TokenGenerator:
    def __init__(self, prefix: str = ""):
        self.prefix = prefix
    
    def generate(self, length: int = 32, type: TokenType = TokenType.ACCESS, ttl: int = None, **metadata) -> Token:
        token_bytes = secrets.token_bytes(length)
        token_value = base64.urlsafe_b64encode(token_bytes).decode().rstrip("=")
        
        if self.prefix:
            token_value = f"{self.prefix}_{token_value}"
        
        expires_at = None
        if ttl:
            expires_at = datetime.now() + timedelta(seconds=ttl)
        
        return Token(value=token_value, type=type, expires_at=expires_at, metadata=metadata)
    
    def generate_hex(self, length: int = 32) -> str:
        return secrets.token_hex(length)
    
    def generate_urlsafe(self, length: int = 32) -> str:
        return secrets.token_urlsafe(length)


@dataclass
class JWTHeader:
    alg: str = "HS256"
    typ: str = "JWT"


@dataclass
class JWTPayload:
    sub: str = ""
    iss: str = ""
    aud: str = ""
    exp: int = 0
    iat: int = 0
    nbf: int = 0
    jti: str = ""
    claims: Dict[str, Any] = field(default_factory=dict)


class JWT:
    def __init__(self, secret: Union[str, bytes], algorithm: str = "HS256"):
        if isinstance(secret, str):
            secret = secret.encode("utf-8")
        self.secret = secret
        self.algorithm = algorithm
    
    def _base64_encode(self, data: bytes) -> str:
        return base64.urlsafe_b64encode(data).decode().rstrip("=")
    
    def _base64_decode(self, data: str) -> bytes:
        padding = 4 - len(data) % 4
        return base64.urlsafe_b64decode(data + "=" * padding)
    
    def _sign(self, data: str) -> str:
        if self.algorithm == "HS256":
            sig = hmac.new(self.secret, data.encode(), hashlib.sha256).digest()
        elif self.algorithm == "HS384":
            sig = hmac.new(self.secret, data.encode(), hashlib.sha384).digest()
        elif self.algorithm == "HS512":
            sig = hmac.new(self.secret, data.encode(), hashlib.sha512).digest()
        else:
            raise TokenError(f"Unsupported algorithm: {self.algorithm}")
        return self._base64_encode(sig)
    
    def encode(self, payload: Dict[str, Any], exp: int = 3600, **kwargs) -> str:
        header = {"alg": self.algorithm, "typ": "JWT"}
        
        now = int(time.time())
        payload = {**payload}
        payload.setdefault("iat", now)
        payload.setdefault("exp", now + exp)
        
        for key, value in kwargs.items():
            payload[key] = value
        
        header_b64 = self._base64_encode(json.dumps(header, separators=(",", ":")).encode())
        payload_b64 = self._base64_encode(json.dumps(payload, separators=(",", ":")).encode())
        
        message = f"{header_b64}.{payload_b64}"
        signature = self._sign(message)
        
        return f"{message}.{signature}"
    
    def decode(self, token: str, verify: bool = True) -> Dict[str, Any]:
        parts = token.split(".")
        if len(parts) != 3:
            raise TokenError("Invalid token format")
        
        header_b64, payload_b64, signature = parts
        
        if verify:
            expected_sig = self._sign(f"{header_b64}.{payload_b64}")
            if not hmac.compare_digest(signature, expected_sig):
                raise TokenError("Invalid signature")
        
        payload = json.loads(self._base64_decode(payload_b64))
        
        if verify:
            now = int(time.time())
            if "exp" in payload and payload["exp"] < now:
                raise TokenError("Token expired")
            if "nbf" in payload and payload["nbf"] > now:
                raise TokenError("Token not yet valid")
        
        return payload
    
    def refresh(self, token: str, exp: int = 3600) -> str:
        payload = self.decode(token, verify=False)
        payload.pop("iat", None)
        payload.pop("exp", None)
        return self.encode(payload, exp=exp)


class APIKeyManager:
    def __init__(self, prefix: str = "br"):
        self.prefix = prefix
        self._keys: Dict[str, Dict[str, Any]] = {}
    
    def generate(self, name: str = "", scopes: List[str] = None, ttl: int = None) -> str:
        key_id = secrets.token_hex(8)
        key_secret = secrets.token_urlsafe(32)
        key = f"{self.prefix}_{key_id}_{key_secret}"
        
        self._keys[key] = {
            "id": key_id,
            "name": name,
            "scopes": scopes or [],
            "created_at": datetime.now(),
            "expires_at": datetime.now() + timedelta(seconds=ttl) if ttl else None
        }
        
        return key
    
    def validate(self, key: str) -> Optional[Dict[str, Any]]:
        if key not in self._keys:
            return None
        
        info = self._keys[key]
        if info["expires_at"] and datetime.now() > info["expires_at"]:
            return None
        
        return info
    
    def revoke(self, key: str) -> bool:
        if key in self._keys:
            del self._keys[key]
            return True
        return False


def generate_token(length: int = 32) -> str:
    return TokenGenerator().generate(length).value


def create_jwt(payload: Dict[str, Any], secret: str, exp: int = 3600) -> str:
    return JWT(secret).encode(payload, exp)


def verify_jwt(token: str, secret: str) -> Dict[str, Any]:
    return JWT(secret).decode(token)


def example_usage():
    gen = TokenGenerator(prefix="br")
    token = gen.generate(type=TokenType.ACCESS, ttl=3600, user_id=123)
    print(f"Token: {token.value}")
    print(f"Expires: {token.expires_at}")
    
    jwt = JWT("my-secret-key")
    encoded = jwt.encode({"user_id": 123, "role": "admin"}, exp=3600)
    print(f"\nJWT: {encoded}")
    
    decoded = jwt.decode(encoded)
    print(f"Decoded: {decoded}")
    
    api_manager = APIKeyManager()
    api_key = api_manager.generate(name="my-app", scopes=["read", "write"])
    print(f"\nAPI Key: {api_key}")
    
    info = api_manager.validate(api_key)
    print(f"Valid: {info is not None}")

