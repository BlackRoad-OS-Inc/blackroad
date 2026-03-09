"""
RoadWebSocket - WebSocket Infrastructure for BlackRoad OS

WebSocket client and server with rooms, broadcasting,
event emitters, and automatic reconnection.
"""

from .websocket import (
    WebSocketServer,
    WebSocketClient,
    WebSocketManager,
    WebSocketConnection,
    WebSocketMessage,
    Room,
    EventEmitter,
    MessageType,
    ConnectionState,
)

__version__ = "0.1.0"
__author__ = "BlackRoad OS"
__all__ = [
    # Server/Client
    "WebSocketServer",
    "WebSocketClient",
    "WebSocketManager",
    # Connection
    "WebSocketConnection",
    "WebSocketMessage",
    "Room",
    # Events
    "EventEmitter",
    # Enums
    "MessageType",
    "ConnectionState",
]
