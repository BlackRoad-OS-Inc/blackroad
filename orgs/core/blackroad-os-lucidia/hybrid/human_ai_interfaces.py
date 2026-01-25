from __future__ import annotations

from dataclasses import dataclass

@dataclass
class Interface:
    """Represents an interface between a human and AI."""
    name: str
    description: str
    version: str = "1.0"


class InterfaceManager:
    """Manage human-AI interfaces."""
    def __init__(self) -> None:
        self.interfaces: dict[str, Interface] = {}

    def register(self, iface: Interface) -> None:
        """Register a new interface."""
        self.interfaces[iface.name] = iface

    def get(self, name: str) -> Interface | None:
        """Retrieve an interface by name."""
        return self.interfaces.get(name)


if __name__ == "__main__":
    manager = InterfaceManager()
    manager.register(Interface("CLI", "Command line interface"))
    print(manager.get("CLI"))
