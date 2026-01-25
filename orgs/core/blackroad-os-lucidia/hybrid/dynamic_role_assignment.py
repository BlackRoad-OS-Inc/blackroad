from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Any

@dataclass
class Role:
    """
    Represents a dynamic role for an agent with a set of capabilities.
    """
    name: str
    capabilities: Dict[str, Any]

class RoleAssigner:
    """Assigns roles dynamically to agents based on context."""

    def assign(self, agent: str, context: Dict[str, Any]) -> Role:
        """
        Very naive assignment: create a role with context keys as capabilities.
        """
        role_name = f"{agent}_role"
        return Role(role_name, capabilities=context)

if __name__ == "__main__":
    assigner = RoleAssigner()
    r = assigner.assign("Guardian", {"monitor": True, "level": 3})
    print(r)
