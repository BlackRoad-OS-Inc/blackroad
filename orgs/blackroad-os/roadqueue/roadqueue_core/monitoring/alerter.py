"""RoadQueue Alerter - Alert Management.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional

logger = logging.getLogger(__name__)


class AlertLevel(Enum):
    """Alert severity levels."""

    INFO = auto()
    WARNING = auto()
    ERROR = auto()
    CRITICAL = auto()


@dataclass
class Alert:
    """An alert."""

    alert_id: str
    level: AlertLevel
    message: str
    source: str
    timestamp: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)
    acknowledged: bool = False
    acknowledged_at: Optional[datetime] = None
    acknowledged_by: Optional[str] = None


@dataclass
class AlertRule:
    """An alerting rule."""

    name: str
    condition: Callable[[Any], bool]
    level: AlertLevel
    message_template: str
    cooldown_seconds: int = 60


class Alerter:
    """Alert management system."""

    def __init__(self, max_alerts: int = 1000):
        self.max_alerts = max_alerts
        self._alerts: List[Alert] = []
        self._rules: List[AlertRule] = []
        self._handlers: List[Callable[[Alert], None]] = []
        self._last_fired: Dict[str, datetime] = {}

    def add_rule(self, rule: AlertRule) -> None:
        """Add an alerting rule."""
        self._rules.append(rule)

    def add_handler(self, handler: Callable[[Alert], None]) -> None:
        """Add an alert handler."""
        self._handlers.append(handler)

    def fire(self, alert: Alert) -> None:
        """Fire an alert."""
        self._alerts.append(alert)

        # Trim old alerts
        if len(self._alerts) > self.max_alerts:
            self._alerts = self._alerts[-self.max_alerts:]

        # Notify handlers
        for handler in self._handlers:
            try:
                handler(alert)
            except Exception as e:
                logger.error(f"Alert handler error: {e}")

        logger.log(
            logging.ERROR if alert.level == AlertLevel.CRITICAL else logging.WARNING,
            f"Alert [{alert.level.name}]: {alert.message}",
        )

    def check_rules(self, context: Any, source: str) -> List[Alert]:
        """Check all rules against context."""
        now = datetime.now()
        alerts = []

        for rule in self._rules:
            # Check cooldown
            last_fired = self._last_fired.get(rule.name)
            if last_fired:
                elapsed = (now - last_fired).total_seconds()
                if elapsed < rule.cooldown_seconds:
                    continue

            try:
                if rule.condition(context):
                    alert = Alert(
                        alert_id=f"{rule.name}-{now.timestamp()}",
                        level=rule.level,
                        message=rule.message_template,
                        source=source,
                    )
                    self.fire(alert)
                    alerts.append(alert)
                    self._last_fired[rule.name] = now
            except Exception as e:
                logger.error(f"Alert rule {rule.name} error: {e}")

        return alerts

    def acknowledge(self, alert_id: str, by: str) -> bool:
        """Acknowledge an alert."""
        for alert in self._alerts:
            if alert.alert_id == alert_id:
                alert.acknowledged = True
                alert.acknowledged_at = datetime.now()
                alert.acknowledged_by = by
                return True
        return False

    def get_active_alerts(self, level: Optional[AlertLevel] = None) -> List[Alert]:
        """Get active (unacknowledged) alerts."""
        alerts = [a for a in self._alerts if not a.acknowledged]
        if level:
            alerts = [a for a in alerts if a.level == level]
        return alerts

    def get_all_alerts(self, limit: int = 100) -> List[Alert]:
        """Get all alerts."""
        return self._alerts[-limit:]


__all__ = ["Alerter", "Alert", "AlertLevel", "AlertRule"]
