"""
RoadRPC - JSON-RPC 2.0 for BlackRoad OS

A complete JSON-RPC 2.0 implementation with middleware,
service classes, and async support.
"""

from .rpc import (
    RPCServer,
    RPCClient,
    RPCManager,
    RPCService,
    RPCRequest,
    RPCResponse,
    RPCMethod,
    RPCError,
    RPCErrorCode,
    RPCMiddleware,
    LoggingMiddleware,
    TimingMiddleware,
    AuthMiddleware,
)

__version__ = "0.1.0"
__author__ = "BlackRoad OS"
__all__ = [
    # Core
    "RPCServer",
    "RPCClient",
    "RPCManager",
    "RPCService",
    # Data classes
    "RPCRequest",
    "RPCResponse",
    "RPCMethod",
    # Errors
    "RPCError",
    "RPCErrorCode",
    # Middleware
    "RPCMiddleware",
    "LoggingMiddleware",
    "TimingMiddleware",
    "AuthMiddleware",
]
