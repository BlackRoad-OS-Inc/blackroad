"""
RoadSocket - Socket Operations for BlackRoad
TCP/UDP socket wrapper with connection pooling.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Tuple, Union
import asyncio
import socket
import ssl
import struct
import threading
import logging

logger = logging.getLogger(__name__)


class SocketType(str, Enum):
    TCP = "tcp"
    UDP = "udp"


class SocketError(Exception):
    pass


@dataclass
class SocketAddress:
    host: str
    port: int

    def __str__(self) -> str:
        return f"{self.host}:{self.port}"

    def to_tuple(self) -> Tuple[str, int]:
        return (self.host, self.port)


@dataclass
class SocketConfig:
    timeout: float = 30.0
    buffer_size: int = 8192
    reuse_addr: bool = True
    keep_alive: bool = True
    no_delay: bool = True


class TCPSocket:
    def __init__(self, config: SocketConfig = None):
        self.config = config or SocketConfig()
        self._socket: Optional[socket.socket] = None
        self._connected = False

    def connect(self, address: Union[SocketAddress, Tuple[str, int]]) -> "TCPSocket":
        if isinstance(address, SocketAddress):
            address = address.to_tuple()

        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._socket.settimeout(self.config.timeout)

        if self.config.reuse_addr:
            self._socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        if self.config.keep_alive:
            self._socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        if self.config.no_delay:
            self._socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

        self._socket.connect(address)
        self._connected = True
        return self

    def send(self, data: bytes) -> int:
        if not self._connected:
            raise SocketError("Not connected")
        return self._socket.send(data)

    def sendall(self, data: bytes) -> None:
        if not self._connected:
            raise SocketError("Not connected")
        self._socket.sendall(data)

    def recv(self, size: int = None) -> bytes:
        if not self._connected:
            raise SocketError("Not connected")
        return self._socket.recv(size or self.config.buffer_size)

    def recv_exact(self, size: int) -> bytes:
        data = b""
        while len(data) < size:
            chunk = self.recv(size - len(data))
            if not chunk:
                raise SocketError("Connection closed")
            data += chunk
        return data

    def recv_line(self, encoding: str = "utf-8") -> str:
        data = b""
        while not data.endswith(b"\n"):
            chunk = self.recv(1)
            if not chunk:
                break
            data += chunk
        return data.decode(encoding).rstrip("\r\n")

    def close(self) -> None:
        if self._socket:
            self._socket.close()
            self._socket = None
        self._connected = False

    def __enter__(self) -> "TCPSocket":
        return self

    def __exit__(self, *args) -> None:
        self.close()


class UDPSocket:
    def __init__(self, config: SocketConfig = None):
        self.config = config or SocketConfig()
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._socket.settimeout(self.config.timeout)

    def bind(self, address: Union[SocketAddress, Tuple[str, int]]) -> "UDPSocket":
        if isinstance(address, SocketAddress):
            address = address.to_tuple()
        self._socket.bind(address)
        return self

    def sendto(self, data: bytes, address: Union[SocketAddress, Tuple[str, int]]) -> int:
        if isinstance(address, SocketAddress):
            address = address.to_tuple()
        return self._socket.sendto(data, address)

    def recvfrom(self, size: int = None) -> Tuple[bytes, Tuple[str, int]]:
        return self._socket.recvfrom(size or self.config.buffer_size)

    def close(self) -> None:
        self._socket.close()

    def __enter__(self) -> "UDPSocket":
        return self

    def __exit__(self, *args) -> None:
        self.close()


class TCPServer:
    def __init__(self, address: Union[SocketAddress, Tuple[str, int]], config: SocketConfig = None):
        self.address = address if isinstance(address, tuple) else address.to_tuple()
        self.config = config or SocketConfig()
        self._socket: Optional[socket.socket] = None
        self._running = False
        self._handler: Optional[Callable] = None

    def on_connection(self, handler: Callable) -> "TCPServer":
        self._handler = handler
        return self

    def start(self) -> "TCPServer":
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._socket.bind(self.address)
        self._socket.listen(128)
        self._running = True

        while self._running:
            try:
                client_socket, client_addr = self._socket.accept()
                if self._handler:
                    thread = threading.Thread(target=self._handle, args=(client_socket, client_addr))
                    thread.daemon = True
                    thread.start()
            except socket.timeout:
                continue
            except OSError:
                break

        return self

    def _handle(self, client_socket: socket.socket, address: tuple) -> None:
        try:
            self._handler(client_socket, address)
        except Exception as e:
            logger.error(f"Handler error: {e}")
        finally:
            client_socket.close()

    def stop(self) -> None:
        self._running = False
        if self._socket:
            self._socket.close()


class ConnectionPool:
    def __init__(self, address: Union[SocketAddress, Tuple[str, int]], max_connections: int = 10):
        self.address = address if isinstance(address, tuple) else address.to_tuple()
        self.max_connections = max_connections
        self._pool: List[TCPSocket] = []
        self._lock = threading.Lock()

    def acquire(self) -> TCPSocket:
        with self._lock:
            if self._pool:
                return self._pool.pop()
        sock = TCPSocket()
        sock.connect(self.address)
        return sock

    def release(self, sock: TCPSocket) -> None:
        with self._lock:
            if len(self._pool) < self.max_connections:
                self._pool.append(sock)
            else:
                sock.close()

    def close(self) -> None:
        with self._lock:
            for sock in self._pool:
                sock.close()
            self._pool.clear()


def create_tcp(host: str, port: int) -> TCPSocket:
    return TCPSocket().connect((host, port))


def create_udp() -> UDPSocket:
    return UDPSocket()


def example_usage():
    with create_tcp("example.com", 80) as sock:
        sock.sendall(b"GET / HTTP/1.0\r\nHost: example.com\r\n\r\n")
        response = b""
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            response += chunk
        print(f"Response length: {len(response)} bytes")
        print(response[:500].decode())

