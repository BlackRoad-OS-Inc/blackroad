"""
RoadPassword - Password Utilities for BlackRoad
Hash, verify, and generate secure passwords.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple
import base64
import hashlib
import hmac
import os
import re
import secrets
import string
import logging

logger = logging.getLogger(__name__)


class PasswordError(Exception):
    pass


class HashMethod(str, Enum):
    PBKDF2 = "pbkdf2"
    BCRYPT_LIKE = "bcrypt"
    SCRYPT_LIKE = "scrypt"
    ARGON2_LIKE = "argon2"


@dataclass
class PasswordHash:
    method: str
    hash: bytes
    salt: bytes
    iterations: int = 0
    
    def to_string(self) -> str:
        salt_b64 = base64.b64encode(self.salt).decode()
        hash_b64 = base64.b64encode(self.hash).decode()
        return f"${self.method}${self.iterations}${salt_b64}${hash_b64}"
    
    @classmethod
    def from_string(cls, s: str) -> "PasswordHash":
        parts = s.split("$")
        if len(parts) != 5:
            raise PasswordError("Invalid hash format")
        _, method, iterations, salt_b64, hash_b64 = parts
        return cls(
            method=method,
            iterations=int(iterations),
            salt=base64.b64decode(salt_b64),
            hash=base64.b64decode(hash_b64)
        )


@dataclass
class PasswordStrength:
    score: int  # 0-4
    feedback: List[str]
    crack_time: str
    
    @property
    def level(self) -> str:
        levels = ["Very Weak", "Weak", "Fair", "Strong", "Very Strong"]
        return levels[min(self.score, 4)]


class PasswordHasher:
    def __init__(self, method: HashMethod = HashMethod.PBKDF2, iterations: int = 100000):
        self.method = method
        self.iterations = iterations
    
    def hash(self, password: str) -> PasswordHash:
        salt = os.urandom(16)
        
        if self.method == HashMethod.PBKDF2:
            h = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, self.iterations)
        elif self.method == HashMethod.BCRYPT_LIKE:
            h = self._bcrypt_like(password.encode(), salt, self.iterations)
        elif self.method == HashMethod.SCRYPT_LIKE:
            h = self._scrypt_like(password.encode(), salt)
        elif self.method == HashMethod.ARGON2_LIKE:
            h = self._argon2_like(password.encode(), salt, self.iterations)
        else:
            raise PasswordError(f"Unknown method: {self.method}")
        
        return PasswordHash(method=self.method.value, hash=h, salt=salt, iterations=self.iterations)
    
    def _bcrypt_like(self, password: bytes, salt: bytes, iterations: int) -> bytes:
        state = hashlib.sha256(salt + password).digest()
        for _ in range(iterations):
            state = hashlib.sha256(state + password).digest()
        return state
    
    def _scrypt_like(self, password: bytes, salt: bytes) -> bytes:
        n = 16384
        r = 8
        p = 1
        state = hashlib.pbkdf2_hmac("sha256", password, salt, 1)
        for _ in range(n // 1024):
            state = hashlib.sha256(state).digest()
        return state
    
    def _argon2_like(self, password: bytes, salt: bytes, iterations: int) -> bytes:
        state = hashlib.sha512(salt + password).digest()
        for i in range(iterations):
            state = hashlib.sha512(state + bytes([i % 256])).digest()
        return state[:32]
    
    def verify(self, password: str, hashed: PasswordHash) -> bool:
        if hashed.method == HashMethod.PBKDF2.value:
            h = hashlib.pbkdf2_hmac("sha256", password.encode(), hashed.salt, hashed.iterations)
        elif hashed.method == HashMethod.BCRYPT_LIKE.value:
            h = self._bcrypt_like(password.encode(), hashed.salt, hashed.iterations)
        elif hashed.method == HashMethod.SCRYPT_LIKE.value:
            h = self._scrypt_like(password.encode(), hashed.salt)
        elif hashed.method == HashMethod.ARGON2_LIKE.value:
            h = self._argon2_like(password.encode(), hashed.salt, hashed.iterations)
        else:
            raise PasswordError(f"Unknown method: {hashed.method}")
        
        return hmac.compare_digest(h, hashed.hash)


class PasswordGenerator:
    LOWER = string.ascii_lowercase
    UPPER = string.ascii_uppercase
    DIGITS = string.digits
    SYMBOLS = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    SIMILAR = "il1Lo0O"
    AMBIGUOUS = "{}[]()/\\'\"`~,;:.<>"
    
    def __init__(self):
        self.length = 16
        self.use_lower = True
        self.use_upper = True
        self.use_digits = True
        self.use_symbols = True
        self.exclude_similar = False
        self.exclude_ambiguous = False
        self.min_lower = 0
        self.min_upper = 0
        self.min_digits = 0
        self.min_symbols = 0
    
    def generate(self) -> str:
        charset = ""
        required = []
        
        if self.use_lower:
            chars = self.LOWER
            if self.exclude_similar:
                chars = "".join(c for c in chars if c not in self.SIMILAR)
            charset += chars
            required.extend(secrets.choice(chars) for _ in range(self.min_lower))
        
        if self.use_upper:
            chars = self.UPPER
            if self.exclude_similar:
                chars = "".join(c for c in chars if c not in self.SIMILAR)
            charset += chars
            required.extend(secrets.choice(chars) for _ in range(self.min_upper))
        
        if self.use_digits:
            chars = self.DIGITS
            if self.exclude_similar:
                chars = "".join(c for c in chars if c not in self.SIMILAR)
            charset += chars
            required.extend(secrets.choice(chars) for _ in range(self.min_digits))
        
        if self.use_symbols:
            chars = self.SYMBOLS
            if self.exclude_ambiguous:
                chars = "".join(c for c in chars if c not in self.AMBIGUOUS)
            charset += chars
            required.extend(secrets.choice(chars) for _ in range(self.min_symbols))
        
        remaining = self.length - len(required)
        if remaining < 0:
            raise PasswordError("Length too short for requirements")
        
        password = required + [secrets.choice(charset) for _ in range(remaining)]
        secrets.SystemRandom().shuffle(password)
        
        return "".join(password)


class PasswordValidator:
    def __init__(self):
        self.min_length = 8
        self.max_length = 128
        self.require_lower = True
        self.require_upper = True
        self.require_digit = True
        self.require_symbol = True
        self.common_passwords = {"password", "123456", "qwerty", "admin", "letmein"}
    
    def validate(self, password: str) -> Tuple[bool, List[str]]:
        errors = []
        
        if len(password) < self.min_length:
            errors.append(f"Password must be at least {self.min_length} characters")
        if len(password) > self.max_length:
            errors.append(f"Password must be at most {self.max_length} characters")
        if self.require_lower and not any(c.islower() for c in password):
            errors.append("Password must contain a lowercase letter")
        if self.require_upper and not any(c.isupper() for c in password):
            errors.append("Password must contain an uppercase letter")
        if self.require_digit and not any(c.isdigit() for c in password):
            errors.append("Password must contain a digit")
        if self.require_symbol and not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password):
            errors.append("Password must contain a symbol")
        if password.lower() in self.common_passwords:
            errors.append("Password is too common")
        
        return len(errors) == 0, errors
    
    def strength(self, password: str) -> PasswordStrength:
        score = 0
        feedback = []
        
        if len(password) >= 8:
            score += 1
        if len(password) >= 12:
            score += 1
        if re.search(r"[a-z]", password) and re.search(r"[A-Z]", password):
            score += 1
        if re.search(r"\d", password):
            score += 0.5
        if re.search(r"[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]", password):
            score += 0.5
        
        crack_times = ["instant", "minutes", "hours", "days", "years"]
        
        return PasswordStrength(score=int(score), feedback=feedback, crack_time=crack_times[min(int(score), 4)])


def hash_password(password: str) -> str:
    return PasswordHasher().hash(password).to_string()


def verify_password(password: str, hashed: str) -> bool:
    return PasswordHasher().verify(password, PasswordHash.from_string(hashed))


def generate_password(length: int = 16) -> str:
    gen = PasswordGenerator()
    gen.length = length
    return gen.generate()


def example_usage():
    password = "MySecurePassword123!"
    
    hashed = hash_password(password)
    print(f"Hashed: {hashed}")
    print(f"Verified: {verify_password(password, hashed)}")
    
    gen = PasswordGenerator()
    gen.length = 20
    gen.min_symbols = 2
    print(f"\nGenerated: {gen.generate()}")
    
    validator = PasswordValidator()
    valid, errors = validator.validate("weak")
    print(f"\n'weak' valid: {valid}")
    print(f"Errors: {errors}")
    
    strength = validator.strength(password)
    print(f"\nStrength: {strength.level} ({strength.score}/4)")

