"""Parameterized circuit elements.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import math
import uuid
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Union

import numpy as np


@dataclass
class Parameter:
    """A symbolic parameter for quantum circuits.

    Parameters allow creating parameterized circuits that can be
    instantiated with concrete values later.

    Example:
        theta = Parameter("θ")
        circuit.rx(theta, 0)

        # Bind parameter
        bound_circuit = circuit.bind({theta: 0.5})
    """

    name: str
    _uuid: str = field(default_factory=lambda: str(uuid.uuid4())[:8])

    def __hash__(self) -> int:
        return hash(self._uuid)

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Parameter):
            return self._uuid == other._uuid
        return False

    def __repr__(self) -> str:
        return f"Parameter({self.name})"

    def __add__(self, other: Union["Parameter", float]) -> "ParameterExpression":
        return ParameterExpression(self) + other

    def __radd__(self, other: float) -> "ParameterExpression":
        return ParameterExpression(self) + other

    def __sub__(self, other: Union["Parameter", float]) -> "ParameterExpression":
        return ParameterExpression(self) - other

    def __rsub__(self, other: float) -> "ParameterExpression":
        return other + (-1 * ParameterExpression(self))

    def __mul__(self, other: Union["Parameter", float]) -> "ParameterExpression":
        return ParameterExpression(self) * other

    def __rmul__(self, other: float) -> "ParameterExpression":
        return ParameterExpression(self) * other

    def __truediv__(self, other: Union["Parameter", float]) -> "ParameterExpression":
        return ParameterExpression(self) / other

    def __neg__(self) -> "ParameterExpression":
        return ParameterExpression(self) * -1


class ParameterExpression:
    """An expression involving parameters.

    Supports basic arithmetic operations.
    """

    def __init__(
        self,
        param: Optional[Parameter] = None,
        expr: Optional[str] = None,
        value: float = 0.0,
    ):
        self._params: Set[Parameter] = set()
        self._expr_parts: List[tuple] = []  # (coefficient, parameter or None)

        if param:
            self._params.add(param)
            self._expr_parts.append((1.0, param))
        elif expr is None:
            self._expr_parts.append((value, None))

    @property
    def parameters(self) -> Set[Parameter]:
        """Get all parameters in expression."""
        return self._params.copy()

    def bind(self, values: Dict[Parameter, float]) -> float:
        """Evaluate expression with parameter values."""
        result = 0.0
        for coeff, param in self._expr_parts:
            if param is None:
                result += coeff
            elif param in values:
                result += coeff * values[param]
            else:
                raise ValueError(f"Parameter {param.name} not bound")
        return result

    def __add__(self, other: Union["ParameterExpression", Parameter, float]) -> "ParameterExpression":
        result = ParameterExpression()
        result._expr_parts = self._expr_parts.copy()
        result._params = self._params.copy()

        if isinstance(other, ParameterExpression):
            result._expr_parts.extend(other._expr_parts)
            result._params.update(other._params)
        elif isinstance(other, Parameter):
            result._expr_parts.append((1.0, other))
            result._params.add(other)
        else:
            result._expr_parts.append((float(other), None))

        return result

    def __radd__(self, other: float) -> "ParameterExpression":
        return self + other

    def __sub__(self, other: Union["ParameterExpression", Parameter, float]) -> "ParameterExpression":
        if isinstance(other, (ParameterExpression, Parameter)):
            return self + (other * -1)
        return self + (-other)

    def __mul__(self, other: float) -> "ParameterExpression":
        result = ParameterExpression()
        result._params = self._params.copy()
        result._expr_parts = [(coeff * other, param) for coeff, param in self._expr_parts]
        return result

    def __rmul__(self, other: float) -> "ParameterExpression":
        return self * other

    def __truediv__(self, other: float) -> "ParameterExpression":
        return self * (1.0 / other)

    def __neg__(self) -> "ParameterExpression":
        return self * -1

    def __repr__(self) -> str:
        parts = []
        for coeff, param in self._expr_parts:
            if param is None:
                parts.append(str(coeff))
            elif coeff == 1.0:
                parts.append(param.name)
            elif coeff == -1.0:
                parts.append(f"-{param.name}")
            else:
                parts.append(f"{coeff}*{param.name}")
        return " + ".join(parts) if parts else "0"


class ParameterVector:
    """A vector of parameters.

    Example:
        params = ParameterVector("θ", 3)
        for i, qubit in enumerate(qubits):
            circuit.rx(params[i], qubit)
    """

    def __init__(self, name: str, length: int):
        self.name = name
        self.length = length
        self._params = [Parameter(f"{name}[{i}]") for i in range(length)]

    def __len__(self) -> int:
        return self.length

    def __getitem__(self, key: Union[int, slice]) -> Union[Parameter, List[Parameter]]:
        return self._params[key]

    def __iter__(self):
        return iter(self._params)

    @property
    def params(self) -> List[Parameter]:
        """Get all parameters."""
        return self._params.copy()


__all__ = ["Parameter", "ParameterExpression", "ParameterVector"]
