"""
RoadNotify - Push Notification System for BlackRoad
Multi-channel notifications: push, email, SMS, webhooks, in-app.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Union
import asyncio
import hashlib
import json
import logging
import re
import uuid

logger = logging.getLogger(__name__)


class NotificationChannel(str, Enum):
    """Notification delivery channels."""
    PUSH = "push"
    EMAIL = "email"
    SMS = "sms"
    WEBHOOK = "webhook"
    IN_APP = "in_app"
    SLACK = "slack"
    DISCORD = "discord"


class NotificationPriority(str, Enum):
    """Notification priority levels."""
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"


class NotificationStatus(str, Enum):
    """Notification delivery status."""
    PENDING = "pending"
    SENT = "sent"
    DELIVERED = "delivered"
    READ = "read"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass
class NotificationTemplate:
    """Reusable notification template."""
    id: str
    name: str
    channels: Set[NotificationChannel]
    title_template: str
    body_template: str
    data_schema: Optional[Dict[str, Any]] = None
    default_priority: NotificationPriority = NotificationPriority.NORMAL

    def render(self, data: Dict[str, Any]) -> tuple:
        """Render template with data."""
        title = self.title_template
        body = self.body_template

        for key, value in data.items():
            placeholder = f"{{{{{key}}}}}"
            title = title.replace(placeholder, str(value))
            body = body.replace(placeholder, str(value))

        return title, body


@dataclass
class DeviceToken:
    """Push notification device token."""
    token: str
    platform: str  # ios, android, web
    user_id: str
    created_at: datetime = field(default_factory=datetime.now)
    last_used: Optional[datetime] = None
    is_active: bool = True
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class NotificationPreferences:
    """User notification preferences."""
    user_id: str
    enabled_channels: Set[NotificationChannel] = field(
        default_factory=lambda: {NotificationChannel.PUSH, NotificationChannel.EMAIL}
    )
    quiet_hours_start: Optional[int] = None  # Hour 0-23
    quiet_hours_end: Optional[int] = None
    category_settings: Dict[str, bool] = field(default_factory=dict)
    frequency_limits: Dict[str, int] = field(default_factory=dict)


@dataclass
class Notification:
    """A notification to be sent."""
    id: str
    user_id: str
    channel: NotificationChannel
    title: str
    body: str
    priority: NotificationPriority = NotificationPriority.NORMAL
    status: NotificationStatus = NotificationStatus.PENDING
    data: Dict[str, Any] = field(default_factory=dict)
    action_url: Optional[str] = None
    image_url: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)
    scheduled_for: Optional[datetime] = None
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    error: Optional[str] = None
    template_id: Optional[str] = None
    category: Optional[str] = None
    collapse_key: Optional[str] = None  # For grouping
    ttl: Optional[int] = None  # Time to live in seconds

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "channel": self.channel.value,
            "title": self.title,
            "body": self.body,
            "priority": self.priority.value,
            "status": self.status.value,
            "data": self.data,
            "action_url": self.action_url,
            "image_url": self.image_url,
            "created_at": self.created_at.isoformat(),
            "scheduled_for": self.scheduled_for.isoformat() if self.scheduled_for else None,
            "sent_at": self.sent_at.isoformat() if self.sent_at else None,
            "category": self.category
        }


class DeviceRegistry:
    """Manage device tokens for push notifications."""

    def __init__(self):
        self.devices: Dict[str, DeviceToken] = {}
        self.user_devices: Dict[str, Set[str]] = {}

    def register(self, token: DeviceToken) -> None:
        """Register a device token."""
        self.devices[token.token] = token
        if token.user_id not in self.user_devices:
            self.user_devices[token.user_id] = set()
        self.user_devices[token.user_id].add(token.token)
        logger.info(f"Registered device for user {token.user_id}: {token.platform}")

    def unregister(self, token: str) -> None:
        """Unregister a device token."""
        if token in self.devices:
            device = self.devices.pop(token)
            self.user_devices.get(device.user_id, set()).discard(token)

    def get_user_devices(self, user_id: str) -> List[DeviceToken]:
        """Get all devices for a user."""
        tokens = self.user_devices.get(user_id, set())
        return [self.devices[t] for t in tokens if t in self.devices and self.devices[t].is_active]

    def mark_inactive(self, token: str) -> None:
        """Mark a device as inactive."""
        if token in self.devices:
            self.devices[token].is_active = False


class PreferencesManager:
    """Manage user notification preferences."""

    def __init__(self):
        self.preferences: Dict[str, NotificationPreferences] = {}
        self.sent_counts: Dict[str, Dict[str, int]] = {}  # user_id -> {category: count}

    def get(self, user_id: str) -> NotificationPreferences:
        """Get user preferences."""
        if user_id not in self.preferences:
            self.preferences[user_id] = NotificationPreferences(user_id=user_id)
        return self.preferences[user_id]

    def update(self, user_id: str, **kwargs) -> NotificationPreferences:
        """Update user preferences."""
        prefs = self.get(user_id)
        for key, value in kwargs.items():
            if hasattr(prefs, key):
                setattr(prefs, key, value)
        return prefs

    def is_channel_enabled(self, user_id: str, channel: NotificationChannel) -> bool:
        """Check if channel is enabled for user."""
        prefs = self.get(user_id)
        return channel in prefs.enabled_channels

    def is_quiet_hours(self, user_id: str) -> bool:
        """Check if currently in quiet hours."""
        prefs = self.get(user_id)
        if prefs.quiet_hours_start is None or prefs.quiet_hours_end is None:
            return False

        current_hour = datetime.now().hour
        start, end = prefs.quiet_hours_start, prefs.quiet_hours_end

        if start <= end:
            return start <= current_hour < end
        else:  # Spans midnight
            return current_hour >= start or current_hour < end

    def check_frequency_limit(self, user_id: str, category: str) -> bool:
        """Check if user has exceeded frequency limit for category."""
        prefs = self.get(user_id)
        limit = prefs.frequency_limits.get(category)
        if not limit:
            return True

        counts = self.sent_counts.get(user_id, {})
        return counts.get(category, 0) < limit

    def increment_sent_count(self, user_id: str, category: str) -> None:
        """Increment sent count for user/category."""
        if user_id not in self.sent_counts:
            self.sent_counts[user_id] = {}
        self.sent_counts[user_id][category] = self.sent_counts[user_id].get(category, 0) + 1


class NotificationStore:
    """Store and retrieve notifications."""

    def __init__(self, max_per_user: int = 1000):
        self.notifications: Dict[str, Notification] = {}
        self.user_notifications: Dict[str, List[str]] = {}
        self.max_per_user = max_per_user

    def save(self, notification: Notification) -> None:
        """Save a notification."""
        self.notifications[notification.id] = notification

        if notification.user_id not in self.user_notifications:
            self.user_notifications[notification.user_id] = []

        self.user_notifications[notification.user_id].append(notification.id)

        # Prune old notifications
        user_notifs = self.user_notifications[notification.user_id]
        if len(user_notifs) > self.max_per_user:
            old_ids = user_notifs[:-self.max_per_user]
            self.user_notifications[notification.user_id] = user_notifs[-self.max_per_user:]
            for old_id in old_ids:
                self.notifications.pop(old_id, None)

    def get(self, notification_id: str) -> Optional[Notification]:
        """Get a notification by ID."""
        return self.notifications.get(notification_id)

    def get_user_notifications(
        self,
        user_id: str,
        status: Optional[NotificationStatus] = None,
        channel: Optional[NotificationChannel] = None,
        limit: int = 50
    ) -> List[Notification]:
        """Get notifications for a user."""
        notif_ids = self.user_notifications.get(user_id, [])
        notifications = [self.notifications[nid] for nid in notif_ids if nid in self.notifications]

        if status:
            notifications = [n for n in notifications if n.status == status]
        if channel:
            notifications = [n for n in notifications if n.channel == channel]

        return sorted(notifications, key=lambda n: n.created_at, reverse=True)[:limit]

    def get_unread_count(self, user_id: str) -> int:
        """Get unread notification count."""
        notifs = self.get_user_notifications(user_id)
        return sum(1 for n in notifs if n.status in {NotificationStatus.DELIVERED, NotificationStatus.SENT})

    def mark_read(self, notification_id: str) -> bool:
        """Mark notification as read."""
        notif = self.get(notification_id)
        if notif:
            notif.status = NotificationStatus.READ
            notif.read_at = datetime.now()
            return True
        return False

    def mark_all_read(self, user_id: str) -> int:
        """Mark all notifications as read for a user."""
        count = 0
        for notif in self.get_user_notifications(user_id):
            if notif.status in {NotificationStatus.DELIVERED, NotificationStatus.SENT}:
                notif.status = NotificationStatus.READ
                notif.read_at = datetime.now()
                count += 1
        return count


class ChannelProvider:
    """Base class for notification channel providers."""

    async def send(self, notification: Notification, **kwargs) -> bool:
        """Send notification through this channel."""
        raise NotImplementedError


class PushProvider(ChannelProvider):
    """Push notification provider (FCM/APNS)."""

    def __init__(self, fcm_key: Optional[str] = None, apns_key: Optional[str] = None):
        self.fcm_key = fcm_key
        self.apns_key = apns_key

    async def send(self, notification: Notification, devices: List[DeviceToken]) -> bool:
        """Send push notification to devices."""
        success = True
        for device in devices:
            try:
                # In production, use actual FCM/APNS APIs
                logger.info(f"Push to {device.platform}: {notification.title}")
                device.last_used = datetime.now()
            except Exception as e:
                logger.error(f"Push failed for {device.token}: {e}")
                success = False
        return success


class EmailProvider(ChannelProvider):
    """Email notification provider."""

    def __init__(self, smtp_host: str = "localhost", smtp_port: int = 587):
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port

    async def send(self, notification: Notification, email: str) -> bool:
        """Send email notification."""
        try:
            # In production, use actual SMTP/SES
            logger.info(f"Email to {email}: {notification.title}")
            return True
        except Exception as e:
            logger.error(f"Email failed: {e}")
            return False


class SMSProvider(ChannelProvider):
    """SMS notification provider."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key

    async def send(self, notification: Notification, phone: str) -> bool:
        """Send SMS notification."""
        try:
            # In production, use Twilio/AWS SNS
            logger.info(f"SMS to {phone}: {notification.body[:160]}")
            return True
        except Exception as e:
            logger.error(f"SMS failed: {e}")
            return False


class WebhookProvider(ChannelProvider):
    """Webhook notification provider."""

    async def send(self, notification: Notification, url: str, secret: Optional[str] = None) -> bool:
        """Send webhook notification."""
        try:
            payload = notification.to_dict()
            # In production, make actual HTTP request with signature
            logger.info(f"Webhook to {url}: {notification.title}")
            return True
        except Exception as e:
            logger.error(f"Webhook failed: {e}")
            return False


class SlackProvider(ChannelProvider):
    """Slack notification provider."""

    async def send(self, notification: Notification, webhook_url: str) -> bool:
        """Send Slack notification."""
        try:
            payload = {
                "text": notification.title,
                "blocks": [
                    {"type": "header", "text": {"type": "plain_text", "text": notification.title}},
                    {"type": "section", "text": {"type": "mrkdwn", "text": notification.body}}
                ]
            }
            # In production, POST to webhook_url
            logger.info(f"Slack: {notification.title}")
            return True
        except Exception as e:
            logger.error(f"Slack failed: {e}")
            return False


class NotificationService:
    """Main notification service."""

    def __init__(self):
        self.store = NotificationStore()
        self.devices = DeviceRegistry()
        self.preferences = PreferencesManager()
        self.templates: Dict[str, NotificationTemplate] = {}
        self.providers: Dict[NotificationChannel, ChannelProvider] = {
            NotificationChannel.PUSH: PushProvider(),
            NotificationChannel.EMAIL: EmailProvider(),
            NotificationChannel.SMS: SMSProvider(),
            NotificationChannel.WEBHOOK: WebhookProvider(),
            NotificationChannel.SLACK: SlackProvider(),
        }
        self.pending_queue: asyncio.Queue = asyncio.Queue()
        self.running = False

    def register_template(self, template: NotificationTemplate) -> None:
        """Register a notification template."""
        self.templates[template.id] = template

    def get_template(self, template_id: str) -> Optional[NotificationTemplate]:
        """Get a template by ID."""
        return self.templates.get(template_id)

    async def send(
        self,
        user_id: str,
        channel: NotificationChannel,
        title: str,
        body: str,
        priority: NotificationPriority = NotificationPriority.NORMAL,
        data: Optional[Dict[str, Any]] = None,
        action_url: Optional[str] = None,
        image_url: Optional[str] = None,
        category: Optional[str] = None,
        scheduled_for: Optional[datetime] = None,
        **kwargs
    ) -> Notification:
        """Send a notification."""
        notification = Notification(
            id=str(uuid.uuid4()),
            user_id=user_id,
            channel=channel,
            title=title,
            body=body,
            priority=priority,
            data=data or {},
            action_url=action_url,
            image_url=image_url,
            category=category,
            scheduled_for=scheduled_for
        )

        # Check preferences
        if not self.preferences.is_channel_enabled(user_id, channel):
            notification.status = NotificationStatus.CANCELLED
            notification.error = "Channel disabled by user"
            self.store.save(notification)
            return notification

        # Check quiet hours for non-urgent
        if priority != NotificationPriority.URGENT and self.preferences.is_quiet_hours(user_id):
            if not scheduled_for:
                notification.scheduled_for = self._get_end_of_quiet_hours(user_id)

        # Check frequency limits
        if category and not self.preferences.check_frequency_limit(user_id, category):
            notification.status = NotificationStatus.CANCELLED
            notification.error = "Frequency limit exceeded"
            self.store.save(notification)
            return notification

        self.store.save(notification)

        # Schedule or send immediately
        if notification.scheduled_for and notification.scheduled_for > datetime.now():
            await self.pending_queue.put(notification)
        else:
            await self._deliver(notification, **kwargs)

        return notification

    async def send_from_template(
        self,
        user_id: str,
        template_id: str,
        data: Dict[str, Any],
        channels: Optional[Set[NotificationChannel]] = None,
        **kwargs
    ) -> List[Notification]:
        """Send notifications using a template."""
        template = self.get_template(template_id)
        if not template:
            raise ValueError(f"Template not found: {template_id}")

        title, body = template.render(data)
        target_channels = channels or template.channels

        notifications = []
        for channel in target_channels:
            notif = await self.send(
                user_id=user_id,
                channel=channel,
                title=title,
                body=body,
                priority=template.default_priority,
                data=data,
                **kwargs
            )
            notifications.append(notif)

        return notifications

    async def send_bulk(
        self,
        user_ids: List[str],
        channel: NotificationChannel,
        title: str,
        body: str,
        **kwargs
    ) -> List[Notification]:
        """Send notification to multiple users."""
        tasks = [
            self.send(user_id, channel, title, body, **kwargs)
            for user_id in user_ids
        ]
        return await asyncio.gather(*tasks)

    async def _deliver(self, notification: Notification, **kwargs) -> bool:
        """Deliver notification through appropriate channel."""
        provider = self.providers.get(notification.channel)
        if not provider:
            notification.status = NotificationStatus.FAILED
            notification.error = f"No provider for channel: {notification.channel}"
            return False

        try:
            success = False

            if notification.channel == NotificationChannel.PUSH:
                devices = self.devices.get_user_devices(notification.user_id)
                if devices:
                    success = await provider.send(notification, devices)
                else:
                    notification.error = "No registered devices"

            elif notification.channel == NotificationChannel.EMAIL:
                email = kwargs.get("email")
                if email:
                    success = await provider.send(notification, email)
                else:
                    notification.error = "No email address provided"

            elif notification.channel == NotificationChannel.SMS:
                phone = kwargs.get("phone")
                if phone:
                    success = await provider.send(notification, phone)
                else:
                    notification.error = "No phone number provided"

            elif notification.channel == NotificationChannel.WEBHOOK:
                url = kwargs.get("webhook_url")
                if url:
                    success = await provider.send(notification, url)
                else:
                    notification.error = "No webhook URL provided"

            elif notification.channel == NotificationChannel.SLACK:
                url = kwargs.get("slack_webhook")
                if url:
                    success = await provider.send(notification, url)
                else:
                    notification.error = "No Slack webhook provided"

            else:
                # In-app notifications are just stored
                success = True

            if success:
                notification.status = NotificationStatus.SENT
                notification.sent_at = datetime.now()
                if notification.category:
                    self.preferences.increment_sent_count(notification.user_id, notification.category)
            else:
                notification.status = NotificationStatus.FAILED

            return success

        except Exception as e:
            notification.status = NotificationStatus.FAILED
            notification.error = str(e)
            logger.error(f"Notification delivery failed: {e}")
            return False

    def _get_end_of_quiet_hours(self, user_id: str) -> datetime:
        """Calculate end of quiet hours."""
        prefs = self.preferences.get(user_id)
        now = datetime.now()
        end_hour = prefs.quiet_hours_end or 8

        scheduled = now.replace(hour=end_hour, minute=0, second=0, microsecond=0)
        if scheduled <= now:
            scheduled += timedelta(days=1)

        return scheduled

    async def _scheduler_loop(self) -> None:
        """Process scheduled notifications."""
        while self.running:
            try:
                notification = await asyncio.wait_for(
                    self.pending_queue.get(),
                    timeout=1.0
                )

                if notification.scheduled_for and notification.scheduled_for > datetime.now():
                    await self.pending_queue.put(notification)
                    await asyncio.sleep(0.1)
                else:
                    await self._deliver(notification)

            except asyncio.TimeoutError:
                continue

    async def start(self) -> None:
        """Start notification service."""
        self.running = True
        logger.info("Notification service started")
        await self._scheduler_loop()

    async def stop(self) -> None:
        """Stop notification service."""
        self.running = False
        logger.info("Notification service stopped")

    def get_stats(self) -> Dict[str, Any]:
        """Get service statistics."""
        all_notifs = list(self.store.notifications.values())

        by_status = {}
        for status in NotificationStatus:
            by_status[status.value] = sum(1 for n in all_notifs if n.status == status)

        by_channel = {}
        for channel in NotificationChannel:
            by_channel[channel.value] = sum(1 for n in all_notifs if n.channel == channel)

        return {
            "total_notifications": len(all_notifs),
            "registered_devices": len(self.devices.devices),
            "users_with_preferences": len(self.preferences.preferences),
            "templates": len(self.templates),
            "by_status": by_status,
            "by_channel": by_channel,
            "pending_queue_size": self.pending_queue.qsize()
        }


# Example usage
async def example_usage():
    """Example notification service usage."""
    service = NotificationService()

    # Register device
    service.devices.register(DeviceToken(
        token="abc123",
        platform="ios",
        user_id="user-1"
    ))

    # Create template
    service.register_template(NotificationTemplate(
        id="welcome",
        name="Welcome Email",
        channels={NotificationChannel.EMAIL, NotificationChannel.PUSH},
        title_template="Welcome, {{name}}!",
        body_template="Thanks for joining {{app_name}}. Let's get started!"
    ))

    # Send notification
    await service.send(
        user_id="user-1",
        channel=NotificationChannel.PUSH,
        title="New Message",
        body="You have a new message from Alice",
        priority=NotificationPriority.HIGH,
        action_url="/messages/123"
    )

    # Send from template
    await service.send_from_template(
        user_id="user-1",
        template_id="welcome",
        data={"name": "Bob", "app_name": "BlackRoad"}
    )
