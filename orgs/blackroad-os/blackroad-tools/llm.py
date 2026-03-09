import json
import os
import urllib.parse

import requests


def _openai_chat(prompt: str, system: str = "", model: str | None = None) -> str:
    base = os.getenv("OPENAI_BASE", "https://api.openai.com/v1")
    parsed = urllib.parse.urlparse(base)
    if parsed.scheme != "https":
        raise ValueError("OPENAI_BASE must use https")
    if parsed.hostname != "api.openai.com":
        raise ValueError("OPENAI_BASE host not allowed")

    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        raise RuntimeError("OPENAI_API_KEY is not set")

    model = model or os.getenv("MODEL", "gpt-4.1")
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    payload = {"model": model, "messages": []}
    if system:
        payload["messages"].append({"role": "system", "content": system})
    payload["messages"].append({"role": "user", "content": prompt})

    r = requests.post(
        f"{base}/chat/completions", headers=headers, data=json.dumps(payload), timeout=120
    )
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]


def _ollama(prompt: str, system: str = "", model: str | None = None) -> str:
    model = model or os.getenv("MODEL", "llama3.1")
    payload = {"model": model, "prompt": (system + "\n\n" + prompt).strip(), "stream": False}
    r = requests.post("http://localhost:11434/api/generate", json=payload, timeout=120)
    r.raise_for_status()
    data = r.json()
    # Ollama returns text in 'response'
    return data.get("response", "")


def chat(prompt: str, system: str = "") -> str:
    backend = os.getenv("AI_BACKEND", "openai").lower()
    if backend == "ollama":
        return _ollama(prompt, system)
    return _openai_chat(prompt, system)
