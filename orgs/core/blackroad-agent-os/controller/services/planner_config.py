"""
Planner Configuration - Multi-provider LLM settings
"""
import os
from enum import Enum
from typing import Optional
from pydantic import BaseModel


class PlannerProvider(str, Enum):
    STUB = "stub"
    ANTHROPIC = "anthropic"
    OPENAI = "openai"
    GPT_OSS = "gpt_oss"  # HuggingFace hosted
    MISTRAL = "mistral"
    OLLAMA = "ollama"


class PlannerConfig(BaseModel):
    """Configuration for the LLM planner"""
    provider: PlannerProvider = PlannerProvider.STUB

    # Anthropic
    anthropic_api_key: Optional[str] = None
    anthropic_model: str = "claude-sonnet-4-20250514"

    # OpenAI
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-4o-mini"

    # HuggingFace / GPT-OSS
    hf_api_token: Optional[str] = None
    gpt_oss_model: str = "mistralai/Mistral-7B-Instruct-v0.2"
    gpt_oss_endpoint: Optional[str] = None  # Custom endpoint if self-hosting

    # Mistral
    mistral_api_key: Optional[str] = None
    mistral_model: str = "mistral-large-latest"

    # Ollama (local)
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "llama3"

    @classmethod
    def from_env(cls) -> "PlannerConfig":
        """Load configuration from environment variables"""
        # Determine provider
        provider_str = os.environ.get("PLANNER_PROVIDER", "").lower()

        if provider_str:
            try:
                provider = PlannerProvider(provider_str)
            except ValueError:
                provider = PlannerProvider.STUB
        else:
            # Auto-detect based on available keys
            if os.environ.get("ANTHROPIC_API_KEY"):
                provider = PlannerProvider.ANTHROPIC
            elif os.environ.get("OPENAI_API_KEY"):
                provider = PlannerProvider.OPENAI
            elif os.environ.get("MISTRAL_API_KEY"):
                provider = PlannerProvider.MISTRAL
            elif os.environ.get("HF_API_TOKEN"):
                provider = PlannerProvider.GPT_OSS
            elif os.environ.get("OLLAMA_MODEL"):
                provider = PlannerProvider.OLLAMA
            else:
                provider = PlannerProvider.STUB

        return cls(
            provider=provider,
            # Anthropic
            anthropic_api_key=os.environ.get("ANTHROPIC_API_KEY"),
            anthropic_model=os.environ.get("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
            # OpenAI
            openai_api_key=os.environ.get("OPENAI_API_KEY"),
            openai_model=os.environ.get("OPENAI_MODEL", "gpt-4o-mini"),
            # HuggingFace
            hf_api_token=os.environ.get("HF_API_TOKEN"),
            gpt_oss_model=os.environ.get("GPT_OSS_MODEL", "mistralai/Mistral-7B-Instruct-v0.2"),
            gpt_oss_endpoint=os.environ.get("GPT_OSS_ENDPOINT"),
            # Mistral
            mistral_api_key=os.environ.get("MISTRAL_API_KEY"),
            mistral_model=os.environ.get("MISTRAL_MODEL", "mistral-large-latest"),
            # Ollama
            ollama_base_url=os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434"),
            ollama_model=os.environ.get("OLLAMA_MODEL", "llama3"),
        )
