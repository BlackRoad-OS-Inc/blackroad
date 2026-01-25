"""
Contradiction Log Module for Lucidia.

This module provides simple functions to log contradictions to a JSON file.
It is part of the truth operation to ensure that when the system falls back
or forgets, the event is recorded as a contradiction.

Functions:
    - log_contradiction(event: str) -> None: Append a contradiction with timestamp to the log.
    - load_log(file_path: str = LOG_FILE) -> List[Dict[str, Any]]: Load the contradictions log.

"""

import json
import os
from datetime import datetime
from typing import Any, Dict, List

LOG_FILE = os.path.join(os.path.dirname(__file__), 'contradictions.json')


def load_log(file_path: str = LOG_FILE) -> List[Dict[str, Any]]:
    """
    Load the list of logged contradictions from a JSON file.

    If the file does not exist or cannot be parsed, returns an empty list.
    """
    if not os.path.exists(file_path):
        return []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        # Return empty on failure
        return []


def log_contradiction(event: str, file_path: str = LOG_FILE) -> None:
    """
    Append a contradiction event to the log with a UTC timestamp.

    Each event is stored as a dictionary with 'timestamp' and 'event' keys.
    """
    log = load_log(file_path)
    log_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'event': event,
    }
    log.append(log_entry)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(log, f, indent=2)
