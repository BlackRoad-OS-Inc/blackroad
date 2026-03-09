"""Ollama Provider implementation for local models."""

from __future__ import annotations

import os
import time
import uuid
from typing import AsyncIterator

import httpx
from ollama import AsyncClient

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


class OllamaProvider(AIProvider):
    """Ollama local model provider."""

    name = "ollama"

    # Local models are free
    PRICING = {
        "llama3.2": (0.0, 0.0),
        "llama3.1": (0.0, 0.0),
        "llama3": (0.0, 0.0),
        "mistral": (0.0, 0.0),
        "mixtral": (0.0, 0.0),
        "phi3": (0.0, 0.0),
        "phi3.5": (0.0, 0.0),
        "codellama": (0.0, 0.0),
        "deepseek-coder": (0.0, 0.0),
        "qwen2.5-coder": (0.0, 0.0),
    }

    def __init__(self, host: str | None = None):
        self.host = host or os.getenv("OLLAMA_HOST", "http://localhost:11434")
        self.client = AsyncClient(host=self.host)

    async def chat(self, request: ChatRequest) -> ChatResponse:
        """Execute chat completion via Ollama."""
        messages = [
            {"role": m.role.value, "content": m.content}
            for m in request.messages
        ]

        response = await self.client.chat(
            model=request.model,
            messages=messages,
            options={
                "temperature": request.temperature,
                "num_predict": request.max_tokens or -1,
            },
        )

        # Estimate tokens (Ollama provides this)
        prompt_tokens = response.get("prompt_eval_count", 0)
        completion_tokens = response.get("eval_count", 0)

        return ChatResponse(
            id=f"ollama-{uuid.uuid4().hex[:8]}",
            model=response.get("model", request.model),
            provider=self.name,
            choices=[
                Choice(
                    index=0,
                    message=Message(
                        role=Role.ASSISTANT,
                        content=response["message"]["content"],
                    ),
                    finish_reason="stop",
                )
            ],
            usage=Usage(
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=prompt_tokens + completion_tokens,
                estimated_cost_usd=0.0,  # Local is free!
            ),
            created=int(time.time()),
        )

    async def chat_stream(self, request: ChatRequest) -> AsyncIterator[StreamChunk]:
        """Execute streaming chat completion via Ollama."""
        messages = [
            {"role": m.role.value, "content": m.content}
            for m in request.messages
        ]

        chunk_id = f"ollama-{uuid.uuid4().hex[:8]}"

        async for chunk in await self.client.chat(
            model=request.model,
            messages=messages,
            stream=True,
            options={
                "temperature": request.temperature,
                "num_predict": request.max_tokens or -1,
            },
        ):
            yield StreamChunk(
                id=chunk_id,
                model=request.model,
                provider=self.name,
                delta=Delta(content=chunk["message"]["content"]),
                finish_reason="stop" if chunk.get("done") else None,
            )

    async def health_check(self) -> bool:
        """Check if Ollama is running and accessible."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.host}/api/tags", timeout=5.0)
                return response.status_code == 200
        except Exception:
            return False

    async def list_models(self) -> list[str]:
        """List available local models."""
        try:
            models = await self.client.list()
            return [m["name"] for m in models.get("models", [])]
        except Exception:
            return []
