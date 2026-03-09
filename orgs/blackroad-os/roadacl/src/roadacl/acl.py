"""
RoadACL - Access Control Lists for BlackRoad
Fine-grained permission management with roles, rules, and policies.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, Flag, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import fnmatch
import json
import logging
import re
import threading

logger = logging.getLogger(__name__)


class Permission(Flag):
    """Basic permissions."""
    NONE = 0
    READ = auto()
    WRITE = auto()
    CREATE = auto()
    DELETE = auto()
    EXECUTE = auto()
    ADMIN = auto()

    # Common combinations
    READ_WRITE = READ | WRITE
    FULL = READ | WRITE | CREATE | DELETE
    ALL = READ | WRITE | CREATE | DELETE | EXECUTE | ADMIN


class Effect(str, Enum):
    """Rule effect."""
    ALLOW = "allow"
    DENY = "deny"


@dataclass
class Principal:
    """A security principal (user, group, role, etc.)."""
    id: str
    type: str = "user"  # user, group, role, service
    name: Optional[str] = None
    attributes: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Resource:
    """A protected resource."""
    type: str
    id: Optional[str] = None
    path: Optional[str] = None
    attributes: Dict[str, Any] = field(default_factory=dict)

    def matches(self, pattern: "Resource") -> bool:
        """Check if this resource matches a pattern."""
        if pattern.type != "*" and pattern.type != self.type:
            return False

        if pattern.id:
            if pattern.id == "*":
                return True
            if pattern.id != self.id:
                return False

        if pattern.path:
            if pattern.path == "*":
                return True
            if not fnmatch.fnmatch(self.path or "", pattern.path):
                return False

        return True


@dataclass
class Condition:
    """A condition for rule evaluation."""
    type: str  # equals, not_equals, contains, regex, ip_range, time_range
    field: str
    value: Any

    def evaluate(self, context: Dict[str, Any]) -> bool:
        """Evaluate the condition against a context."""
        actual = self._get_field_value(context)

        if self.type == "equals":
            return actual == self.value
        elif self.type == "not_equals":
            return actual != self.value
        elif self.type == "contains":
            return self.value in (actual or [])
        elif self.type == "in":
            return actual in (self.value or [])
        elif self.type == "regex":
            return bool(re.match(self.value, str(actual or "")))
        elif self.type == "gt":
            return (actual or 0) > self.value
        elif self.type == "lt":
            return (actual or 0) < self.value
        elif self.type == "exists":
            return actual is not None

        return False

    def _get_field_value(self, context: Dict[str, Any]) -> Any:
        """Get nested field value from context."""
        parts = self.field.split(".")
        value = context
        for part in parts:
            if isinstance(value, dict):
                value = value.get(part)
            else:
                return None
        return value


@dataclass
class Rule:
    """An ACL rule."""
    id: str
    effect: Effect
    principals: List[str]  # Principal IDs or patterns
    resources: List[Resource]  # Resource patterns
    permissions: Permission
    conditions: List[Condition] = field(default_factory=list)
    priority: int = 0
    description: str = ""
    enabled: bool = True

    def matches_principal(self, principal: Principal) -> bool:
        """Check if rule applies to principal."""
        for pattern in self.principals:
            if pattern == "*":
                return True
            if pattern == principal.id:
                return True
            if pattern.startswith("type:") and pattern[5:] == principal.type:
                return True
            if fnmatch.fnmatch(principal.id, pattern):
                return True
        return False

    def matches_resource(self, resource: Resource) -> bool:
        """Check if rule applies to resource."""
        for pattern in self.resources:
            if resource.matches(pattern):
                return True
        return False

    def evaluate_conditions(self, context: Dict[str, Any]) -> bool:
        """Evaluate all conditions."""
        return all(c.evaluate(context) for c in self.conditions)


@dataclass
class Role:
    """A role with permissions."""
    id: str
    name: str
    permissions: Dict[str, Permission] = field(default_factory=dict)  # resource_type -> permissions
    parent_roles: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def get_permissions(self, resource_type: str) -> Permission:
        """Get permissions for a resource type."""
        return self.permissions.get(resource_type, Permission.NONE)


class RoleHierarchy:
    """Manage role inheritance."""

    def __init__(self):
        self.roles: Dict[str, Role] = {}
        self._lock = threading.Lock()

    def add_role(self, role: Role) -> None:
        """Add a role."""
        with self._lock:
            self.roles[role.id] = role

    def get_role(self, role_id: str) -> Optional[Role]:
        """Get a role by ID."""
        return self.roles.get(role_id)

    def get_effective_permissions(
        self,
        role_id: str,
        resource_type: str
    ) -> Permission:
        """Get permissions including inherited ones."""
        role = self.roles.get(role_id)
        if not role:
            return Permission.NONE

        permissions = role.get_permissions(resource_type)

        # Add parent permissions
        for parent_id in role.parent_roles:
            parent_perms = self.get_effective_permissions(parent_id, resource_type)
            permissions = permissions | parent_perms

        return permissions

    def get_all_roles(self, role_id: str) -> Set[str]:
        """Get all roles including inherited ones."""
        result = {role_id}
        role = self.roles.get(role_id)

        if role:
            for parent_id in role.parent_roles:
                result.update(self.get_all_roles(parent_id))

        return result


class ACLEngine:
    """Core ACL evaluation engine."""

    def __init__(self, default_effect: Effect = Effect.DENY):
        self.default_effect = default_effect
        self.rules: List[Rule] = []
        self.role_hierarchy = RoleHierarchy()
        self._lock = threading.Lock()

    def add_rule(self, rule: Rule) -> None:
        """Add a rule."""
        with self._lock:
            self.rules.append(rule)
            self.rules.sort(key=lambda r: r.priority, reverse=True)

    def remove_rule(self, rule_id: str) -> bool:
        """Remove a rule by ID."""
        with self._lock:
            for i, rule in enumerate(self.rules):
                if rule.id == rule_id:
                    self.rules.pop(i)
                    return True
        return False

    def check(
        self,
        principal: Principal,
        resource: Resource,
        permission: Permission,
        context: Dict[str, Any] = None
    ) -> bool:
        """Check if principal has permission on resource."""
        context = context or {}

        # Add principal and resource to context
        context["principal"] = {
            "id": principal.id,
            "type": principal.type,
            **principal.attributes
        }
        context["resource"] = {
            "type": resource.type,
            "id": resource.id,
            "path": resource.path,
            **resource.attributes
        }

        # Find matching rules
        matching_rules = []
        for rule in self.rules:
            if not rule.enabled:
                continue

            if not rule.matches_principal(principal):
                continue

            if not rule.matches_resource(resource):
                continue

            if not (rule.permissions & permission):
                continue

            if not rule.evaluate_conditions(context):
                continue

            matching_rules.append(rule)

        # Apply first matching rule (highest priority)
        for rule in matching_rules:
            if rule.effect == Effect.DENY:
                return False
            if rule.effect == Effect.ALLOW:
                return True

        # Check role-based permissions
        if principal.type == "user" and "roles" in principal.attributes:
            for role_id in principal.attributes["roles"]:
                role_perms = self.role_hierarchy.get_effective_permissions(
                    role_id, resource.type
                )
                if role_perms & permission:
                    return True

        # Default
        return self.default_effect == Effect.ALLOW

    def filter_resources(
        self,
        principal: Principal,
        resources: List[Resource],
        permission: Permission,
        context: Dict[str, Any] = None
    ) -> List[Resource]:
        """Filter resources by permission."""
        return [
            r for r in resources
            if self.check(principal, r, permission, context)
        ]


class ACLBuilder:
    """Builder for ACL rules."""

    def __init__(self):
        self._rules: List[Rule] = []
        self._current_rule: Dict[str, Any] = {}

    def allow(self) -> "ACLBuilder":
        """Start an allow rule."""
        self._current_rule = {"effect": Effect.ALLOW}
        return self

    def deny(self) -> "ACLBuilder":
        """Start a deny rule."""
        self._current_rule = {"effect": Effect.DENY}
        return self

    def principals(self, *principals: str) -> "ACLBuilder":
        """Set principals for current rule."""
        self._current_rule["principals"] = list(principals)
        return self

    def anyone(self) -> "ACLBuilder":
        """Allow any principal."""
        self._current_rule["principals"] = ["*"]
        return self

    def resources(self, *patterns: Resource) -> "ACLBuilder":
        """Set resource patterns."""
        self._current_rule["resources"] = list(patterns)
        return self

    def resource_type(self, rtype: str) -> "ACLBuilder":
        """Match resources of a type."""
        self._current_rule["resources"] = [Resource(type=rtype, id="*")]
        return self

    def permissions(self, perms: Permission) -> "ACLBuilder":
        """Set permissions."""
        self._current_rule["permissions"] = perms
        return self

    def read(self) -> "ACLBuilder":
        return self.permissions(Permission.READ)

    def write(self) -> "ACLBuilder":
        return self.permissions(Permission.WRITE)

    def full(self) -> "ACLBuilder":
        return self.permissions(Permission.FULL)

    def when(self, condition: Condition) -> "ACLBuilder":
        """Add a condition."""
        if "conditions" not in self._current_rule:
            self._current_rule["conditions"] = []
        self._current_rule["conditions"].append(condition)
        return self

    def priority(self, p: int) -> "ACLBuilder":
        """Set priority."""
        self._current_rule["priority"] = p
        return self

    def done(self, rule_id: str = None, description: str = "") -> "ACLBuilder":
        """Complete current rule."""
        import uuid
        rule = Rule(
            id=rule_id or str(uuid.uuid4())[:8],
            effect=self._current_rule.get("effect", Effect.DENY),
            principals=self._current_rule.get("principals", ["*"]),
            resources=self._current_rule.get("resources", []),
            permissions=self._current_rule.get("permissions", Permission.NONE),
            conditions=self._current_rule.get("conditions", []),
            priority=self._current_rule.get("priority", 0),
            description=description
        )
        self._rules.append(rule)
        self._current_rule = {}
        return self

    def build(self) -> List[Rule]:
        """Build all rules."""
        return self._rules


class ACLManager:
    """High-level ACL management."""

    def __init__(self, default_deny: bool = True):
        self.engine = ACLEngine(
            default_effect=Effect.DENY if default_deny else Effect.ALLOW
        )
        self._principals: Dict[str, Principal] = {}

    def add_principal(self, principal: Principal) -> None:
        """Register a principal."""
        self._principals[principal.id] = principal

    def get_principal(self, principal_id: str) -> Optional[Principal]:
        """Get a principal."""
        return self._principals.get(principal_id)

    def add_role(self, role: Role) -> None:
        """Add a role."""
        self.engine.role_hierarchy.add_role(role)

    def assign_role(self, principal_id: str, role_id: str) -> bool:
        """Assign a role to a principal."""
        principal = self._principals.get(principal_id)
        if not principal:
            return False

        if "roles" not in principal.attributes:
            principal.attributes["roles"] = []

        if role_id not in principal.attributes["roles"]:
            principal.attributes["roles"].append(role_id)

        return True

    def add_rule(self, rule: Rule) -> None:
        """Add an ACL rule."""
        self.engine.add_rule(rule)

    def can(
        self,
        principal_id: str,
        permission: Permission,
        resource: Resource,
        context: Dict[str, Any] = None
    ) -> bool:
        """Check if principal can perform action."""
        principal = self._principals.get(principal_id)
        if not principal:
            return False

        return self.engine.check(principal, resource, permission, context)

    def can_read(self, principal_id: str, resource: Resource) -> bool:
        return self.can(principal_id, Permission.READ, resource)

    def can_write(self, principal_id: str, resource: Resource) -> bool:
        return self.can(principal_id, Permission.WRITE, resource)

    def can_delete(self, principal_id: str, resource: Resource) -> bool:
        return self.can(principal_id, Permission.DELETE, resource)

    def filter(
        self,
        principal_id: str,
        permission: Permission,
        resources: List[Resource]
    ) -> List[Resource]:
        """Filter resources by permission."""
        principal = self._principals.get(principal_id)
        if not principal:
            return []

        return self.engine.filter_resources(principal, resources, permission)

    def builder(self) -> ACLBuilder:
        """Get a rule builder."""
        return ACLBuilder()

    def list_rules(self) -> List[Dict[str, Any]]:
        """List all rules."""
        return [
            {
                "id": r.id,
                "effect": r.effect.value,
                "principals": r.principals,
                "permissions": str(r.permissions),
                "priority": r.priority,
                "enabled": r.enabled
            }
            for r in self.engine.rules
        ]


# Example usage
def example_usage():
    """Example ACL usage."""
    acl = ACLManager()

    # Create roles
    admin_role = Role(
        id="admin",
        name="Administrator",
        permissions={"*": Permission.ALL}
    )

    editor_role = Role(
        id="editor",
        name="Editor",
        permissions={
            "document": Permission.READ_WRITE,
            "comment": Permission.FULL
        }
    )

    viewer_role = Role(
        id="viewer",
        name="Viewer",
        permissions={
            "document": Permission.READ,
            "comment": Permission.READ
        }
    )

    acl.add_role(admin_role)
    acl.add_role(editor_role)
    acl.add_role(viewer_role)

    # Create principals
    admin = Principal(id="admin-1", type="user", name="Admin")
    alice = Principal(id="alice", type="user", name="Alice")
    bob = Principal(id="bob", type="user", name="Bob")

    acl.add_principal(admin)
    acl.add_principal(alice)
    acl.add_principal(bob)

    # Assign roles
    acl.assign_role("admin-1", "admin")
    acl.assign_role("alice", "editor")
    acl.assign_role("bob", "viewer")

    # Add specific rules using builder
    rules = (
        acl.builder()
        .deny()
        .principals("bob")
        .resource_type("document")
        .permissions(Permission.DELETE)
        .priority(100)
        .done("deny-bob-delete", "Bob cannot delete documents")
        .allow()
        .principals("alice")
        .resources(Resource(type="document", path="/projects/secret/*"))
        .full()
        .done("alice-secret-access", "Alice has full access to secret projects")
        .build()
    )

    for rule in rules:
        acl.add_rule(rule)

    # Check permissions
    doc = Resource(type="document", id="doc-1", path="/projects/public/readme")
    secret_doc = Resource(type="document", id="doc-2", path="/projects/secret/plan")

    print(f"Admin can read doc: {acl.can_read('admin-1', doc)}")
    print(f"Alice can write doc: {acl.can_write('alice', doc)}")
    print(f"Bob can read doc: {acl.can_read('bob', doc)}")
    print(f"Bob can delete doc: {acl.can_delete('bob', doc)}")
    print(f"Alice can access secret: {acl.can_read('alice', secret_doc)}")

    # Filter resources
    resources = [
        Resource(type="document", id="1"),
        Resource(type="document", id="2"),
        Resource(type="comment", id="1"),
    ]

    visible = acl.filter("bob", Permission.READ, resources)
    print(f"Bob can see {len(visible)} resources")

    # List rules
    print(f"Rules: {acl.list_rules()}")

