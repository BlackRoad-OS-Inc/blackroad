"""Utilities for multi-tenant paths and RBAC."""
from __future__ import annotations

from pathlib import Path
from typing import Iterable

from . import settings

ROOT = Path(__file__).resolve().parents[1]
DATA_ROOT = ROOT / "app" / "data"
TENANTS_ROOT = DATA_ROOT / "tenants"


def ns_path(tenant: str | None, relative_path: str) -> str:
    """Return namespaced path if multi-tenant mode is enabled."""
    p = Path(relative_path)
    if not settings.MULTI_TENANT or not tenant:
        return str(p)
    return str(TENANTS_ROOT / tenant / p)


def assert_tenant_access(user_perms: Iterable[str], tenant: str, target: str) -> None:
    if tenant != target and "TENANT_ADMIN" not in user_perms:
        raise PermissionError("Cross-tenant access denied")
