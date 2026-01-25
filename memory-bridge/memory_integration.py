"""
🧠 BlackRoad [MEMORY] System Integration
Connects AI models to the centralized memory system
"""

import os
import json
import asyncio
import subprocess
from typing import Optional, Dict, List
from datetime import datetime


class MemoryBridge:
    """
    Bridge between AI models and BlackRoad [MEMORY] system

    Features:
    - Read/write to memory system
    - Session context management
    - Collaboration with other Claude instances
    - Real-time context updates
    """

    def __init__(self):
        self.memory_script = os.getenv("MEMORY_SCRIPT_PATH", "/Users/alexa/memory-system.sh")
        self.session_id = None
        self.connected = False

    async def connect(self):
        """Initialize connection to memory system"""
        try:
            # Test memory system availability
            result = subprocess.run(
                [self.memory_script, "summary"],
                capture_output=True,
                text=True,
                timeout=5
            )
            self.connected = result.returncode == 0
            if self.connected:
                print("✅ [MEMORY] Connected to BlackRoad memory system")
            return self.connected
        except Exception as e:
            print(f"❌ [MEMORY] Connection failed: {e}")
            return False

    async def disconnect(self):
        """Cleanup and disconnect"""
        self.connected = False
        print("🛑 [MEMORY] Disconnected")

    def is_connected(self) -> bool:
        """Check if connected to memory system"""
        return self.connected

    async def get_context(self, session_id: Optional[str] = None) -> Optional[str]:
        """
        Get relevant context from memory system

        Args:
            session_id: Optional session identifier

        Returns:
            Context string or None
        """
        if not self.connected:
            return None

        try:
            # Get recent memory entries relevant to this session
            cmd = [
                self.memory_script,
                "check",
                session_id or "ai-model-context"
            ]

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0 and result.stdout:
                return f"[MEMORY Context]\n{result.stdout}\n"
            return None

        except Exception as e:
            print(f"⚠️ [MEMORY] Context retrieval failed: {e}")
            return None

    async def save_interaction(
        self,
        session_id: str,
        user_message: str,
        assistant_response: str,
        tags: Optional[List[str]] = None
    ):
        """
        Save interaction to memory system

        Args:
            session_id: Session identifier
            user_message: User's message
            assistant_response: Model's response
            tags: Optional tags for categorization
        """
        if not self.connected:
            return

        try:
            # Create memory entry
            context = f"ai-qwen-{session_id}"
            message = f"Q: {user_message}\nA: {assistant_response}"
            tag_str = ",".join(tags or ["ai-interaction", "qwen2.5"])

            cmd = [
                self.memory_script,
                "log",
                "interaction",
                context,
                message,
                tag_str
            ]

            subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=5
            )

        except Exception as e:
            print(f"⚠️ [MEMORY] Save failed: {e}")

    async def broadcast_status(self, status: str, details: Dict):
        """
        Broadcast status to other Claude instances via memory

        Args:
            status: Status message
            details: Additional details dictionary
        """
        if not self.connected:
            return

        try:
            message = f"{status} | {json.dumps(details)}"
            cmd = [
                self.memory_script,
                "log",
                "status",
                "ai-qwen-service",
                message,
                "ai-status,qwen"
            ]

            subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=5
            )

        except Exception as e:
            print(f"⚠️ [MEMORY] Broadcast failed: {e}")

    async def get_collaboration_context(self) -> Dict:
        """
        Get context from other active Claude instances

        Returns:
            Dictionary of collaboration context
        """
        if not self.connected:
            return {}

        try:
            # Use collaboration dashboard script
            result = subprocess.run(
                ["/Users/alexa/memory-collaboration-dashboard.sh", "compact"],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                # Parse the output (simplified - would need proper parsing)
                return {
                    "active_agents": "See dashboard output",
                    "raw_output": result.stdout
                }
            return {}

        except Exception as e:
            print(f"⚠️ [MEMORY] Collaboration context failed: {e}")
            return {}


# Singleton instance
_memory_bridge_instance = None


def get_memory_bridge() -> MemoryBridge:
    """Get singleton memory bridge instance"""
    global _memory_bridge_instance
    if _memory_bridge_instance is None:
        _memory_bridge_instance = MemoryBridge()
    return _memory_bridge_instance
