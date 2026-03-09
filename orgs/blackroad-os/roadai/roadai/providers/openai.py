"""OpenAI Provider implementation."""

from __future__ import annotations

import os
import time
import uuid
from typing import AsyncIterator

from openai import AsyncOpenAI

from roadai.models.messages import (
    ChatRequest,
    ChatResponse,
    Choice,
    Delta,
    Message,
    Role,
    StreamChunk,
    ToolCall,
    ToolFunction,
    Usage,
)
from roadai.providers.base import AIProvider


class OpenAIProvider(AIProvider):
    """OpenAI API provider."""

    name = "openai"

    # Pricing per 1M tokens (input, output) - Jan 2025
    PRICING = {
        "gpt-4o": (2.50, 10.00),
        "gpt-4o-mini": (0.15, 0.60),
        "gpt-4-turbo": (10.00, 30.00),
        "gpt-4": (30.00, 60.00),
        "gpt-3.5-turbo": (0.50, 1.50),
        "o1": (15.00, 60.00),
        "o1-mini": (3.00, 12.00),
    }

    def __init__(self, api_key: str | None = None, base_url: str | None = None):
        self.client = AsyncOpenAI(
            api_key=api_key or os.getenv("OPENAI_API_KEY"),
            base_url=base_url,
        )

    async def chat(self, request: ChatRequest) -> ChatResponse:
        """Execute chat completion."""
        messages = [
            {"role": m.role.value, "content": m.content}
            for m in request.messages
        ]

        kwargs: dict = {
            "model": request.model,
            "messages": messages,
            "temperature": request.temperature,
        }
        if request.max_tokens:
            kwargs["max_tokens"] = request.max_tokens
        if request.tools:
            kwargs["tools"] = [t.model_dump() for t in request.tools]
            if request.tool_choice:
                kwargs["tool_choice"] = request.tool_choice

        response = await self.client.chat.completions.create(**kwargs)

        # Parse response
        choice = response.choices[0]
        tool_calls = None
        if choice.message.tool_calls:
            tool_calls = [
                ToolCall(
                    id=tc.id,
                    function=ToolFunction(
                        name=tc.function.name,
                        arguments=tc.function.arguments,
                    ),
                )
                for tc in choice.message.tool_calls
            ]

        return ChatResponse(
            id=response.id,
            model=response.model,
            provider=self.name,
            choices=[
                Choice(
                    index=0,
                    message=Message(
                        role=Role(choice.message.role),
                        content=choice.message.content or "",
                        tool_calls=tool_calls,
                    ),
                    finish_reason=choice.finish_reason,
                )
            ],
            usage=Usage(
                prompt_tokens=response.usage.prompt_tokens if response.usage else 0,
                completion_tokens=response.usage.completion_tokens if response.usage else 0,
                total_tokens=response.usage.total_tokens if response.usage else 0,
                estimated_cost_usd=self.estimate_cost(
                    response.model,
                    response.usage.prompt_tokens if response.usage else 0,
                    response.usage.completion_tokens if response.usage else 0,
                ),
            ),
            created=response.created,
        )

    async def chat_stream(self, request: ChatRequest) -> AsyncIterator[StreamChunk]:
        """Execute streaming chat completion."""
        messages = [
            {"role": m.role.value, "content": m.content}
            for m in request.messages
        ]

        stream = await self.client.chat.completions.create(
            model=request.model,
            messages=messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
            stream=True,
        )

        chunk_id = f"chatcmpl-{uuid.uuid4().hex[:8]}"

        async for chunk in stream:
            if chunk.choices and chunk.choices[0].delta:
                delta = chunk.choices[0].delta
                yield StreamChunk(
                    id=chunk_id,
                    model=request.model,
                    provider=self.name,
                    delta=Delta(
                        role=Role(delta.role) if delta.role else None,
                        content=delta.content,
                    ),
                    finish_reason=chunk.choices[0].finish_reason,
                )

    async def health_check(self) -> bool:
        """Check OpenAI API health."""
        try:
            await self.client.models.list()
            return True
        except Exception:
            return False
