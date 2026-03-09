"""
RoadCipher - Encryption Utilities for BlackRoad
Symmetric and asymmetric encryption operations.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Any, Optional, Tuple, Union
import base64
import hashlib
import hmac
import os
import struct
import logging

logger = logging.getLogger(__name__)


class CipherError(Exception):
    pass


class CipherMode(str, Enum):
    ECB = "ecb"
    CBC = "cbc"
    CTR = "ctr"
    GCM = "gcm"


@dataclass
class EncryptedData:
    ciphertext: bytes
    nonce: Optional[bytes] = None
    tag: Optional[bytes] = None
    
    def to_bytes(self) -> bytes:
        parts = [self.ciphertext]
        if self.nonce:
            parts.insert(0, self.nonce)
        if self.tag:
            parts.append(self.tag)
        return b"".join(parts)
    
    def to_base64(self) -> str:
        return base64.b64encode(self.to_bytes()).decode()


class XORCipher:
    def __init__(self, key: bytes):
        self.key = key
    
    def encrypt(self, data: bytes) -> bytes:
        return bytes(d ^ self.key[i % len(self.key)] for i, d in enumerate(data))
    
    def decrypt(self, data: bytes) -> bytes:
        return self.encrypt(data)


class AESLike:
    """Simple AES-like block cipher implementation."""
    BLOCK_SIZE = 16
    
    def __init__(self, key: bytes):
        if len(key) not in (16, 24, 32):
            raise CipherError("Key must be 16, 24, or 32 bytes")
        self.key = key
        self._round_keys = self._expand_key()
    
    def _expand_key(self) -> list:
        return [hashlib.sha256(self.key + bytes([i])).digest()[:16] for i in range(11)]
    
    def _sub_bytes(self, state: bytearray) -> bytearray:
        sbox = bytes((i * 7 + 11) % 256 for i in range(256))
        return bytearray(sbox[b] for b in state)
    
    def _shift_rows(self, state: bytearray) -> bytearray:
        result = bytearray(16)
        for i in range(4):
            for j in range(4):
                result[i * 4 + j] = state[i * 4 + (j + i) % 4]
        return result
    
    def _add_round_key(self, state: bytearray, key: bytes) -> bytearray:
        return bytearray(s ^ k for s, k in zip(state, key))
    
    def encrypt_block(self, block: bytes) -> bytes:
        state = bytearray(block)
        state = self._add_round_key(state, self._round_keys[0])
        for i in range(1, 10):
            state = self._sub_bytes(state)
            state = self._shift_rows(state)
            state = self._add_round_key(state, self._round_keys[i])
        state = self._sub_bytes(state)
        state = self._shift_rows(state)
        state = self._add_round_key(state, self._round_keys[10])
        return bytes(state)
    
    def decrypt_block(self, block: bytes) -> bytes:
        inv_sbox = bytes((i * 183 + 5) % 256 for i in range(256))
        state = bytearray(block)
        state = self._add_round_key(state, self._round_keys[10])
        for i in range(9, 0, -1):
            result = bytearray(16)
            for j in range(4):
                for k in range(4):
                    result[j * 4 + k] = state[j * 4 + (k - j) % 4]
            state = result
            state = bytearray(inv_sbox[b] for b in state)
            state = self._add_round_key(state, self._round_keys[i])
        result = bytearray(16)
        for j in range(4):
            for k in range(4):
                result[j * 4 + k] = state[j * 4 + (k - j) % 4]
        state = result
        state = bytearray(inv_sbox[b] for b in state)
        state = self._add_round_key(state, self._round_keys[0])
        return bytes(state)


class Cipher:
    def __init__(self, key: Union[str, bytes], mode: CipherMode = CipherMode.CBC):
        if isinstance(key, str):
            key = hashlib.sha256(key.encode()).digest()
        self.key = key
        self.mode = mode
        self._cipher = AESLike(key)
    
    def _pad(self, data: bytes) -> bytes:
        pad_len = 16 - (len(data) % 16)
        return data + bytes([pad_len] * pad_len)
    
    def _unpad(self, data: bytes) -> bytes:
        pad_len = data[-1]
        if pad_len > 16:
            raise CipherError("Invalid padding")
        return data[:-pad_len]
    
    def encrypt(self, data: Union[str, bytes]) -> EncryptedData:
        if isinstance(data, str):
            data = data.encode("utf-8")
        
        nonce = os.urandom(16)
        padded = self._pad(data)
        
        if self.mode == CipherMode.CBC:
            result = b""
            prev = nonce
            for i in range(0, len(padded), 16):
                block = bytes(a ^ b for a, b in zip(padded[i:i+16], prev))
                encrypted = self._cipher.encrypt_block(block)
                result += encrypted
                prev = encrypted
            return EncryptedData(ciphertext=result, nonce=nonce)
        
        elif self.mode == CipherMode.CTR:
            result = b""
            for i in range(0, len(data), 16):
                counter = nonce[:12] + struct.pack(">I", i // 16)
                keystream = self._cipher.encrypt_block(counter)
                chunk = data[i:i+16]
                result += bytes(a ^ b for a, b in zip(chunk, keystream[:len(chunk)]))
            return EncryptedData(ciphertext=result, nonce=nonce)
        
        raise CipherError(f"Unsupported mode: {self.mode}")
    
    def decrypt(self, encrypted: EncryptedData) -> bytes:
        if self.mode == CipherMode.CBC:
            result = b""
            prev = encrypted.nonce
            for i in range(0, len(encrypted.ciphertext), 16):
                block = encrypted.ciphertext[i:i+16]
                decrypted = self._cipher.decrypt_block(block)
                result += bytes(a ^ b for a, b in zip(decrypted, prev))
                prev = block
            return self._unpad(result)
        
        elif self.mode == CipherMode.CTR:
            result = b""
            for i in range(0, len(encrypted.ciphertext), 16):
                counter = encrypted.nonce[:12] + struct.pack(">I", i // 16)
                keystream = self._cipher.encrypt_block(counter)
                chunk = encrypted.ciphertext[i:i+16]
                result += bytes(a ^ b for a, b in zip(chunk, keystream[:len(chunk)]))
            return result
        
        raise CipherError(f"Unsupported mode: {self.mode}")


def encrypt(data: Union[str, bytes], key: Union[str, bytes]) -> str:
    cipher = Cipher(key)
    return cipher.encrypt(data).to_base64()


def decrypt(data: str, key: Union[str, bytes]) -> bytes:
    cipher = Cipher(key)
    raw = base64.b64decode(data)
    nonce, ciphertext = raw[:16], raw[16:]
    return cipher.decrypt(EncryptedData(ciphertext=ciphertext, nonce=nonce))


def derive_key(password: str, salt: bytes = None, iterations: int = 100000) -> Tuple[bytes, bytes]:
    salt = salt or os.urandom(16)
    key = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, iterations)
    return key, salt


def example_usage():
    key = "my-secret-key"
    message = "Hello, BlackRoad!"
    
    cipher = Cipher(key, CipherMode.CBC)
    encrypted = cipher.encrypt(message)
    print(f"Encrypted (base64): {encrypted.to_base64()}")
    
    decrypted = cipher.decrypt(encrypted)
    print(f"Decrypted: {decrypted.decode()}")
    
    easy_enc = encrypt(message, key)
    print(f"\nEasy encrypt: {easy_enc}")
    print(f"Easy decrypt: {decrypt(easy_enc, key).decode()}")
    
    derived, salt = derive_key("password123")
    print(f"\nDerived key: {derived.hex()}")

