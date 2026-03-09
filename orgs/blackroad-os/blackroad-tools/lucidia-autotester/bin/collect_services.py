#!/usr/bin/env python3
"""Collect service definitions for the autotester."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

import httpx


REGISTRY_ENV = "LUCIDIA_SERVICE_GRAPH"
BASE_DIR = Path(__file__).resolve().parent


def from_service_graph(url: str) -> dict:
    """Fetch service registry from internal Service Graph."""
    with httpx.Client(timeout=10) as client:
        resp = client.get(url)
        resp.raise_for_status()
        return resp.json()


def from_json(env: str) -> dict:
    mapping = BASE_DIR / f"service_mapping.{env}.json"
    if not mapping.exists():
        raise FileNotFoundError(mapping)
    return json.loads(mapping.read_text())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env", default="staging")
    args = parser.parse_args()

    registry_url = os.getenv(REGISTRY_ENV)
    if registry_url:
        data = from_service_graph(registry_url)
    else:
        data = from_json(args.env)

    print(json.dumps(data))


if __name__ == "__main__":
    main()
