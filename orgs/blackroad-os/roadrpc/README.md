# RoadRPC

> JSON-RPC 2.0 implementation for BlackRoad OS with middleware and service discovery

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![BlackRoad OS](https://img.shields.io/badge/BlackRoad-OS-FF1D6C.svg)](https://github.com/BlackRoad-OS)

## Overview

RoadRPC provides a complete JSON-RPC 2.0 implementation with:

- **Full JSON-RPC 2.0** - Requests, responses, notifications, batch calls
- **Middleware System** - Logging, timing, authentication, custom middleware
- **Service Classes** - Register entire service classes with namespace prefixes
- **Client/Server** - Both client and server implementations
- **Async Support** - Native asyncio for both sync and async handlers

## Installation

```bash
pip install roadrpc
```

## Quick Start

### Server

```python
import asyncio
from roadrpc import RPCServer, RPCManager

server = RPCServer()

@server.method("add", description="Add two numbers")
def add(a: int, b: int) -> int:
    return a + b

@server.method("greet")
async def greet(name: str) -> str:
    return f"Hello, {name}!"

# Handle JSON-RPC request
request = '{"jsonrpc": "2.0", "method": "add", "params": [1, 2], "id": 1}'
response = await server.handle_json(request)
# {"jsonrpc": "2.0", "result": 3, "id": 1}
```

### Client

```python
from roadrpc import RPCClient

def http_transport(request_str: str) -> str:
    # Your HTTP implementation
    return requests.post(url, data=request_str).text

client = RPCClient(transport=http_transport)

result = await client.call("add", 1, 2)  # 3
result = await client.call("greet", name="World")  # "Hello, World!"
```

### Service Classes

```python
from roadrpc import RPCService, RPCManager

class MathService(RPCService):
    def add(self, a: float, b: float) -> float:
        return a + b

    def multiply(self, a: float, b: float) -> float:
        return a * b

    def divide(self, a: float, b: float) -> float:
        if b == 0:
            raise RPCError(-32001, "Division by zero")
        return a / b

manager = RPCManager()
manager.register_service("math", MathService())

# Methods available as: math.add, math.multiply, math.divide
```

## Middleware

### Built-in Middleware

```python
from roadrpc import RPCServer, LoggingMiddleware, TimingMiddleware, AuthMiddleware

server = RPCServer()

# Logging
server.add_middleware(LoggingMiddleware())

# Timing (tracks execution time per method)
timing = TimingMiddleware()
server.add_middleware(timing)

# Authentication
def validate_token(token: str) -> bool:
    return token == "valid-token"

server.add_middleware(AuthMiddleware(validate_token))
```

### Custom Middleware

```python
from roadrpc import RPCMiddleware, RPCRequest, RPCResponse

class RateLimitMiddleware(RPCMiddleware):
    def __init__(self, max_requests: int = 100):
        self.requests = {}
        self.max_requests = max_requests

    async def before_call(self, request: RPCRequest) -> RPCRequest:
        # Rate limiting logic
        return request

    async def after_call(self, request: RPCRequest, response: RPCResponse) -> RPCResponse:
        # Post-processing
        return response

    async def on_error(self, request: RPCRequest, error: Exception) -> Optional[RPCResponse]:
        # Error handling
        return None
```

## Batch Requests

```python
# Server handles batch automatically
batch_request = '''[
    {"jsonrpc": "2.0", "method": "add", "params": [1, 2], "id": 1},
    {"jsonrpc": "2.0", "method": "multiply", "params": [3, 4], "id": 2}
]'''

response = await server.handle_json(batch_request)
# [{"jsonrpc": "2.0", "result": 3, "id": 1}, {"jsonrpc": "2.0", "result": 12, "id": 2}]

# Client batch
results = await client.batch([
    ("add", [1, 2]),
    ("multiply", {"a": 3, "b": 4})
])
```

## Notifications

```python
# Server - notification handlers (no response)
@server.method("log_event")
def log_event(event: dict):
    print(f"Event: {event}")

# Client - send notification (no id = no response expected)
await client.notify("log_event", {"type": "user_login", "user": "john"})
```

## Error Handling

```python
from roadrpc import RPCError, RPCErrorCode

@server.method("validate")
def validate(data: dict):
    if "required_field" not in data:
        raise RPCError(
            code=RPCErrorCode.INVALID_PARAMS,
            message="Missing required_field",
            data={"field": "required_field"}
        )
    return {"valid": True}
```

### Standard Error Codes

| Code | Name | Description |
|------|------|-------------|
| -32700 | Parse Error | Invalid JSON |
| -32600 | Invalid Request | Not a valid request object |
| -32601 | Method Not Found | Method doesn't exist |
| -32602 | Invalid Params | Invalid method parameters |
| -32603 | Internal Error | Internal JSON-RPC error |
| -32000 | Server Error | Custom server errors |

## API Reference

### Classes

| Class | Description |
|-------|-------------|
| `RPCServer` | JSON-RPC 2.0 server |
| `RPCClient` | JSON-RPC 2.0 client |
| `RPCManager` | High-level management |
| `RPCService` | Base class for services |
| `RPCRequest` | Request dataclass |
| `RPCResponse` | Response dataclass |
| `RPCMethod` | Method metadata |
| `RPCError` | RPC exception |
| `RPCMiddleware` | Base middleware |

### Built-in Middleware

- `LoggingMiddleware` - Log all RPC calls
- `TimingMiddleware` - Track execution timing
- `AuthMiddleware` - Token authentication

## License

Proprietary - BlackRoad OS, Inc. All rights reserved.

## Related

- [roadhttp](https://github.com/BlackRoad-OS/roadhttp) - HTTP client
- [roadwebsocket](https://github.com/BlackRoad-OS/roadwebsocket) - WebSocket
- [roadpubsub](https://github.com/BlackRoad-OS/roadpubsub) - Pub/Sub messaging
