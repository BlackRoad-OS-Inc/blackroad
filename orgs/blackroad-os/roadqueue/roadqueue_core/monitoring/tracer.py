"""RoadQueue Tracer - Distributed Tracing.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class Span:
    """A trace span."""

    span_id: str
    trace_id: str
    parent_id: Optional[str]
    operation: str
    service: str
    start_time: float
    end_time: Optional[float] = None
    status: str = "OK"
    tags: Dict[str, str] = field(default_factory=dict)
    logs: List[Dict[str, Any]] = field(default_factory=list)

    @property
    def duration_ms(self) -> float:
        """Get span duration in milliseconds."""
        if self.end_time:
            return (self.end_time - self.start_time) * 1000
        return 0.0

    def finish(self, status: str = "OK") -> None:
        """Finish the span."""
        self.end_time = time.time()
        self.status = status

    def set_tag(self, key: str, value: str) -> None:
        """Set a tag."""
        self.tags[key] = value

    def log(self, event: str, **kwargs) -> None:
        """Add a log entry."""
        self.logs.append({
            "timestamp": time.time(),
            "event": event,
            **kwargs,
        })


class Tracer:
    """Distributed tracing service."""

    def __init__(self, service_name: str = "roadqueue"):
        self.service_name = service_name
        self._traces: Dict[str, List[Span]] = {}
        self._active_spans: Dict[str, Span] = {}

    def start_span(
        self,
        operation: str,
        trace_id: Optional[str] = None,
        parent_id: Optional[str] = None,
        tags: Optional[Dict[str, str]] = None,
    ) -> Span:
        """Start a new span."""
        span = Span(
            span_id=uuid.uuid4().hex[:16],
            trace_id=trace_id or uuid.uuid4().hex[:32],
            parent_id=parent_id,
            operation=operation,
            service=self.service_name,
            start_time=time.time(),
            tags=tags or {},
        )

        self._active_spans[span.span_id] = span

        if span.trace_id not in self._traces:
            self._traces[span.trace_id] = []
        self._traces[span.trace_id].append(span)

        return span

    def finish_span(self, span: Span, status: str = "OK") -> None:
        """Finish a span."""
        span.finish(status)
        self._active_spans.pop(span.span_id, None)

    def get_trace(self, trace_id: str) -> List[Span]:
        """Get all spans for a trace."""
        return self._traces.get(trace_id, [])

    def get_active_spans(self) -> List[Span]:
        """Get all active spans."""
        return list(self._active_spans.values())

    def inject_context(self, span: Span) -> Dict[str, str]:
        """Get context for propagation."""
        return {
            "trace_id": span.trace_id,
            "span_id": span.span_id,
            "parent_id": span.parent_id or "",
        }

    def extract_context(self, headers: Dict[str, str]) -> Dict[str, Optional[str]]:
        """Extract context from headers."""
        return {
            "trace_id": headers.get("trace_id"),
            "parent_id": headers.get("span_id"),
        }


__all__ = ["Tracer", "Span"]
