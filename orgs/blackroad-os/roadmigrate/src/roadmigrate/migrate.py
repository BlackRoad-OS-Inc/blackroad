"""
RoadMigrate - Database Migrations for BlackRoad
Manage database schema migrations with versioning.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import hashlib
import json
import logging
import os
import re
import threading

logger = logging.getLogger(__name__)


class MigrationStatus(str, Enum):
    PENDING = "pending"
    APPLIED = "applied"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


@dataclass
class Migration:
    version: str
    name: str
    up_sql: str = ""
    down_sql: str = ""
    up_fn: Optional[Callable] = None
    down_fn: Optional[Callable] = None
    checksum: str = ""
    applied_at: Optional[datetime] = None
    status: MigrationStatus = MigrationStatus.PENDING

    def __post_init__(self):
        if not self.checksum:
            content = self.up_sql + self.down_sql
            self.checksum = hashlib.md5(content.encode()).hexdigest()[:8]


@dataclass
class MigrationResult:
    version: str
    name: str
    success: bool
    direction: str  # up or down
    duration_ms: float = 0
    error: Optional[str] = None


class MigrationStore:
    def __init__(self):
        self.migrations: Dict[str, Migration] = {}
        self.applied: List[str] = []
        self._lock = threading.Lock()

    def get_applied(self) -> List[str]:
        return self.applied.copy()

    def mark_applied(self, version: str) -> None:
        with self._lock:
            if version not in self.applied:
                self.applied.append(version)

    def mark_rolled_back(self, version: str) -> None:
        with self._lock:
            if version in self.applied:
                self.applied.remove(version)

    def is_applied(self, version: str) -> bool:
        return version in self.applied


class MigrationRunner:
    def __init__(self, executor: Callable[[str], Any] = None):
        self.executor = executor or self._default_executor

    def _default_executor(self, sql: str) -> Any:
        logger.info(f"Executing SQL: {sql[:100]}...")
        return True

    def run_up(self, migration: Migration) -> MigrationResult:
        import time
        start = time.time()
        
        try:
            if migration.up_fn:
                migration.up_fn()
            elif migration.up_sql:
                self.executor(migration.up_sql)
            
            duration = (time.time() - start) * 1000
            return MigrationResult(
                version=migration.version,
                name=migration.name,
                success=True,
                direction="up",
                duration_ms=duration
            )
        except Exception as e:
            duration = (time.time() - start) * 1000
            logger.error(f"Migration {migration.version} failed: {e}")
            return MigrationResult(
                version=migration.version,
                name=migration.name,
                success=False,
                direction="up",
                duration_ms=duration,
                error=str(e)
            )

    def run_down(self, migration: Migration) -> MigrationResult:
        import time
        start = time.time()
        
        try:
            if migration.down_fn:
                migration.down_fn()
            elif migration.down_sql:
                self.executor(migration.down_sql)
            
            duration = (time.time() - start) * 1000
            return MigrationResult(
                version=migration.version,
                name=migration.name,
                success=True,
                direction="down",
                duration_ms=duration
            )
        except Exception as e:
            duration = (time.time() - start) * 1000
            logger.error(f"Rollback {migration.version} failed: {e}")
            return MigrationResult(
                version=migration.version,
                name=migration.name,
                success=False,
                direction="down",
                duration_ms=duration,
                error=str(e)
            )


class MigrationBuilder:
    def __init__(self, version: str, name: str):
        self.migration = Migration(version=version, name=name)

    def up(self, sql: str) -> "MigrationBuilder":
        self.migration.up_sql = sql
        return self

    def down(self, sql: str) -> "MigrationBuilder":
        self.migration.down_sql = sql
        return self

    def up_fn(self, fn: Callable) -> "MigrationBuilder":
        self.migration.up_fn = fn
        return self

    def down_fn(self, fn: Callable) -> "MigrationBuilder":
        self.migration.down_fn = fn
        return self

    def build(self) -> Migration:
        return self.migration


class Migrator:
    def __init__(self, store: MigrationStore = None, runner: MigrationRunner = None):
        self.store = store or MigrationStore()
        self.runner = runner or MigrationRunner()
        self.migrations: Dict[str, Migration] = {}
        self.hooks: Dict[str, List[Callable]] = {
            "before_migrate": [], "after_migrate": [],
            "before_rollback": [], "after_rollback": []
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

    def register(self, migration: Migration) -> None:
        self.migrations[migration.version] = migration

    def create(self, version: str, name: str) -> MigrationBuilder:
        return MigrationBuilder(version, name)

    def pending(self) -> List[Migration]:
        applied = set(self.store.get_applied())
        pending = []
        for version in sorted(self.migrations.keys()):
            if version not in applied:
                pending.append(self.migrations[version])
        return pending

    def applied(self) -> List[Migration]:
        applied_versions = self.store.get_applied()
        return [self.migrations[v] for v in applied_versions if v in self.migrations]

    def migrate(self, target: str = None) -> List[MigrationResult]:
        self._emit("before_migrate")
        results = []
        pending = self.pending()
        
        for migration in pending:
            if target and migration.version > target:
                break
            
            result = self.runner.run_up(migration)
            results.append(result)
            
            if result.success:
                self.store.mark_applied(migration.version)
                migration.status = MigrationStatus.APPLIED
                migration.applied_at = datetime.now()
                logger.info(f"Applied: {migration.version} - {migration.name}")
            else:
                migration.status = MigrationStatus.FAILED
                logger.error(f"Failed: {migration.version} - {result.error}")
                break
        
        self._emit("after_migrate", results)
        return results

    def rollback(self, steps: int = 1) -> List[MigrationResult]:
        self._emit("before_rollback")
        results = []
        applied = list(reversed(self.store.get_applied()))
        
        for i, version in enumerate(applied):
            if i >= steps:
                break
            
            migration = self.migrations.get(version)
            if not migration:
                continue
            
            result = self.runner.run_down(migration)
            results.append(result)
            
            if result.success:
                self.store.mark_rolled_back(version)
                migration.status = MigrationStatus.ROLLED_BACK
                logger.info(f"Rolled back: {version} - {migration.name}")
            else:
                migration.status = MigrationStatus.FAILED
                logger.error(f"Rollback failed: {version} - {result.error}")
                break
        
        self._emit("after_rollback", results)
        return results

    def rollback_to(self, target: str) -> List[MigrationResult]:
        results = []
        applied = list(reversed(self.store.get_applied()))
        
        for version in applied:
            if version <= target:
                break
            
            migration = self.migrations.get(version)
            if migration:
                result = self.runner.run_down(migration)
                results.append(result)
                if result.success:
                    self.store.mark_rolled_back(version)
        
        return results

    def status(self) -> Dict[str, Any]:
        applied = self.store.get_applied()
        pending = self.pending()
        
        return {
            "applied_count": len(applied),
            "pending_count": len(pending),
            "applied": applied,
            "pending": [m.version for m in pending],
            "latest": applied[-1] if applied else None
        }

    def generate(self, name: str) -> str:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        slug = re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')
        return f"{timestamp}_{slug}"


def example_usage():
    migrator = Migrator()
    
    m1 = (migrator.create("001", "create_users_table")
        .up("""
            CREATE TABLE users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        """)
        .down("DROP TABLE users")
        .build())
    migrator.register(m1)
    
    m2 = (migrator.create("002", "add_age_to_users")
        .up("ALTER TABLE users ADD COLUMN age INTEGER")
        .down("ALTER TABLE users DROP COLUMN age")
        .build())
    migrator.register(m2)
    
    m3 = (migrator.create("003", "create_posts_table")
        .up("""
            CREATE TABLE posts (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id),
                title VARCHAR(255) NOT NULL,
                content TEXT,
                created_at TIMESTAMP DEFAULT NOW()
            )
        """)
        .down("DROP TABLE posts")
        .build())
    migrator.register(m3)
    
    print("Status before migration:")
    print(migrator.status())
    
    print("\nRunning migrations...")
    results = migrator.migrate()
    for r in results:
        status = "✓" if r.success else "✗"
        print(f"  {status} {r.version} - {r.name} ({r.duration_ms:.2f}ms)")
    
    print("\nStatus after migration:")
    print(migrator.status())
    
    print("\nRolling back 1 migration...")
    results = migrator.rollback(1)
    for r in results:
        status = "✓" if r.success else "✗"
        print(f"  {status} {r.version} - {r.name} (rollback)")
    
    print("\nFinal status:")
    print(migrator.status())

