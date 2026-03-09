"""
RoadWS - WebSocket Client for BlackRoad
Async WebSocket client with reconnection and message handling.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Union
import asyncio
import base64
import hashlib
import json
import os
import struct
import logging

logger = logging.getLogger(__name__)


class WSOpcode(int, Enum):
    CONTINUATION = 0x0
    TEXT = 0x1
    BINARY = 0x2
    CLOSE = 0x8
    PING = 0x9
    PONG = 0xA


class WSState(str, Enum):
    CONNECTING = "connecting"
    OPEN = "open"
    CLOSING = "closing"
    CLOSED = "closed"


@dataclass
class WSMessage:
    type: str  # "text", "binary", "ping", "pong", "close"
    data: Union[str, bytes]
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class WSConfig:
    ping_interval: float = 30.0
    ping_timeout: float = 10.0
    reconnect: bool = True
    reconnect_interval: float = 5.0
    max_reconnects: int = 10


class WSClient:
    GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

    def __init__(self, url: str, config: WSConfig = None):
        self.url = url
        self.config = config or WSConfig()
        self.state = WSState.CLOSED
        self._reader: Optional[asyncio.StreamReader] = None
        self._writer: Optional[asyncio.StreamWriter] = None
        self._handlers: Dict[str, List[Callable]] = {
            "open": [], "message": [], "close": [], "error": []
        }
        self._reconnect_count = 0

    def on(self, event: str, handler: Callable) -> "WSClient":
        if event in self._handlers:
            self._handlers[event].append(handler)
        return self

    def _emit(self, event: str, *args) -> None:
        for handler in self._handlers.get(event, []):
            try:
                if asyncio.iscoroutinefunction(handler):
                    asyncio.create_task(handler(*args))
                else:
                    handler(*args)
            except Exception as e:
                logger.error(f"Handler error: {e}")

    def _parse_url(self) -> tuple:
        url = self.url
        secure = url.startswith("wss://")
        url = url.replace("wss://", "").replace("ws://", "")
        if "/" in url:
            host_port, path = url.split("/", 1)
            path = "/" + path
        else:
            host_port, path = url, "/"
        if ":" in host_port:
            host, port = host_port.split(":")
            port = int(port)
        else:
            host = host_port
            port = 443 if secure else 80
        return secure, host, port, path

    async def connect(self) -> None:
        self.state = WSState.CONNECTING
        secure, host, port, path = self._parse_url()

        self._reader, self._writer = await asyncio.open_connection(host, port, ssl=secure)

        key = base64.b64encode(os.urandom(16)).decode()
        handshake = (
            f"GET {path} HTTP/1.1\r\n"
            f"Host: {host}\r\n"
            f"Upgrade: websocket\r\n"
            f"Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            f"Sec-WebSocket-Version: 13\r\n\r\n"
        )
        self._writer.write(handshake.encode())
        await self._writer.drain()

        response = await self._reader.readuntil(b"\r\n\r\n")
        if b"101" not in response:
            raise ConnectionError("WebSocket handshake failed")

        self.state = WSState.OPEN
        self._reconnect_count = 0
        self._emit("open")

    async def _read_frame(self) -> tuple:
        header = await self._reader.read(2)
        if len(header) < 2:
            return None, None

        fin = (header[0] >> 7) & 1
        opcode = header[0] & 0xF
        masked = (header[1] >> 7) & 1
        length = header[1] & 0x7F

        if length == 126:
            length = struct.unpack(">H", await self._reader.read(2))[0]
        elif length == 127:
            length = struct.unpack(">Q", await self._reader.read(8))[0]

        if masked:
            mask = await self._reader.read(4)
            data = bytearray(await self._reader.read(length))
            for i in range(length):
                data[i] ^= mask[i % 4]
        else:
            data = await self._reader.read(length)

        return opcode, bytes(data)

    async def _write_frame(self, opcode: int, data: bytes, mask: bool = True) -> None:
        frame = bytearray()
        frame.append(0x80 | opcode)  # FIN + opcode

        length = len(data)
        if length < 126:
            frame.append((0x80 if mask else 0) | length)
        elif length < 65536:
            frame.append((0x80 if mask else 0) | 126)
            frame.extend(struct.pack(">H", length))
        else:
            frame.append((0x80 if mask else 0) | 127)
            frame.extend(struct.pack(">Q", length))

        if mask:
            mask_key = os.urandom(4)
            frame.extend(mask_key)
            masked_data = bytearray(data)
            for i in range(length):
                masked_data[i] ^= mask_key[i % 4]
            frame.extend(masked_data)
        else:
            frame.extend(data)

        self._writer.write(bytes(frame))
        await self._writer.drain()

    async def send(self, data: Union[str, bytes, dict]) -> None:
        if self.state != WSState.OPEN:
            raise RuntimeError("WebSocket not connected")

        if isinstance(data, dict):
            data = json.dumps(data)
        if isinstance(data, str):
            await self._write_frame(WSOpcode.TEXT, data.encode())
        else:
            await self._write_frame(WSOpcode.BINARY, data)

    async def recv(self) -> Optional[WSMessage]:
        opcode, data = await self._read_frame()
        if opcode is None:
            return None

        if opcode == WSOpcode.TEXT:
            return WSMessage(type="text", data=data.decode())
        elif opcode == WSOpcode.BINARY:
            return WSMessage(type="binary", data=data)
        elif opcode == WSOpcode.PING:
            await self._write_frame(WSOpcode.PONG, data)
            return WSMessage(type="ping", data=data)
        elif opcode == WSOpcode.CLOSE:
            self.state = WSState.CLOSING
            return WSMessage(type="close", data=data)
        return None

    async def close(self, code: int = 1000, reason: str = "") -> None:
        if self.state == WSState.OPEN:
            self.state = WSState.CLOSING
            data = struct.pack(">H", code) + reason.encode()
            await self._write_frame(WSOpcode.CLOSE, data)
            if self._writer:
                self._writer.close()
                await self._writer.wait_closed()
            self.state = WSState.CLOSED
            self._emit("close", code, reason)

    async def run(self) -> None:
        await self.connect()
        try:
            while self.state == WSState.OPEN:
                msg = await self.recv()
                if msg:
                    if msg.type == "close":
                        break
                    self._emit("message", msg)
        except Exception as e:
            self._emit("error", e)
        finally:
            await self.close()


async def connect(url: str, **kwargs) -> WSClient:
    client = WSClient(url, WSConfig(**kwargs))
    await client.connect()
    return client


def example_usage():
    async def main():
        client = WSClient("wss://echo.websocket.org")
        
        @client.on("open")
        def on_open():
            print("Connected!")

        @client.on("message")
        def on_message(msg: WSMessage):
            print(f"Received: {msg.data}")

        await client.connect()
        await client.send("Hello, WebSocket!")
        msg = await client.recv()
        print(f"Echo: {msg.data}")
        await client.close()

    asyncio.run(main())

