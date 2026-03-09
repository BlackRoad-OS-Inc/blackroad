"""
RoadAI - BlackRoad AI Platform Core

Unified AI orchestration and inference platform supporting multiple providers:
- OpenAI (GPT-4, GPT-4o, etc.)
- Anthropic (Claude 3.5 Sonnet, Claude 3 Opus, etc.)
- Ollama (Local models - Llama, Mistral, Phi, etc.)
- Custom endpoints

Features:
- Unified API across all providers
- Automatic failover and load balancing
- Token tracking and cost estimation
- Streaming support
- Tool/function calling
- RAG integration ready
"""

__version__ = "0.1.0"
__author__ = "BlackRoad OS"

from roadai.main import app, create_app
from roadai.models.messages import Message, ChatRequest, ChatResponse
from roadai.providers.base import AIProvider

__all__ = [
    "app",
    "create_app",
    "Message",
    "ChatRequest",
    "ChatResponse",
    "AIProvider",
]
