"""Webhook Trigger - HTTP webhook-based triggers.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import logging
import threading
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Any, Callable, Dict, List, Optional, Tuple
from urllib.parse import parse_qs, urlparse

from roadworkflow_core.triggers.base import (
    Trigger,
    TriggerConfig,
    TriggerEvent,
    TriggerType,
)

logger = logging.getLogger(__name__)


@dataclass
class WebhookRequest:
    """Incoming webhook request."""

    method: str
    path: str
    headers: Dict[str, str]
    query_params: Dict[str, List[str]]
    body: bytes
    client_ip: str
    timestamp: datetime = field(default_factory=datetime.utcnow)

    @property
    def json(self) -> Optional[Dict[str, Any]]:
        """Parse body as JSON."""
        try:
            return json.loads(self.body.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            return None

    @property
    def text(self) -> str:
        """Get body as text."""
        return self.body.decode("utf-8", errors="replace")


@dataclass
class WebhookResponse:
    """Webhook response."""

    status_code: int = 200
    body: str = ""
    headers: Dict[str, str] = field(default_factory=dict)


class WebhookHandler(BaseHTTPRequestHandler):
    """HTTP handler for webhooks."""

    def log_message(self, format: str, *args) -> None:
        """Suppress default logging."""
        pass

    def do_GET(self) -> None:
        """Handle GET request."""
        self._handle_request("GET")

    def do_POST(self) -> None:
        """Handle POST request."""
        self._handle_request("POST")

    def do_PUT(self) -> None:
        """Handle PUT request."""
        self._handle_request("PUT")

    def do_DELETE(self) -> None:
        """Handle DELETE request."""
        self._handle_request("DELETE")

    def _handle_request(self, method: str) -> None:
        """Process incoming request."""
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""

        parsed = urlparse(self.path)
        query_params = parse_qs(parsed.query)

        request = WebhookRequest(
            method=method,
            path=parsed.path,
            headers=dict(self.headers),
            query_params=query_params,
            body=body,
            client_ip=self.client_address[0],
        )

        response = self.server.webhook_server.handle_webhook(request)

        self.send_response(response.status_code)
        for key, value in response.headers.items():
            self.send_header(key, value)
        self.send_header("Content-Type", "application/json")
        self.end_headers()

        if response.body:
            self.wfile.write(response.body.encode("utf-8"))


class WebhookServer:
    """Webhook HTTP server.

    Manages multiple webhook endpoints and routes requests.

    Usage:
        server = WebhookServer(port=8080)
        server.register("/workflow/trigger", handler)
        server.start()
    """

    def __init__(
        self,
        host: str = "0.0.0.0",
        port: int = 8080,
        secret: Optional[str] = None,
    ):
        self.host = host
        self.port = port
        self.secret = secret
        self._handlers: Dict[str, Callable[[WebhookRequest], WebhookResponse]] = {}
        self._server: Optional[HTTPServer] = None
        self._thread: Optional[threading.Thread] = None
        self._running = False

    def register(
        self,
        path: str,
        handler: Callable[[WebhookRequest], WebhookResponse],
    ) -> None:
        """Register webhook handler.

        Args:
            path: URL path
            handler: Request handler function
        """
        self._handlers[path] = handler
        logger.info(f"Registered webhook handler: {path}")

    def unregister(self, path: str) -> None:
        """Unregister webhook handler."""
        if path in self._handlers:
            del self._handlers[path]

    def start(self) -> None:
        """Start webhook server."""
        if self._running:
            return

        self._server = HTTPServer((self.host, self.port), WebhookHandler)
        self._server.webhook_server = self

        self._thread = threading.Thread(
            target=self._server.serve_forever,
            daemon=True,
            name="WebhookServer",
        )
        self._thread.start()
        self._running = True
        logger.info(f"Webhook server started on {self.host}:{self.port}")

    def stop(self) -> None:
        """Stop webhook server."""
        if self._server:
            self._server.shutdown()
            self._server = None

        if self._thread:
            self._thread.join(timeout=5)
            self._thread = None

        self._running = False
        logger.info("Webhook server stopped")

    def handle_webhook(self, request: WebhookRequest) -> WebhookResponse:
        """Route and handle webhook request."""
        if self.secret and not self._verify_signature(request):
            return WebhookResponse(
                status_code=401,
                body=json.dumps({"error": "Invalid signature"}),
            )

        handler = self._handlers.get(request.path)

        if handler is None:
            for path, h in self._handlers.items():
                if request.path.startswith(path):
                    handler = h
                    break

        if handler is None:
            return WebhookResponse(
                status_code=404,
                body=json.dumps({"error": "Endpoint not found"}),
            )

        try:
            return handler(request)
        except Exception as e:
            logger.error(f"Webhook handler error: {e}")
            return WebhookResponse(
                status_code=500,
                body=json.dumps({"error": str(e)}),
            )

    def _verify_signature(self, request: WebhookRequest) -> bool:
        """Verify webhook signature."""
        signature = request.headers.get("X-Webhook-Signature") or \
                   request.headers.get("X-Hub-Signature-256")

        if not signature:
            return False

        if signature.startswith("sha256="):
            signature = signature[7:]

        expected = hmac.new(
            self.secret.encode(),
            request.body,
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(signature, expected)


class WebhookTrigger(Trigger):
    """Webhook-based trigger.

    Usage:
        trigger = WebhookTrigger(
            path="/api/trigger/my-workflow",
            methods=["POST"],
            secret="my-secret"
        )
        trigger.on_trigger(lambda e: run_workflow(e.payload))
        trigger.start()
    """

    _shared_server: Optional[WebhookServer] = None
    _server_lock = threading.Lock()
    _server_refcount = 0

    def __init__(
        self,
        path: str,
        methods: Optional[List[str]] = None,
        secret: Optional[str] = None,
        port: int = 8080,
        filter_fn: Optional[Callable[[WebhookRequest], bool]] = None,
        transform_fn: Optional[Callable[[WebhookRequest], Dict[str, Any]]] = None,
        **kwargs,
    ):
        config = TriggerConfig(trigger_type=TriggerType.WEBHOOK)
        super().__init__(config=config, **kwargs)

        self.path = path
        self.methods = methods or ["POST"]
        self.secret = secret
        self.port = port
        self.filter_fn = filter_fn
        self.transform_fn = transform_fn

    def start(self) -> None:
        """Start webhook trigger."""
        if self._running:
            return

        with WebhookTrigger._server_lock:
            if WebhookTrigger._shared_server is None:
                WebhookTrigger._shared_server = WebhookServer(
                    port=self.port,
                    secret=self.secret,
                )
                WebhookTrigger._shared_server.start()

            WebhookTrigger._server_refcount += 1

        WebhookTrigger._shared_server.register(self.path, self._handle_request)
        self._running = True
        logger.info(f"WebhookTrigger started: {self.path}")

    def stop(self) -> None:
        """Stop webhook trigger."""
        if not self._running:
            return

        if WebhookTrigger._shared_server:
            WebhookTrigger._shared_server.unregister(self.path)

        with WebhookTrigger._server_lock:
            WebhookTrigger._server_refcount -= 1

            if WebhookTrigger._server_refcount <= 0:
                if WebhookTrigger._shared_server:
                    WebhookTrigger._shared_server.stop()
                    WebhookTrigger._shared_server = None
                WebhookTrigger._server_refcount = 0

        self._running = False
        logger.info(f"WebhookTrigger stopped: {self.path}")

    def check(self) -> Optional[TriggerEvent]:
        """Webhooks are push-based, no polling needed."""
        return None

    def _handle_request(self, request: WebhookRequest) -> WebhookResponse:
        """Handle incoming webhook request."""
        if request.method not in self.methods:
            return WebhookResponse(
                status_code=405,
                body=json.dumps({"error": f"Method {request.method} not allowed"}),
            )

        if self.filter_fn and not self.filter_fn(request):
            return WebhookResponse(
                status_code=400,
                body=json.dumps({"error": "Request filtered"}),
            )

        if self.transform_fn:
            payload = self.transform_fn(request)
        else:
            payload = {
                "method": request.method,
                "path": request.path,
                "headers": request.headers,
                "body": request.json or request.text,
                "query_params": request.query_params,
                "client_ip": request.client_ip,
            }

        event = self._create_event(payload=payload, source="webhook")
        self._fire(event)

        return WebhookResponse(
            status_code=200,
            body=json.dumps({
                "status": "accepted",
                "event_id": event.event_id,
                "timestamp": event.timestamp.isoformat(),
            }),
        )


class GitHubWebhookTrigger(WebhookTrigger):
    """GitHub-specific webhook trigger."""

    def __init__(
        self,
        path: str,
        events: Optional[List[str]] = None,
        repos: Optional[List[str]] = None,
        branches: Optional[List[str]] = None,
        **kwargs,
    ):
        super().__init__(path=path, **kwargs)
        self.github_events = events or ["push"]
        self.repos = repos
        self.branches = branches

    def _handle_request(self, request: WebhookRequest) -> WebhookResponse:
        """Handle GitHub webhook."""
        event_type = request.headers.get("X-GitHub-Event")

        if event_type not in self.github_events:
            return WebhookResponse(
                status_code=200,
                body=json.dumps({"status": "ignored", "reason": "event type"}),
            )

        payload = request.json

        if self.repos and payload:
            repo = payload.get("repository", {}).get("full_name")
            if repo not in self.repos:
                return WebhookResponse(
                    status_code=200,
                    body=json.dumps({"status": "ignored", "reason": "repo filter"}),
                )

        if self.branches and payload and event_type == "push":
            ref = payload.get("ref", "")
            branch = ref.replace("refs/heads/", "")
            if branch not in self.branches:
                return WebhookResponse(
                    status_code=200,
                    body=json.dumps({"status": "ignored", "reason": "branch filter"}),
                )

        event = self._create_event(
            payload={
                "event_type": event_type,
                "delivery_id": request.headers.get("X-GitHub-Delivery"),
                "repository": payload.get("repository", {}).get("full_name") if payload else None,
                "sender": payload.get("sender", {}).get("login") if payload else None,
                "data": payload,
            },
            source="github",
        )
        self._fire(event)

        return WebhookResponse(
            status_code=200,
            body=json.dumps({"status": "accepted", "event_id": event.event_id}),
        )


__all__ = [
    "WebhookTrigger",
    "WebhookServer",
    "WebhookRequest",
    "WebhookResponse",
    "GitHubWebhookTrigger",
]
