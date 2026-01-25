"""
API Routes for BlackRoad Agent OS Controller
"""
from .agents import router as agents_router
from .tasks import router as tasks_router
from .websocket import router as websocket_router

__all__ = [
    "agents_router",
    "tasks_router",
    "websocket_router",
]
