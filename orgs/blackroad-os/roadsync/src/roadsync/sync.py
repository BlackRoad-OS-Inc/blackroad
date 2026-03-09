"""
RoadSync - Data Synchronization for BlackRoad
Sync data between sources with conflict resolution.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple
import hashlib
import json
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class SyncDirection(str, Enum):
    PUSH = "push"
    PULL = "pull"
    BIDIRECTIONAL = "bidirectional"


class ConflictStrategy(str, Enum):
    SOURCE_WINS = "source_wins"
    TARGET_WINS = "target_wins"
    NEWER_WINS = "newer_wins"
    MERGE = "merge"
    MANUAL = "manual"


class SyncStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    CONFLICT = "conflict"


@dataclass
class SyncRecord:
    id: str
    data: Dict[str, Any]
    version: int = 1
    checksum: str = ""
    updated_at: datetime = field(default_factory=datetime.now)
    deleted: bool = False

    def __post_init__(self):
        if not self.checksum:
            self.checksum = self._compute_checksum()

    def _compute_checksum(self) -> str:
        data_str = json.dumps(self.data, sort_keys=True, default=str)
        return hashlib.md5(data_str.encode()).hexdigest()

    def update(self, data: Dict[str, Any]) -> None:
        self.data = data
        self.version += 1
        self.checksum = self._compute_checksum()
        self.updated_at = datetime.now()


@dataclass
class SyncConflict:
    record_id: str
    source_record: SyncRecord
    target_record: SyncRecord
    resolved: bool = False
    resolution: Optional[SyncRecord] = None


@dataclass
class SyncChange:
    record_id: str
    action: str  # create, update, delete
    source_version: int
    target_version: int
    data: Dict[str, Any]


@dataclass
class SyncResult:
    success: bool
    changes_pushed: int = 0
    changes_pulled: int = 0
    conflicts: List[SyncConflict] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    duration_ms: float = 0


class SyncStore:
    def __init__(self):
        self.records: Dict[str, SyncRecord] = {}
        self.version_history: Dict[str, List[int]] = {}
        self._lock = threading.Lock()

    def get(self, record_id: str) -> Optional[SyncRecord]:
        return self.records.get(record_id)

    def put(self, record: SyncRecord) -> None:
        with self._lock:
            self.records[record.id] = record
            if record.id not in self.version_history:
                self.version_history[record.id] = []
            self.version_history[record.id].append(record.version)

    def delete(self, record_id: str) -> bool:
        with self._lock:
            if record_id in self.records:
                self.records[record_id].deleted = True
                return True
            return False

    def list_all(self) -> List[SyncRecord]:
        return list(self.records.values())

    def list_since(self, since: datetime) -> List[SyncRecord]:
        return [r for r in self.records.values() if r.updated_at >= since]

    def get_version(self, record_id: str) -> int:
        record = self.records.get(record_id)
        return record.version if record else 0


class ConflictResolver:
    def __init__(self, strategy: ConflictStrategy = ConflictStrategy.NEWER_WINS):
        self.strategy = strategy
        self.custom_resolver: Optional[Callable] = None

    def resolve(self, conflict: SyncConflict) -> SyncRecord:
        if self.strategy == ConflictStrategy.SOURCE_WINS:
            return conflict.source_record
        elif self.strategy == ConflictStrategy.TARGET_WINS:
            return conflict.target_record
        elif self.strategy == ConflictStrategy.NEWER_WINS:
            if conflict.source_record.updated_at >= conflict.target_record.updated_at:
                return conflict.source_record
            return conflict.target_record
        elif self.strategy == ConflictStrategy.MERGE:
            return self._merge(conflict)
        elif self.custom_resolver:
            return self.custom_resolver(conflict)
        return conflict.source_record

    def _merge(self, conflict: SyncConflict) -> SyncRecord:
        merged_data = {**conflict.target_record.data, **conflict.source_record.data}
        return SyncRecord(
            id=conflict.record_id,
            data=merged_data,
            version=max(conflict.source_record.version, conflict.target_record.version) + 1
        )


class SyncEngine:
    def __init__(self, source: SyncStore, target: SyncStore, direction: SyncDirection = SyncDirection.BIDIRECTIONAL):
        self.source = source
        self.target = target
        self.direction = direction
        self.resolver = ConflictResolver()
        self.last_sync: Optional[datetime] = None
        self.hooks: Dict[str, List[Callable]] = {
            "before_sync": [], "after_sync": [],
            "before_push": [], "after_push": [],
            "before_pull": [], "after_pull": [],
            "on_conflict": []
        }

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self.hooks:
            self.hooks[event].append(handler)

    def _emit(self, event: str, data: Any = None) -> None:
        for handler in self.hooks.get(event, []):
            try:
                handler(data)
            except Exception as e:
                logger.error(f"Hook error: {e}")

    def sync(self, full: bool = False) -> SyncResult:
        start = time.time()
        self._emit("before_sync")
        
        since = None if full else self.last_sync
        result = SyncResult(success=True)
        
        try:
            if self.direction in [SyncDirection.PUSH, SyncDirection.BIDIRECTIONAL]:
                push_result = self._push(since)
                result.changes_pushed = push_result
            
            if self.direction in [SyncDirection.PULL, SyncDirection.BIDIRECTIONAL]:
                pull_result = self._pull(since)
                result.changes_pulled = pull_result
            
            self.last_sync = datetime.now()
        except Exception as e:
            result.success = False
            result.errors.append(str(e))
            logger.error(f"Sync failed: {e}")
        
        result.duration_ms = (time.time() - start) * 1000
        self._emit("after_sync", result)
        return result

    def _push(self, since: datetime = None) -> int:
        self._emit("before_push")
        records = self.source.list_since(since) if since else self.source.list_all()
        pushed = 0
        
        for record in records:
            target_record = self.target.get(record.id)
            
            if target_record is None:
                self.target.put(record)
                pushed += 1
            elif target_record.checksum != record.checksum:
                if target_record.version >= record.version:
                    conflict = SyncConflict(record.id, record, target_record)
                    self._emit("on_conflict", conflict)
                    resolved = self.resolver.resolve(conflict)
                    self.target.put(resolved)
                else:
                    self.target.put(record)
                pushed += 1
        
        self._emit("after_push", pushed)
        return pushed

    def _pull(self, since: datetime = None) -> int:
        self._emit("before_pull")
        records = self.target.list_since(since) if since else self.target.list_all()
        pulled = 0
        
        for record in records:
            source_record = self.source.get(record.id)
            
            if source_record is None:
                self.source.put(record)
                pulled += 1
            elif source_record.checksum != record.checksum:
                if source_record.version >= record.version:
                    conflict = SyncConflict(record.id, source_record, record)
                    self._emit("on_conflict", conflict)
                    resolved = self.resolver.resolve(conflict)
                    self.source.put(resolved)
                else:
                    self.source.put(record)
                pulled += 1
        
        self._emit("after_pull", pulled)
        return pulled

    def diff(self) -> Dict[str, List[str]]:
        source_ids = set(self.source.records.keys())
        target_ids = set(self.target.records.keys())
        
        return {
            "source_only": list(source_ids - target_ids),
            "target_only": list(target_ids - source_ids),
            "both": list(source_ids & target_ids),
            "conflicts": [
                id for id in (source_ids & target_ids)
                if self.source.get(id).checksum != self.target.get(id).checksum
            ]
        }


class SyncManager:
    def __init__(self):
        self.engines: Dict[str, SyncEngine] = {}
        self._running = False

    def register(self, name: str, engine: SyncEngine) -> None:
        self.engines[name] = engine

    def sync(self, name: str, full: bool = False) -> Optional[SyncResult]:
        engine = self.engines.get(name)
        if engine:
            return engine.sync(full)
        return None

    def sync_all(self, full: bool = False) -> Dict[str, SyncResult]:
        results = {}
        for name, engine in self.engines.items():
            results[name] = engine.sync(full)
        return results

    async def start_periodic_sync(self, interval_seconds: int = 60) -> None:
        import asyncio
        self._running = True
        while self._running:
            self.sync_all()
            await asyncio.sleep(interval_seconds)

    def stop(self) -> None:
        self._running = False


def example_usage():
    source = SyncStore()
    target = SyncStore()
    
    source.put(SyncRecord(id="1", data={"name": "Alice", "age": 30}))
    source.put(SyncRecord(id="2", data={"name": "Bob", "age": 25}))
    source.put(SyncRecord(id="3", data={"name": "Charlie", "age": 35}))
    
    target.put(SyncRecord(id="2", data={"name": "Bob", "age": 26}))
    target.put(SyncRecord(id="4", data={"name": "Diana", "age": 28}))
    
    engine = SyncEngine(source, target, SyncDirection.BIDIRECTIONAL)
    engine.resolver = ConflictResolver(ConflictStrategy.NEWER_WINS)
    
    diff = engine.diff()
    print(f"Source only: {diff['source_only']}")
    print(f"Target only: {diff['target_only']}")
    print(f"Conflicts: {diff['conflicts']}")
    
    result = engine.sync()
    print(f"\nSync result:")
    print(f"  Pushed: {result.changes_pushed}")
    print(f"  Pulled: {result.changes_pulled}")
    print(f"  Duration: {result.duration_ms:.2f}ms")
    
    print(f"\nSource records: {len(source.list_all())}")
    print(f"Target records: {len(target.list_all())}")

