"""
Memory manager for Lucidia.

This module provides simple functions to load and save memory state to a JSON file.
It is designed to be used by Lucidia agents to persist conversation history or other
data across sessions. This is not a fully fledged AI memory system but a simple
 demonstration to show how persistent storage could work.
"""

import json
import os
from typing import Any, Dict, Optional

# Default path for storing memory
MEMORY_FILE = os.path.join(os.path.dirname(__file__), 'memory.json')

def load_memory(file_path: str = MEMORY_FILE) -> Dict[str, Any]:
    """Load memory from a JSON file.

    If the file does not exist or cannot be parsed, an empty dictionary is returned.
    """
    if not os.path.exists(file_path):
        return {}
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        # Return empty memory on failure
        return {}

def save_memory(memory: Dict[str, Any], file_path: str = MEMORY_FILE) -> None:
    """Save memory dictionary to a JSON file."""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(memory, f, indent=2)

class MemoryManager:
    """Class to manage memory state for Lucidia agents."""

    def __init__(self, file_path: str = MEMORY_FILE) -> None:
        self.file_path = file_path
        self.memory: Dict[str, Any] = load_memory(self.file_path)

    def get(self, key: str, default: Optional[Any] = None) -> Any:
        """Retrieve a value from memory."""
        return self.memory.get(key, default)

    def set(self, key: str, value: Any) -> None:
        """Set a value in memory and persist it."""
        self.memory[key] = value
        self.save()

    def delete(self, key: str) -> None:
        """Remove a key from memory and persist the change."""
        if key in self.memory:
            del self.memory[key]
            self.save()

    def save(self) -> None:
        """Persist the current memory state to file."""
        save_memory(self.memory, self.file_path)
