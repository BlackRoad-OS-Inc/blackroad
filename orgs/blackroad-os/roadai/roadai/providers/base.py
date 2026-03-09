"""Base AI Provider interface."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import AsyncIterator

from roadai.models.messages import ChatRequest, ChatResponse, StreamChunk


class AIProvider(ABC):
    """Abstract base class for AI providers."""

    name: str = "base"

    # Model pricing per 1M tokens (input, output)
    PRICING: dict[str, tuple[float, float]] = {}

    @abstractmethod
    async def chat(self, request: ChatRequest) -> ChatResponse:
        """Execute a chat completion request."""
        ...

    @abstractmethod
    async def chat_stream(self, request: ChatRequest) -> AsyncIterator[StreamChunk]:
        """Execute a streaming chat completion request."""
        ...

    @abstractmethod
    async def health_check(self) -> bool:
        """Check if the provider is healthy and accessible."""
        ...

    def estimate_cost(self, model: str, prompt_tokens: int, completion_tokens: int) -> float | None:
        """Estimate cost in USD for the given usage."""
        if model not in self.PRICING:
            return None
        input_price, output_price = self.PRICING[model]
        return (prompt_tokens * input_price + completion_tokens * output_price) / 1_000_000

    @classmethod
    def supports_model(cls, model: str) -> bool:
        """Check if this provider supports the given model."""
        return model in cls.PRICING
