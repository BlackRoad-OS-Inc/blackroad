"""Quantum and Classical Registers.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterator, List, Optional, Union


@dataclass
class Qubit:
    """A single qubit."""

    index: int
    register: Optional["QuantumRegister"] = None

    def __hash__(self) -> int:
        return hash((self.index, id(self.register)))

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Qubit):
            return False
        return self.index == other.index and self.register is other.register

    def __repr__(self) -> str:
        if self.register and self.register.name:
            return f"{self.register.name}[{self.index}]"
        return f"q[{self.index}]"


@dataclass
class Clbit:
    """A single classical bit."""

    index: int
    register: Optional["ClassicalRegister"] = None

    def __hash__(self) -> int:
        return hash((self.index, id(self.register)))

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Clbit):
            return False
        return self.index == other.index and self.register is other.register

    def __repr__(self) -> str:
        if self.register and self.register.name:
            return f"{self.register.name}[{self.index}]"
        return f"c[{self.index}]"


class QuantumRegister:
    """A register of qubits.

    Example:
        qr = QuantumRegister(3, name="q")
        circuit.h(qr[0])
        circuit.cx(qr[0], qr[1])
    """

    def __init__(self, size: int, name: Optional[str] = None):
        self.size = size
        self.name = name or "q"
        self._qubits = [Qubit(i, self) for i in range(size)]

    def __len__(self) -> int:
        return self.size

    def __getitem__(self, key: Union[int, slice]) -> Union[Qubit, List[Qubit]]:
        if isinstance(key, slice):
            return self._qubits[key]
        return self._qubits[key]

    def __iter__(self) -> Iterator[Qubit]:
        return iter(self._qubits)

    def __repr__(self) -> str:
        return f"QuantumRegister({self.size}, '{self.name}')"

    @property
    def qubits(self) -> List[Qubit]:
        """Get all qubits."""
        return self._qubits.copy()


class ClassicalRegister:
    """A register of classical bits.

    Example:
        cr = ClassicalRegister(3, name="c")
        circuit.measure(qr[0], cr[0])
    """

    def __init__(self, size: int, name: Optional[str] = None):
        self.size = size
        self.name = name or "c"
        self._bits = [Clbit(i, self) for i in range(size)]

    def __len__(self) -> int:
        return self.size

    def __getitem__(self, key: Union[int, slice]) -> Union[Clbit, List[Clbit]]:
        if isinstance(key, slice):
            return self._bits[key]
        return self._bits[key]

    def __iter__(self) -> Iterator[Clbit]:
        return iter(self._bits)

    def __repr__(self) -> str:
        return f"ClassicalRegister({self.size}, '{self.name}')"

    @property
    def bits(self) -> List[Clbit]:
        """Get all bits."""
        return self._bits.copy()


__all__ = ["QuantumRegister", "ClassicalRegister", "Qubit", "Clbit"]
