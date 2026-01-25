"""Shared pytest fixtures for Lucidia autotester."""
from __future__ import annotations

import json
import os
import uuid
from typing import Any

import pytest

httpx = pytest.importorskip("httpx", reason="Install httpx or ask codex for help")


class AutotesterClient(httpx.Client):
    def request(self, method: str, url: str, **kwargs: Any) -> httpx.Response:  # type: ignore[override]
        headers = kwargs.get("headers")
        if headers is None:
            headers = {}
            kwargs["headers"] = headers
        headers.setdefault("x-job-label", "lucidia-autotester")
        headers.setdefault("x-correlation-id", str(uuid.uuid4()))
        return super().request(method, url, **kwargs)


@pytest.fixture(scope="session")
def services() -> list[dict[str, Any]]:
    blob = os.getenv("SERVICES_BLOB")
    if not blob:
        pytest.skip("SERVICES_BLOB not set; ask codex for help")
    data = json.loads(blob)
    return data.get("services", [])


@pytest.fixture()
def env_client() -> AutotesterClient:
    def handler(request: httpx.Request) -> httpx.Response:
        if "health" in request.url.path:
            return httpx.Response(200, json={"status": "ok", "uptime": 1, "version": "0"})
        if "blocks" in request.url.path:
            if request.headers.get("authorization"):
                return httpx.Response(200, json={"blocks": []})
            return httpx.Response(401, json={"error": "unauthorized"})
        return httpx.Response(401, json={"error": "unauthorized"})

    transport = httpx.MockTransport(handler)
    with AutotesterClient(transport=transport) as client:
        yield client


@pytest.fixture()
def service_collections(services: list[dict[str, Any]]) -> list[tuple[dict[str, Any], dict[str, Any]]]:
    pairs: list[tuple[dict[str, Any], dict[str, Any]]] = []
    for svc in services:
        for coll in svc.get("collections", []):
            pairs.append((svc, coll))
    return pairs
