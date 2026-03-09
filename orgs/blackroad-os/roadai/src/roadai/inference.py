"""
RoadAI Inference Engine

Production-ready AI model inference with caching and batching.

Features:
- Multi-model support (OpenAI, Anthropic, local)
- Inference caching
- Request batching
- Rate limiting
- Cost tracking
- Streaming responses
"""

from typing import Optional, Dict, Any, List, AsyncGenerator, Union
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import hashlib
import json
import time
import asyncio


class ModelProvider(str, Enum):
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    LOCAL = "local"
    HUGGINGFACE = "huggingface"


class ModelType(str, Enum):
    CHAT = "chat"
    COMPLETION = "completion"
    EMBEDDING = "embedding"
    IMAGE = "image"
    AUDIO = "audio"


@dataclass
class ModelConfig:
    provider: ModelProvider
    model_id: str
    model_type: ModelType
    api_key: Optional[str] = None
    base_url: Optional[str] = None
    max_tokens: int = 4096
    temperature: float = 0.7
    cost_per_1k_input: float = 0.0
    cost_per_1k_output: float = 0.0


@dataclass
class InferenceRequest:
    model: str
    messages: Optional[List[Dict[str, str]]] = None
    prompt: Optional[str] = None
    max_tokens: int = 1024
    temperature: float = 0.7
    stream: bool = False
    user_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def cache_key(self) -> str:
        """Generate cache key for request."""
        key_data = {
            "model": self.model,
            "messages": self.messages,
            "prompt": self.prompt,
            "max_tokens": self.max_tokens,
            "temperature": self.temperature,
        }
        return hashlib.sha256(json.dumps(key_data, sort_keys=True).encode()).hexdigest()


@dataclass
class InferenceResponse:
    model: str
    content: str
    usage: Dict[str, int]
    latency_ms: int
    cached: bool = False
    cost: float = 0.0
    finish_reason: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "model": self.model,
            "content": self.content,
            "usage": self.usage,
            "latency_ms": self.latency_ms,
            "cached": self.cached,
            "cost": self.cost,
            "finish_reason": self.finish_reason,
            "metadata": self.metadata,
        }


class InferenceCache:
    """Cache for inference responses."""

    def __init__(self, storage, ttl_seconds: int = 3600):
        self.storage = storage
        self.ttl = ttl_seconds

    async def get(self, key: str) -> Optional[InferenceResponse]:
        """Get cached response."""
        data = await self.storage.get(f"inference_cache:{key}")
        if data:
            return InferenceResponse(**data)
        return None

    async def set(self, key: str, response: InferenceResponse) -> None:
        """Cache response."""
        await self.storage.put(
            f"inference_cache:{key}",
            response.to_dict(),
            ttl=self.ttl,
        )

    async def invalidate(self, key: str) -> None:
        """Invalidate cache entry."""
        await self.storage.delete(f"inference_cache:{key}")


class CostTracker:
    """Track inference costs."""

    def __init__(self, storage):
        self.storage = storage

    async def record_cost(
        self,
        user_id: str,
        model: str,
        input_tokens: int,
        output_tokens: int,
        cost: float,
    ) -> None:
        """Record inference cost."""
        today = datetime.utcnow().strftime("%Y-%m-%d")
        key = f"cost:{user_id}:{today}"

        data = await self.storage.get(key) or {
            "total_cost": 0,
            "total_input_tokens": 0,
            "total_output_tokens": 0,
            "requests": 0,
            "by_model": {},
        }

        data["total_cost"] += cost
        data["total_input_tokens"] += input_tokens
        data["total_output_tokens"] += output_tokens
        data["requests"] += 1

        if model not in data["by_model"]:
            data["by_model"][model] = {"cost": 0, "requests": 0}
        data["by_model"][model]["cost"] += cost
        data["by_model"][model]["requests"] += 1

        await self.storage.put(key, data)

    async def get_usage(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Get usage summary."""
        total_cost = 0
        total_requests = 0
        by_model: Dict[str, Dict] = {}

        now = datetime.utcnow()
        for i in range(days):
            date = (now - timedelta(days=i)).strftime("%Y-%m-%d")
            key = f"cost:{user_id}:{date}"
            data = await self.storage.get(key)

            if data:
                total_cost += data.get("total_cost", 0)
                total_requests += data.get("requests", 0)

                for model, stats in data.get("by_model", {}).items():
                    if model not in by_model:
                        by_model[model] = {"cost": 0, "requests": 0}
                    by_model[model]["cost"] += stats["cost"]
                    by_model[model]["requests"] += stats["requests"]

        return {
            "total_cost": round(total_cost, 4),
            "total_requests": total_requests,
            "by_model": by_model,
            "period_days": days,
        }


class RateLimiter:
    """Rate limit inference requests."""

    def __init__(self, storage):
        self.storage = storage

    async def check_limit(
        self,
        user_id: str,
        requests_per_minute: int = 60,
    ) -> Dict[str, Any]:
        """Check if user is within rate limit."""
        window = int(time.time()) // 60
        key = f"rate_limit:{user_id}:{window}"

        current = await self.storage.get(key) or 0

        return {
            "allowed": current < requests_per_minute,
            "current": current,
            "limit": requests_per_minute,
            "remaining": max(0, requests_per_minute - current),
            "reset_in": 60 - (int(time.time()) % 60),
        }

    async def increment(self, user_id: str) -> None:
        """Increment rate limit counter."""
        window = int(time.time()) // 60
        key = f"rate_limit:{user_id}:{window}"

        current = await self.storage.get(key) or 0
        await self.storage.put(key, current + 1, ttl=120)


class InferenceEngine:
    """
    Main inference engine with multi-provider support.
    """

    def __init__(
        self,
        storage,
        cache_ttl: int = 3600,
        enable_cache: bool = True,
    ):
        self.storage = storage
        self.models: Dict[str, ModelConfig] = {}
        self.cache = InferenceCache(storage, cache_ttl) if enable_cache else None
        self.cost_tracker = CostTracker(storage)
        self.rate_limiter = RateLimiter(storage)

    def register_model(self, name: str, config: ModelConfig) -> None:
        """Register a model configuration."""
        self.models[name] = config

    async def infer(
        self,
        request: InferenceRequest,
    ) -> InferenceResponse:
        """
        Run inference on a model.
        """
        start_time = time.time()

        # Check cache first
        if self.cache and not request.stream:
            cache_key = request.cache_key()
            cached = await self.cache.get(cache_key)
            if cached:
                cached.cached = True
                return cached

        # Get model config
        config = self.models.get(request.model)
        if not config:
            raise ValueError(f"Model {request.model} not registered")

        # Run inference based on provider
        if config.provider == ModelProvider.OPENAI:
            response = await self._infer_openai(request, config)
        elif config.provider == ModelProvider.ANTHROPIC:
            response = await self._infer_anthropic(request, config)
        elif config.provider == ModelProvider.LOCAL:
            response = await self._infer_local(request, config)
        else:
            raise ValueError(f"Unsupported provider: {config.provider}")

        # Calculate cost
        input_tokens = response.usage.get("input_tokens", 0)
        output_tokens = response.usage.get("output_tokens", 0)
        cost = (
            (input_tokens / 1000) * config.cost_per_1k_input +
            (output_tokens / 1000) * config.cost_per_1k_output
        )
        response.cost = round(cost, 6)

        # Record metrics
        response.latency_ms = int((time.time() - start_time) * 1000)

        # Cache response
        if self.cache and not request.stream:
            await self.cache.set(request.cache_key(), response)

        # Track cost
        if request.user_id:
            await self.cost_tracker.record_cost(
                request.user_id,
                request.model,
                input_tokens,
                output_tokens,
                response.cost,
            )

        return response

    async def stream(
        self,
        request: InferenceRequest,
    ) -> AsyncGenerator[str, None]:
        """
        Stream inference response.
        """
        config = self.models.get(request.model)
        if not config:
            raise ValueError(f"Model {request.model} not registered")

        if config.provider == ModelProvider.OPENAI:
            async for chunk in self._stream_openai(request, config):
                yield chunk
        elif config.provider == ModelProvider.ANTHROPIC:
            async for chunk in self._stream_anthropic(request, config):
                yield chunk
        else:
            # Fallback to non-streaming
            response = await self.infer(request)
            yield response.content

    async def _infer_openai(
        self,
        request: InferenceRequest,
        config: ModelConfig,
    ) -> InferenceResponse:
        """Run inference on OpenAI."""
        import httpx

        headers = {
            "Authorization": f"Bearer {config.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": config.model_id,
            "messages": request.messages or [{"role": "user", "content": request.prompt}],
            "max_tokens": request.max_tokens,
            "temperature": request.temperature,
        }

        base_url = config.base_url or "https://api.openai.com/v1"

        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{base_url}/chat/completions",
                headers=headers,
                json=payload,
                timeout=120.0,
            )
            data = resp.json()

        choice = data["choices"][0]
        usage = data.get("usage", {})

        return InferenceResponse(
            model=request.model,
            content=choice["message"]["content"],
            usage={
                "input_tokens": usage.get("prompt_tokens", 0),
                "output_tokens": usage.get("completion_tokens", 0),
                "total_tokens": usage.get("total_tokens", 0),
            },
            latency_ms=0,
            finish_reason=choice.get("finish_reason"),
        )

    async def _infer_anthropic(
        self,
        request: InferenceRequest,
        config: ModelConfig,
    ) -> InferenceResponse:
        """Run inference on Anthropic."""
        import httpx

        headers = {
            "x-api-key": config.api_key,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        }

        # Convert messages format
        messages = request.messages or [{"role": "user", "content": request.prompt}]

        payload = {
            "model": config.model_id,
            "messages": messages,
            "max_tokens": request.max_tokens,
            "temperature": request.temperature,
        }

        base_url = config.base_url or "https://api.anthropic.com/v1"

        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{base_url}/messages",
                headers=headers,
                json=payload,
                timeout=120.0,
            )
            data = resp.json()

        content = data["content"][0]["text"] if data.get("content") else ""
        usage = data.get("usage", {})

        return InferenceResponse(
            model=request.model,
            content=content,
            usage={
                "input_tokens": usage.get("input_tokens", 0),
                "output_tokens": usage.get("output_tokens", 0),
                "total_tokens": usage.get("input_tokens", 0) + usage.get("output_tokens", 0),
            },
            latency_ms=0,
            finish_reason=data.get("stop_reason"),
        )

    async def _infer_local(
        self,
        request: InferenceRequest,
        config: ModelConfig,
    ) -> InferenceResponse:
        """Run inference on local model (Ollama, vLLM, etc.)."""
        import httpx

        base_url = config.base_url or "http://localhost:11434"

        payload = {
            "model": config.model_id,
            "prompt": request.prompt or request.messages[-1]["content"],
            "stream": False,
        }

        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{base_url}/api/generate",
                json=payload,
                timeout=300.0,
            )
            data = resp.json()

        return InferenceResponse(
            model=request.model,
            content=data.get("response", ""),
            usage={
                "input_tokens": data.get("prompt_eval_count", 0),
                "output_tokens": data.get("eval_count", 0),
                "total_tokens": data.get("prompt_eval_count", 0) + data.get("eval_count", 0),
            },
            latency_ms=0,
        )

    async def _stream_openai(
        self,
        request: InferenceRequest,
        config: ModelConfig,
    ) -> AsyncGenerator[str, None]:
        """Stream from OpenAI."""
        import httpx

        headers = {
            "Authorization": f"Bearer {config.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": config.model_id,
            "messages": request.messages or [{"role": "user", "content": request.prompt}],
            "max_tokens": request.max_tokens,
            "temperature": request.temperature,
            "stream": True,
        }

        base_url = config.base_url or "https://api.openai.com/v1"

        async with httpx.AsyncClient() as client:
            async with client.stream(
                "POST",
                f"{base_url}/chat/completions",
                headers=headers,
                json=payload,
                timeout=120.0,
            ) as resp:
                async for line in resp.aiter_lines():
                    if line.startswith("data: "):
                        data = line[6:]
                        if data == "[DONE]":
                            break
                        chunk = json.loads(data)
                        delta = chunk["choices"][0].get("delta", {})
                        if "content" in delta:
                            yield delta["content"]

    async def _stream_anthropic(
        self,
        request: InferenceRequest,
        config: ModelConfig,
    ) -> AsyncGenerator[str, None]:
        """Stream from Anthropic."""
        import httpx

        headers = {
            "x-api-key": config.api_key,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        }

        messages = request.messages or [{"role": "user", "content": request.prompt}]

        payload = {
            "model": config.model_id,
            "messages": messages,
            "max_tokens": request.max_tokens,
            "temperature": request.temperature,
            "stream": True,
        }

        base_url = config.base_url or "https://api.anthropic.com/v1"

        async with httpx.AsyncClient() as client:
            async with client.stream(
                "POST",
                f"{base_url}/messages",
                headers=headers,
                json=payload,
                timeout=120.0,
            ) as resp:
                async for line in resp.aiter_lines():
                    if line.startswith("data: "):
                        data = json.loads(line[6:])
                        if data["type"] == "content_block_delta":
                            yield data["delta"].get("text", "")


class EmbeddingEngine:
    """
    Generate embeddings for text.
    """

    def __init__(self, storage, api_key: str, provider: ModelProvider = ModelProvider.OPENAI):
        self.storage = storage
        self.api_key = api_key
        self.provider = provider
        self.cache = {}

    async def embed(
        self,
        texts: Union[str, List[str]],
        model: str = "text-embedding-3-small",
        cache: bool = True,
    ) -> List[List[float]]:
        """Generate embeddings for texts."""
        if isinstance(texts, str):
            texts = [texts]

        # Check cache
        if cache:
            cached_results = []
            uncached_texts = []
            uncached_indices = []

            for i, text in enumerate(texts):
                cache_key = hashlib.sha256(f"{model}:{text}".encode()).hexdigest()
                if cache_key in self.cache:
                    cached_results.append((i, self.cache[cache_key]))
                else:
                    uncached_texts.append(text)
                    uncached_indices.append(i)

            if not uncached_texts:
                # All cached
                cached_results.sort(key=lambda x: x[0])
                return [x[1] for x in cached_results]

            # Get uncached embeddings
            new_embeddings = await self._get_embeddings(uncached_texts, model)

            # Cache new embeddings
            for text, embedding in zip(uncached_texts, new_embeddings):
                cache_key = hashlib.sha256(f"{model}:{text}".encode()).hexdigest()
                self.cache[cache_key] = embedding

            # Combine results
            all_results = cached_results + list(zip(uncached_indices, new_embeddings))
            all_results.sort(key=lambda x: x[0])
            return [x[1] for x in all_results]

        return await self._get_embeddings(texts, model)

    async def _get_embeddings(
        self,
        texts: List[str],
        model: str,
    ) -> List[List[float]]:
        """Get embeddings from API."""
        import httpx

        if self.provider == ModelProvider.OPENAI:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            }

            payload = {
                "model": model,
                "input": texts,
            }

            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    "https://api.openai.com/v1/embeddings",
                    headers=headers,
                    json=payload,
                    timeout=60.0,
                )
                data = resp.json()

            return [item["embedding"] for item in data["data"]]

        raise ValueError(f"Embedding not supported for provider: {self.provider}")

    async def similarity(
        self,
        text1: str,
        text2: str,
        model: str = "text-embedding-3-small",
    ) -> float:
        """Calculate cosine similarity between two texts."""
        embeddings = await self.embed([text1, text2], model)
        return self._cosine_similarity(embeddings[0], embeddings[1])

    def _cosine_similarity(self, a: List[float], b: List[float]) -> float:
        """Calculate cosine similarity."""
        dot_product = sum(x * y for x, y in zip(a, b))
        norm_a = sum(x * x for x in a) ** 0.5
        norm_b = sum(x * x for x in b) ** 0.5
        return dot_product / (norm_a * norm_b) if norm_a and norm_b else 0.0


# Factory function
def create_inference_engine(
    storage,
    openai_key: Optional[str] = None,
    anthropic_key: Optional[str] = None,
    local_url: Optional[str] = None,
) -> InferenceEngine:
    """Create a configured inference engine."""
    engine = InferenceEngine(storage)

    # Register OpenAI models
    if openai_key:
        engine.register_model("gpt-4o", ModelConfig(
            provider=ModelProvider.OPENAI,
            model_id="gpt-4o",
            model_type=ModelType.CHAT,
            api_key=openai_key,
            cost_per_1k_input=0.005,
            cost_per_1k_output=0.015,
        ))
        engine.register_model("gpt-4o-mini", ModelConfig(
            provider=ModelProvider.OPENAI,
            model_id="gpt-4o-mini",
            model_type=ModelType.CHAT,
            api_key=openai_key,
            cost_per_1k_input=0.00015,
            cost_per_1k_output=0.0006,
        ))

    # Register Anthropic models
    if anthropic_key:
        engine.register_model("claude-sonnet", ModelConfig(
            provider=ModelProvider.ANTHROPIC,
            model_id="claude-sonnet-4-20250514",
            model_type=ModelType.CHAT,
            api_key=anthropic_key,
            cost_per_1k_input=0.003,
            cost_per_1k_output=0.015,
        ))
        engine.register_model("claude-opus", ModelConfig(
            provider=ModelProvider.ANTHROPIC,
            model_id="claude-opus-4-20250514",
            model_type=ModelType.CHAT,
            api_key=anthropic_key,
            cost_per_1k_input=0.015,
            cost_per_1k_output=0.075,
        ))

    # Register local models
    if local_url:
        engine.register_model("local-llama", ModelConfig(
            provider=ModelProvider.LOCAL,
            model_id="llama3.2",
            model_type=ModelType.CHAT,
            base_url=local_url,
        ))

    return engine


from datetime import timedelta
