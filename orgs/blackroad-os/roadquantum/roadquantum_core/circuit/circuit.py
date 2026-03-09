"""Quantum Circuit.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import copy
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union

import numpy as np

from roadquantum_core.circuit.register import QuantumRegister, ClassicalRegister, Qubit, Clbit
from roadquantum_core.circuit.instruction import (
    Instruction, Gate, Measurement, Barrier, Reset, Delay
)
from roadquantum_core.circuit.parameter import Parameter, ParameterExpression


@dataclass
class CircuitInstruction:
    """An instruction applied to specific qubits."""

    instruction: Instruction
    qubits: List[Qubit]
    clbits: List[Clbit] = field(default_factory=list)

    def __repr__(self) -> str:
        qubits_str = ", ".join(str(q) for q in self.qubits)
        if self.clbits:
            clbits_str = ", ".join(str(c) for c in self.clbits)
            return f"{self.instruction.name}({qubits_str}) -> {clbits_str}"
        return f"{self.instruction.name}({qubits_str})"


class QuantumCircuit:
    """A quantum circuit.

    A quantum circuit is a sequence of quantum gates and measurements
    applied to quantum registers.

    Example:
        # Create circuit with quantum and classical registers
        qr = QuantumRegister(2)
        cr = ClassicalRegister(2)
        circuit = QuantumCircuit(qr, cr)

        # Apply gates
        circuit.h(0)           # Hadamard
        circuit.cx(0, 1)       # CNOT
        circuit.measure_all()  # Measure all qubits

    Attributes:
        qregs: Quantum registers
        cregs: Classical registers
        num_qubits: Total number of qubits
        num_clbits: Total number of classical bits
        data: List of circuit instructions
    """

    def __init__(
        self,
        *regs: Union[QuantumRegister, ClassicalRegister, int],
        name: Optional[str] = None,
    ):
        self.name = name or "circuit"
        self.qregs: List[QuantumRegister] = []
        self.cregs: List[ClassicalRegister] = []
        self._data: List[CircuitInstruction] = []
        self._qubit_map: Dict[Qubit, int] = {}
        self._clbit_map: Dict[Clbit, int] = {}
        self._parameters: Set[Parameter] = set()

        for reg in regs:
            if isinstance(reg, QuantumRegister):
                self.add_register(reg)
            elif isinstance(reg, ClassicalRegister):
                self.add_register(reg)
            elif isinstance(reg, int):
                self.add_register(QuantumRegister(reg))

    @property
    def num_qubits(self) -> int:
        return sum(len(qr) for qr in self.qregs)

    @property
    def num_clbits(self) -> int:
        return sum(len(cr) for cr in self.cregs)

    @property
    def qubits(self) -> List[Qubit]:
        """All qubits in circuit."""
        return [q for qr in self.qregs for q in qr]

    @property
    def clbits(self) -> List[Clbit]:
        """All classical bits in circuit."""
        return [c for cr in self.cregs for c in cr]

    @property
    def data(self) -> List[CircuitInstruction]:
        """Circuit instructions."""
        return self._data

    @property
    def parameters(self) -> Set[Parameter]:
        """Parameters in circuit."""
        return self._parameters.copy()

    @property
    def depth(self) -> int:
        """Circuit depth."""
        if not self._data:
            return 0

        qubit_depth = {i: 0 for i in range(self.num_qubits)}

        for inst in self._data:
            indices = [self._qubit_map[q] for q in inst.qubits]
            max_depth = max(qubit_depth[i] for i in indices)
            new_depth = max_depth + 1
            for i in indices:
                qubit_depth[i] = new_depth

        return max(qubit_depth.values())

    def add_register(self, reg: Union[QuantumRegister, ClassicalRegister]) -> None:
        """Add a register to the circuit."""
        if isinstance(reg, QuantumRegister):
            start_idx = self.num_qubits
            self.qregs.append(reg)
            for i, qubit in enumerate(reg):
                self._qubit_map[qubit] = start_idx + i
        elif isinstance(reg, ClassicalRegister):
            start_idx = self.num_clbits
            self.cregs.append(reg)
            for i, clbit in enumerate(reg):
                self._clbit_map[clbit] = start_idx + i

    def _resolve_qubit(self, qubit: Union[Qubit, int]) -> Qubit:
        """Resolve qubit reference."""
        if isinstance(qubit, int):
            return self.qubits[qubit]
        return qubit

    def _resolve_clbit(self, clbit: Union[Clbit, int]) -> Clbit:
        """Resolve classical bit reference."""
        if isinstance(clbit, int):
            return self.clbits[clbit]
        return clbit

    def _append_instruction(
        self,
        instruction: Instruction,
        qubits: List[Union[Qubit, int]],
        clbits: Optional[List[Union[Clbit, int]]] = None,
    ) -> "QuantumCircuit":
        """Append an instruction."""
        resolved_qubits = [self._resolve_qubit(q) for q in qubits]
        resolved_clbits = [self._resolve_clbit(c) for c in (clbits or [])]

        for param in instruction.params:
            if isinstance(param, Parameter):
                self._parameters.add(param)
            elif isinstance(param, ParameterExpression):
                self._parameters.update(param.parameters)

        self._data.append(CircuitInstruction(
            instruction=instruction,
            qubits=resolved_qubits,
            clbits=resolved_clbits,
        ))

        return self

    # Single-qubit gates
    def h(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply Hadamard gate."""
        from roadquantum_core.gates.standard import HGate
        return self._append_instruction(HGate(), [qubit])

    def x(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply Pauli-X (NOT) gate."""
        from roadquantum_core.gates.standard import XGate
        return self._append_instruction(XGate(), [qubit])

    def y(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply Pauli-Y gate."""
        from roadquantum_core.gates.standard import YGate
        return self._append_instruction(YGate(), [qubit])

    def z(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply Pauli-Z gate."""
        from roadquantum_core.gates.standard import ZGate
        return self._append_instruction(ZGate(), [qubit])

    def s(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply S gate (sqrt(Z))."""
        from roadquantum_core.gates.standard import SGate
        return self._append_instruction(SGate(), [qubit])

    def sdg(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply S-dagger gate."""
        from roadquantum_core.gates.standard import SdgGate
        return self._append_instruction(SdgGate(), [qubit])

    def t(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply T gate (sqrt(S))."""
        from roadquantum_core.gates.standard import TGate
        return self._append_instruction(TGate(), [qubit])

    def tdg(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply T-dagger gate."""
        from roadquantum_core.gates.standard import TdgGate
        return self._append_instruction(TdgGate(), [qubit])

    # Rotation gates
    def rx(self, theta: Union[float, Parameter], qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply rotation around X-axis."""
        from roadquantum_core.gates.rotation import RXGate
        return self._append_instruction(RXGate(theta), [qubit])

    def ry(self, theta: Union[float, Parameter], qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply rotation around Y-axis."""
        from roadquantum_core.gates.rotation import RYGate
        return self._append_instruction(RYGate(theta), [qubit])

    def rz(self, theta: Union[float, Parameter], qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply rotation around Z-axis."""
        from roadquantum_core.gates.rotation import RZGate
        return self._append_instruction(RZGate(theta), [qubit])

    def u(
        self,
        theta: Union[float, Parameter],
        phi: Union[float, Parameter],
        lam: Union[float, Parameter],
        qubit: Union[Qubit, int],
    ) -> "QuantumCircuit":
        """Apply general single-qubit unitary."""
        from roadquantum_core.gates.rotation import UGate
        return self._append_instruction(UGate(theta, phi, lam), [qubit])

    # Two-qubit gates
    def cx(
        self,
        control: Union[Qubit, int],
        target: Union[Qubit, int],
    ) -> "QuantumCircuit":
        """Apply CNOT (controlled-X) gate."""
        from roadquantum_core.gates.standard import CXGate
        return self._append_instruction(CXGate(), [control, target])

    def cnot(self, control: Union[Qubit, int], target: Union[Qubit, int]) -> "QuantumCircuit":
        """Alias for cx."""
        return self.cx(control, target)

    def cy(self, control: Union[Qubit, int], target: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply controlled-Y gate."""
        from roadquantum_core.gates.standard import CYGate
        return self._append_instruction(CYGate(), [control, target])

    def cz(self, control: Union[Qubit, int], target: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply controlled-Z gate."""
        from roadquantum_core.gates.standard import CZGate
        return self._append_instruction(CZGate(), [control, target])

    def swap(self, qubit1: Union[Qubit, int], qubit2: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply SWAP gate."""
        from roadquantum_core.gates.standard import SwapGate
        return self._append_instruction(SwapGate(), [qubit1, qubit2])

    def iswap(self, qubit1: Union[Qubit, int], qubit2: Union[Qubit, int]) -> "QuantumCircuit":
        """Apply iSWAP gate."""
        from roadquantum_core.gates.standard import iSwapGate
        return self._append_instruction(iSwapGate(), [qubit1, qubit2])

    # Three-qubit gates
    def ccx(
        self,
        control1: Union[Qubit, int],
        control2: Union[Qubit, int],
        target: Union[Qubit, int],
    ) -> "QuantumCircuit":
        """Apply Toffoli (CCX) gate."""
        from roadquantum_core.gates.standard import CCXGate
        return self._append_instruction(CCXGate(), [control1, control2, target])

    def toffoli(
        self,
        control1: Union[Qubit, int],
        control2: Union[Qubit, int],
        target: Union[Qubit, int],
    ) -> "QuantumCircuit":
        """Alias for ccx."""
        return self.ccx(control1, control2, target)

    def cswap(
        self,
        control: Union[Qubit, int],
        target1: Union[Qubit, int],
        target2: Union[Qubit, int],
    ) -> "QuantumCircuit":
        """Apply Fredkin (CSWAP) gate."""
        from roadquantum_core.gates.standard import CSwapGate
        return self._append_instruction(CSwapGate(), [control, target1, target2])

    # Measurement
    def measure(
        self,
        qubit: Union[Qubit, int, List[Union[Qubit, int]]],
        clbit: Union[Clbit, int, List[Union[Clbit, int]]],
    ) -> "QuantumCircuit":
        """Measure qubit(s) to classical bit(s)."""
        if isinstance(qubit, list):
            qubits = qubit
            clbits = clbit if isinstance(clbit, list) else [clbit]
            for q, c in zip(qubits, clbits):
                self._append_instruction(Measurement(), [q], [c])
        else:
            self._append_instruction(Measurement(), [qubit], [clbit])
        return self

    def measure_all(self, add_bits: bool = True) -> "QuantumCircuit":
        """Measure all qubits."""
        if add_bits and self.num_clbits < self.num_qubits:
            cr = ClassicalRegister(self.num_qubits, "meas")
            self.add_register(cr)

        for i in range(self.num_qubits):
            self.measure(i, i)

        return self

    # Other operations
    def barrier(self, *qubits: Union[Qubit, int]) -> "QuantumCircuit":
        """Add barrier."""
        if not qubits:
            qubits = tuple(range(self.num_qubits))
        return self._append_instruction(Barrier(num_qubits=len(qubits)), list(qubits))

    def reset(self, qubit: Union[Qubit, int]) -> "QuantumCircuit":
        """Reset qubit to |0⟩."""
        return self._append_instruction(Reset(), [qubit])

    def delay(
        self,
        duration: float,
        qubit: Union[Qubit, int],
        unit: str = "ns",
    ) -> "QuantumCircuit":
        """Add delay."""
        return self._append_instruction(Delay(duration=duration, unit=unit), [qubit])

    # Circuit operations
    def compose(
        self,
        other: "QuantumCircuit",
        qubits: Optional[List[int]] = None,
        clbits: Optional[List[int]] = None,
        front: bool = False,
    ) -> "QuantumCircuit":
        """Compose with another circuit."""
        result = copy.deepcopy(self)

        qubit_map = qubits or list(range(other.num_qubits))
        clbit_map = clbits or list(range(other.num_clbits))

        new_instructions = []
        for inst in other.data:
            mapped_qubits = [result.qubits[qubit_map[other._qubit_map[q]]] for q in inst.qubits]
            mapped_clbits = [result.clbits[clbit_map[other._clbit_map[c]]] for c in inst.clbits]

            new_instructions.append(CircuitInstruction(
                instruction=copy.deepcopy(inst.instruction),
                qubits=mapped_qubits,
                clbits=mapped_clbits,
            ))

        if front:
            result._data = new_instructions + result._data
        else:
            result._data.extend(new_instructions)

        return result

    def inverse(self) -> "QuantumCircuit":
        """Return inverse circuit."""
        result = QuantumCircuit(*self.qregs, *self.cregs, name=f"{self.name}_inv")

        for inst in reversed(self._data):
            if isinstance(inst.instruction, Measurement):
                continue
            inv_inst = inst.instruction.inverse()
            result._data.append(CircuitInstruction(
                instruction=inv_inst,
                qubits=inst.qubits.copy(),
                clbits=inst.clbits.copy(),
            ))

        return result

    def bind_parameters(
        self,
        values: Dict[Parameter, float],
    ) -> "QuantumCircuit":
        """Bind parameters to values."""
        result = copy.deepcopy(self)
        result._parameters = set()

        for inst in result._data:
            new_params = []
            for param in inst.instruction.params:
                if isinstance(param, Parameter):
                    if param in values:
                        new_params.append(values[param])
                    else:
                        new_params.append(param)
                        result._parameters.add(param)
                elif isinstance(param, ParameterExpression):
                    try:
                        new_params.append(param.bind(values))
                    except ValueError:
                        new_params.append(param)
                        result._parameters.update(param.parameters - set(values.keys()))
                else:
                    new_params.append(param)
            inst.instruction.params = new_params

        return result

    def copy(self, name: Optional[str] = None) -> "QuantumCircuit":
        """Return a copy of the circuit."""
        result = copy.deepcopy(self)
        if name:
            result.name = name
        return result

    def draw(self, output: str = "text") -> str:
        """Draw circuit diagram."""
        if output == "text":
            return self._draw_text()
        raise ValueError(f"Unknown output format: {output}")

    def _draw_text(self) -> str:
        """Draw ASCII circuit diagram."""
        lines = []
        for i, qr in enumerate(self.qregs):
            for j, q in enumerate(qr):
                line = f"{qr.name}[{j}]: ─"
                for inst in self._data:
                    if q in inst.qubits:
                        gate_str = f"[{inst.instruction.name}]"
                        line += gate_str + "─"
                    else:
                        line += "─" * (len(inst.instruction.name) + 2) + "─"
                lines.append(line)

        return "\n".join(lines)

    def __repr__(self) -> str:
        return f"QuantumCircuit(qubits={self.num_qubits}, depth={self.depth})"


__all__ = ["QuantumCircuit", "CircuitInstruction"]
