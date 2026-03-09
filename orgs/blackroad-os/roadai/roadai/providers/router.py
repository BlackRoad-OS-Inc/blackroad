"""Provider Router - Smart routing between AI providers."""

from __future__ import annotations

import asyncio
from typing import AsyncIterator

from roadai.models.messages import ChatRequest, ChatResponse, StreamChunk
from roadai.providers.base import AIProvider
from roadai.providers.openai import OpenAIProvider
from roadai.providers.anthropic import AnthropicProvider
from roadai.providers.ollama import OllamaProvider


class ProviderRouter:
    """Routes requests to the appropriate AI provider with fallback support."""

    # Model to provider mapping
    MODEL_PROVIDERS = {
        # OpenAI
        "gpt-4o": "openai",
        "gpt-4o-mini": "openai",
        "gpt-4-turbo": "openai",
        "gpt-4": "openai",
        "gpt-3.5-turbo": "openai",
        "o1": "openai",
        "o1-mini": "openai",
        # Anthropic
        "claude-3.5-sonnet": "anthropic",
        "claude-3.5-haiku": "anthropic",
        "claude-3-opus": "anthropic",
        "claude-3-sonnet": "anthropic",
        "claude-3-haiku": "anthropic",
        "claude-3-5-sonnet-20241022": "anthropic",
        "claude-3-5-haiku-20241022": "anthropic",
        "claude-3-opus-20240229": "anthropic",
        # Ollama (local)
        "llama3.2": "ollama",
        "llama3.1": "ollama",
        "llama3": "ollama",
        "mistral": "ollama",
        "phi3": "ollama",
        "codellama": "ollama",
        "deepseek-coder": "ollama",
    }

    def __init__(self):
        self.providers: dict[str, AIProvider] = {}
        self._init_providers()

    def _init_providers(self) -> None:
        """Initialize available providers."""
        # Try to initialize each provider
        try:
            self.providers["openai"] = OpenAIProvider()
        except Exception:
            pass

        try:
            self.providers["anthropic"] = AnthropicProvider()
        except Exception:
            pass

        try:
            self.providers["ollama"] = OllamaProvider()
        except Exception:
            pass

    def get_provider(self, name: str) -> AIProvider | None:
        """Get a specific provider by name."""
        return self.providers.get(name)

    def resolve_provider(self, model: str, preferred: str | None = None) -> AIProvider:
        """Resolve which provider to use for a model."""
        # Use preferred provider if specified and available
        if preferred and preferred in self.providers:
            return self.providers[preferred]

        # Look up by model
        provider_name = self.MODEL_PROVIDERS.get(model)
        if provider_name and provider_name in self.providers:
            return self.providers[provider_name]

        # Default fallback order
        for name in ["openai", "anthropic", "ollama"]:
            if name in self.providers:
                return self.providers[name]

        raise RuntimeError("No AI providers available")

    async def chat(
        self,
        request: ChatRequest,
        fallback_providers: list[str] | None = None,
    ) -> ChatResponse:
        """Execute chat with automatic fallback."""
        providers_to_try = []

        # Primary provider
        primary = self.resolve_provider(request.model, request.provider)
        providers_to_try.append(primary)

        # Add fallback providers
        if fallback_providers:
            for name in fallback_providers:
                if name in self.providers and self.providers[name] != primary:
                    providers_to_try.append(self.providers[name])

        last_error: Exception | None = None
        for provider in providers_to_try:
            try:
                return await provider.chat(request)
            except Exception as e:
                last_error = e
                continue

        raise last_error or RuntimeError("All providers failed")

    async def chat_stream(
        self,
        request: ChatRequest,
    ) -> AsyncIterator[StreamChunk]:
        """Execute streaming chat."""
        provider = self.resolve_provider(request.model, request.provider)
        async for chunk in provider.chat_stream(request):
            yield chunk

    async def health(self) -> dict[str, bool]:
        """Check health of all providers."""
        results = {}
        checks = [
            (name, provider.health_check())
            for name, provider in self.providers.items()
        ]

        for name, coro in checks:
            try:
                results[name] = await asyncio.wait_for(coro, timeout=10.0)
            except Exception:
                results[name] = False

        return results
