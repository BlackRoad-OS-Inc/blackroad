"""
RoadMigrations - Database Migration System for BlackRoad
Version-controlled schema migrations with rollback support.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple, Union
import hashlib
import importlib.util
import json
import logging
import os
import re
import threading
import time

logger = logging.getLogger(__name__)


class MigrationStatus(str, Enum):
    """Migration status."""
    PENDING = "pending"
    APPLIED = "applied"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class MigrationDirection(str, Enum):
    """Migration direction."""
    UP = "up"
    DOWN = "down"


@dataclass
class Migration:
    """A database migration."""
    version: str
    name: str
    description: str = ""
    up_sql: Optional[str] = None
    down_sql: Optional[str] = None
    up_fn: Optional[Callable] = None
    down_fn: Optional[Callable] = None
    checksum: Optional[str] = None
    dependencies: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)

    def __post_init__(self):
        if self.up_sql and not self.checksum:
            self.checksum = hashlib.md5(self.up_sql.encode()).hexdigest()


@dataclass
class MigrationRecord:
    """Record of applied migration."""
    version: str
    name: str
    status: MigrationStatus
    applied_at: Optional[datetime] = None
    rolled_back_at: Optional[datetime] = None
    checksum: Optional[str] = None
    execution_time_ms: Optional[float] = None
    error_message: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "version": self.version,
            "name": self.name,
            "status": self.status.value,
            "applied_at": self.applied_at.isoformat() if self.applied_at else None,
            "rolled_back_at": self.rolled_back_at.isoformat() if self.rolled_back_at else None,
            "checksum": self.checksum,
            "execution_time_ms": self.execution_time_ms,
            "error_message": self.error_message
        }


class MigrationStore:
    """Store for migration history."""

    def __init__(self):
        self.records: Dict[str, MigrationRecord] = {}
        self._lock = threading.Lock()

    def save(self, record: MigrationRecord) -> None:
        """Save migration record."""
        with self._lock:
            self.records[record.version] = record

    def get(self, version: str) -> Optional[MigrationRecord]:
        """Get migration record."""
        return self.records.get(version)

    def get_applied(self) -> List[MigrationRecord]:
        """Get all applied migrations."""
        return sorted(
            [r for r in self.records.values() if r.status == MigrationStatus.APPLIED],
            key=lambda r: r.version
        )

    def get_latest(self) -> Optional[MigrationRecord]:
        """Get latest applied migration."""
        applied = self.get_applied()
        return applied[-1] if applied else None

    def is_applied(self, version: str) -> bool:
        """Check if migration is applied."""
        record = self.get(version)
        return record is not None and record.status == MigrationStatus.APPLIED


class MigrationLoader:
    """Load migrations from files."""

    def __init__(self, migrations_dir: str = "migrations"):
        self.migrations_dir = Path(migrations_dir)

    def _parse_version(self, filename: str) -> Tuple[str, str]:
        """Parse version and name from filename."""
        # Expected format: V001__create_users_table.sql or 20240101120000_create_users.py
        match = re.match(r"^V?(\d+)__?(.+)\.(sql|py)$", filename, re.IGNORECASE)
        if match:
            return match.group(1), match.group(2).replace("_", " ")

        # Timestamp format
        match = re.match(r"^(\d{14})_(.+)\.(sql|py)$", filename)
        if match:
            return match.group(1), match.group(2).replace("_", " ")

        raise ValueError(f"Invalid migration filename: {filename}")

    def _load_sql_migration(self, path: Path) -> Migration:
        """Load SQL migration file."""
        content = path.read_text()
        version, name = self._parse_version(path.name)

        # Split up and down
        up_sql = content
        down_sql = None

        if "-- DOWN" in content:
            parts = content.split("-- DOWN")
            up_sql = parts[0].replace("-- UP", "").strip()
            down_sql = parts[1].strip()

        return Migration(
            version=version,
            name=name,
            up_sql=up_sql,
            down_sql=down_sql
        )

    def _load_python_migration(self, path: Path) -> Migration:
        """Load Python migration file."""
        version, name = self._parse_version(path.name)

        spec = importlib.util.spec_from_file_location(f"migration_{version}", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        return Migration(
            version=version,
            name=name,
            description=getattr(module, "description", ""),
            up_fn=getattr(module, "up", None),
            down_fn=getattr(module, "down", None),
            dependencies=getattr(module, "dependencies", [])
        )

    def load_all(self) -> List[Migration]:
        """Load all migrations from directory."""
        if not self.migrations_dir.exists():
            return []

        migrations = []

        for path in sorted(self.migrations_dir.iterdir()):
            if path.suffix == ".sql":
                try:
                    migrations.append(self._load_sql_migration(path))
                except Exception as e:
                    logger.error(f"Failed to load {path}: {e}")

            elif path.suffix == ".py" and not path.name.startswith("__"):
                try:
                    migrations.append(self._load_python_migration(path))
                except Exception as e:
                    logger.error(f"Failed to load {path}: {e}")

        return sorted(migrations, key=lambda m: m.version)


class DatabaseAdapter:
    """Abstract database adapter."""

    def execute(self, sql: str) -> None:
        """Execute SQL statement."""
        raise NotImplementedError

    def begin_transaction(self) -> None:
        """Begin transaction."""
        pass

    def commit(self) -> None:
        """Commit transaction."""
        pass

    def rollback(self) -> None:
        """Rollback transaction."""
        pass


class MemoryDatabaseAdapter(DatabaseAdapter):
    """In-memory database adapter for testing."""

    def __init__(self):
        self.executed: List[str] = []

    def execute(self, sql: str) -> None:
        self.executed.append(sql)
        logger.debug(f"Executed: {sql[:100]}...")


class MigrationRunner:
    """Execute migrations."""

    def __init__(self, db: DatabaseAdapter, store: MigrationStore):
        self.db = db
        self.store = store

    def _execute_migration(
        self,
        migration: Migration,
        direction: MigrationDirection
    ) -> Tuple[bool, Optional[str]]:
        """Execute a single migration."""
        start_time = time.time()

        try:
            self.db.begin_transaction()

            if direction == MigrationDirection.UP:
                if migration.up_sql:
                    self.db.execute(migration.up_sql)
                elif migration.up_fn:
                    migration.up_fn(self.db)
                else:
                    raise ValueError("No up migration defined")

            else:  # DOWN
                if migration.down_sql:
                    self.db.execute(migration.down_sql)
                elif migration.down_fn:
                    migration.down_fn(self.db)
                else:
                    raise ValueError("No down migration defined")

            self.db.commit()
            execution_time = (time.time() - start_time) * 1000

            # Record
            record = MigrationRecord(
                version=migration.version,
                name=migration.name,
                status=MigrationStatus.APPLIED if direction == MigrationDirection.UP else MigrationStatus.ROLLED_BACK,
                applied_at=datetime.now() if direction == MigrationDirection.UP else None,
                rolled_back_at=datetime.now() if direction == MigrationDirection.DOWN else None,
                checksum=migration.checksum,
                execution_time_ms=execution_time
            )
            self.store.save(record)

            logger.info(f"Migration {migration.version} {direction.value}: {migration.name}")
            return True, None

        except Exception as e:
            self.db.rollback()
            error_msg = str(e)

            record = MigrationRecord(
                version=migration.version,
                name=migration.name,
                status=MigrationStatus.FAILED,
                error_message=error_msg
            )
            self.store.save(record)

            logger.error(f"Migration {migration.version} failed: {error_msg}")
            return False, error_msg

    def migrate_up(self, migration: Migration) -> Tuple[bool, Optional[str]]:
        """Run migration up."""
        return self._execute_migration(migration, MigrationDirection.UP)

    def migrate_down(self, migration: Migration) -> Tuple[bool, Optional[str]]:
        """Run migration down."""
        return self._execute_migration(migration, MigrationDirection.DOWN)


class MigrationManager:
    """High-level migration management."""

    def __init__(
        self,
        db: Optional[DatabaseAdapter] = None,
        migrations_dir: str = "migrations"
    ):
        self.db = db or MemoryDatabaseAdapter()
        self.store = MigrationStore()
        self.runner = MigrationRunner(self.db, self.store)
        self.loader = MigrationLoader(migrations_dir)
        self._migrations: List[Migration] = []

    def load_migrations(self) -> int:
        """Load migrations from directory."""
        self._migrations = self.loader.load_all()
        return len(self._migrations)

    def register_migration(self, migration: Migration) -> None:
        """Register a migration programmatically."""
        self._migrations.append(migration)
        self._migrations.sort(key=lambda m: m.version)

    def get_pending(self) -> List[Migration]:
        """Get pending migrations."""
        return [m for m in self._migrations if not self.store.is_applied(m.version)]

    def get_applied(self) -> List[MigrationRecord]:
        """Get applied migrations."""
        return self.store.get_applied()

    def get_status(self) -> List[Dict[str, Any]]:
        """Get status of all migrations."""
        status = []
        for migration in self._migrations:
            record = self.store.get(migration.version)
            status.append({
                "version": migration.version,
                "name": migration.name,
                "status": record.status.value if record else "pending",
                "applied_at": record.applied_at.isoformat() if record and record.applied_at else None
            })
        return status

    def migrate(
        self,
        target_version: Optional[str] = None,
        dry_run: bool = False
    ) -> Tuple[int, List[str]]:
        """Run pending migrations."""
        pending = self.get_pending()

        if target_version:
            pending = [m for m in pending if m.version <= target_version]

        if not pending:
            logger.info("No pending migrations")
            return 0, []

        if dry_run:
            return len(pending), [m.name for m in pending]

        applied = 0
        errors = []

        for migration in pending:
            # Check dependencies
            for dep in migration.dependencies:
                if not self.store.is_applied(dep):
                    errors.append(f"Dependency not met: {dep}")
                    break
            else:
                success, error = self.runner.migrate_up(migration)
                if success:
                    applied += 1
                else:
                    errors.append(f"{migration.version}: {error}")
                    break

        return applied, errors

    def rollback(
        self,
        steps: int = 1
    ) -> Tuple[int, List[str]]:
        """Rollback migrations."""
        applied = self.get_applied()

        if not applied:
            logger.info("No migrations to rollback")
            return 0, []

        to_rollback = applied[-steps:]
        to_rollback.reverse()

        rolled_back = 0
        errors = []

        for record in to_rollback:
            migration = next(
                (m for m in self._migrations if m.version == record.version),
                None
            )

            if not migration:
                errors.append(f"Migration not found: {record.version}")
                continue

            if not migration.down_sql and not migration.down_fn:
                errors.append(f"No rollback defined: {record.version}")
                continue

            success, error = self.runner.migrate_down(migration)
            if success:
                rolled_back += 1
            else:
                errors.append(f"{record.version}: {error}")
                break

        return rolled_back, errors

    def reset(self) -> Tuple[int, List[str]]:
        """Rollback all migrations."""
        applied = self.get_applied()
        return self.rollback(steps=len(applied))

    def refresh(self) -> Tuple[int, int, List[str]]:
        """Reset and re-run all migrations."""
        rolled_back, errors = self.reset()
        if errors:
            return rolled_back, 0, errors

        applied, errors = self.migrate()
        return rolled_back, applied, errors

    def validate(self) -> List[str]:
        """Validate migration checksums."""
        issues = []

        for migration in self._migrations:
            record = self.store.get(migration.version)
            if record and record.checksum and migration.checksum:
                if record.checksum != migration.checksum:
                    issues.append(
                        f"Checksum mismatch for {migration.version}: "
                        f"expected {record.checksum}, got {migration.checksum}"
                    )

        return issues


class MigrationGenerator:
    """Generate migration files."""

    def __init__(self, migrations_dir: str = "migrations"):
        self.migrations_dir = Path(migrations_dir)
        self.migrations_dir.mkdir(parents=True, exist_ok=True)

    def _get_next_version(self) -> str:
        """Generate next version number."""
        return datetime.now().strftime("%Y%m%d%H%M%S")

    def create_sql(
        self,
        name: str,
        up_sql: str,
        down_sql: Optional[str] = None
    ) -> Path:
        """Create SQL migration file."""
        version = self._get_next_version()
        filename = f"{version}_{name.replace(' ', '_').lower()}.sql"
        path = self.migrations_dir / filename

        content = f"-- UP\n{up_sql}\n"
        if down_sql:
            content += f"\n-- DOWN\n{down_sql}\n"

        path.write_text(content)
        logger.info(f"Created migration: {filename}")
        return path

    def create_python(self, name: str, description: str = "") -> Path:
        """Create Python migration file."""
        version = self._get_next_version()
        filename = f"{version}_{name.replace(' ', '_').lower()}.py"
        path = self.migrations_dir / filename

        template = f'''"""
Migration: {name}
Version: {version}
{description}
"""

description = "{description}"
dependencies = []


def up(db):
    """Apply migration."""
    # db.execute("CREATE TABLE ...")
    pass


def down(db):
    """Rollback migration."""
    # db.execute("DROP TABLE ...")
    pass
'''

        path.write_text(template)
        logger.info(f"Created migration: {filename}")
        return path


# Decorators
def migration(
    version: str,
    name: str,
    dependencies: Optional[List[str]] = None
):
    """Decorator to define migration functions."""
    def decorator(cls):
        cls._migration_version = version
        cls._migration_name = name
        cls._migration_dependencies = dependencies or []
        return cls
    return decorator


# Example usage
def example_usage():
    """Example migration usage."""
    manager = MigrationManager()

    # Register migrations
    manager.register_migration(Migration(
        version="001",
        name="Create users table",
        up_sql="""
            CREATE TABLE users (
                id SERIAL PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        """,
        down_sql="DROP TABLE users"
    ))

    manager.register_migration(Migration(
        version="002",
        name="Add name to users",
        up_sql="ALTER TABLE users ADD COLUMN name VARCHAR(255)",
        down_sql="ALTER TABLE users DROP COLUMN name",
        dependencies=["001"]
    ))

    # Check status
    status = manager.get_status()
    print(f"Migration status: {status}")

    # Run migrations
    applied, errors = manager.migrate()
    print(f"Applied: {applied}, Errors: {errors}")

    # Rollback
    rolled_back, errors = manager.rollback(steps=1)
    print(f"Rolled back: {rolled_back}")

    # Generate new migration
    generator = MigrationGenerator()
    generator.create_sql(
        name="Add posts table",
        up_sql="CREATE TABLE posts (id SERIAL PRIMARY KEY, title VARCHAR(255))",
        down_sql="DROP TABLE posts"
    )
