"""Offline friendly web search adapter."""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

_DEFAULT_INDEX = Path("fixtures/web_search/index.json")


@dataclass(slots=True)
class SearchResult:
    title: str
    url: str
    snippet: str


class SearchIndex:
    """Small text index backed by a JSON file."""

    def __init__(self, entries: Iterable[dict[str, str]]):
        self._entries = [
            SearchResult(entry.get("title", ""), entry.get("url", ""), entry.get("snippet", ""))
            for entry in entries
        ]

    @classmethod
    def load(cls, path: Path) -> "SearchIndex":
        if not path.exists():
            return cls([])
        with path.open(encoding="utf-8") as file:
            data = json.load(file)
        if not isinstance(data, list):
            raise ValueError("Search index must be a list of objects")
        return cls([entry for entry in data if isinstance(entry, dict)])

    def search(self, query: str, *, limit: int = 5) -> list[SearchResult]:
        pattern = re.compile(re.escape(query), re.IGNORECASE)
        matches = [result for result in self._entries if pattern.search(result.snippet or result.title)]
        return matches[:limit]


def _load_index() -> SearchIndex:
    configured = os.getenv("PRISM_WEB_SEARCH_INDEX", "")
    path = Path(configured) if configured else _DEFAULT_INDEX
    return SearchIndex.load(path.expanduser().resolve())


def search(query: str, *, limit: int = 5) -> list[SearchResult]:
    """Return search results from the local index or a helpful fallback."""

    if not query.strip():
        raise ValueError("Query must not be empty")

    index = _load_index()
    results = index.search(query, limit=limit)
    if results:
        return results

    return [
        SearchResult(
            title="Web search unavailable",
            url="https://example.com/prism-offline-search",
            snippet=(
                "No indexed results were found for the query. Configure a search index via "
                "PRISM_WEB_SEARCH_INDEX to surface domain-specific answers."
            ),
        )
    ]


__all__ = ["search", "SearchResult"]
"""Stub web search adapter.

No network calls are permitted; this module is a placeholder.
"""


def search(query: str) -> list[str]:
    """Return results for *query*.

    Raises
    ------
    NotImplementedError
        Always, because network access is disabled.
    """

    raise NotImplementedError("Network access disabled by guardrails")
