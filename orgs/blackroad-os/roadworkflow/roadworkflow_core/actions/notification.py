"""Notification Action - Workflow notifications.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import json
import logging
import smtplib
import urllib.request
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class NotificationConfig:
    """Notification configuration."""

    enabled: bool = True
    on_success: bool = False
    on_failure: bool = True
    on_retry: bool = False
    on_start: bool = False
    on_complete: bool = True


class NotificationAction(ABC):
    """Abstract notification action."""

    def __init__(self, config: Optional[NotificationConfig] = None):
        self.config = config or NotificationConfig()

    @abstractmethod
    def send(
        self,
        subject: str,
        message: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Send notification.

        Args:
            subject: Notification subject
            message: Notification message
            context: Additional context

        Returns:
            True if sent successfully
        """
        pass

    def on_workflow_start(
        self,
        workflow_id: str,
        run_id: str,
        params: Optional[Dict[str, Any]] = None,
    ) -> None:
        """Handle workflow start."""
        if not self.config.on_start:
            return

        self.send(
            subject=f"Workflow Started: {workflow_id}",
            message=f"Run {run_id} has started.",
            context={"workflow_id": workflow_id, "run_id": run_id, "params": params},
        )

    def on_workflow_success(
        self,
        workflow_id: str,
        run_id: str,
        duration: float,
    ) -> None:
        """Handle workflow success."""
        if not self.config.on_success:
            return

        self.send(
            subject=f"Workflow Completed: {workflow_id}",
            message=f"Run {run_id} completed successfully in {duration:.2f}s.",
            context={"workflow_id": workflow_id, "run_id": run_id, "duration": duration},
        )

    def on_workflow_failure(
        self,
        workflow_id: str,
        run_id: str,
        error: str,
    ) -> None:
        """Handle workflow failure."""
        if not self.config.on_failure:
            return

        self.send(
            subject=f"Workflow Failed: {workflow_id}",
            message=f"Run {run_id} failed: {error}",
            context={"workflow_id": workflow_id, "run_id": run_id, "error": error},
        )

    def on_task_retry(
        self,
        workflow_id: str,
        task_id: str,
        attempt: int,
        error: str,
    ) -> None:
        """Handle task retry."""
        if not self.config.on_retry:
            return

        self.send(
            subject=f"Task Retry: {task_id}",
            message=f"Task {task_id} failed (attempt {attempt}): {error}",
            context={"workflow_id": workflow_id, "task_id": task_id, "attempt": attempt},
        )


class EmailNotification(NotificationAction):
    """Email notification."""

    def __init__(
        self,
        smtp_host: str,
        smtp_port: int = 587,
        username: Optional[str] = None,
        password: Optional[str] = None,
        from_addr: str = "",
        to_addrs: Optional[List[str]] = None,
        use_tls: bool = True,
        config: Optional[NotificationConfig] = None,
    ):
        super().__init__(config)
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port
        self.username = username
        self.password = password
        self.from_addr = from_addr
        self.to_addrs = to_addrs or []
        self.use_tls = use_tls

    def send(
        self,
        subject: str,
        message: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Send email notification."""
        if not self.config.enabled or not self.to_addrs:
            return False

        try:
            msg = MIMEMultipart()
            msg["From"] = self.from_addr
            msg["To"] = ", ".join(self.to_addrs)
            msg["Subject"] = subject

            body = message
            if context:
                body += f"\n\nContext:\n{json.dumps(context, indent=2, default=str)}"

            msg.attach(MIMEText(body, "plain"))

            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                if self.use_tls:
                    server.starttls()
                if self.username and self.password:
                    server.login(self.username, self.password)
                server.send_message(msg)

            logger.info(f"Email sent: {subject}")
            return True

        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False


class SlackNotification(NotificationAction):
    """Slack notification."""

    def __init__(
        self,
        webhook_url: str,
        channel: Optional[str] = None,
        username: str = "RoadWorkflow",
        icon_emoji: str = ":robot_face:",
        config: Optional[NotificationConfig] = None,
    ):
        super().__init__(config)
        self.webhook_url = webhook_url
        self.channel = channel
        self.username = username
        self.icon_emoji = icon_emoji

    def send(
        self,
        subject: str,
        message: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Send Slack notification."""
        if not self.config.enabled:
            return False

        try:
            payload = {
                "username": self.username,
                "icon_emoji": self.icon_emoji,
                "attachments": [
                    {
                        "title": subject,
                        "text": message,
                        "color": self._get_color(context),
                        "fields": self._format_context(context) if context else [],
                        "footer": "RoadWorkflow",
                        "ts": datetime.utcnow().timestamp(),
                    }
                ],
            }

            if self.channel:
                payload["channel"] = self.channel

            data = json.dumps(payload).encode("utf-8")

            request = urllib.request.Request(
                self.webhook_url,
                data=data,
                headers={"Content-Type": "application/json"},
            )

            with urllib.request.urlopen(request) as response:
                if response.status == 200:
                    logger.info(f"Slack message sent: {subject}")
                    return True

            return False

        except Exception as e:
            logger.error(f"Failed to send Slack message: {e}")
            return False

    def _get_color(self, context: Optional[Dict[str, Any]]) -> str:
        """Get attachment color based on context."""
        if not context:
            return "#2196F3"

        if "error" in context:
            return "#F44336"
        if context.get("status") == "success":
            return "#4CAF50"

        return "#2196F3"

    def _format_context(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Format context as Slack fields."""
        fields = []

        for key, value in context.items():
            if key in ("error", "traceback"):
                continue
            fields.append({
                "title": key.replace("_", " ").title(),
                "value": str(value)[:50],
                "short": True,
            })

        return fields[:8]


class WebhookNotification(NotificationAction):
    """Webhook notification."""

    def __init__(
        self,
        url: str,
        method: str = "POST",
        headers: Optional[Dict[str, str]] = None,
        config: Optional[NotificationConfig] = None,
    ):
        super().__init__(config)
        self.url = url
        self.method = method
        self.headers = headers or {}

    def send(
        self,
        subject: str,
        message: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Send webhook notification."""
        if not self.config.enabled:
            return False

        try:
            payload = {
                "subject": subject,
                "message": message,
                "timestamp": datetime.utcnow().isoformat(),
                **(context or {}),
            }

            data = json.dumps(payload).encode("utf-8")
            headers = {"Content-Type": "application/json", **self.headers}

            request = urllib.request.Request(
                self.url,
                data=data,
                headers=headers,
                method=self.method,
            )

            with urllib.request.urlopen(request) as response:
                if 200 <= response.status < 300:
                    logger.info(f"Webhook sent: {subject}")
                    return True

            return False

        except Exception as e:
            logger.error(f"Failed to send webhook: {e}")
            return False


class CompositeNotification(NotificationAction):
    """Send to multiple notification channels."""

    def __init__(
        self,
        notifications: List[NotificationAction],
        config: Optional[NotificationConfig] = None,
    ):
        super().__init__(config)
        self.notifications = notifications

    def send(
        self,
        subject: str,
        message: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Send to all channels."""
        success = True

        for notification in self.notifications:
            if not notification.send(subject, message, context):
                success = False

        return success


__all__ = [
    "NotificationAction",
    "NotificationConfig",
    "EmailNotification",
    "SlackNotification",
    "WebhookNotification",
    "CompositeNotification",
]
