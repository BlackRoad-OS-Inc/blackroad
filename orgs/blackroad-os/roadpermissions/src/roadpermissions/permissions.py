"""
RoadPermissions - Role-Based Access Control for BlackRoad
Fine-grained permissions with roles, policies, and resource-based access.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Union
import fnmatch
import hashlib
import json
import logging
import threading

logger = logging.getLogger(__name__)


class Action(str, Enum):
    """Permission actions."""
    CREATE = "create"
    READ = "read"
    UPDATE = "update"
    DELETE = "delete"
    LIST = "list"
    EXECUTE = "execute"
    ADMIN = "admin"
    ALL = "*"


class Effect(str, Enum):
    """Policy effect."""
    ALLOW = "allow"
    DENY = "deny"


@dataclass
class Resource:
    """A resource identifier."""
    type: str
    id: Optional[str] = None
    attributes: Dict[str, Any] = field(default_factory=dict)

    def matches(self, pattern: str) -> bool:
        """Check if resource matches pattern."""
        resource_str = f"{self.type}:{self.id or '*'}"
        return fnmatch.fnmatch(resource_str, pattern)

    def __str__(self) -> str:
        return f"{self.type}:{self.id or '*'}"


@dataclass
class Permission:
    """A single permission."""
    action: Action
    resource_pattern: str
    conditions: Dict[str, Any] = field(default_factory=dict)

    def matches(self, action: Action, resource: Resource) -> bool:
        """Check if permission matches action and resource."""
        if self.action != Action.ALL and self.action != action:
            return False
        return resource.matches(self.resource_pattern)


@dataclass
class Policy:
    """A policy document."""
    id: str
    name: str
    effect: Effect
    permissions: List[Permission]
    description: str = ""
    priority: int = 0
    conditions: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)

    def evaluate(self, action: Action, resource: Resource, context: Dict[str, Any] = None) -> Optional[Effect]:
        """Evaluate policy against action and resource."""
        for permission in self.permissions:
            if permission.matches(action, resource):
                if self._check_conditions(context or {}):
                    return self.effect
        return None

    def _check_conditions(self, context: Dict[str, Any]) -> bool:
        """Check if conditions are met."""
        for key, expected in self.conditions.items():
            if key not in context:
                return False
            if context[key] != expected:
                return False
        return True

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "effect": self.effect.value,
            "permissions": [
                {"action": p.action.value, "resource": p.resource_pattern}
                for p in self.permissions
            ],
            "description": self.description,
            "priority": self.priority
        }


@dataclass
class Role:
    """A role with attached policies."""
    id: str
    name: str
    policies: List[str]  # Policy IDs
    description: str = ""
    parent_roles: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "policies": self.policies,
            "description": self.description,
            "parent_roles": self.parent_roles
        }


@dataclass
class Subject:
    """A subject (user, service, etc.)."""
    id: str
    type: str = "user"
    roles: Set[str] = field(default_factory=set)
    direct_policies: List[str] = field(default_factory=list)
    attributes: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "type": self.type,
            "roles": list(self.roles),
            "direct_policies": self.direct_policies,
            "attributes": self.attributes
        }


class PolicyStore:
    """Store for policies and roles."""

    def __init__(self):
        self.policies: Dict[str, Policy] = {}
        self.roles: Dict[str, Role] = {}
        self.subjects: Dict[str, Subject] = {}
        self._lock = threading.Lock()

    def add_policy(self, policy: Policy) -> None:
        with self._lock:
            self.policies[policy.id] = policy
            logger.info(f"Added policy: {policy.name}")

    def get_policy(self, policy_id: str) -> Optional[Policy]:
        return self.policies.get(policy_id)

    def remove_policy(self, policy_id: str) -> bool:
        with self._lock:
            if policy_id in self.policies:
                del self.policies[policy_id]
                return True
            return False

    def add_role(self, role: Role) -> None:
        with self._lock:
            self.roles[role.id] = role
            logger.info(f"Added role: {role.name}")

    def get_role(self, role_id: str) -> Optional[Role]:
        return self.roles.get(role_id)

    def remove_role(self, role_id: str) -> bool:
        with self._lock:
            if role_id in self.roles:
                del self.roles[role_id]
                return True
            return False

    def add_subject(self, subject: Subject) -> None:
        with self._lock:
            self.subjects[subject.id] = subject

    def get_subject(self, subject_id: str) -> Optional[Subject]:
        return self.subjects.get(subject_id)

    def assign_role(self, subject_id: str, role_id: str) -> bool:
        with self._lock:
            subject = self.subjects.get(subject_id)
            if subject and role_id in self.roles:
                subject.roles.add(role_id)
                return True
            return False

    def revoke_role(self, subject_id: str, role_id: str) -> bool:
        with self._lock:
            subject = self.subjects.get(subject_id)
            if subject:
                subject.roles.discard(role_id)
                return True
            return False


class PermissionEvaluator:
    """Evaluate permissions for subjects."""

    def __init__(self, store: PolicyStore):
        self.store = store
        self._cache: Dict[str, Dict[str, bool]] = {}
        self._cache_ttl = 300  # 5 minutes

    def _get_all_policies(self, subject: Subject) -> List[Policy]:
        """Get all policies for a subject including inherited."""
        policies = []
        seen_roles = set()

        def collect_role_policies(role_id: str):
            if role_id in seen_roles:
                return
            seen_roles.add(role_id)

            role = self.store.get_role(role_id)
            if not role:
                return

            for parent_id in role.parent_roles:
                collect_role_policies(parent_id)

            for policy_id in role.policies:
                policy = self.store.get_policy(policy_id)
                if policy:
                    policies.append(policy)

        for role_id in subject.roles:
            collect_role_policies(role_id)

        for policy_id in subject.direct_policies:
            policy = self.store.get_policy(policy_id)
            if policy:
                policies.append(policy)

        return sorted(policies, key=lambda p: p.priority, reverse=True)

    def check(
        self,
        subject_id: str,
        action: Action,
        resource: Resource,
        context: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Check if subject can perform action on resource."""
        subject = self.store.get_subject(subject_id)
        if not subject:
            return False

        policies = self._get_all_policies(subject)
        
        # Deny takes precedence
        for policy in policies:
            effect = policy.evaluate(action, resource, context)
            if effect == Effect.DENY:
                logger.debug(f"Denied by policy: {policy.name}")
                return False

        # Check for allow
        for policy in policies:
            effect = policy.evaluate(action, resource, context)
            if effect == Effect.ALLOW:
                logger.debug(f"Allowed by policy: {policy.name}")
                return True

        return False

    def filter_resources(
        self,
        subject_id: str,
        action: Action,
        resources: List[Resource]
    ) -> List[Resource]:
        """Filter resources subject can access."""
        return [r for r in resources if self.check(subject_id, action, r)]


class PermissionManager:
    """High-level permission management."""

    def __init__(self):
        self.store = PolicyStore()
        self.evaluator = PermissionEvaluator(self.store)
        self._setup_default_policies()

    def _setup_default_policies(self):
        """Setup default admin policy."""
        admin_policy = Policy(
            id="admin-all",
            name="Admin Full Access",
            effect=Effect.ALLOW,
            permissions=[Permission(Action.ALL, "*:*")],
            priority=1000
        )
        self.store.add_policy(admin_policy)

        admin_role = Role(
            id="admin",
            name="Administrator",
            policies=["admin-all"],
            description="Full system access"
        )
        self.store.add_role(admin_role)

    def create_policy(
        self,
        name: str,
        effect: Effect,
        actions: List[Action],
        resources: List[str],
        description: str = "",
        conditions: Dict[str, Any] = None
    ) -> Policy:
        """Create a new policy."""
        policy_id = hashlib.md5(f"{name}{datetime.now()}".encode()).hexdigest()[:12]
        
        permissions = [
            Permission(action, resource)
            for action in actions
            for resource in resources
        ]

        policy = Policy(
            id=policy_id,
            name=name,
            effect=effect,
            permissions=permissions,
            description=description,
            conditions=conditions or {}
        )
        
        self.store.add_policy(policy)
        return policy

    def create_role(
        self,
        name: str,
        policy_ids: List[str],
        description: str = "",
        parent_roles: List[str] = None
    ) -> Role:
        """Create a new role."""
        role_id = hashlib.md5(f"{name}{datetime.now()}".encode()).hexdigest()[:12]
        
        role = Role(
            id=role_id,
            name=name,
            policies=policy_ids,
            description=description,
            parent_roles=parent_roles or []
        )
        
        self.store.add_role(role)
        return role

    def create_subject(
        self,
        subject_id: str,
        subject_type: str = "user",
        roles: List[str] = None,
        attributes: Dict[str, Any] = None
    ) -> Subject:
        """Create or update a subject."""
        subject = Subject(
            id=subject_id,
            type=subject_type,
            roles=set(roles or []),
            attributes=attributes or {}
        )
        self.store.add_subject(subject)
        return subject

    def can(
        self,
        subject_id: str,
        action: Union[Action, str],
        resource_type: str,
        resource_id: Optional[str] = None,
        context: Dict[str, Any] = None
    ) -> bool:
        """Check if subject can perform action."""
        if isinstance(action, str):
            action = Action(action)
        
        resource = Resource(type=resource_type, id=resource_id)
        return self.evaluator.check(subject_id, action, resource, context)

    def assign_role(self, subject_id: str, role_id: str) -> bool:
        """Assign role to subject."""
        return self.store.assign_role(subject_id, role_id)

    def revoke_role(self, subject_id: str, role_id: str) -> bool:
        """Revoke role from subject."""
        return self.store.revoke_role(subject_id, role_id)

    def list_permissions(self, subject_id: str) -> List[Dict[str, Any]]:
        """List effective permissions for subject."""
        subject = self.store.get_subject(subject_id)
        if not subject:
            return []

        policies = self.evaluator._get_all_policies(subject)
        permissions = []
        
        for policy in policies:
            for perm in policy.permissions:
                permissions.append({
                    "policy": policy.name,
                    "effect": policy.effect.value,
                    "action": perm.action.value,
                    "resource": perm.resource_pattern
                })
        
        return permissions


# Decorator for permission checks
def require_permission(action: Action, resource_type: str):
    """Decorator to require permission for function."""
    def decorator(func: Callable):
        def wrapper(*args, **kwargs):
            # Get subject_id from kwargs or first arg
            subject_id = kwargs.get('subject_id') or (args[0] if args else None)
            resource_id = kwargs.get('resource_id')
            
            manager = kwargs.get('permission_manager')
            if manager and not manager.can(subject_id, action, resource_type, resource_id):
                raise PermissionError(f"Permission denied: {action.value} on {resource_type}")
            
            return func(*args, **kwargs)
        return wrapper
    return decorator


# Example usage
def example_usage():
    """Example permission system usage."""
    manager = PermissionManager()

    # Create policies
    read_users_policy = manager.create_policy(
        name="Read Users",
        effect=Effect.ALLOW,
        actions=[Action.READ, Action.LIST],
        resources=["user:*"],
        description="Allow reading user data"
    )

    manage_posts_policy = manager.create_policy(
        name="Manage Posts",
        effect=Effect.ALLOW,
        actions=[Action.CREATE, Action.READ, Action.UPDATE, Action.DELETE],
        resources=["post:*"],
        description="Full post management"
    )

    # Create roles
    viewer_role = manager.create_role(
        name="Viewer",
        policy_ids=[read_users_policy.id],
        description="Can view users"
    )

    editor_role = manager.create_role(
        name="Editor",
        policy_ids=[read_users_policy.id, manage_posts_policy.id],
        description="Can view users and manage posts",
        parent_roles=[viewer_role.id]
    )

    # Create subjects
    alice = manager.create_subject("alice", roles=[editor_role.id])
    bob = manager.create_subject("bob", roles=[viewer_role.id])

    # Check permissions
    print(f"Alice can read users: {manager.can('alice', Action.READ, 'user')}")
    print(f"Alice can create posts: {manager.can('alice', Action.CREATE, 'post')}")
    print(f"Bob can read users: {manager.can('bob', Action.READ, 'user')}")
    print(f"Bob can create posts: {manager.can('bob', Action.CREATE, 'post')}")

    # List permissions
    print(f"Alice's permissions: {manager.list_permissions('alice')}")
