"""
RoadNotify - Notification System for BlackRoad
Send notifications via email, SMS, push, and webhooks.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import asyncio
import json
import logging
import threading
import uuid

logger = logging.getLogger(__name__)


class NotificationChannel(str, Enum):
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    WEBHOOK = "webhook"
    SLACK = "slack"
    DISCORD = "discord"


class NotificationPriority(str, Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"


class NotificationStatus(str, Enum):
    PENDING = "pending"
    SENDING = "sending"
    SENT = "sent"
    FAILED = "failed"
    DELIVERED = "delivered"


@dataclass
class NotificationRecipient:
    id: str
    channels: Dict[NotificationChannel, str] = field(default_factory=dict)
    preferences: Dict[str, Any] = field(default_factory=dict)


@dataclass
class NotificationTemplate:
    id: str
    name: str
    channel: NotificationChannel
    subject: str = ""
    body: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)

    def render(self, context: Dict[str, Any]) -> tuple:
        subject = self.subject
        body = self.body
        for key, value in context.items():
            subject = subject.replace(f"{{{{{key}}}}}", str(value))
            body = body.replace(f"{{{{{key}}}}}", str(value))
        return subject, body


@dataclass
class Notification:
    id: str
    channel: NotificationChannel
    recipient: str
    subject: str
    body: str
    priority: NotificationPriority = NotificationPriority.NORMAL
    status: NotificationStatus = NotificationStatus.PENDING
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    sent_at: Optional[datetime] = None
    error: Optional[str] = None


class NotificationProvider:
    async def send(self, notification: Notification) -> bool:
        raise NotImplementedError


class EmailProvider(NotificationProvider):
    def __init__(self, smtp_host: str = "", smtp_port: int = 587, username: str = "", password: str = ""):
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port
        self.username = username
        self.password = password

    async def send(self, notification: Notification) -> bool:
        logger.info(f"Sending email to {notification.recipient}: {notification.subject}")
        await asyncio.sleep(0.1)  # Simulate network delay
        return True


class SMSProvider(NotificationProvider):
    def __init__(self, api_key: str = "", from_number: str = ""):
        self.api_key = api_key
        self.from_number = from_number

    async def send(self, notification: Notification) -> bool:
        logger.info(f"Sending SMS to {notification.recipient}: {notification.body[:50]}...")
        await asyncio.sleep(0.1)
        return True


class PushProvider(NotificationProvider):
    def __init__(self, api_key: str = ""):
        self.api_key = api_key

    async def send(self, notification: Notification) -> bool:
        logger.info(f"Sending push to {notification.recipient}: {notification.subject}")
        await asyncio.sleep(0.1)
        return True


class WebhookProvider(NotificationProvider):
    def __init__(self, default_url: str = ""):
        self.default_url = default_url

    async def send(self, notification: Notification) -> bool:
        url = notification.metadata.get("url", self.default_url)
        logger.info(f"Sending webhook to {url}")
        await asyncio.sleep(0.1)
        return True


class SlackProvider(NotificationProvider):
    def __init__(self, webhook_url: str = ""):
        self.webhook_url = webhook_url

    async def send(self, notification: Notification) -> bool:
        logger.info(f"Sending Slack message: {notification.body[:50]}...")
        await asyncio.sleep(0.1)
        return True


class NotificationQueue:
    def __init__(self, max_size: int = 10000):
        self.max_size = max_size
        self.queue: List[Notification] = []
        self._lock = threading.Lock()

    def enqueue(self, notification: Notification) -> None:
        with self._lock:
            if len(self.queue) >= self.max_size:
                self.queue.pop(0)
            self.queue.append(notification)

    def dequeue(self) -> Optional[Notification]:
        with self._lock:
            for i, n in enumerate(self.queue):
                if n.status == NotificationStatus.PENDING:
                    n.status = NotificationStatus.SENDING
                    return n
            return None

    def update(self, notification: Notification) -> None:
        with self._lock:
            for i, n in enumerate(self.queue):
                if n.id == notification.id:
                    self.queue[i] = notification
                    return

    def get_pending(self) -> List[Notification]:
        return [n for n in self.queue if n.status == NotificationStatus.PENDING]


class NotificationManager:
    def __init__(self):
        self.providers: Dict[NotificationChannel, NotificationProvider] = {}
        self.templates: Dict[str, NotificationTemplate] = {}
        self.recipients: Dict[str, NotificationRecipient] = {}
        self.queue = NotificationQueue()
        self.hooks: Dict[str, List[Callable]] = {"before_send": [], "after_send": [], "on_error": []}
        self._running = False

    def register_provider(self, channel: NotificationChannel, provider: NotificationProvider) -> None:
        self.providers[channel] = provider

    def register_template(self, template: NotificationTemplate) -> None:
        self.templates[template.id] = template

    def register_recipient(self, recipient: NotificationRecipient) -> None:
        self.recipients[recipient.id] = recipient

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self.hooks:
            self.hooks[event].append(handler)

    def _run_hooks(self, event: str, notification: Notification) -> None:
        for handler in self.hooks.get(event, []):
            try:
                handler(notification)
            except Exception as e:
                logger.error(f"Hook error: {e}")

    async def send(self, channel: NotificationChannel, recipient: str, subject: str, body: str, priority: NotificationPriority = NotificationPriority.NORMAL, **metadata) -> Notification:
        notification = Notification(
            id=str(uuid.uuid4())[:12],
            channel=channel,
            recipient=recipient,
            subject=subject,
            body=body,
            priority=priority,
            metadata=metadata
        )
        
        self._run_hooks("before_send", notification)
        
        provider = self.providers.get(channel)
        if not provider:
            notification.status = NotificationStatus.FAILED
            notification.error = f"No provider for channel: {channel}"
            self._run_hooks("on_error", notification)
            return notification
        
        try:
            success = await provider.send(notification)
            if success:
                notification.status = NotificationStatus.SENT
                notification.sent_at = datetime.now()
            else:
                notification.status = NotificationStatus.FAILED
        except Exception as e:
            notification.status = NotificationStatus.FAILED
            notification.error = str(e)
            self._run_hooks("on_error", notification)
        
        self._run_hooks("after_send", notification)
        return notification

    async def send_template(self, template_id: str, recipient_id: str, context: Dict[str, Any] = None, priority: NotificationPriority = NotificationPriority.NORMAL) -> Optional[Notification]:
        template = self.templates.get(template_id)
        recipient = self.recipients.get(recipient_id)
        
        if not template or not recipient:
            return None
        
        address = recipient.channels.get(template.channel)
        if not address:
            return None
        
        subject, body = template.render(context or {})
        return await self.send(template.channel, address, subject, body, priority)

    async def broadcast(self, channel: NotificationChannel, subject: str, body: str, filter_fn: Callable[[NotificationRecipient], bool] = None) -> List[Notification]:
        results = []
        for recipient in self.recipients.values():
            if filter_fn and not filter_fn(recipient):
                continue
            address = recipient.channels.get(channel)
            if address:
                result = await self.send(channel, address, subject, body)
                results.append(result)
        return results

    def queue_notification(self, channel: NotificationChannel, recipient: str, subject: str, body: str, **kwargs) -> str:
        notification = Notification(
            id=str(uuid.uuid4())[:12],
            channel=channel,
            recipient=recipient,
            subject=subject,
            body=body,
            **kwargs
        )
        self.queue.enqueue(notification)
        return notification.id

    async def process_queue(self, batch_size: int = 10) -> int:
        processed = 0
        for _ in range(batch_size):
            notification = self.queue.dequeue()
            if not notification:
                break
            
            provider = self.providers.get(notification.channel)
            if provider:
                try:
                    success = await provider.send(notification)
                    notification.status = NotificationStatus.SENT if success else NotificationStatus.FAILED
                except Exception as e:
                    notification.status = NotificationStatus.FAILED
                    notification.error = str(e)
            
            self.queue.update(notification)
            processed += 1
        
        return processed


async def example_usage():
    manager = NotificationManager()
    
    manager.register_provider(NotificationChannel.EMAIL, EmailProvider())
    manager.register_provider(NotificationChannel.SMS, SMSProvider())
    manager.register_provider(NotificationChannel.PUSH, PushProvider())
    manager.register_provider(NotificationChannel.SLACK, SlackProvider())
    
    manager.register_template(NotificationTemplate(
        id="welcome",
        name="Welcome Email",
        channel=NotificationChannel.EMAIL,
        subject="Welcome to {{app_name}}, {{name}}!",
        body="Hi {{name}}, thanks for joining {{app_name}}. Get started at {{url}}."
    ))
    
    manager.register_recipient(NotificationRecipient(
        id="user-1",
        channels={
            NotificationChannel.EMAIL: "alice@example.com",
            NotificationChannel.SMS: "+1234567890",
            NotificationChannel.PUSH: "device-token-123"
        }
    ))
    
    result = await manager.send(
        NotificationChannel.EMAIL,
        "alice@example.com",
        "Test Subject",
        "Test Body"
    )
    print(f"Sent: {result.status.value}")
    
    result = await manager.send_template(
        "welcome",
        "user-1",
        {"app_name": "BlackRoad", "name": "Alice", "url": "https://blackroad.io"}
    )
    print(f"Template sent: {result.status.value}")

