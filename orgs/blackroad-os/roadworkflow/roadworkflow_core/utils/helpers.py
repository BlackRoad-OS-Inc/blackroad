"""Helper Utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import re
import time
import uuid
from datetime import timedelta
from typing import Any, Dict, List, Optional, Union


def generate_id(prefix: str = "", length: int = 8) -> str:
    """Generate unique identifier.

    Args:
        prefix: Optional prefix
        length: ID length

    Returns:
        Unique identifier
    """
    unique = str(uuid.uuid4()).replace("-", "")[:length]
    if prefix:
        return f"{prefix}_{unique}"
    return unique


def format_duration(seconds: float) -> str:
    """Format duration as human-readable string.

    Args:
        seconds: Duration in seconds

    Returns:
        Formatted string (e.g., "1h 23m 45s")
    """
    if seconds < 0:
        return "0s"

    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    ms = int((seconds % 1) * 1000)

    parts = []
    if hours > 0:
        parts.append(f"{hours}h")
    if minutes > 0:
        parts.append(f"{minutes}m")
    if secs > 0 or not parts:
        if ms > 0 and hours == 0:
            parts.append(f"{secs}.{ms:03d}s")
        else:
            parts.append(f"{secs}s")

    return " ".join(parts)


def parse_duration(duration_str: str) -> float:
    """Parse duration string to seconds.

    Args:
        duration_str: Duration string (e.g., "1h30m", "45s", "500ms")

    Returns:
        Duration in seconds
    """
    total_seconds = 0.0

    patterns = [
        (r"(\d+(?:\.\d+)?)\s*d(?:ays?)?", 86400),
        (r"(\d+(?:\.\d+)?)\s*h(?:ours?)?", 3600),
        (r"(\d+(?:\.\d+)?)\s*m(?:in(?:utes?)?)?(?!s)", 60),
        (r"(\d+(?:\.\d+)?)\s*s(?:ec(?:onds?)?)?(?!m)", 1),
        (r"(\d+(?:\.\d+)?)\s*ms(?:ec)?", 0.001),
    ]

    for pattern, multiplier in patterns:
        for match in re.finditer(pattern, duration_str, re.IGNORECASE):
            total_seconds += float(match.group(1)) * multiplier

    if total_seconds == 0 and duration_str.strip().isdigit():
        total_seconds = float(duration_str.strip())

    return total_seconds


def deep_merge(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    """Deep merge two dictionaries.

    Args:
        base: Base dictionary
        override: Override dictionary

    Returns:
        Merged dictionary
    """
    result = base.copy()

    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value

    return result


def flatten_dict(
    d: Dict[str, Any],
    parent_key: str = "",
    separator: str = ".",
) -> Dict[str, Any]:
    """Flatten nested dictionary.

    Args:
        d: Dictionary to flatten
        parent_key: Parent key prefix
        separator: Key separator

    Returns:
        Flattened dictionary
    """
    items: List[tuple] = []

    for key, value in d.items():
        new_key = f"{parent_key}{separator}{key}" if parent_key else key

        if isinstance(value, dict):
            items.extend(flatten_dict(value, new_key, separator).items())
        else:
            items.append((new_key, value))

    return dict(items)


def unflatten_dict(d: Dict[str, Any], separator: str = ".") -> Dict[str, Any]:
    """Unflatten dictionary.

    Args:
        d: Flattened dictionary
        separator: Key separator

    Returns:
        Nested dictionary
    """
    result: Dict[str, Any] = {}

    for key, value in d.items():
        parts = key.split(separator)
        current = result

        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]

        current[parts[-1]] = value

    return result


def hash_content(content: Union[str, bytes]) -> str:
    """Generate content hash.

    Args:
        content: Content to hash

    Returns:
        SHA-256 hash
    """
    if isinstance(content, str):
        content = content.encode("utf-8")
    return hashlib.sha256(content).hexdigest()


def retry_with_backoff(
    func,
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
):
    """Execute function with exponential backoff retry.

    Args:
        func: Function to execute
        max_retries: Maximum retry attempts
        base_delay: Base delay between retries
        max_delay: Maximum delay
        exponential_base: Backoff multiplier
    """
    last_exception = None

    for attempt in range(max_retries + 1):
        try:
            return func()
        except Exception as e:
            last_exception = e
            if attempt < max_retries:
                delay = min(base_delay * (exponential_base ** attempt), max_delay)
                time.sleep(delay)

    raise last_exception


def chunk_list(lst: List[Any], chunk_size: int) -> List[List[Any]]:
    """Split list into chunks.

    Args:
        lst: List to chunk
        chunk_size: Size of each chunk

    Returns:
        List of chunks
    """
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]


def safe_get(d: Dict[str, Any], *keys: str, default: Any = None) -> Any:
    """Safely get nested dictionary value.

    Args:
        d: Dictionary
        *keys: Key path
        default: Default value if not found

    Returns:
        Value or default
    """
    current = d

    for key in keys:
        if isinstance(current, dict) and key in current:
            current = current[key]
        else:
            return default

    return current


def truncate_string(s: str, max_length: int = 100, suffix: str = "...") -> str:
    """Truncate string to max length.

    Args:
        s: String to truncate
        max_length: Maximum length
        suffix: Suffix for truncated strings

    Returns:
        Truncated string
    """
    if len(s) <= max_length:
        return s
    return s[:max_length - len(suffix)] + suffix


__all__ = [
    "generate_id",
    "format_duration",
    "parse_duration",
    "deep_merge",
    "flatten_dict",
    "unflatten_dict",
    "hash_content",
    "retry_with_backoff",
    "chunk_list",
    "safe_get",
    "truncate_string",
]
