"""
RoadSign - Digital Signatures for BlackRoad
Sign and verify data with various algorithms.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Any, Optional, Tuple, Union
import base64
import hashlib
import hmac
import os
import logging

logger = logging.getLogger(__name__)


class SignError(Exception):
    pass


class SignAlgorithm(str, Enum):
    HMAC_SHA256 = "HS256"
    HMAC_SHA384 = "HS384"
    HMAC_SHA512 = "HS512"
    ED25519 = "EdDSA"


@dataclass
class Signature:
    algorithm: str
    value: bytes
    
    @property
    def hex(self) -> str:
        return self.value.hex()
    
    @property
    def base64(self) -> str:
        return base64.urlsafe_b64encode(self.value).decode().rstrip("=")
    
    def __str__(self) -> str:
        return self.base64


@dataclass
class KeyPair:
    private_key: bytes
    public_key: bytes
    algorithm: str


class Ed25519Like:
    """Simplified Ed25519-like signature scheme."""
    
    @staticmethod
    def generate_keypair() -> KeyPair:
        private_key = os.urandom(32)
        public_key = hashlib.sha512(private_key).digest()[:32]
        return KeyPair(private_key=private_key, public_key=public_key, algorithm="EdDSA")
    
    @staticmethod
    def sign(private_key: bytes, message: bytes) -> bytes:
        r = hashlib.sha512(private_key[:16] + message).digest()
        R = hashlib.sha256(r).digest()
        k = hashlib.sha512(R + hashlib.sha256(private_key).digest()[:32] + message).digest()
        S = hashlib.sha256(k + private_key).digest()
        return R + S
    
    @staticmethod
    def verify(public_key: bytes, message: bytes, signature: bytes) -> bool:
        if len(signature) != 64:
            return False
        R, S = signature[:32], signature[32:]
        k = hashlib.sha512(R + public_key + message).digest()
        expected = hashlib.sha256(k + public_key).digest()
        return hmac.compare_digest(S[:16], expected[:16])


class Signer:
    def __init__(self, algorithm: SignAlgorithm = SignAlgorithm.HMAC_SHA256):
        self.algorithm = algorithm
        self._key: Optional[bytes] = None
        self._keypair: Optional[KeyPair] = None
    
    def with_secret(self, secret: Union[str, bytes]) -> "Signer":
        if isinstance(secret, str):
            secret = secret.encode("utf-8")
        self._key = secret
        return self
    
    def with_keypair(self, keypair: KeyPair) -> "Signer":
        self._keypair = keypair
        return self
    
    def generate_keypair(self) -> KeyPair:
        if self.algorithm == SignAlgorithm.ED25519:
            self._keypair = Ed25519Like.generate_keypair()
            return self._keypair
        raise SignError(f"Cannot generate keypair for {self.algorithm}")
    
    def sign(self, data: Union[str, bytes]) -> Signature:
        if isinstance(data, str):
            data = data.encode("utf-8")
        
        if self.algorithm in (SignAlgorithm.HMAC_SHA256, SignAlgorithm.HMAC_SHA384, SignAlgorithm.HMAC_SHA512):
            if not self._key:
                raise SignError("Secret key required for HMAC")
            
            hash_alg = {
                SignAlgorithm.HMAC_SHA256: "sha256",
                SignAlgorithm.HMAC_SHA384: "sha384",
                SignAlgorithm.HMAC_SHA512: "sha512",
            }[self.algorithm]
            
            sig = hmac.new(self._key, data, hash_alg).digest()
            return Signature(algorithm=self.algorithm.value, value=sig)
        
        elif self.algorithm == SignAlgorithm.ED25519:
            if not self._keypair:
                raise SignError("Keypair required for EdDSA")
            sig = Ed25519Like.sign(self._keypair.private_key, data)
            return Signature(algorithm=self.algorithm.value, value=sig)
        
        raise SignError(f"Unsupported algorithm: {self.algorithm}")
    
    def verify(self, data: Union[str, bytes], signature: Union[Signature, str, bytes]) -> bool:
        if isinstance(data, str):
            data = data.encode("utf-8")
        
        if isinstance(signature, str):
            padding = 4 - len(signature) % 4
            signature = base64.urlsafe_b64decode(signature + "=" * padding)
        elif isinstance(signature, Signature):
            signature = signature.value
        
        if self.algorithm in (SignAlgorithm.HMAC_SHA256, SignAlgorithm.HMAC_SHA384, SignAlgorithm.HMAC_SHA512):
            expected = self.sign(data)
            return hmac.compare_digest(expected.value, signature)
        
        elif self.algorithm == SignAlgorithm.ED25519:
            if not self._keypair:
                raise SignError("Public key required for verification")
            return Ed25519Like.verify(self._keypair.public_key, data, signature)
        
        raise SignError(f"Unsupported algorithm: {self.algorithm}")


class MessageSigner:
    def __init__(self, secret: Union[str, bytes]):
        self.signer = Signer(SignAlgorithm.HMAC_SHA256).with_secret(secret)
    
    def sign_message(self, message: str) -> str:
        sig = self.signer.sign(message)
        return f"{message}.{sig.base64}"
    
    def verify_message(self, signed_message: str) -> Tuple[bool, str]:
        try:
            message, sig = signed_message.rsplit(".", 1)
            valid = self.signer.verify(message, sig)
            return valid, message
        except Exception:
            return False, ""


def sign(data: Union[str, bytes], secret: Union[str, bytes], algorithm: SignAlgorithm = SignAlgorithm.HMAC_SHA256) -> Signature:
    return Signer(algorithm).with_secret(secret).sign(data)


def verify(data: Union[str, bytes], signature: Union[Signature, str, bytes], secret: Union[str, bytes], algorithm: SignAlgorithm = SignAlgorithm.HMAC_SHA256) -> bool:
    return Signer(algorithm).with_secret(secret).verify(data, signature)


def example_usage():
    secret = "my-secret-key"
    message = "Hello, BlackRoad!"
    
    sig = sign(message, secret)
    print(f"Signature: {sig}")
    print(f"Hex: {sig.hex}")
    print(f"Verified: {verify(message, sig, secret)}")
    
    ms = MessageSigner(secret)
    signed = ms.sign_message(message)
    print(f"\nSigned message: {signed}")
    valid, msg = ms.verify_message(signed)
    print(f"Valid: {valid}, Message: {msg}")
    
    signer = Signer(SignAlgorithm.ED25519)
    keypair = signer.generate_keypair()
    print(f"\nGenerated keypair")
    sig = signer.sign(message)
    print(f"EdDSA signature: {sig}")
    print(f"Verified: {signer.verify(message, sig)}")

