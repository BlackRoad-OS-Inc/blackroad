"""
RoadDiff - Diff/Patch Utilities for BlackRoad
Compare and patch data structures, text, and files.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple, Union
import difflib
import hashlib
import json
import logging
import copy

logger = logging.getLogger(__name__)


class DiffOperation(str, Enum):
    """Diff operations."""
    ADD = "add"
    REMOVE = "remove"
    REPLACE = "replace"
    MOVE = "move"
    COPY = "copy"
    UNCHANGED = "unchanged"


@dataclass
class DiffEntry:
    """A single diff entry."""
    operation: DiffOperation
    path: str
    old_value: Any = None
    new_value: Any = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "op": self.operation.value,
            "path": self.path,
            "old": self.old_value,
            "new": self.new_value
        }


@dataclass
class DiffResult:
    """Result of a diff operation."""
    entries: List[DiffEntry] = field(default_factory=list)
    stats: Dict[str, int] = field(default_factory=dict)

    def __post_init__(self):
        self._calculate_stats()

    def _calculate_stats(self):
        self.stats = {op.value: 0 for op in DiffOperation}
        for entry in self.entries:
            self.stats[entry.operation.value] += 1

    @property
    def has_changes(self) -> bool:
        return any(e.operation != DiffOperation.UNCHANGED for e in self.entries)

    @property
    def additions(self) -> int:
        return self.stats.get("add", 0)

    @property
    def deletions(self) -> int:
        return self.stats.get("remove", 0)

    @property
    def modifications(self) -> int:
        return self.stats.get("replace", 0)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "entries": [e.to_dict() for e in self.entries],
            "stats": self.stats
        }


class ObjectDiffer:
    """Diff arbitrary objects/dicts."""

    def __init__(self, deep: bool = True, include_unchanged: bool = False):
        self.deep = deep
        self.include_unchanged = include_unchanged

    def diff(self, old: Any, new: Any, path: str = "") -> DiffResult:
        """Calculate diff between two objects."""
        entries = self._diff_values(old, new, path)
        return DiffResult(entries=entries)

    def _diff_values(self, old: Any, new: Any, path: str) -> List[DiffEntry]:
        """Diff two values."""
        entries = []

        # Both None or equal
        if old == new:
            if self.include_unchanged:
                entries.append(DiffEntry(
                    operation=DiffOperation.UNCHANGED,
                    path=path,
                    old_value=old,
                    new_value=new
                ))
            return entries

        # One is None
        if old is None:
            entries.append(DiffEntry(
                operation=DiffOperation.ADD,
                path=path,
                new_value=new
            ))
            return entries

        if new is None:
            entries.append(DiffEntry(
                operation=DiffOperation.REMOVE,
                path=path,
                old_value=old
            ))
            return entries

        # Different types
        if type(old) != type(new):
            entries.append(DiffEntry(
                operation=DiffOperation.REPLACE,
                path=path,
                old_value=old,
                new_value=new
            ))
            return entries

        # Dicts
        if isinstance(old, dict) and self.deep:
            entries.extend(self._diff_dicts(old, new, path))
            return entries

        # Lists
        if isinstance(old, list) and self.deep:
            entries.extend(self._diff_lists(old, new, path))
            return entries

        # Simple values
        if old != new:
            entries.append(DiffEntry(
                operation=DiffOperation.REPLACE,
                path=path,
                old_value=old,
                new_value=new
            ))

        return entries

    def _diff_dicts(self, old: Dict, new: Dict, path: str) -> List[DiffEntry]:
        """Diff two dicts."""
        entries = []
        all_keys = set(old.keys()) | set(new.keys())

        for key in sorted(all_keys):
            key_path = f"{path}.{key}" if path else key
            old_val = old.get(key)
            new_val = new.get(key)

            if key not in old:
                entries.append(DiffEntry(
                    operation=DiffOperation.ADD,
                    path=key_path,
                    new_value=new_val
                ))
            elif key not in new:
                entries.append(DiffEntry(
                    operation=DiffOperation.REMOVE,
                    path=key_path,
                    old_value=old_val
                ))
            else:
                entries.extend(self._diff_values(old_val, new_val, key_path))

        return entries

    def _diff_lists(self, old: List, new: List, path: str) -> List[DiffEntry]:
        """Diff two lists."""
        entries = []

        # Simple approach: compare by index
        max_len = max(len(old), len(new))

        for i in range(max_len):
            item_path = f"{path}[{i}]"

            if i >= len(old):
                entries.append(DiffEntry(
                    operation=DiffOperation.ADD,
                    path=item_path,
                    new_value=new[i]
                ))
            elif i >= len(new):
                entries.append(DiffEntry(
                    operation=DiffOperation.REMOVE,
                    path=item_path,
                    old_value=old[i]
                ))
            else:
                entries.extend(self._diff_values(old[i], new[i], item_path))

        return entries


class TextDiffer:
    """Diff text content."""

    def __init__(self, context_lines: int = 3):
        self.context_lines = context_lines

    def diff(self, old: str, new: str) -> DiffResult:
        """Diff two text strings."""
        old_lines = old.splitlines(keepends=True)
        new_lines = new.splitlines(keepends=True)

        differ = difflib.unified_diff(
            old_lines, new_lines,
            fromfile="old", tofile="new",
            n=self.context_lines
        )

        entries = []
        for line in differ:
            if line.startswith('+') and not line.startswith('+++'):
                entries.append(DiffEntry(
                    operation=DiffOperation.ADD,
                    path="",
                    new_value=line[1:].rstrip('\n')
                ))
            elif line.startswith('-') and not line.startswith('---'):
                entries.append(DiffEntry(
                    operation=DiffOperation.REMOVE,
                    path="",
                    old_value=line[1:].rstrip('\n')
                ))

        return DiffResult(entries=entries)

    def unified_diff(self, old: str, new: str, old_label: str = "old", new_label: str = "new") -> str:
        """Generate unified diff format."""
        old_lines = old.splitlines(keepends=True)
        new_lines = new.splitlines(keepends=True)

        diff = difflib.unified_diff(
            old_lines, new_lines,
            fromfile=old_label, tofile=new_label,
            n=self.context_lines
        )

        return ''.join(diff)

    def html_diff(self, old: str, new: str) -> str:
        """Generate HTML diff."""
        differ = difflib.HtmlDiff()
        return differ.make_table(
            old.splitlines(),
            new.splitlines()
        )


class Patcher:
    """Apply patches to objects."""

    def apply(self, obj: Any, diff: DiffResult) -> Any:
        """Apply diff to an object."""
        result = copy.deepcopy(obj)

        for entry in diff.entries:
            if entry.operation == DiffOperation.UNCHANGED:
                continue

            result = self._apply_entry(result, entry)

        return result

    def _apply_entry(self, obj: Any, entry: DiffEntry) -> Any:
        """Apply a single diff entry."""
        if not entry.path:
            if entry.operation == DiffOperation.REPLACE:
                return entry.new_value
            return obj

        parts = self._parse_path(entry.path)
        return self._set_at_path(obj, parts, entry)

    def _parse_path(self, path: str) -> List[Union[str, int]]:
        """Parse a path string into parts."""
        parts = []
        current = ""

        i = 0
        while i < len(path):
            c = path[i]

            if c == '.':
                if current:
                    parts.append(current)
                    current = ""
            elif c == '[':
                if current:
                    parts.append(current)
                    current = ""
                # Find closing bracket
                end = path.index(']', i)
                index = int(path[i+1:end])
                parts.append(index)
                i = end
            else:
                current += c

            i += 1

        if current:
            parts.append(current)

        return parts

    def _set_at_path(self, obj: Any, parts: List, entry: DiffEntry) -> Any:
        """Set value at path."""
        if not parts:
            return entry.new_value

        current = obj
        for i, part in enumerate(parts[:-1]):
            if isinstance(part, int):
                current = current[part]
            else:
                current = current[part]

        last_part = parts[-1]

        if entry.operation == DiffOperation.ADD:
            if isinstance(last_part, int):
                if isinstance(current, list):
                    current.insert(last_part, entry.new_value)
            else:
                current[last_part] = entry.new_value

        elif entry.operation == DiffOperation.REMOVE:
            if isinstance(last_part, int):
                if isinstance(current, list):
                    current.pop(last_part)
            else:
                del current[last_part]

        elif entry.operation == DiffOperation.REPLACE:
            current[last_part] = entry.new_value

        return obj


@dataclass
class Patch:
    """A patch that can be applied to objects."""
    entries: List[DiffEntry]
    created_at: datetime = field(default_factory=datetime.now)
    checksum: str = ""

    def __post_init__(self):
        if not self.checksum:
            self.checksum = self._calculate_checksum()

    def _calculate_checksum(self) -> str:
        data = json.dumps([e.to_dict() for e in self.entries], sort_keys=True)
        return hashlib.md5(data.encode()).hexdigest()[:8]

    def apply(self, obj: Any) -> Any:
        """Apply patch to object."""
        patcher = Patcher()
        return patcher.apply(obj, DiffResult(entries=self.entries))

    def reverse(self) -> "Patch":
        """Create reverse patch."""
        reversed_entries = []
        for entry in reversed(self.entries):
            if entry.operation == DiffOperation.ADD:
                reversed_entries.append(DiffEntry(
                    operation=DiffOperation.REMOVE,
                    path=entry.path,
                    old_value=entry.new_value
                ))
            elif entry.operation == DiffOperation.REMOVE:
                reversed_entries.append(DiffEntry(
                    operation=DiffOperation.ADD,
                    path=entry.path,
                    new_value=entry.old_value
                ))
            elif entry.operation == DiffOperation.REPLACE:
                reversed_entries.append(DiffEntry(
                    operation=DiffOperation.REPLACE,
                    path=entry.path,
                    old_value=entry.new_value,
                    new_value=entry.old_value
                ))
        return Patch(entries=reversed_entries)

    def to_json(self) -> str:
        return json.dumps({
            "entries": [e.to_dict() for e in self.entries],
            "checksum": self.checksum,
            "created_at": self.created_at.isoformat()
        }, indent=2)

    @classmethod
    def from_json(cls, data: str) -> "Patch":
        parsed = json.loads(data)
        entries = [
            DiffEntry(
                operation=DiffOperation(e["op"]),
                path=e["path"],
                old_value=e.get("old"),
                new_value=e.get("new")
            )
            for e in parsed["entries"]
        ]
        return cls(entries=entries)


class DiffManager:
    """High-level diff management."""

    def __init__(self):
        self.object_differ = ObjectDiffer()
        self.text_differ = TextDiffer()
        self.patcher = Patcher()

    def diff_objects(self, old: Any, new: Any) -> DiffResult:
        """Diff two objects."""
        return self.object_differ.diff(old, new)

    def diff_text(self, old: str, new: str) -> DiffResult:
        """Diff two text strings."""
        return self.text_differ.diff(old, new)

    def create_patch(self, old: Any, new: Any) -> Patch:
        """Create a patch from two objects."""
        diff = self.diff_objects(old, new)
        return Patch(entries=diff.entries)

    def apply_patch(self, obj: Any, patch: Patch) -> Any:
        """Apply a patch to an object."""
        return patch.apply(obj)

    def unified_diff(self, old: str, new: str) -> str:
        """Get unified diff for text."""
        return self.text_differ.unified_diff(old, new)

    def three_way_merge(
        self,
        base: Any,
        ours: Any,
        theirs: Any
    ) -> Tuple[Any, List[str]]:
        """Three-way merge."""
        our_diff = self.diff_objects(base, ours)
        their_diff = self.diff_objects(base, theirs)

        conflicts = []
        result = copy.deepcopy(base)

        # Apply non-conflicting changes from ours
        our_paths = {e.path for e in our_diff.entries}
        their_paths = {e.path for e in their_diff.entries}

        for entry in our_diff.entries:
            if entry.path in their_paths:
                # Check for conflict
                their_entry = next(e for e in their_diff.entries if e.path == entry.path)
                if entry.new_value != their_entry.new_value:
                    conflicts.append(entry.path)
                    continue

            result = self.patcher._apply_entry(result, entry)

        # Apply non-conflicting changes from theirs
        for entry in their_diff.entries:
            if entry.path not in our_paths:
                result = self.patcher._apply_entry(result, entry)

        return result, conflicts


# Example usage
def example_usage():
    """Example diff usage."""
    manager = DiffManager()

    # Object diff
    old_obj = {
        "name": "Alice",
        "age": 30,
        "tags": ["dev", "python"],
        "address": {"city": "NYC", "zip": "10001"}
    }

    new_obj = {
        "name": "Alice",
        "age": 31,
        "tags": ["dev", "python", "rust"],
        "address": {"city": "LA", "zip": "90001"},
        "active": True
    }

    diff = manager.diff_objects(old_obj, new_obj)
    print(f"Object diff has {len(diff.entries)} changes")
    print(f"Stats: {diff.stats}")

    for entry in diff.entries:
        print(f"  {entry.operation.value}: {entry.path}")

    # Create and apply patch
    patch = manager.create_patch(old_obj, new_obj)
    print(f"\nPatch checksum: {patch.checksum}")

    restored = manager.apply_patch(old_obj, patch)
    print(f"After patch: {restored}")

    # Reverse patch
    reverse = patch.reverse()
    original = manager.apply_patch(restored, reverse)
    print(f"After reverse: {original}")

    # Text diff
    old_text = "line 1\nline 2\nline 3\n"
    new_text = "line 1\nline 2 modified\nline 3\nline 4\n"

    unified = manager.unified_diff(old_text, new_text)
    print(f"\nUnified diff:\n{unified}")

    # Three-way merge
    base = {"a": 1, "b": 2}
    ours = {"a": 1, "b": 3, "c": 4}
    theirs = {"a": 2, "b": 2, "d": 5}

    merged, conflicts = manager.three_way_merge(base, ours, theirs)
    print(f"\nMerged: {merged}")
    print(f"Conflicts: {conflicts}")

