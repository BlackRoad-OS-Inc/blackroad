"""
RoadHash - Hashing Utilities for BlackRoad
Cryptographic and non-cryptographic hash functions.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Any, BinaryIO, Union
import hashlib
import hmac
import struct
import logging

logger = logging.getLogger(__name__)


class HashAlgorithm(str, Enum):
    MD5 = "md5"
    SHA1 = "sha1"
    SHA256 = "sha256"
    SHA384 = "sha384"
    SHA512 = "sha512"
    BLAKE2B = "blake2b"
    BLAKE2S = "blake2s"


@dataclass
class HashResult:
    algorithm: str
    digest: bytes
    hex_digest: str

    def __str__(self) -> str:
        return self.hex_digest

    def __eq__(self, other: Any) -> bool:
        if isinstance(other, HashResult):
            return hmac.compare_digest(self.digest, other.digest)
        if isinstance(other, str):
            return hmac.compare_digest(self.hex_digest, other)
        if isinstance(other, bytes):
            return hmac.compare_digest(self.digest, other)
        return False


class Hasher:
    def __init__(self, algorithm: Union[HashAlgorithm, str] = HashAlgorithm.SHA256):
        self.algorithm = algorithm.value if isinstance(algorithm, HashAlgorithm) else algorithm
        self._hasher = hashlib.new(self.algorithm)

    def update(self, data: Union[str, bytes]) -> "Hasher":
        if isinstance(data, str):
            data = data.encode("utf-8")
        self._hasher.update(data)
        return self

    def digest(self) -> HashResult:
        d = self._hasher.digest()
        return HashResult(algorithm=self.algorithm, digest=d, hex_digest=d.hex())

    def hex_digest(self) -> str:
        return self._hasher.hexdigest()


def hash_data(data: Union[str, bytes], algorithm: Union[HashAlgorithm, str] = HashAlgorithm.SHA256) -> HashResult:
    return Hasher(algorithm).update(data).digest()


def hash_file(path: str, algorithm: Union[HashAlgorithm, str] = HashAlgorithm.SHA256, chunk_size: int = 8192) -> HashResult:
    hasher = Hasher(algorithm)
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            hasher.update(chunk)
    return hasher.digest()


def hmac_hash(key: Union[str, bytes], data: Union[str, bytes], algorithm: Union[HashAlgorithm, str] = HashAlgorithm.SHA256) -> HashResult:
    if isinstance(key, str):
        key = key.encode("utf-8")
    if isinstance(data, str):
        data = data.encode("utf-8")
    alg = algorithm.value if isinstance(algorithm, HashAlgorithm) else algorithm
    h = hmac.new(key, data, alg)
    return HashResult(algorithm=f"hmac-{alg}", digest=h.digest(), hex_digest=h.hexdigest())


def verify_hmac(key: Union[str, bytes], data: Union[str, bytes], signature: Union[str, bytes], algorithm: Union[HashAlgorithm, str] = HashAlgorithm.SHA256) -> bool:
    computed = hmac_hash(key, data, algorithm)
    if isinstance(signature, str):
        return hmac.compare_digest(computed.hex_digest, signature)
    return hmac.compare_digest(computed.digest, signature)


class MurmurHash3:
    @staticmethod
    def hash32(data: Union[str, bytes], seed: int = 0) -> int:
        if isinstance(data, str):
            data = data.encode("utf-8")
        c1 = 0xcc9e2d51
        c2 = 0x1b873593
        h1 = seed
        length = len(data)
        for i in range(0, length - 3, 4):
            k1 = struct.unpack("<I", data[i:i+4])[0]
            k1 = (k1 * c1) & 0xffffffff
            k1 = ((k1 << 15) | (k1 >> 17)) & 0xffffffff
            k1 = (k1 * c2) & 0xffffffff
            h1 ^= k1
            h1 = ((h1 << 13) | (h1 >> 19)) & 0xffffffff
            h1 = ((h1 * 5) + 0xe6546b64) & 0xffffffff
        h1 ^= length
        h1 ^= h1 >> 16
        h1 = (h1 * 0x85ebca6b) & 0xffffffff
        h1 ^= h1 >> 13
        h1 = (h1 * 0xc2b2ae35) & 0xffffffff
        h1 ^= h1 >> 16
        return h1


def checksum_crc32(data: Union[str, bytes]) -> int:
    import zlib
    if isinstance(data, str):
        data = data.encode("utf-8")
    return zlib.crc32(data) & 0xffffffff


def checksum_adler32(data: Union[str, bytes]) -> int:
    import zlib
    if isinstance(data, str):
        data = data.encode("utf-8")
    return zlib.adler32(data) & 0xffffffff


def example_usage():
    data = "Hello, BlackRoad!"
    print(f"SHA256: {hash_data(data, HashAlgorithm.SHA256)}")
    print(f"SHA512: {hash_data(data, HashAlgorithm.SHA512)}")
    print(f"MD5: {hash_data(data, HashAlgorithm.MD5)}")
    key = "secret-key"
    sig = hmac_hash(key, data)
    print(f"HMAC-SHA256: {sig}")
    print(f"Verified: {verify_hmac(key, data, sig.hex_digest)}")
    print(f"Murmur3-32: {MurmurHash3.hash32(data)}")
    print(f"CRC32: {checksum_crc32(data)}")
