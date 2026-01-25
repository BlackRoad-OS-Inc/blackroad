"""
🤖 BlackRoad AI - Ollama Wrapper Server
Adds [MEMORY] integration, emoji support, and actions to Ollama
"""

import os
import subprocess
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import httpx

app = FastAPI(
    title="BlackRoad AI - Ollama Wrapper",
    description="Ollama with [MEMORY] integration and BlackRoad enhancements",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ollama client
OLLAMA_URL = "http://localhost:11434"


class ChatRequest(BaseModel):
    model: str
    message: str
    max_tokens: int = 512
    temperature: float = 0.7
    use_memory: bool = True
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    response: str
    model: str
    memory_context_used: bool = False
    emoji_enhanced: bool = True


@app.get("/")
async def root():
    return {
        "service": "BlackRoad AI - Ollama Wrapper",
        "status": "online",
        "features": ["memory_integration", "emoji_support", "multi_model"]
    }


@app.get("/health")
async def health():
    """Health check"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_URL}/api/tags")
            return {
                "status": "healthy",
                "ollama_running": response.status_code == 200
            }
    except:
        return {"status": "unhealthy", "ollama_running": False}


@app.get("/models")
async def list_models():
    """List available models"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_URL}/api/tags")
            return response.json()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Chat with Ollama model + BlackRoad enhancements
    """
    prompt = request.message
    memory_used = False

    # Add memory context
    if request.use_memory and request.session_id:
        try:
            result = subprocess.run(
                ["/host-home/memory-system.sh", "check", f"ollama-{request.session_id}"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0 and result.stdout:
                prompt = f"[Context]\n{result.stdout}\n\n{request.message}"
                memory_used = True
        except:
            pass

    # Call Ollama
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{OLLAMA_URL}/api/generate",
                json={
                    "model": request.model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": request.temperature,
                        "num_predict": request.max_tokens
                    }
                }
            )
            result = response.json()
            response_text = result.get("response", "")

            # Enhance with emojis
            response_text = enhance_with_emojis(response_text)

            # Save to memory
            if request.session_id:
                try:
                    subprocess.run(
                        [
                            "/host-home/memory-system.sh", "log", "interaction",
                            f"ollama-{request.session_id}",
                            f"Q: {request.message}\nA: {response_text}",
                            f"ai,ollama,{request.model}"
                        ],
                        timeout=5
                    )
                except:
                    pass

            return ChatResponse(
                response=response_text,
                model=request.model,
                memory_context_used=memory_used,
                emoji_enhanced=True
            )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def enhance_with_emojis(text: str) -> str:
    """Add contextual emojis"""
    emoji_map = {
        "success": "✅",
        "error": "❌",
        "warning": "⚠️",
        "info": "ℹ️",
        "blackroad": "🖤🛣️",
        "ai": "🤖",
        "quantum": "⚛️"
    }

    for keyword, emoji in emoji_map.items():
        if keyword.lower() in text.lower() and emoji not in text:
            text = text.replace(keyword, f"{emoji} {keyword}", 1)

    return text


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
