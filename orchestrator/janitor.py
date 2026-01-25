from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from config.settings import DATA_RETENTION_DAYS


DATA_ROOT = Path('data')


def purge_old_artifacts(now: datetime | None = None) -> int:
    """Remove files under DATA_ROOT older than retention days.

    Returns number of files removed."""
    now = now or datetime.utcnow()
    cutoff = now - timedelta(days=DATA_RETENTION_DAYS)
    removed = 0
    if not DATA_ROOT.exists():
        return 0
    for path in DATA_ROOT.rglob('*'):
        if path.is_file() and datetime.utcfromtimestamp(path.stat().st_mtime) < cutoff:
            path.unlink(missing_ok=True)
            removed += 1
    return removed
