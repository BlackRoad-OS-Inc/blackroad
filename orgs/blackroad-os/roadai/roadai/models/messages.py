"""Message and request/response models for RoadAI."""

from __future__ import annotations

from enum import Enum
from typing import Any, Literal

from pydantic import BaseModel, Field


class Role(str, Enum):
    """Message role."""
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"
    TOOL = "tool"


class Message(BaseModel):
    """A single message in a conversation."""
    role: Role
    content: str
    name: str | None = None
    tool_calls: list[ToolCall] | None = None
    tool_call_id: str | None = None


class ToolCall(BaseModel):
    """A tool/function call made by the model."""
    id: str
    type: Literal["function"] = "function"
    function: ToolFunction


class ToolFunction(BaseModel):
    """Function details in a tool call."""
    name: str
    arguments: str  # JSON string


class Tool(BaseModel):
    """Tool definition for function calling."""
    type: Literal["function"] = "function"
    function: ToolDefinition


class ToolDefinition(BaseModel):
    """Function definition for tools."""
    name: str
    description: str
    parameters: dict[str, Any] = Field(default_factory=dict)


class Usage(BaseModel):
    """Token usage statistics."""
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    estimated_cost_usd: float | None = None


class ChatRequest(BaseModel):
    """Request for chat completion."""
    model: str = "gpt-4o"
    messages: list[Message]
    temperature: float = Field(default=0.7, ge=0, le=2)
    max_tokens: int | None = None
    stream: bool = False
    tools: list[Tool] | None = None
    tool_choice: str | dict[str, Any] | None = None

    # Provider routing
    provider: str | None = None  # openai, anthropic, ollama, auto
    fallback_providers: list[str] | None = None


class ChatResponse(BaseModel):
    """Response from chat completion."""
    id: str
    model: str
    provider: str
    choices: list[Choice]
    usage: Usage
    created: int


class Choice(BaseModel):
    """A single completion choice."""
    index: int = 0
    message: Message
    finish_reason: str | None = None


class StreamChunk(BaseModel):
    """A chunk from streaming response."""
    id: str
    model: str
    provider: str
    delta: Delta
    finish_reason: str | None = None


class Delta(BaseModel):
    """Delta content in a stream chunk."""
    role: Role | None = None
    content: str | None = None
    tool_calls: list[ToolCall] | None = None
