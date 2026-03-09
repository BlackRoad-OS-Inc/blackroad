"""Anthropic Provider implementation."""

from __future__ import annotations

import os
import time
import uuid
from typing import AsyncIterator

from anthropic import AsyncAnthropic

from roadai.models.messages import (
    ChatRequest,
    ChatResponse,
    Choice,
    Delta,
    Message,
    Role,
    StreamChunk,
    Usage,
)
from roadai.providers.base import AIProvider


class AnthropicProvider(AIProvider):
    """Anthropic Claude API provider."""

    name = "anthropic"

    # Pricing per 1M tokens (input, output) - Jan 2025
    PRICING = {
        "claude-3-5-sonnet-20241022": (3.00, 15.00),
        "claude-3-5-haiku-20241022": (0.80, 4.00),
        "claude-3-opus-20240229": (15.00, 75.00),
        "claude-3-sonnet-20240229": (3.00, 15.00),
        "claude-3-haiku-20240307": (0.25, 1.25),
    }

    # Model aliases
    MODEL_ALIASES = {
        "claude-3.5-sonnet": "claude-3-5-sonnet-20241022",
        "claude-3.5-haiku": "claude-3-5-haiku-20241022",
        "claude-3-opus": "claude-3-opus-20240229",
        "claude-3-sonnet": "claude-3-sonnet-20240229",
        "claude-3-haiku": "claude-3-haiku-20240307",
    }

    def __init__(self, api_key: str | None = None):
        self.client = AsyncAnthropic(
            api_key=api_key or os.getenv("ANTHROPIC_API_KEY"),
        )

    def _resolve_model(self, model: str) -> str:
        """Resolve model alias to full model name."""
        return self.MODEL_ALIASES.get(model, model)

    async def chat(self, request: ChatRequest) -> ChatResponse:
        """Execute chat completion."""
        model = self._resolve_model(request.model)

        # Extract system message
        system = None
        messages = []
        for m in request.messages:
            if m.role == Role.SYSTEM:
                system = m.content
            else:
                messages.append({
                    "role": m.role.value,
                    "content": m.content,
                })

        response = await self.client.messages.create(
            model=model,
            max_tokens=request.max_tokens or 4096,
            system=system or "",
            messages=messages,
            temperature=request.temperature,
        )

        content = ""
        for block in response.content:
            if block.type == "text":
                content += block.text

        return ChatResponse(
            id=response.id,
            model=response.model,
            provider=self.name,
            choices=[
                Choice(
                    index=0,
                    message=Message(
                        role=Role.ASSISTANT,
                        content=content,
                    ),
                    finish_reason=response.stop_reason,
                )
            ],
            usage=Usage(
                prompt_tokens=response.usage.input_tokens,
                completion_tokens=response.usage.output_tokens,
                total_tokens=response.usage.input_tokens + response.usage.output_tokens,
                estimated_cost_usd=self.estimate_cost(
                    model,
                    response.usage.input_tokens,
                    response.usage.output_tokens,
                ),
            ),
            created=int(time.time()),
        )

    async def chat_stream(self, request: ChatRequest) -> AsyncIterator[StreamChunk]:
        """Execute streaming chat completion."""
        model = self._resolve_model(request.model)

        system = None
        messages = []
        for m in request.messages:
            if m.role == Role.SYSTEM:
                system = m.content
            else:
                messages.append({
                    "role": m.role.value,
                    "content": m.content,
                })

        chunk_id = f"msg-{uuid.uuid4().hex[:8]}"

        async with self.client.messages.stream(
            model=model,
            max_tokens=request.max_tokens or 4096,
            system=system or "",
            messages=messages,
            temperature=request.temperature,
        ) as stream:
            async for text in stream.text_stream:
                yield StreamChunk(
                    id=chunk_id,
                    model=model,
                    provider=self.name,
                    delta=Delta(content=text),
                    finish_reason=None,
                )

            yield StreamChunk(
                id=chunk_id,
                model=model,
                provider=self.name,
                delta=Delta(content=""),
                finish_reason="end_turn",
            )

    async def health_check(self) -> bool:
        """Check Anthropic API health."""
        try:
            # Simple API call to verify connectivity
            await self.client.messages.create(
                model="claude-3-haiku-20240307",
                max_tokens=10,
                messages=[{"role": "user", "content": "hi"}],
            )
            return True
        except Exception:
            return False
