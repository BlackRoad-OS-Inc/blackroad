"""RoadAI - Main FastAPI Application."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse

from roadai.models.messages import ChatRequest, ChatResponse, StreamChunk
from roadai.providers.router import ProviderRouter


# Global router instance
router: ProviderRouter | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    global router
    router = ProviderRouter()
    yield
    router = None


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="RoadAI",
        description="BlackRoad AI Platform - Unified AI orchestration and inference",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register routes
    @app.get("/")
    async def root():
        """Root endpoint."""
        return {
            "name": "RoadAI",
            "version": "0.1.0",
            "description": "BlackRoad AI Platform Core",
            "docs": "/docs",
        }

    @app.get("/health")
    async def health():
        """Health check endpoint."""
        if not router:
            raise HTTPException(status_code=503, detail="Service not initialized")

        provider_health = await router.health()
        all_healthy = any(provider_health.values())

        return {
            "status": "healthy" if all_healthy else "degraded",
            "providers": provider_health,
        }

    @app.get("/providers")
    async def list_providers():
        """List available AI providers."""
        if not router:
            raise HTTPException(status_code=503, detail="Service not initialized")

        return {
            "providers": list(router.providers.keys()),
            "models": router.MODEL_PROVIDERS,
        }

    @app.post("/v1/chat/completions", response_model=ChatResponse)
    async def chat_completions(request: ChatRequest):
        """
        OpenAI-compatible chat completions endpoint.

        Supports:
        - All major models (GPT-4o, Claude 3.5, Llama 3, etc.)
        - Automatic provider routing
        - Fallback providers
        - Token tracking and cost estimation
        """
        if not router:
            raise HTTPException(status_code=503, detail="Service not initialized")

        if request.stream:
            return StreamingResponse(
                stream_response(request),
                media_type="text/event-stream",
            )

        try:
            response = await router.chat(
                request,
                fallback_providers=request.fallback_providers,
            )
            return response
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    async def stream_response(request: ChatRequest) -> AsyncIterator[str]:
        """Generate SSE stream for chat completions."""
        try:
            async for chunk in router.chat_stream(request):
                yield f"data: {chunk.model_dump_json()}\n\n"
            yield "data: [DONE]\n\n"
        except Exception as e:
            yield f"data: {{'error': '{str(e)}'}}\n\n"

    @app.post("/chat", response_model=ChatResponse)
    async def simple_chat(request: ChatRequest):
        """
        Simple chat endpoint (non-OpenAI format).
        Same as /v1/chat/completions but without streaming.
        """
        if not router:
            raise HTTPException(status_code=503, detail="Service not initialized")

        try:
            return await router.chat(request)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    return app


# Default app instance
app = create_app()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "roadai.main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8000")),
        reload=True,
    )
