"""
RoadHTTP - HTTP Client for BlackRoad
Async HTTP client with retry, caching, and middleware.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Union
import asyncio
import base64
import json
import socket
import ssl
import urllib.parse
import logging

logger = logging.getLogger(__name__)


class HTTPMethod(str, Enum):
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    DELETE = "DELETE"
    PATCH = "PATCH"
    HEAD = "HEAD"
    OPTIONS = "OPTIONS"


@dataclass
class HTTPRequest:
    method: HTTPMethod
    url: str
    headers: Dict[str, str] = field(default_factory=dict)
    body: bytes = b""
    params: Dict[str, str] = field(default_factory=dict)
    timeout: float = 30.0


@dataclass
class HTTPResponse:
    status: int
    headers: Dict[str, str]
    body: bytes
    url: str
    elapsed: float = 0.0

    @property
    def ok(self) -> bool:
        return 200 <= self.status < 300

    @property
    def text(self) -> str:
        return self.body.decode("utf-8", errors="replace")

    def json(self) -> Any:
        return json.loads(self.body)


class HTTPError(Exception):
    def __init__(self, message: str, response: HTTPResponse = None):
        self.response = response
        super().__init__(message)


class HTTPClient:
    def __init__(self, base_url: str = "", headers: Dict[str, str] = None, timeout: float = 30.0):
        self.base_url = base_url.rstrip("/")
        self.default_headers = {"User-Agent": "RoadHTTP/1.0", **(headers or {})}
        self.timeout = timeout
        self._middleware: List[Callable] = []

    def use(self, middleware: Callable) -> "HTTPClient":
        self._middleware.append(middleware)
        return self

    def _build_url(self, path: str, params: Dict[str, str] = None) -> str:
        url = f"{self.base_url}/{path.lstrip('/')}" if self.base_url else path
        if params:
            query = urllib.parse.urlencode(params)
            url = f"{url}?{query}"
        return url

    def _parse_url(self, url: str) -> tuple:
        parsed = urllib.parse.urlparse(url)
        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        path = parsed.path or "/"
        if parsed.query:
            path = f"{path}?{parsed.query}"
        return parsed.scheme, parsed.hostname, port, path

    async def _send(self, request: HTTPRequest) -> HTTPResponse:
        start = datetime.now()
        scheme, host, port, path = self._parse_url(request.url)
        
        headers = {**self.default_headers, **request.headers}
        if request.body and "Content-Length" not in headers:
            headers["Content-Length"] = str(len(request.body))
        if "Host" not in headers:
            headers["Host"] = host

        header_lines = [f"{request.method.value} {path} HTTP/1.1"]
        header_lines.extend(f"{k}: {v}" for k, v in headers.items())
        raw_request = "\r\n".join(header_lines) + "\r\n\r\n"

        reader, writer = await asyncio.wait_for(
            asyncio.open_connection(host, port, ssl=scheme == "https"),
            timeout=request.timeout
        )

        try:
            writer.write(raw_request.encode() + request.body)
            await writer.drain()

            response_line = await reader.readline()
            _, status_str, _ = response_line.decode().split(" ", 2)
            status = int(status_str)

            resp_headers = {}
            while True:
                line = await reader.readline()
                if line == b"\r\n":
                    break
                key, value = line.decode().strip().split(": ", 1)
                resp_headers[key.lower()] = value

            content_length = int(resp_headers.get("content-length", 0))
            body = await reader.read(content_length) if content_length else b""

            elapsed = (datetime.now() - start).total_seconds()
            return HTTPResponse(status=status, headers=resp_headers, body=body, url=request.url, elapsed=elapsed)
        finally:
            writer.close()
            await writer.wait_closed()

    async def request(self, method: HTTPMethod, path: str, **kwargs) -> HTTPResponse:
        url = self._build_url(path, kwargs.pop("params", None))
        body = b""
        if "json" in kwargs:
            body = json.dumps(kwargs.pop("json")).encode()
            kwargs.setdefault("headers", {})["Content-Type"] = "application/json"
        elif "data" in kwargs:
            body = kwargs.pop("data")
            if isinstance(body, str):
                body = body.encode()

        request = HTTPRequest(
            method=method,
            url=url,
            headers=kwargs.get("headers", {}),
            body=body,
            timeout=kwargs.get("timeout", self.timeout)
        )

        for mw in self._middleware:
            request = await mw(request) if asyncio.iscoroutinefunction(mw) else mw(request)

        return await self._send(request)

    async def get(self, path: str, **kwargs) -> HTTPResponse:
        return await self.request(HTTPMethod.GET, path, **kwargs)

    async def post(self, path: str, **kwargs) -> HTTPResponse:
        return await self.request(HTTPMethod.POST, path, **kwargs)

    async def put(self, path: str, **kwargs) -> HTTPResponse:
        return await self.request(HTTPMethod.PUT, path, **kwargs)

    async def delete(self, path: str, **kwargs) -> HTTPResponse:
        return await self.request(HTTPMethod.DELETE, path, **kwargs)

    async def patch(self, path: str, **kwargs) -> HTTPResponse:
        return await self.request(HTTPMethod.PATCH, path, **kwargs)


class RetryMiddleware:
    def __init__(self, max_retries: int = 3, backoff: float = 1.0):
        self.max_retries = max_retries
        self.backoff = backoff

    def __call__(self, request: HTTPRequest) -> HTTPRequest:
        request.retries = self.max_retries
        request.backoff = self.backoff
        return request


class AuthMiddleware:
    def __init__(self, token: str = None, username: str = None, password: str = None):
        self.token = token
        self.username = username
        self.password = password

    def __call__(self, request: HTTPRequest) -> HTTPRequest:
        if self.token:
            request.headers["Authorization"] = f"Bearer {self.token}"
        elif self.username and self.password:
            creds = base64.b64encode(f"{self.username}:{self.password}".encode()).decode()
            request.headers["Authorization"] = f"Basic {creds}"
        return request


def create_client(base_url: str = "", **kwargs) -> HTTPClient:
    return HTTPClient(base_url, **kwargs)


async def get(url: str, **kwargs) -> HTTPResponse:
    return await HTTPClient().get(url, **kwargs)


async def post(url: str, **kwargs) -> HTTPResponse:
    return await HTTPClient().post(url, **kwargs)


def example_usage():
    async def main():
        client = create_client("https://httpbin.org")
        client.use(AuthMiddleware(token="secret"))
        
        resp = await client.get("/get", params={"foo": "bar"})
        print(f"Status: {resp.status}")
        print(f"Body: {resp.text[:200]}")

    asyncio.run(main())

