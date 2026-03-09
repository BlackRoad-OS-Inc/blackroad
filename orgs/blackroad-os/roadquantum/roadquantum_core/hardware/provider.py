"""Hardware providers.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, List, Optional

@dataclass
class BackendInfo:
    name: str
    num_qubits: int
    basis_gates: List[str]
    online: bool = True

class Provider(ABC):
    @abstractmethod
    def get_backend(self, name: str) -> Any:
        pass
    
    @abstractmethod
    def backends(self) -> List[BackendInfo]:
        pass

class LocalProvider(Provider):
    def get_backend(self, name: str = "statevector") -> Any:
        from roadquantum_core.simulator import SimulatorBackend
        return SimulatorBackend()
    
    def backends(self) -> List[BackendInfo]:
        return [BackendInfo("statevector", 30, ["h", "x", "y", "z", "cx"])]

class IBMProvider(Provider):
    def __init__(self, token: Optional[str] = None):
        self.token = token
    
    def get_backend(self, name: str) -> Any:
        raise NotImplementedError("IBM backend requires IBM Quantum credentials")
    
    def backends(self) -> List[BackendInfo]:
        return []

__all__ = ["Provider", "IBMProvider", "LocalProvider", "BackendInfo"]
