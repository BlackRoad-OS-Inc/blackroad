"""
Lucidia AI package.

This package implements a simple conversational agent with a short‑term
memory and basic sentiment awareness.  Lucidia aims to provide a more
empathetic interaction than typical chatbots by remembering past
exchanges and tailoring responses according to the emotional tone
detected in user input.  See the `README.md` for an overview of the
project philosophy and usage instructions.
"""

from .core import LucidiaAI



__all__ = ["LucidiaAI"]
__version__ = "0.1.0"

from .truth_agent import TruthAgent

__all__ = ["LucidiaAI", "TruthAgent", "VideoAgent"]
from .video_agent import VideoAgent

from .chatgpt_agent import ChatGPTAgent
__all__.append("ChatGPTAgent")
