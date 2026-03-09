"""
RoadTenant - Multi-Tenancy System for BlackRoad
Tenant isolation, resource quotas, and tenant-aware data access.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import hashlib
import json
import logging
import threading
import uuid

logger = logging.getLogger(__name__)


class TenantStatus(str, Enum):
    """Tenant status."""
    ACTIVE = "active"
    SUSPENDED = "suspended"
    PENDING = "pending"
    ARCHIVED = "archived"


class IsolationLevel(str, Enum):
    """Data isolation level."""
    SHARED = "shared"  # Shared tables with tenant_id column
    SCHEMA = "schema"  # Separate schema per tenant
    DATABASE = "database"  # Separate database per tenant


@dataclass
class ResourceQuota:
    """Resource quotas for a tenant."""
    max_users: int = 100
    max_storage_gb: float = 10.0
    max_api_calls_per_day: int = 10000
    max_projects: int = 50
    max_custom_domains: int = 5
    features: Set[str] = field(default_factory=set)
    custom_limits: Dict[str, Any] = field(default_factory=dict)


@dataclass
class TenantUsage:
    """Current resource usage."""
    users: int = 0
    storage_gb: float = 0.0
    api_calls_today: int = 0
    projects: int = 0
    custom_domains: int = 0
    last_updated: datetime = field(default_factory=datetime.now)


@dataclass
class Tenant:
    """A tenant organization."""
    id: str
    name: str
    slug: str
    status: TenantStatus = TenantStatus.ACTIVE
    isolation: IsolationLevel = IsolationLevel.SHARED
    quota: ResourceQuota = field(default_factory=ResourceQuota)
    usage: TenantUsage = field(default_factory=TenantUsage)
    settings: Dict[str, Any] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    owner_id: Optional[str] = None
    parent_tenant_id: Optional[str] = None  # For hierarchical tenants

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "slug": self.slug,
            "status": self.status.value,
            "isolation": self.isolation.value,
            "created_at": self.created_at.isoformat(),
            "quota": {
                "max_users": self.quota.max_users,
                "max_storage_gb": self.quota.max_storage_gb
            },
            "usage": {
                "users": self.usage.users,
                "storage_gb": self.usage.storage_gb
            }
        }


@dataclass
class TenantMember:
    """A member of a tenant."""
    id: str
    tenant_id: str
    user_id: str
    role: str = "member"
    permissions: Set[str] = field(default_factory=set)
    joined_at: datetime = field(default_factory=datetime.now)


class TenantStore:
    """Store for tenant data."""

    def __init__(self):
        self.tenants: Dict[str, Tenant] = {}
        self.members: Dict[str, List[TenantMember]] = {}  # tenant_id -> members
        self.user_tenants: Dict[str, Set[str]] = {}  # user_id -> tenant_ids
        self._lock = threading.Lock()

    def save_tenant(self, tenant: Tenant) -> None:
        with self._lock:
            self.tenants[tenant.id] = tenant

    def get_tenant(self, tenant_id: str) -> Optional[Tenant]:
        return self.tenants.get(tenant_id)

    def get_by_slug(self, slug: str) -> Optional[Tenant]:
        for tenant in self.tenants.values():
            if tenant.slug == slug:
                return tenant
        return None

    def delete_tenant(self, tenant_id: str) -> bool:
        with self._lock:
            if tenant_id in self.tenants:
                del self.tenants[tenant_id]
                self.members.pop(tenant_id, None)
                return True
        return False

    def add_member(self, member: TenantMember) -> None:
        with self._lock:
            if member.tenant_id not in self.members:
                self.members[member.tenant_id] = []
            self.members[member.tenant_id].append(member)
            
            if member.user_id not in self.user_tenants:
                self.user_tenants[member.user_id] = set()
            self.user_tenants[member.user_id].add(member.tenant_id)

    def remove_member(self, tenant_id: str, user_id: str) -> bool:
        with self._lock:
            if tenant_id in self.members:
                self.members[tenant_id] = [
                    m for m in self.members[tenant_id] if m.user_id != user_id
                ]
                if user_id in self.user_tenants:
                    self.user_tenants[user_id].discard(tenant_id)
                return True
        return False

    def get_members(self, tenant_id: str) -> List[TenantMember]:
        return self.members.get(tenant_id, [])

    def get_user_tenants(self, user_id: str) -> List[Tenant]:
        tenant_ids = self.user_tenants.get(user_id, set())
        return [self.tenants[tid] for tid in tenant_ids if tid in self.tenants]

    def list_tenants(
        self,
        status: Optional[TenantStatus] = None,
        limit: int = 100
    ) -> List[Tenant]:
        tenants = list(self.tenants.values())
        if status:
            tenants = [t for t in tenants if t.status == status]
        return sorted(tenants, key=lambda t: t.created_at, reverse=True)[:limit]


class TenantContext:
    """Thread-local tenant context."""
    _context = threading.local()

    @classmethod
    def set_tenant(cls, tenant_id: str) -> None:
        cls._context.tenant_id = tenant_id

    @classmethod
    def get_tenant(cls) -> Optional[str]:
        return getattr(cls._context, 'tenant_id', None)

    @classmethod
    def clear(cls) -> None:
        cls._context.tenant_id = None


class QuotaEnforcer:
    """Enforce resource quotas."""

    def __init__(self, store: TenantStore):
        self.store = store

    def check_quota(self, tenant_id: str, resource: str, amount: int = 1) -> bool:
        """Check if resource usage is within quota."""
        tenant = self.store.get_tenant(tenant_id)
        if not tenant:
            return False

        quota = tenant.quota
        usage = tenant.usage

        checks = {
            "users": (usage.users + amount <= quota.max_users),
            "storage": (usage.storage_gb + amount <= quota.max_storage_gb),
            "api_calls": (usage.api_calls_today + amount <= quota.max_api_calls_per_day),
            "projects": (usage.projects + amount <= quota.max_projects),
            "domains": (usage.custom_domains + amount <= quota.max_custom_domains)
        }

        return checks.get(resource, True)

    def increment_usage(self, tenant_id: str, resource: str, amount: int = 1) -> bool:
        """Increment resource usage."""
        if not self.check_quota(tenant_id, resource, amount):
            return False

        tenant = self.store.get_tenant(tenant_id)
        if not tenant:
            return False

        if resource == "users":
            tenant.usage.users += amount
        elif resource == "storage":
            tenant.usage.storage_gb += amount
        elif resource == "api_calls":
            tenant.usage.api_calls_today += amount
        elif resource == "projects":
            tenant.usage.projects += amount
        elif resource == "domains":
            tenant.usage.custom_domains += amount

        tenant.usage.last_updated = datetime.now()
        return True

    def decrement_usage(self, tenant_id: str, resource: str, amount: int = 1) -> None:
        """Decrement resource usage."""
        tenant = self.store.get_tenant(tenant_id)
        if not tenant:
            return

        if resource == "users":
            tenant.usage.users = max(0, tenant.usage.users - amount)
        elif resource == "projects":
            tenant.usage.projects = max(0, tenant.usage.projects - amount)


class TenantResolver:
    """Resolve tenant from various sources."""

    def __init__(self, store: TenantStore):
        self.store = store
        self.resolvers: List[Callable[[Dict], Optional[str]]] = []

    def add_resolver(self, resolver: Callable[[Dict], Optional[str]]) -> None:
        """Add a tenant resolver."""
        self.resolvers.append(resolver)

    def resolve(self, context: Dict[str, Any]) -> Optional[str]:
        """Resolve tenant ID from context."""
        for resolver in self.resolvers:
            tenant_id = resolver(context)
            if tenant_id:
                return tenant_id
        return None

    @staticmethod
    def from_header(header_name: str = "X-Tenant-ID") -> Callable:
        """Resolver from HTTP header."""
        def resolver(context: Dict) -> Optional[str]:
            headers = context.get("headers", {})
            return headers.get(header_name)
        return resolver

    @staticmethod
    def from_subdomain() -> Callable:
        """Resolver from subdomain."""
        def resolver(context: Dict) -> Optional[str]:
            host = context.get("host", "")
            parts = host.split(".")
            if len(parts) >= 3:
                return parts[0]  # Return subdomain
            return None
        return resolver

    @staticmethod
    def from_path_prefix() -> Callable:
        """Resolver from URL path prefix."""
        def resolver(context: Dict) -> Optional[str]:
            path = context.get("path", "")
            parts = path.strip("/").split("/")
            if parts and parts[0].startswith("tenant-"):
                return parts[0].replace("tenant-", "")
            return None
        return resolver


class TenantManager:
    """High-level tenant management."""

    def __init__(self):
        self.store = TenantStore()
        self.enforcer = QuotaEnforcer(self.store)
        self.resolver = TenantResolver(self.store)
        
        # Setup default resolvers
        self.resolver.add_resolver(TenantResolver.from_header())
        self.resolver.add_resolver(TenantResolver.from_subdomain())

    def create_tenant(
        self,
        name: str,
        slug: str,
        owner_id: str,
        quota: Optional[ResourceQuota] = None,
        isolation: IsolationLevel = IsolationLevel.SHARED
    ) -> Tenant:
        """Create a new tenant."""
        # Check slug uniqueness
        if self.store.get_by_slug(slug):
            raise ValueError(f"Slug already exists: {slug}")

        tenant_id = str(uuid.uuid4())
        
        tenant = Tenant(
            id=tenant_id,
            name=name,
            slug=slug,
            owner_id=owner_id,
            quota=quota or ResourceQuota(),
            isolation=isolation
        )
        
        self.store.save_tenant(tenant)
        
        # Add owner as admin
        self.add_member(tenant_id, owner_id, role="admin")
        
        logger.info(f"Created tenant: {name} ({tenant_id})")
        return tenant

    def get_tenant(self, tenant_id: str) -> Optional[Tenant]:
        """Get tenant by ID."""
        return self.store.get_tenant(tenant_id)

    def get_by_slug(self, slug: str) -> Optional[Tenant]:
        """Get tenant by slug."""
        return self.store.get_by_slug(slug)

    def update_tenant(
        self,
        tenant_id: str,
        name: Optional[str] = None,
        settings: Optional[Dict] = None,
        status: Optional[TenantStatus] = None
    ) -> Optional[Tenant]:
        """Update tenant."""
        tenant = self.store.get_tenant(tenant_id)
        if not tenant:
            return None

        if name:
            tenant.name = name
        if settings:
            tenant.settings.update(settings)
        if status:
            tenant.status = status

        self.store.save_tenant(tenant)
        return tenant

    def suspend_tenant(self, tenant_id: str, reason: str = "") -> bool:
        """Suspend a tenant."""
        tenant = self.store.get_tenant(tenant_id)
        if tenant:
            tenant.status = TenantStatus.SUSPENDED
            tenant.metadata["suspension_reason"] = reason
            tenant.metadata["suspended_at"] = datetime.now().isoformat()
            self.store.save_tenant(tenant)
            return True
        return False

    def activate_tenant(self, tenant_id: str) -> bool:
        """Activate a suspended tenant."""
        tenant = self.store.get_tenant(tenant_id)
        if tenant and tenant.status == TenantStatus.SUSPENDED:
            tenant.status = TenantStatus.ACTIVE
            self.store.save_tenant(tenant)
            return True
        return False

    def delete_tenant(self, tenant_id: str) -> bool:
        """Delete a tenant."""
        return self.store.delete_tenant(tenant_id)

    def add_member(
        self,
        tenant_id: str,
        user_id: str,
        role: str = "member",
        permissions: Set[str] = None
    ) -> Optional[TenantMember]:
        """Add member to tenant."""
        if not self.enforcer.check_quota(tenant_id, "users"):
            logger.warning(f"User quota exceeded for tenant {tenant_id}")
            return None

        member = TenantMember(
            id=str(uuid.uuid4()),
            tenant_id=tenant_id,
            user_id=user_id,
            role=role,
            permissions=permissions or set()
        )
        
        self.store.add_member(member)
        self.enforcer.increment_usage(tenant_id, "users")
        
        return member

    def remove_member(self, tenant_id: str, user_id: str) -> bool:
        """Remove member from tenant."""
        result = self.store.remove_member(tenant_id, user_id)
        if result:
            self.enforcer.decrement_usage(tenant_id, "users")
        return result

    def get_members(self, tenant_id: str) -> List[TenantMember]:
        """Get tenant members."""
        return self.store.get_members(tenant_id)

    def get_user_tenants(self, user_id: str) -> List[Tenant]:
        """Get tenants for a user."""
        return self.store.get_user_tenants(user_id)

    def check_access(self, tenant_id: str, user_id: str, permission: str = None) -> bool:
        """Check if user has access to tenant."""
        members = self.store.get_members(tenant_id)
        for member in members:
            if member.user_id == user_id:
                if permission:
                    return permission in member.permissions or member.role == "admin"
                return True
        return False

    def list_tenants(self, **kwargs) -> List[Dict[str, Any]]:
        """List tenants."""
        tenants = self.store.list_tenants(**kwargs)
        return [t.to_dict() for t in tenants]


# Decorator for tenant-aware functions
def require_tenant(func: Callable) -> Callable:
    """Decorator to require tenant context."""
    def wrapper(*args, **kwargs):
        tenant_id = TenantContext.get_tenant()
        if not tenant_id:
            raise ValueError("Tenant context not set")
        kwargs['tenant_id'] = tenant_id
        return func(*args, **kwargs)
    return wrapper


# Example usage
def example_usage():
    """Example multi-tenancy usage."""
    manager = TenantManager()

    # Create tenant
    tenant = manager.create_tenant(
        name="Acme Corp",
        slug="acme",
        owner_id="user-123",
        quota=ResourceQuota(max_users=50, max_storage_gb=100)
    )

    print(f"Created tenant: {tenant.name} ({tenant.id})")

    # Add members
    manager.add_member(tenant.id, "user-456", role="member")
    manager.add_member(tenant.id, "user-789", role="admin")

    # Check access
    has_access = manager.check_access(tenant.id, "user-456")
    print(f"User 456 has access: {has_access}")

    # Set tenant context
    TenantContext.set_tenant(tenant.id)
    current = TenantContext.get_tenant()
    print(f"Current tenant: {current}")

    # Get tenant info
    info = manager.get_tenant(tenant.id)
    print(f"Tenant quota: {info.quota.max_users} users")
    print(f"Current users: {info.usage.users}")

    # List tenants
    tenants = manager.list_tenants()
    print(f"Total tenants: {len(tenants)}")
