"""Minimal Atlassian (JIRA) integration helpers."""

from __future__ import annotations

import base64
import os
from typing import Any, Dict

import requests


def _auth_header(email: str, token: str) -> str:
    creds = f"{email}:{token}".encode("utf-8")
    return base64.b64encode(creds).decode("utf-8")


def create_jira_issue(
    summary: str,
    description: str,
    project_key: str,
    *,
    issue_type: str = "Task",
    base_url: str | None = None,
    email: str | None = None,
    api_token: str | None = None,
) -> Dict[str, Any]:
    """Create an issue in Atlassian JIRA.

    Configuration values are taken from the environment when not
    explicitly provided:

    ``ATLASSIAN_BASE_URL`` – Base URL of the JIRA instance.
    ``ATLASSIAN_EMAIL`` – User email for authentication.
    ``ATLASSIAN_API_TOKEN`` – API token for the user.
    """

    base_url = base_url or os.getenv("ATLASSIAN_BASE_URL")
    email = email or os.getenv("ATLASSIAN_EMAIL")
    api_token = api_token or os.getenv("ATLASSIAN_API_TOKEN")
    if not base_url or not email or not api_token:
        raise RuntimeError("Atlassian credentials are not fully configured")

    url = f"{base_url.rstrip('/')}/rest/api/3/issue"
    headers = {
        "Authorization": f"Basic {_auth_header(email, api_token)}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    payload = {
        "fields": {
            "project": {"key": project_key},
            "summary": summary,
            "description": description,
            "issuetype": {"name": issue_type},
        }
    }
    resp = requests.post(url, headers=headers, json=payload, timeout=10)
    resp.raise_for_status()
    return resp.json()

