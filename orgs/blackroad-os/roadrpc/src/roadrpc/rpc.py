"""
RoadRPC - Remote Procedure Calls for BlackRoad
JSON-RPC 2.0 implementation with middleware and service discovery.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Tuple, Type, Union
import asyncio
import inspect
import json
import logging
import threading
import uuid

logger = logging.getLogger(__name__)


class RPCErrorCode(int, Enum):
    """JSON-RPC 2.0 error codes."""
    PARSE_ERROR = -32700
    INVALID_REQUEST = -32600
    METHOD_NOT_FOUND = -32601
    INVALID_PARAMS = -32602
    INTERNAL_ERROR = -32603
    SERVER_ERROR = -32000


class RPCError(Exception):
    """RPC error."""

    def __init__(self, code: int, message: str, data: Any = None):
        self.code = code
        self.message = message
        self.data = data
        super().__init__(message)

    def to_dict(self) -> Dict[str, Any]:
        error = {"code": self.code, "message": self.message}
        if self.data is not None:
            error["data"] = self.data
        return error


@dataclass
class RPCRequest:
    """JSON-RPC 2.0 request."""
    method: str
    params: Union[List, Dict] = field(default_factory=list)
    id: Optional[Union[str, int]] = None
    jsonrpc: str = "2.0"

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "RPCRequest":
        return cls(
            method=data.get("method", ""),
            params=data.get("params", []),
            id=data.get("id"),
            jsonrpc=data.get("jsonrpc", "2.0")
        )

    def to_dict(self) -> Dict[str, Any]:
        request = {
            "jsonrpc": self.jsonrpc,
            "method": self.method,
            "params": self.params
        }
        if self.id is not None:
            request["id"] = self.id
        return request

    @property
    def is_notification(self) -> bool:
        return self.id is None


@dataclass
class RPCResponse:
    """JSON-RPC 2.0 response."""
    result: Any = None
    error: Optional[Dict[str, Any]] = None
    id: Optional[Union[str, int]] = None
    jsonrpc: str = "2.0"

    @classmethod
    def success(cls, result: Any, id: Union[str, int] = None) -> "RPCResponse":
        return cls(result=result, id=id)

    @classmethod
    def failure(cls, error: RPCError, id: Union[str, int] = None) -> "RPCResponse":
        return cls(error=error.to_dict(), id=id)

    def to_dict(self) -> Dict[str, Any]:
        response = {"jsonrpc": self.jsonrpc, "id": self.id}
        if self.error:
            response["error"] = self.error
        else:
            response["result"] = self.result
        return response


@dataclass
class RPCMethod:
    """Registered RPC method."""
    name: str
    handler: Callable
    description: str = ""
    params_schema: Dict[str, Any] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)


class RPCMiddleware:
    """Base middleware class."""

    async def before_call(self, request: RPCRequest) -> RPCRequest:
        """Called before method execution."""
        return request

    async def after_call(self, request: RPCRequest, response: RPCResponse) -> RPCResponse:
        """Called after method execution."""
        return response

    async def on_error(self, request: RPCRequest, error: Exception) -> Optional[RPCResponse]:
        """Called on error."""
        return None


class LoggingMiddleware(RPCMiddleware):
    """Log RPC calls."""

    async def before_call(self, request: RPCRequest) -> RPCRequest:
        logger.info(f"RPC call: {request.method}")
        return request

    async def after_call(self, request: RPCRequest, response: RPCResponse) -> RPCResponse:
        if response.error:
            logger.error(f"RPC error: {response.error}")
        else:
            logger.info(f"RPC success: {request.method}")
        return response


class TimingMiddleware(RPCMiddleware):
    """Track RPC call timing."""

    def __init__(self):
        self.timings: Dict[str, List[float]] = {}

    async def before_call(self, request: RPCRequest) -> RPCRequest:
        request.metadata["start_time"] = datetime.now()
        return request

    async def after_call(self, request: RPCRequest, response: RPCResponse) -> RPCResponse:
        start = request.metadata.get("start_time")
        if start:
            elapsed = (datetime.now() - start).total_seconds() * 1000
            if request.method not in self.timings:
                self.timings[request.method] = []
            self.timings[request.method].append(elapsed)
        return response


class AuthMiddleware(RPCMiddleware):
    """Authentication middleware."""

    def __init__(self, validator: Callable[[str], bool]):
        self.validator = validator

    async def before_call(self, request: RPCRequest) -> RPCRequest:
        token = request.metadata.get("auth_token")
        if not token or not self.validator(token):
            raise RPCError(
                code=-32001,
                message="Authentication required"
            )
        return request


class RPCServer:
    """JSON-RPC 2.0 server."""

    def __init__(self):
        self.methods: Dict[str, RPCMethod] = {}
        self.middleware: List[RPCMiddleware] = []
        self._lock = threading.Lock()

    def add_middleware(self, middleware: RPCMiddleware) -> None:
        """Add middleware."""
        self.middleware.append(middleware)

    def method(self, name: str = None, description: str = ""):
        """Decorator to register a method."""
        def decorator(fn: Callable):
            method_name = name or fn.__name__
            self.register(method_name, fn, description)
            return fn
        return decorator

    def register(self, name: str, handler: Callable, description: str = "") -> None:
        """Register a method."""
        with self._lock:
            self.methods[name] = RPCMethod(
                name=name,
                handler=handler,
                description=description
            )
            logger.debug(f"Registered method: {name}")

    def unregister(self, name: str) -> bool:
        """Unregister a method."""
        with self._lock:
            if name in self.methods:
                del self.methods[name]
                return True
            return False

    async def call(self, request: RPCRequest) -> Optional[RPCResponse]:
        """Execute an RPC call."""
        # Apply before middleware
        try:
            for mw in self.middleware:
                request = await mw.before_call(request)
        except RPCError as e:
            return RPCResponse.failure(e, request.id)
        except Exception as e:
            return RPCResponse.failure(
                RPCError(RPCErrorCode.INTERNAL_ERROR, str(e)),
                request.id
            )

        # Find method
        method = self.methods.get(request.method)
        if not method:
            return RPCResponse.failure(
                RPCError(RPCErrorCode.METHOD_NOT_FOUND, f"Method not found: {request.method}"),
                request.id
            )

        # Execute method
        try:
            if isinstance(request.params, dict):
                result = method.handler(**request.params)
            elif isinstance(request.params, list):
                result = method.handler(*request.params)
            else:
                result = method.handler()

            if asyncio.iscoroutine(result):
                result = await result

            response = RPCResponse.success(result, request.id)

        except RPCError as e:
            response = RPCResponse.failure(e, request.id)
        except TypeError as e:
            response = RPCResponse.failure(
                RPCError(RPCErrorCode.INVALID_PARAMS, str(e)),
                request.id
            )
        except Exception as e:
            # Try error middleware
            for mw in self.middleware:
                mw_response = await mw.on_error(request, e)
                if mw_response:
                    response = mw_response
                    break
            else:
                response = RPCResponse.failure(
                    RPCError(RPCErrorCode.INTERNAL_ERROR, str(e)),
                    request.id
                )

        # Apply after middleware
        for mw in self.middleware:
            response = await mw.after_call(request, response)

        # Don't return response for notifications
        if request.is_notification:
            return None

        return response

    async def handle_json(self, json_str: str) -> str:
        """Handle JSON-RPC request string."""
        try:
            data = json.loads(json_str)
        except json.JSONDecodeError as e:
            return json.dumps(RPCResponse.failure(
                RPCError(RPCErrorCode.PARSE_ERROR, str(e))
            ).to_dict())

        # Handle batch request
        if isinstance(data, list):
            if not data:
                return json.dumps(RPCResponse.failure(
                    RPCError(RPCErrorCode.INVALID_REQUEST, "Empty batch")
                ).to_dict())

            responses = []
            for item in data:
                request = RPCRequest.from_dict(item)
                response = await self.call(request)
                if response:
                    responses.append(response.to_dict())

            return json.dumps(responses)

        # Single request
        request = RPCRequest.from_dict(data)
        response = await self.call(request)

        if response:
            return json.dumps(response.to_dict())
        return ""

    def list_methods(self) -> List[Dict[str, Any]]:
        """List all registered methods."""
        return [
            {
                "name": m.name,
                "description": m.description
            }
            for m in self.methods.values()
        ]


class RPCClient:
    """JSON-RPC 2.0 client."""

    def __init__(self, transport: Callable[[str], str] = None):
        self.transport = transport
        self._id_counter = 0
        self._lock = threading.Lock()

    def _next_id(self) -> int:
        with self._lock:
            self._id_counter += 1
            return self._id_counter

    async def call(self, method: str, *args, **kwargs) -> Any:
        """Call a remote method."""
        if args and kwargs:
            raise ValueError("Cannot mix positional and keyword arguments")

        request = RPCRequest(
            method=method,
            params=list(args) if args else kwargs,
            id=self._next_id()
        )

        if not self.transport:
            raise ValueError("No transport configured")

        # Send request
        response_str = self.transport(json.dumps(request.to_dict()))

        if not response_str:
            return None

        # Parse response
        response_data = json.loads(response_str)

        if "error" in response_data:
            error = response_data["error"]
            raise RPCError(
                code=error.get("code", -32000),
                message=error.get("message", "Unknown error"),
                data=error.get("data")
            )

        return response_data.get("result")

    async def notify(self, method: str, *args, **kwargs) -> None:
        """Send a notification (no response expected)."""
        if args and kwargs:
            raise ValueError("Cannot mix positional and keyword arguments")

        request = RPCRequest(
            method=method,
            params=list(args) if args else kwargs,
            id=None  # Notification
        )

        if self.transport:
            self.transport(json.dumps(request.to_dict()))

    async def batch(self, calls: List[Tuple[str, Any]]) -> List[Any]:
        """Execute batch of calls."""
        requests = []
        for method, params in calls:
            request = RPCRequest(
                method=method,
                params=params if isinstance(params, (list, dict)) else [params],
                id=self._next_id()
            )
            requests.append(request.to_dict())

        if not self.transport:
            raise ValueError("No transport configured")

        response_str = self.transport(json.dumps(requests))
        responses = json.loads(response_str)

        results = []
        for response in responses:
            if "error" in response:
                results.append(RPCError(
                    code=response["error"].get("code"),
                    message=response["error"].get("message")
                ))
            else:
                results.append(response.get("result"))

        return results


class RPCService:
    """Base class for RPC services."""

    def get_methods(self) -> Dict[str, Callable]:
        """Get all public methods."""
        methods = {}
        for name in dir(self):
            if not name.startswith("_"):
                method = getattr(self, name)
                if callable(method) and not name.startswith("get_"):
                    methods[name] = method
        return methods


class RPCManager:
    """High-level RPC management."""

    def __init__(self):
        self.server = RPCServer()
        self._services: Dict[str, RPCService] = {}

    def register_service(self, prefix: str, service: RPCService) -> None:
        """Register a service with all its methods."""
        self._services[prefix] = service

        for name, method in service.get_methods().items():
            full_name = f"{prefix}.{name}"
            self.server.register(full_name, method)

    def unregister_service(self, prefix: str) -> bool:
        """Unregister a service."""
        if prefix not in self._services:
            return False

        service = self._services[prefix]
        for name in service.get_methods():
            full_name = f"{prefix}.{name}"
            self.server.unregister(full_name)

        del self._services[prefix]
        return True

    async def handle(self, json_str: str) -> str:
        """Handle RPC request."""
        return await self.server.handle_json(json_str)

    def create_client(self) -> RPCClient:
        """Create a local client (for testing)."""
        async def transport(request_str: str) -> str:
            return await self.server.handle_json(request_str)

        # Sync wrapper
        def sync_transport(request_str: str) -> str:
            loop = asyncio.get_event_loop()
            return loop.run_until_complete(transport(request_str))

        return RPCClient(sync_transport)


# Example usage
async def example_usage():
    """Example RPC usage."""
    manager = RPCManager()

    # Add middleware
    manager.server.add_middleware(LoggingMiddleware())
    manager.server.add_middleware(TimingMiddleware())

    # Register methods
    @manager.server.method("add", description="Add two numbers")
    def add(a: int, b: int) -> int:
        return a + b

    @manager.server.method("multiply")
    def multiply(a: int, b: int) -> int:
        return a * b

    @manager.server.method("greet")
    async def greet(name: str) -> str:
        return f"Hello, {name}!"

    # Create a service
    class MathService(RPCService):
        def divide(self, a: float, b: float) -> float:
            if b == 0:
                raise RPCError(-32001, "Division by zero")
            return a / b

        def power(self, base: float, exp: float) -> float:
            return base ** exp

    manager.register_service("math", MathService())

    # Handle requests
    request = json.dumps({
        "jsonrpc": "2.0",
        "method": "add",
        "params": [1, 2],
        "id": 1
    })

    response = await manager.handle(request)
    print(f"Response: {response}")

    # Batch request
    batch = json.dumps([
        {"jsonrpc": "2.0", "method": "add", "params": [1, 2], "id": 1},
        {"jsonrpc": "2.0", "method": "multiply", "params": [3, 4], "id": 2},
        {"jsonrpc": "2.0", "method": "math.divide", "params": {"a": 10, "b": 2}, "id": 3}
    ])

    response = await manager.handle(batch)
    print(f"Batch response: {response}")

