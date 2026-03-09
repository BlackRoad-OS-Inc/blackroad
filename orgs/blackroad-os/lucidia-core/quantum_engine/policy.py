"""Runtime guardrails for the quantum engine."""
from __future__ import annotations

import builtins
import os
import random
import socket
from typing import Optional

MAX_WIRES = 8
MAX_SHOTS = 2048
TIMEOUT = 60

DENYLIST = (
    'torchquantum.plugins',
    'qiskit',
    'qiskit_ibm_runtime',
)


def enforce_import_block() -> None:
    """Block imports of disallowed modules."""
    real_import = builtins.__import__

    def guarded(name, *args, **kwargs):
        for bad in DENYLIST:
            if name.startswith(bad):
                raise ImportError(f'{bad} is disabled')
        return real_import(name, *args, **kwargs)

    builtins.__import__ = guarded


def guard_env() -> None:
    """Fail closed on hardware flags and block outbound sockets."""
    if os.getenv('LUCIDIA_QHW') == '1':
        raise RuntimeError('Hardware backends are disabled')

    class _BlockedSocket(socket.socket):
        def __init__(self, *args, **kwargs):
            raise RuntimeError('Network access disabled')

    socket.socket = _BlockedSocket


def set_seed(seed: Optional[int] = None) -> int:
    if seed is None:
        seed = 0
    random.seed(seed)
    try:
        import torch

        torch.manual_seed(seed)
    except Exception:
        pass
    return seed
