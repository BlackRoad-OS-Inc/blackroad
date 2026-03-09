"""BlackRoad Gemini API Wrapper"""
import os
from typing import Optional, List
import google.generativeai as genai

class GeminiWrapper:
    def __init__(self, api_key: Optional[str] = None):
        genai.configure(api_key=api_key or os.getenv("GOOGLE_API_KEY"))
        self.model = genai.GenerativeModel('gemini-pro')
        
    def generate(self, prompt: str, **kwargs) -> str:
        response = self.model.generate_content(prompt, **kwargs)
        return response.text
        
    def chat(self, messages: List[dict]) -> str:
        chat = self.model.start_chat(history=[])
        for msg in messages:
            if msg.get("role") == "user":
                response = chat.send_message(msg["content"])
        return response.text

def get_gemini() -> GeminiWrapper:
    return GeminiWrapper()
