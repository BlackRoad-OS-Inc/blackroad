"""Security/Crypto utility skills for encryption, auth, and vulnerability analysis.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

This software is proprietary and confidential. Unauthorized copying, transfer,
or reproduction of this file, via any medium, is strictly prohibited.

Licensed for non-commercial testing and evaluation purposes only.
Commercial use requires a separate license agreement with BlackRoad OS, Inc.

For licensing inquiries: legal@blackroad.io
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import re
import secrets
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Set, Tuple
from urllib.parse import parse_qs, urlparse


@dataclass
class VulnerabilityFinding:
    """A security vulnerability finding."""

    severity: str  # critical, high, medium, low, info
    category: str
    description: str
    location: Optional[str] = None
    line_number: Optional[int] = None
    recommendation: Optional[str] = None
    cwe_id: Optional[str] = None


@dataclass
class SecretFinding:
    """A detected secret or sensitive data."""

    secret_type: str
    pattern_matched: str
    location: str
    line_number: int
    masked_value: str
    confidence: str  # high, medium, low


# ============================================================================
# Hashing & Encoding
# ============================================================================


def hash_sha256(data: str | bytes) -> str:
    """Generate SHA-256 hash."""
    if isinstance(data, str):
        data = data.encode()
    return hashlib.sha256(data).hexdigest()


def hash_sha512(data: str | bytes) -> str:
    """Generate SHA-512 hash."""
    if isinstance(data, str):
        data = data.encode()
    return hashlib.sha512(data).hexdigest()


def hash_md5(data: str | bytes) -> str:
    """Generate MD5 hash (for checksums, not security)."""
    if isinstance(data, str):
        data = data.encode()
    return hashlib.md5(data).hexdigest()


def hash_blake2b(data: str | bytes, digest_size: int = 32) -> str:
    """Generate BLAKE2b hash."""
    if isinstance(data, str):
        data = data.encode()
    return hashlib.blake2b(data, digest_size=digest_size).hexdigest()


def hash_password(password: str, salt: Optional[str] = None) -> Tuple[str, str]:
    """Hash a password with salt using PBKDF2.

    Returns (hash, salt) tuple.
    """
    if salt is None:
        salt = secrets.token_hex(16)

    key = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode(),
        salt.encode(),
        iterations=100000,
    )

    return base64.b64encode(key).decode(), salt


def verify_password(password: str, stored_hash: str, salt: str) -> bool:
    """Verify a password against stored hash."""
    computed_hash, _ = hash_password(password, salt)
    return hmac.compare_digest(computed_hash, stored_hash)


def base64_encode(data: str | bytes) -> str:
    """Base64 encode data."""
    if isinstance(data, str):
        data = data.encode()
    return base64.b64encode(data).decode()


def base64_decode(data: str) -> bytes:
    """Base64 decode data."""
    return base64.b64decode(data)


def base64url_encode(data: str | bytes) -> str:
    """URL-safe Base64 encode (for JWTs)."""
    if isinstance(data, str):
        data = data.encode()
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def base64url_decode(data: str) -> bytes:
    """URL-safe Base64 decode."""
    padding = 4 - len(data) % 4
    if padding != 4:
        data += '=' * padding
    return base64.urlsafe_b64decode(data)


# ============================================================================
# Token Generation
# ============================================================================


def generate_token(length: int = 32) -> str:
    """Generate a cryptographically secure random token."""
    return secrets.token_hex(length)


def generate_api_key(prefix: str = "br") -> str:
    """Generate an API key with prefix."""
    random_part = secrets.token_urlsafe(32)
    return f"{prefix}_{random_part}"


def generate_uuid() -> str:
    """Generate a UUID4."""
    import uuid
    return str(uuid.uuid4())


def generate_otp(length: int = 6) -> str:
    """Generate a numeric OTP."""
    return ''.join(secrets.choice('0123456789') for _ in range(length))


def generate_passphrase(words: int = 4, separator: str = "-") -> str:
    """Generate a passphrase from common words."""
    wordlist = [
        "apple", "banana", "cherry", "delta", "echo", "foxtrot", "golf",
        "hotel", "india", "juliet", "kilo", "lima", "mike", "november",
        "oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform",
        "victor", "whiskey", "xray", "yankee", "zulu", "alpha", "bravo",
        "charlie", "quantum", "cosmic", "stellar", "lunar", "solar",
        "thunder", "lightning", "crystal", "shadow", "phoenix", "dragon",
    ]
    return separator.join(secrets.choice(wordlist) for _ in range(words))


# ============================================================================
# JWT Operations (without external libraries)
# ============================================================================


def create_jwt(
    payload: Dict[str, Any],
    secret: str,
    expires_in: int = 3600,
) -> str:
    """Create a simple JWT (HS256)."""
    header = {"alg": "HS256", "typ": "JWT"}

    # Add standard claims
    now = int(time.time())
    payload["iat"] = now
    payload["exp"] = now + expires_in

    # Encode
    header_b64 = base64url_encode(json.dumps(header))
    payload_b64 = base64url_encode(json.dumps(payload))

    # Sign
    message = f"{header_b64}.{payload_b64}"
    signature = hmac.new(
        secret.encode(),
        message.encode(),
        hashlib.sha256
    ).digest()
    signature_b64 = base64url_encode(signature)

    return f"{header_b64}.{payload_b64}.{signature_b64}"


def verify_jwt(token: str, secret: str) -> Tuple[bool, Optional[Dict[str, Any]]]:
    """Verify a JWT and return payload if valid."""
    try:
        parts = token.split('.')
        if len(parts) != 3:
            return False, None

        header_b64, payload_b64, signature_b64 = parts

        # Verify signature
        message = f"{header_b64}.{payload_b64}"
        expected_sig = hmac.new(
            secret.encode(),
            message.encode(),
            hashlib.sha256
        ).digest()

        actual_sig = base64url_decode(signature_b64)

        if not hmac.compare_digest(expected_sig, actual_sig):
            return False, None

        # Decode payload
        payload = json.loads(base64url_decode(payload_b64))

        # Check expiration
        if "exp" in payload and payload["exp"] < time.time():
            return False, None

        return True, payload

    except Exception:
        return False, None


def decode_jwt_unsafe(token: str) -> Optional[Dict[str, Any]]:
    """Decode JWT without verification (for inspection only)."""
    try:
        parts = token.split('.')
        if len(parts) != 3:
            return None
        payload_b64 = parts[1]
        return json.loads(base64url_decode(payload_b64))
    except Exception:
        return None


# ============================================================================
# Secret Detection
# ============================================================================


SECRET_PATTERNS = [
    ("AWS Access Key", r"AKIA[0-9A-Z]{16}", "high"),
    ("AWS Secret Key", r"[0-9a-zA-Z/+]{40}", "medium"),
    ("GitHub Token", r"ghp_[a-zA-Z0-9]{36}", "high"),
    ("GitHub Token (old)", r"github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}", "high"),
    ("Slack Token", r"xox[baprs]-[0-9a-zA-Z-]{10,}", "high"),
    ("Stripe Key", r"sk_live_[0-9a-zA-Z]{24}", "high"),
    ("Stripe Test Key", r"sk_test_[0-9a-zA-Z]{24}", "medium"),
    ("Private Key", r"-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----", "high"),
    ("Generic API Key", r"api[_-]?key['\"]?\s*[:=]\s*['\"][a-zA-Z0-9]{16,}['\"]", "medium"),
    ("Generic Secret", r"secret['\"]?\s*[:=]\s*['\"][a-zA-Z0-9]{16,}['\"]", "medium"),
    ("Password Assignment", r"password['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]", "medium"),
    ("Bearer Token", r"Bearer\s+[a-zA-Z0-9_\-\.]+", "low"),
    ("Basic Auth", r"Basic\s+[a-zA-Z0-9+/=]{20,}", "medium"),
    ("Cloudflare Token", r"[a-zA-Z0-9_-]{40}", "low"),
    ("JWT", r"eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*", "medium"),
]


def scan_for_secrets(
    content: str,
    filename: Optional[str] = None,
) -> List[SecretFinding]:
    """Scan content for potential secrets and sensitive data."""
    findings = []
    lines = content.split('\n')

    for line_num, line in enumerate(lines, 1):
        for secret_type, pattern, confidence in SECRET_PATTERNS:
            matches = re.finditer(pattern, line, re.IGNORECASE)
            for match in matches:
                # Mask the secret
                value = match.group()
                if len(value) > 8:
                    masked = value[:4] + '*' * (len(value) - 8) + value[-4:]
                else:
                    masked = '*' * len(value)

                findings.append(SecretFinding(
                    secret_type=secret_type,
                    pattern_matched=pattern,
                    location=filename or "content",
                    line_number=line_num,
                    masked_value=masked,
                    confidence=confidence,
                ))

    return findings


def is_likely_secret(value: str) -> bool:
    """Check if a string looks like a secret (high entropy)."""
    if len(value) < 8:
        return False

    # Check entropy
    entropy = calculate_entropy(value)
    if entropy > 4.5:
        return True

    # Check for secret-like patterns
    for _, pattern, _ in SECRET_PATTERNS:
        if re.match(pattern, value):
            return True

    return False


def calculate_entropy(data: str) -> float:
    """Calculate Shannon entropy of a string."""
    import math

    if not data:
        return 0.0

    freq: Dict[str, int] = {}
    for char in data:
        freq[char] = freq.get(char, 0) + 1

    entropy = 0.0
    length = len(data)
    for count in freq.values():
        probability = count / length
        entropy -= probability * math.log2(probability)

    return entropy


# ============================================================================
# Vulnerability Scanning
# ============================================================================


def scan_code_vulnerabilities(
    code: str,
    language: str = "python",
) -> List[VulnerabilityFinding]:
    """Scan code for common vulnerabilities."""
    findings = []
    lines = code.split('\n')

    if language in ("python", "py"):
        findings.extend(_scan_python_vulns(lines))
    elif language in ("javascript", "js", "typescript", "ts"):
        findings.extend(_scan_js_vulns(lines))
    elif language in ("sql",):
        findings.extend(_scan_sql_vulns(lines))

    # General patterns
    findings.extend(_scan_general_vulns(lines))

    return findings


def _scan_python_vulns(lines: List[str]) -> List[VulnerabilityFinding]:
    """Scan Python code for vulnerabilities."""
    findings = []

    patterns = [
        (r"eval\s*\(", "high", "Code Injection", "Use of eval() is dangerous", "CWE-94"),
        (r"exec\s*\(", "high", "Code Injection", "Use of exec() is dangerous", "CWE-94"),
        (r"pickle\.loads?\s*\(", "high", "Deserialization", "Pickle deserialization is unsafe with untrusted data", "CWE-502"),
        (r"yaml\.load\s*\([^,]+\)", "medium", "Deserialization", "Use yaml.safe_load() instead", "CWE-502"),
        (r"shell\s*=\s*True", "high", "Command Injection", "shell=True enables command injection", "CWE-78"),
        (r"subprocess\.(call|run|Popen).*shell\s*=\s*True", "high", "Command Injection", "subprocess with shell=True", "CWE-78"),
        (r"os\.system\s*\(", "medium", "Command Injection", "os.system() may allow injection", "CWE-78"),
        (r"__import__\s*\(", "medium", "Dynamic Import", "Dynamic imports can be dangerous", "CWE-94"),
        (r"input\s*\(", "low", "Input Handling", "Ensure input is validated", "CWE-20"),
        (r"DEBUG\s*=\s*True", "medium", "Configuration", "Debug mode should be disabled in production", "CWE-489"),
        (r"verify\s*=\s*False", "high", "SSL Verification", "SSL verification disabled", "CWE-295"),
        (r"password\s*=\s*['\"][^'\"]+['\"]", "medium", "Hardcoded Credentials", "Hardcoded password detected", "CWE-798"),
    ]

    for line_num, line in enumerate(lines, 1):
        for pattern, severity, category, description, cwe in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append(VulnerabilityFinding(
                    severity=severity,
                    category=category,
                    description=description,
                    line_number=line_num,
                    location=line.strip()[:80],
                    cwe_id=cwe,
                ))

    return findings


def _scan_js_vulns(lines: List[str]) -> List[VulnerabilityFinding]:
    """Scan JavaScript/TypeScript for vulnerabilities."""
    findings = []

    patterns = [
        (r"eval\s*\(", "high", "Code Injection", "Use of eval() is dangerous", "CWE-94"),
        (r"innerHTML\s*=", "medium", "XSS", "innerHTML can lead to XSS", "CWE-79"),
        (r"document\.write\s*\(", "medium", "XSS", "document.write can lead to XSS", "CWE-79"),
        (r"dangerouslySetInnerHTML", "medium", "XSS", "React dangerouslySetInnerHTML requires caution", "CWE-79"),
        (r"localStorage\.(set|get)Item.*password", "medium", "Sensitive Storage", "Passwords in localStorage", "CWE-922"),
        (r"new\s+Function\s*\(", "high", "Code Injection", "new Function() is like eval()", "CWE-94"),
        (r"child_process\.(exec|spawn).*\$\{", "high", "Command Injection", "Template literal in shell command", "CWE-78"),
        (r"\$\{.*\}\s*\+?\s*['\"]", "low", "Injection", "Check for injection in string interpolation", "CWE-89"),
        (r"require\s*\(\s*[a-zA-Z_]+\s*\)", "low", "Dynamic Require", "Dynamic require may be dangerous", "CWE-94"),
    ]

    for line_num, line in enumerate(lines, 1):
        for pattern, severity, category, description, cwe in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append(VulnerabilityFinding(
                    severity=severity,
                    category=category,
                    description=description,
                    line_number=line_num,
                    location=line.strip()[:80],
                    cwe_id=cwe,
                ))

    return findings


def _scan_sql_vulns(lines: List[str]) -> List[VulnerabilityFinding]:
    """Scan SQL for vulnerabilities."""
    findings = []

    patterns = [
        (r"['\"].*\+.*['\"]", "high", "SQL Injection", "String concatenation in SQL query", "CWE-89"),
        (r"\$\{[^}]+\}", "high", "SQL Injection", "Template interpolation in SQL", "CWE-89"),
        (r"%s|%d|\?", "info", "Parameterized", "Parameterized query (good practice)", None),
        (r"GRANT\s+ALL", "medium", "Overprivileged", "Granting all privileges", "CWE-269"),
        (r"--\s*password", "low", "Comment", "Password mentioned in comment", "CWE-615"),
    ]

    for line_num, line in enumerate(lines, 1):
        for pattern, severity, category, description, cwe in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                if severity != "info":
                    findings.append(VulnerabilityFinding(
                        severity=severity,
                        category=category,
                        description=description,
                        line_number=line_num,
                        location=line.strip()[:80],
                        cwe_id=cwe,
                    ))

    return findings


def _scan_general_vulns(lines: List[str]) -> List[VulnerabilityFinding]:
    """Scan for general vulnerabilities."""
    findings = []

    patterns = [
        (r"TODO.*security", "low", "Technical Debt", "Security-related TODO", None),
        (r"FIXME.*auth", "medium", "Technical Debt", "Auth-related FIXME", None),
        (r"0\.0\.0\.0", "low", "Network", "Binding to all interfaces", "CWE-668"),
        (r"http://(?!localhost|127\.0\.0\.1)", "low", "Transport", "Non-HTTPS URL", "CWE-319"),
    ]

    for line_num, line in enumerate(lines, 1):
        for pattern, severity, category, description, cwe in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append(VulnerabilityFinding(
                    severity=severity,
                    category=category,
                    description=description,
                    line_number=line_num,
                    location=line.strip()[:80],
                    cwe_id=cwe,
                ))

    return findings


# ============================================================================
# URL/Input Validation
# ============================================================================


def validate_url(url: str, allowed_schemes: Optional[Set[str]] = None) -> Tuple[bool, Optional[str]]:
    """Validate a URL and check for SSRF risks.

    Returns (is_valid, error_message).
    """
    allowed_schemes = allowed_schemes or {"http", "https"}

    try:
        parsed = urlparse(url)

        if parsed.scheme not in allowed_schemes:
            return False, f"Invalid scheme: {parsed.scheme}"

        if not parsed.netloc:
            return False, "No host specified"

        # Check for private IP ranges (SSRF protection)
        host = parsed.hostname or ""
        private_patterns = [
            r"^localhost$",
            r"^127\.",
            r"^10\.",
            r"^172\.(1[6-9]|2[0-9]|3[01])\.",
            r"^192\.168\.",
            r"^169\.254\.",
            r"^::1$",
            r"^fc00:",
            r"^fe80:",
        ]

        for pattern in private_patterns:
            if re.match(pattern, host, re.IGNORECASE):
                return False, f"Private/internal address not allowed: {host}"

        return True, None

    except Exception as e:
        return False, str(e)


def sanitize_filename(filename: str) -> str:
    """Sanitize a filename to prevent path traversal."""
    # Remove path components
    filename = os.path.basename(filename)

    # Remove dangerous characters
    filename = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '', filename)

    # Remove leading dots and spaces
    filename = filename.lstrip('. ')

    # Ensure not empty
    if not filename:
        filename = "unnamed"

    return filename


def validate_email(email: str) -> bool:
    """Basic email format validation."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def check_password_strength(password: str) -> Dict[str, Any]:
    """Check password strength and return analysis."""
    result = {
        "length": len(password),
        "has_lowercase": bool(re.search(r'[a-z]', password)),
        "has_uppercase": bool(re.search(r'[A-Z]', password)),
        "has_digit": bool(re.search(r'\d', password)),
        "has_special": bool(re.search(r'[!@#$%^&*(),.?":{}|<>]', password)),
        "entropy": calculate_entropy(password),
        "common_pattern": False,
        "score": 0,
        "strength": "weak",
    }

    # Check common patterns
    common_patterns = [
        r"^password",
        r"^123456",
        r"^qwerty",
        r"^admin",
        r"^letmein",
        r"^welcome",
        r"^monkey",
        r"^dragon",
    ]

    for pattern in common_patterns:
        if re.match(pattern, password.lower()):
            result["common_pattern"] = True
            break

    # Calculate score
    score = 0
    if result["length"] >= 8:
        score += 1
    if result["length"] >= 12:
        score += 1
    if result["length"] >= 16:
        score += 1
    if result["has_lowercase"]:
        score += 1
    if result["has_uppercase"]:
        score += 1
    if result["has_digit"]:
        score += 1
    if result["has_special"]:
        score += 1
    if result["entropy"] > 3:
        score += 1
    if result["entropy"] > 4:
        score += 1
    if not result["common_pattern"]:
        score += 1

    result["score"] = score

    if score >= 8:
        result["strength"] = "strong"
    elif score >= 5:
        result["strength"] = "medium"
    else:
        result["strength"] = "weak"

    return result
