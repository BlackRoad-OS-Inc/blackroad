"""Helper builders for Qiskit EstimatorQNN and SamplerQNN."""

from __future__ import annotations

from typing import Optional

from qiskit import QuantumCircuit
from qiskit.circuit import ParameterVector
from qiskit_machine_learning.neural_networks import EstimatorQNN, SamplerQNN

from .backends import AerCPUBackend, QuantumBackend


def build_estimator_qnn(
    feature_map: QuantumCircuit,
    ansatz: QuantumCircuit,
    observable: QuantumCircuit | None,
    input_size: int,
    weight_size: int,
    backend: Optional[QuantumBackend] = None,
) -> EstimatorQNN:
    """Construct an :class:`EstimatorQNN` with gradients enabled."""

    backend = backend or AerCPUBackend()
    input_params = ParameterVector("x", length=input_size)
    weight_params = ParameterVector("w", length=weight_size)
    return EstimatorQNN(
        feature_map=feature_map,
        ansatz=ansatz,
        observable=observable,
        input_params=input_params,
        weight_params=weight_params,
        backend=backend.simulator,
        input_gradients=True,
    )


def build_sampler_qnn(
    feature_map: QuantumCircuit,
    ansatz: QuantumCircuit,
    input_size: int,
    weight_size: int,
    num_classes: int,
    backend: Optional[QuantumBackend] = None,
) -> SamplerQNN:
    """Construct a probabilistic :class:`SamplerQNN`."""

    backend = backend or AerCPUBackend()
    input_params = ParameterVector("x", length=input_size)
    weight_params = ParameterVector("w", length=weight_size)
    return SamplerQNN(
        feature_map=feature_map,
        ansatz=ansatz,
        input_params=input_params,
        weight_params=weight_params,
        output_shape=num_classes,
        backend=backend.simulator,
    )
