"""
RoadOTP - One-Time Password for BlackRoad
Generate and verify TOTP/HOTP codes.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional, Tuple
import base64
import hashlib
import hmac
import os
import struct
import time
import urllib.parse
import logging

logger = logging.getLogger(__name__)


class OTPError(Exception):
    pass


class OTPAlgorithm(str, Enum):
    SHA1 = "SHA1"
    SHA256 = "SHA256"
    SHA512 = "SHA512"


@dataclass
class OTPConfig:
    secret: bytes
    digits: int = 6
    algorithm: OTPAlgorithm = OTPAlgorithm.SHA1
    issuer: str = ""
    account: str = ""


class HOTP:
    def __init__(self, secret: bytes, digits: int = 6, algorithm: OTPAlgorithm = OTPAlgorithm.SHA1):
        self.secret = secret
        self.digits = digits
        self.algorithm = algorithm
    
    def _hash_algo(self):
        return {
            OTPAlgorithm.SHA1: hashlib.sha1,
            OTPAlgorithm.SHA256: hashlib.sha256,
            OTPAlgorithm.SHA512: hashlib.sha512,
        }[self.algorithm]
    
    def generate(self, counter: int) -> str:
        counter_bytes = struct.pack(">Q", counter)
        
        h = hmac.new(self.secret, counter_bytes, self._hash_algo()).digest()
        
        offset = h[-1] & 0x0F
        truncated = struct.unpack(">I", h[offset:offset + 4])[0] & 0x7FFFFFFF
        
        code = truncated % (10 ** self.digits)
        return str(code).zfill(self.digits)
    
    def verify(self, code: str, counter: int, window: int = 0) -> Tuple[bool, int]:
        for i in range(counter, counter + window + 1):
            if hmac.compare_digest(self.generate(i), code):
                return True, i
        return False, counter


class TOTP(HOTP):
    def __init__(self, secret: bytes, digits: int = 6, algorithm: OTPAlgorithm = OTPAlgorithm.SHA1, period: int = 30):
        super().__init__(secret, digits, algorithm)
        self.period = period
    
    def _time_counter(self, timestamp: float = None) -> int:
        timestamp = timestamp or time.time()
        return int(timestamp // self.period)
    
    def generate(self, timestamp: float = None) -> str:
        counter = self._time_counter(timestamp)
        return super().generate(counter)
    
    def verify(self, code: str, timestamp: float = None, window: int = 1) -> bool:
        counter = self._time_counter(timestamp)
        for i in range(-window, window + 1):
            if hmac.compare_digest(super().generate(counter + i), code):
                return True
        return False
    
    def time_remaining(self) -> int:
        return self.period - int(time.time() % self.period)


class OTPAuth:
    @staticmethod
    def generate_secret(length: int = 20) -> bytes:
        return os.urandom(length)
    
    @staticmethod
    def secret_to_base32(secret: bytes) -> str:
        return base64.b32encode(secret).decode().rstrip("=")
    
    @staticmethod
    def secret_from_base32(secret: str) -> bytes:
        padding = 8 - len(secret) % 8
        if padding != 8:
            secret += "=" * padding
        return base64.b32decode(secret)
    
    @staticmethod
    def generate_uri(config: OTPConfig, otp_type: str = "totp", counter: int = None, period: int = 30) -> str:
        secret_b32 = OTPAuth.secret_to_base32(config.secret)
        
        label = config.account
        if config.issuer:
            label = f"{config.issuer}:{config.account}"
        label = urllib.parse.quote(label)
        
        params = {
            "secret": secret_b32,
            "digits": config.digits,
            "algorithm": config.algorithm.value,
        }
        
        if config.issuer:
            params["issuer"] = config.issuer
        
        if otp_type == "hotp" and counter is not None:
            params["counter"] = counter
        elif otp_type == "totp":
            params["period"] = period
        
        query = urllib.parse.urlencode(params)
        return f"otpauth://{otp_type}/{label}?{query}"
    
    @staticmethod
    def parse_uri(uri: str) -> Tuple[OTPConfig, str, Optional[int]]:
        parsed = urllib.parse.urlparse(uri)
        if parsed.scheme != "otpauth":
            raise OTPError("Invalid OTP URI scheme")
        
        otp_type = parsed.netloc
        params = dict(urllib.parse.parse_qsl(parsed.query))
        
        secret = OTPAuth.secret_from_base32(params["secret"])
        
        label = urllib.parse.unquote(parsed.path.lstrip("/"))
        if ":" in label:
            issuer, account = label.split(":", 1)
        else:
            issuer = params.get("issuer", "")
            account = label
        
        config = OTPConfig(
            secret=secret,
            digits=int(params.get("digits", 6)),
            algorithm=OTPAlgorithm(params.get("algorithm", "SHA1")),
            issuer=issuer,
            account=account
        )
        
        counter = int(params["counter"]) if "counter" in params else None
        
        return config, otp_type, counter


class OTPManager:
    def __init__(self):
        self._secrets: dict = {}
    
    def register(self, user_id: str, issuer: str = "BlackRoad") -> Tuple[str, str]:
        secret = OTPAuth.generate_secret()
        self._secrets[user_id] = secret
        
        config = OTPConfig(secret=secret, issuer=issuer, account=user_id)
        uri = OTPAuth.generate_uri(config)
        secret_b32 = OTPAuth.secret_to_base32(secret)
        
        return secret_b32, uri
    
    def verify(self, user_id: str, code: str) -> bool:
        if user_id not in self._secrets:
            return False
        
        totp = TOTP(self._secrets[user_id])
        return totp.verify(code)
    
    def get_code(self, user_id: str) -> Optional[str]:
        if user_id not in self._secrets:
            return None
        
        totp = TOTP(self._secrets[user_id])
        return totp.generate()


def generate_totp(secret: str) -> str:
    secret_bytes = OTPAuth.secret_from_base32(secret)
    return TOTP(secret_bytes).generate()


def verify_totp(secret: str, code: str) -> bool:
    secret_bytes = OTPAuth.secret_from_base32(secret)
    return TOTP(secret_bytes).verify(code)


def example_usage():
    secret = OTPAuth.generate_secret()
    secret_b32 = OTPAuth.secret_to_base32(secret)
    print(f"Secret (base32): {secret_b32}")
    
    totp = TOTP(secret)
    code = totp.generate()
    print(f"Current TOTP: {code}")
    print(f"Time remaining: {totp.time_remaining()}s")
    print(f"Verified: {totp.verify(code)}")
    
    config = OTPConfig(secret=secret, issuer="BlackRoad", account="user@example.com")
    uri = OTPAuth.generate_uri(config)
    print(f"\nOTP URI: {uri}")
    
    manager = OTPManager()
    secret_b32, uri = manager.register("user123", "MyApp")
    print(f"\nRegistered secret: {secret_b32}")
    
    code = manager.get_code("user123")
    print(f"Code: {code}")
    print(f"Verified: {manager.verify('user123', code)}")

