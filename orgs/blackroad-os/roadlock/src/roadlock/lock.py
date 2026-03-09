"""
RoadLock - Distributed Locking for BlackRoad
Coordinate access to shared resources with locks.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import asyncio
import hashlib
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class LockStatus(str, Enum):
    ACQUIRED = "acquired"
    RELEASED = "released"
    EXPIRED = "expired"
    WAITING = "waiting"


@dataclass
class LockInfo:
    key: str
    owner: str
    acquired_at: datetime
    expires_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def is_expired(self) -> bool:
        if self.expires_at is None:
            return False
        return datetime.now() > self.expires_at


class LockStore:
    def __init__(self):
        self.locks: Dict[str, LockInfo] = {}
        self._lock = threading.Lock()

    def acquire(self, key: str, owner: str, ttl: int = 30) -> Optional[LockInfo]:
        with self._lock:
            existing = self.locks.get(key)
            if existing and not existing.is_expired:
                if existing.owner == owner:
                    existing.expires_at = datetime.now() + timedelta(seconds=ttl)
                    return existing
                return None
            
            lock_info = LockInfo(
                key=key,
                owner=owner,
                acquired_at=datetime.now(),
                expires_at=datetime.now() + timedelta(seconds=ttl) if ttl > 0 else None
            )
            self.locks[key] = lock_info
            return lock_info

    def release(self, key: str, owner: str) -> bool:
        with self._lock:
            lock_info = self.locks.get(key)
            if lock_info and lock_info.owner == owner:
                del self.locks[key]
                return True
            return False

    def extend(self, key: str, owner: str, ttl: int) -> bool:
        with self._lock:
            lock_info = self.locks.get(key)
            if lock_info and lock_info.owner == owner and not lock_info.is_expired:
                lock_info.expires_at = datetime.now() + timedelta(seconds=ttl)
                return True
            return False

    def is_locked(self, key: str) -> bool:
        lock_info = self.locks.get(key)
        return lock_info is not None and not lock_info.is_expired

    def get_owner(self, key: str) -> Optional[str]:
        lock_info = self.locks.get(key)
        if lock_info and not lock_info.is_expired:
            return lock_info.owner
        return None

    def cleanup_expired(self) -> int:
        with self._lock:
            expired = [k for k, v in self.locks.items() if v.is_expired]
            for key in expired:
                del self.locks[key]
            return len(expired)


class Lock:
    def __init__(self, store: LockStore, key: str, owner: str = None, ttl: int = 30, auto_extend: bool = False):
        self.store = store
        self.key = key
        self.owner = owner or str(uuid.uuid4())[:12]
        self.ttl = ttl
        self.auto_extend = auto_extend
        self._acquired = False
        self._extend_task = None

    def acquire(self, blocking: bool = True, timeout: float = None) -> bool:
        start = time.time()
        while True:
            lock_info = self.store.acquire(self.key, self.owner, self.ttl)
            if lock_info:
                self._acquired = True
                logger.debug(f"Lock acquired: {self.key} by {self.owner}")
                return True
            
            if not blocking:
                return False
            
            if timeout and (time.time() - start) >= timeout:
                return False
            
            time.sleep(0.01)

    def release(self) -> bool:
        if self._acquired:
            result = self.store.release(self.key, self.owner)
            if result:
                self._acquired = False
                logger.debug(f"Lock released: {self.key} by {self.owner}")
            return result
        return False

    def extend(self, ttl: int = None) -> bool:
        if self._acquired:
            return self.store.extend(self.key, self.owner, ttl or self.ttl)
        return False

    def __enter__(self) -> "Lock":
        if not self.acquire():
            raise RuntimeError(f"Failed to acquire lock: {self.key}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.release()

    async def __aenter__(self) -> "Lock":
        while not self.acquire(blocking=False):
            await asyncio.sleep(0.01)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        self.release()


class ReadWriteLock:
    def __init__(self, store: LockStore, key: str):
        self.store = store
        self.key = key
        self.read_key = f"{key}:read"
        self.write_key = f"{key}:write"
        self._readers: Dict[str, str] = {}
        self._lock = threading.Lock()

    def acquire_read(self, owner: str = None, timeout: float = None) -> bool:
        owner = owner or str(uuid.uuid4())[:12]
        start = time.time()
        
        while True:
            if not self.store.is_locked(self.write_key):
                with self._lock:
                    self._readers[owner] = owner
                return True
            
            if timeout and (time.time() - start) >= timeout:
                return False
            
            time.sleep(0.01)

    def release_read(self, owner: str) -> bool:
        with self._lock:
            if owner in self._readers:
                del self._readers[owner]
                return True
            return False

    def acquire_write(self, owner: str = None, ttl: int = 30, timeout: float = None) -> bool:
        owner = owner or str(uuid.uuid4())[:12]
        start = time.time()
        
        while True:
            with self._lock:
                if not self._readers and not self.store.is_locked(self.write_key):
                    if self.store.acquire(self.write_key, owner, ttl):
                        return True
            
            if timeout and (time.time() - start) >= timeout:
                return False
            
            time.sleep(0.01)

    def release_write(self, owner: str) -> bool:
        return self.store.release(self.write_key, owner)


class Semaphore:
    def __init__(self, store: LockStore, key: str, max_count: int):
        self.store = store
        self.key = key
        self.max_count = max_count
        self._holders: List[str] = []
        self._lock = threading.Lock()

    def acquire(self, owner: str = None, ttl: int = 30) -> bool:
        owner = owner or str(uuid.uuid4())[:12]
        
        with self._lock:
            if len(self._holders) < self.max_count:
                self._holders.append(owner)
                return True
            return False

    def release(self, owner: str) -> bool:
        with self._lock:
            if owner in self._holders:
                self._holders.remove(owner)
                return True
            return False

    def available(self) -> int:
        return self.max_count - len(self._holders)


class LockManager:
    def __init__(self, store: LockStore = None):
        self.store = store or LockStore()
        self._cleanup_interval = 60
        self._running = False

    def lock(self, key: str, ttl: int = 30, **kwargs) -> Lock:
        return Lock(self.store, key, ttl=ttl, **kwargs)

    def rw_lock(self, key: str) -> ReadWriteLock:
        return ReadWriteLock(self.store, key)

    def semaphore(self, key: str, max_count: int) -> Semaphore:
        return Semaphore(self.store, key, max_count)

    def is_locked(self, key: str) -> bool:
        return self.store.is_locked(key)

    def force_release(self, key: str) -> bool:
        owner = self.store.get_owner(key)
        if owner:
            return self.store.release(key, owner)
        return False

    async def start_cleanup(self) -> None:
        self._running = True
        while self._running:
            cleaned = self.store.cleanup_expired()
            if cleaned > 0:
                logger.debug(f"Cleaned up {cleaned} expired locks")
            await asyncio.sleep(self._cleanup_interval)

    def stop_cleanup(self) -> None:
        self._running = False


def example_usage():
    manager = LockManager()
    
    with manager.lock("resource-1") as lock:
        print(f"Lock acquired: {lock.key}")
        time.sleep(0.1)
        print("Doing work with lock...")
    print("Lock released")
    
    lock = manager.lock("resource-2", ttl=10)
    if lock.acquire(blocking=False):
        print("Got non-blocking lock")
        lock.release()
    
    rw_lock = manager.rw_lock("shared-resource")
    
    reader1 = "reader-1"
    reader2 = "reader-2"
    rw_lock.acquire_read(reader1)
    rw_lock.acquire_read(reader2)
    print("Both readers have access")
    rw_lock.release_read(reader1)
    rw_lock.release_read(reader2)
    
    writer = "writer-1"
    if rw_lock.acquire_write(writer, timeout=1):
        print("Writer has exclusive access")
        rw_lock.release_write(writer)
    
    sem = manager.semaphore("connection-pool", max_count=3)
    holders = []
    for i in range(5):
        owner = f"client-{i}"
        if sem.acquire(owner):
            holders.append(owner)
            print(f"{owner} acquired semaphore ({sem.available()} remaining)")
        else:
            print(f"{owner} could not acquire semaphore")
    
    for owner in holders:
        sem.release(owner)

