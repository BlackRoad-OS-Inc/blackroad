"""BlackRoad Mistral API Wrapper"""
import os
from typing import Optional, List
from mistralai.client import MistralClient

class MistralWrapper:
    def __init__(self, api_key: Optional[str] = None):
        self.client = MistralClient(api_key=api_key or os.getenv("MISTRAL_API_KEY"))
        self.default_model = "mistral-medium"
        
    def generate(self, prompt: str, model: Optional[str] = None) -> str:
        response = self.client.chat(
            model=model or self.default_model,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content
        
    def chat(self, messages: List[dict], model: Optional[str] = None) -> str:
        response = self.client.chat(
            model=model or self.default_model,
            messages=messages
        )
        return response.choices[0].message.content

def get_mistral() -> MistralWrapper:
    return MistralWrapper()
