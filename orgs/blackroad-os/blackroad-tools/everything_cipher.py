#!/usr/bin/env python3
"""Reference implementation of the Everything Cipher (v1).

This script provides both library-style helpers and a simple CLI for
encrypting/decrypting byte streams using the "Everything Cipher" recipe. It
implements Argon2id for passphrase stretching, HKDF for domain-separated key
material, and AES-256-GCM for authenticated encryption.  The context label is
bound as AEAD associated data to enforce the "Peter Panda" lock described in
internal security notes.
"""
from __future__ import annotations

import argparse
import base64
import getpass
import os
import sys
from dataclasses import dataclass
from typing import Dict

from argon2.low_level import Type as Argon2Type
from argon2.low_level import hash_secret_raw
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

# ---- Tunable parameters ----------------------------------------------------

ARGON2_MEMORY_MB = 64
ARGON2_TIME = 3
ARGON2_PARALLELISM = 1
AAD = b"Peter Panda Dance v1"
HKDF_INFO_CONTENT = b"EV1/aes-gcm/content"
HEADER_VERSION = "EV1"
KDF_NAME = "argon2id"


def _b64e(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("utf-8").rstrip("=")


def _b64d(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


@dataclass
class CipherParams:
    argon2_memory_mb: int
    argon2_time: int
    argon2_parallelism: int
    salt: bytes
    hkdf_salt: bytes
    nonce: bytes
    ciphertext: bytes

    def header_tokens(self) -> Dict[str, str]:
        return {
            "kdf": KDF_NAME,
            "argon2_params": f"m={self.argon2_memory_mb}MB,t={self.argon2_time},p={self.argon2_parallelism}",
            "salt": _b64e(self.salt),
            "hkdf_salt": _b64e(self.hkdf_salt),
            "nonce": _b64e(self.nonce),
            "ct": _b64e(self.ciphertext),
        }


def _derive_root_key(passphrase: str, salt: bytes) -> bytes:
    return hash_secret_raw(
        secret=passphrase.encode("utf-8"),
        salt=salt,
        time_cost=ARGON2_TIME,
        memory_cost=ARGON2_MEMORY_MB * 1024,
        parallelism=ARGON2_PARALLELISM,
        hash_len=32,
        type=Argon2Type.ID,
        version=19,
    )


def _derive_encryption_key(root_key: bytes, hkdf_salt: bytes) -> bytes:
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=hkdf_salt,
        info=HKDF_INFO_CONTENT,
    )
    return hkdf.derive(root_key)


def encrypt(plaintext: bytes, passphrase: str) -> str:
    salt = os.urandom(16)
    hkdf_salt = os.urandom(16)
    nonce = os.urandom(12)

    root_key = _derive_root_key(passphrase, salt)
    enc_key = _derive_encryption_key(root_key, hkdf_salt)

    aes = AESGCM(enc_key)
    ciphertext = aes.encrypt(nonce, plaintext, AAD)

    params = CipherParams(
        argon2_memory_mb=ARGON2_MEMORY_MB,
        argon2_time=ARGON2_TIME,
        argon2_parallelism=ARGON2_PARALLELISM,
        salt=salt,
        hkdf_salt=hkdf_salt,
        nonce=nonce,
        ciphertext=ciphertext,
    )

    header = params.header_tokens()
    tokens = [HEADER_VERSION, f"kdf={KDF_NAME}", header["argon2_params"]]
    for key in ("salt", "hkdf_salt", "nonce", "ct"):
        tokens.append(f"{key}={header[key]}")
    return "|".join(tokens)


def _parse_header(blob: str) -> Dict[str, str]:
    tokens = blob.split("|")
    if len(tokens) < 7 or tokens[0] != HEADER_VERSION:
        raise ValueError("Unsupported or corrupted Everything Cipher header")

    params: Dict[str, str] = {}
    for token in tokens[1:]:
        if token.startswith("m="):
            params["argon2_params"] = token
            continue
        if "=" not in token:
            raise ValueError("Malformed header token")
        key, value = token.split("=", 1)
        params[key] = value
    return params


def decrypt(blob: str, passphrase: str) -> bytes:
    params = _parse_header(blob)
    if params.get("kdf") != KDF_NAME:
        raise ValueError("Unsupported KDF declared in header")

    salt = _b64d(params["salt"])
    hkdf_salt = _b64d(params["hkdf_salt"])
    nonce = _b64d(params["nonce"])
    ciphertext = _b64d(params["ct"])

    root_key = _derive_root_key(passphrase, salt)
    enc_key = _derive_encryption_key(root_key, hkdf_salt)

    aes = AESGCM(enc_key)
    return aes.decrypt(nonce, ciphertext, AAD)


def _cli(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Everything Cipher (EV1)")
    parser.add_argument("mode", choices=["enc", "dec"], help="encrypt or decrypt")
    args = parser.parse_args(argv)

    data = sys.stdin.buffer.read()
    passphrase = getpass.getpass("Passphrase: ")

    if args.mode == "enc":
        blob = encrypt(data, passphrase)
        sys.stdout.write(blob)
    else:
        plaintext = decrypt(data.decode("utf-8"), passphrase)
        sys.stdout.buffer.write(plaintext)
    return 0


if __name__ == "__main__":
    raise SystemExit(_cli(sys.argv[1:]))
