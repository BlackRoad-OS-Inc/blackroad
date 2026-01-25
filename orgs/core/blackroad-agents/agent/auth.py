"""Simple token authentication middleware for HTTP and WebSocket traffic."""
from __future__ import annotations

from typing import Callable, Dict
from urllib.parse import parse_qs

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp, Receive, Scope, Send

from agent.config import auth_token


def _normalize_headers(raw_headers) -> Dict[str, str]:
    headers: Dict[str, str] = {}
    for key, value in raw_headers or []:
        headers[key.decode("latin-1").lower()] = value.decode("latin-1")
    return headers


def _token_matches(candidate: str) -> bool:
    token = auth_token()
    if not token:
        return True
    return candidate == token


class TokenAuthMiddleware(BaseHTTPMiddleware):
    """Middleware enforcing a shared bearer token for HTTP and WebSocket traffic."""

    def __init__(self, app: ASGIApp) -> None:
        super().__init__(app)

    async def dispatch(self, request: Request, call_next: Callable):
        token = auth_token()
        if not token:
            return await call_next(request)

        auth_header = request.headers.get("authorization", "")
        qs_token = request.query_params.get("token", "")
        candidate = ""
        if auth_header.lower().startswith("bearer "):
            candidate = auth_header.split(None, 1)[1].strip()
        elif qs_token:
            candidate = qs_token

        if not _token_matches(candidate):
            return JSONResponse({"error": "unauthorized"}, status_code=401)
        return await call_next(request)

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] == "websocket":
            token = auth_token()
            if not token:
                await self.app(scope, receive, send)
                return

            headers = _normalize_headers(scope.get("headers"))
            auth_header = headers.get("authorization", "")
            query = parse_qs(scope.get("query_string", b"").decode("latin-1"))
            candidate = ""
            if auth_header.lower().startswith("bearer "):
                candidate = auth_header.split(None, 1)[1].strip()
            elif "token" in query and query["token"]:
                candidate = query["token"][0]

            if not _token_matches(candidate):
                await send({"type": "websocket.close", "code": 4401})
                return

            await self.app(scope, receive, send)
            return

        await super().__call__(scope, receive, send)
