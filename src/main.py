"""
🤖 BlackRoad AI - Qwen2.5 Model Service
Proprietary AI model server with [MEMORY] integration
"""

import os
import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from typing import Optional, List, Dict
import sys
sys.path.append('/app/memory-bridge')
from memory_integration import MemoryBridge


# Configuration
MODEL_NAME = os.getenv("MODEL_NAME", "Qwen/Qwen2.5-7B")
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
MEMORY_ENABLED = os.getenv("BLACKROAD_MEMORY_ENABLED", "true").lower() == "true"
EMOJI_SUPPORT = os.getenv("ENABLE_EMOJI_SUPPORT", "true").lower() == "true"
ACTION_EXECUTION = os.getenv("ENABLE_ACTION_EXECUTION", "true").lower() == "true"

# Global model storage
model = None
tokenizer = None
memory_bridge = None


class ChatRequest(BaseModel):
    """Chat completion request"""
    message: str
    max_tokens: int = 512
    temperature: float = 0.7
    use_memory: bool = True
    enable_actions: bool = True
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    """Chat completion response"""
    response: str
    tokens_used: int
    memory_context_used: bool = False
    actions_executed: List[str] = []
    emoji_enhanced: bool = False


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown lifecycle"""
    global model, tokenizer, memory_bridge

    print("🚀 Loading Qwen2.5 model...")
    print(f"📦 Model: {MODEL_NAME}")
    print(f"💻 Device: {DEVICE}")

    # Load tokenizer and model
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_NAME,
        torch_dtype=torch.float16 if DEVICE == "cuda" else torch.float32,
        device_map="auto"
    )

    # Initialize memory bridge
    if MEMORY_ENABLED:
        memory_bridge = MemoryBridge()
        await memory_bridge.connect()
        print("✅ [MEMORY] Bridge connected")

    print("✅ Model loaded successfully")

    yield

    # Cleanup
    print("🛑 Shutting down...")
    if memory_bridge:
        await memory_bridge.disconnect()


# Create FastAPI app
app = FastAPI(
    title="BlackRoad AI - Qwen2.5",
    description="Proprietary Qwen2.5 deployment with [MEMORY] integration",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "BlackRoad AI - Qwen2.5",
        "status": "online",
        "model": MODEL_NAME,
        "device": DEVICE,
        "features": {
            "memory_integration": MEMORY_ENABLED,
            "emoji_support": EMOJI_SUPPORT,
            "action_execution": ACTION_EXECUTION
        }
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "memory_connected": memory_bridge is not None and memory_bridge.is_connected()
    }


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Generate chat completion

    Features:
    - 🧠 [MEMORY] context integration
    - ⚡ Action execution (bash commands, API calls)
    - 🎨 Emoji enhancement for better UX
    """
    if model is None or tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    # Enhance prompt with memory context
    prompt = request.message
    memory_context_used = False

    if request.use_memory and memory_bridge:
        memory_context = await memory_bridge.get_context(request.session_id)
        if memory_context:
            prompt = f"{memory_context}\n\nUser: {request.message}"
            memory_context_used = True

    # Generate response
    inputs = tokenizer(prompt, return_tensors="pt").to(DEVICE)

    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=request.max_tokens,
            temperature=request.temperature,
            do_sample=True,
            top_p=0.95
        )

    response_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

    # Extract just the new response (remove prompt)
    response_text = response_text[len(prompt):].strip()

    # Execute actions if enabled
    actions_executed = []
    if request.enable_actions and ACTION_EXECUTION:
        actions_executed = await execute_actions(response_text)

    # Enhance with emojis if enabled
    emoji_enhanced = False
    if EMOJI_SUPPORT:
        response_text = enhance_with_emojis(response_text)
        emoji_enhanced = True

    # Save to memory
    if memory_bridge and request.session_id:
        await memory_bridge.save_interaction(
            session_id=request.session_id,
            user_message=request.message,
            assistant_response=response_text
        )

    return ChatResponse(
        response=response_text,
        tokens_used=outputs.shape[1],
        memory_context_used=memory_context_used,
        actions_executed=actions_executed,
        emoji_enhanced=emoji_enhanced
    )


async def execute_actions(text: str) -> List[str]:
    """
    Execute actions mentioned in the response
    Examples: bash commands, API calls, etc.
    """
    actions = []
    # TODO: Implement action parsing and execution
    # This would integrate with BlackRoad's action system
    return actions


def enhance_with_emojis(text: str) -> str:
    """
    Enhance text with contextually appropriate emojis
    """
    emoji_map = {
        "success": "✅",
        "error": "❌",
        "warning": "⚠️",
        "info": "ℹ️",
        "rocket": "🚀",
        "brain": "🧠",
        "lightning": "⚡",
        "art": "🎨",
        "robot": "🤖",
        "blackroad": "🖤🛣️"
    }

    # Simple emoji enhancement
    for keyword, emoji in emoji_map.items():
        if keyword.lower() in text.lower() and emoji not in text:
            text = text.replace(keyword, f"{emoji} {keyword}")

    return text


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
