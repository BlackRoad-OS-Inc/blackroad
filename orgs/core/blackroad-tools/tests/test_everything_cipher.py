"""Tests for everything_cipher — Argon2id + AES-256-GCM encryption."""

import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from everything_cipher import encrypt, decrypt, _b64e, _b64d, _parse_header, HEADER_VERSION


class TestBase64Helpers:
    def test_roundtrip(self):
        data = b"hello world"
        assert _b64d(_b64e(data)) == data

    def test_padding_stripped(self):
        encoded = _b64e(b"hi")
        assert "=" not in encoded


class TestEncryptDecrypt:
    def test_roundtrip(self):
        plaintext = b"BlackRoad OS secret message"
        passphrase = "test-passphrase-123"
        blob = encrypt(plaintext, passphrase)
        recovered = decrypt(blob, passphrase)
        assert recovered == plaintext

    def test_empty_plaintext(self):
        blob = encrypt(b"", "pass")
        assert decrypt(blob, "pass") == b""

    def test_wrong_passphrase_fails(self):
        blob = encrypt(b"secret", "correct")
        with pytest.raises(Exception):
            decrypt(blob, "wrong")

    def test_header_format(self):
        blob = encrypt(b"data", "pass")
        assert blob.startswith(HEADER_VERSION + "|")
        tokens = blob.split("|")
        assert len(tokens) >= 7


class TestParseHeader:
    def test_valid_header(self):
        blob = encrypt(b"test", "pass")
        params = _parse_header(blob)
        assert params["kdf"] == "argon2id"
        assert "salt" in params
        assert "nonce" in params
        assert "ct" in params

    def test_invalid_header_raises(self):
        with pytest.raises(ValueError, match="Unsupported"):
            _parse_header("INVALID|header")
