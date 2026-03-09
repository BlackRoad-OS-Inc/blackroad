"""
RoadWebhooks - Webhook Management System for BlackRoad
Send and receive webhooks with retry, signing, and monitoring.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import asyncio
import hashlib
import hmac
import json
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class WebhookStatus(str, Enum):
    """Webhook delivery status."""
    PENDING = "pending"
    DELIVERED = "delivered"
    FAILED = "failed"
    RETRYING = "retrying"


class WebhookEventType(str, Enum):
    """Common webhook event types."""
    USER_CREATED = "user.created"
    USER_UPDATED = "user.updated"
    USER_DELETED = "user.deleted"
    ORDER_CREATED = "order.created"
    ORDER_PAID = "order.paid"
    ORDER_CANCELLED = "order.cancelled"
    PAYMENT_SUCCESS = "payment.success"
    PAYMENT_FAILED = "payment.failed"
    SUBSCRIPTION_CREATED = "subscription.created"
    SUBSCRIPTION_CANCELLED = "subscription.cancelled"


@dataclass
class WebhookEndpoint:
    """A registered webhook endpoint."""
    id: str
    url: str
    events: Set[str]
    secret: str
    description: str = ""
    active: bool = True
    created_at: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)
    headers: Dict[str, str] = field(default_factory=dict)
    retry_config: Dict[str, Any] = field(default_factory=lambda: {
        "max_retries": 5,
        "initial_delay": 60,
        "max_delay": 3600,
        "exponential_base": 2
    })

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "url": self.url,
            "events": list(self.events),
            "description": self.description,
            "active": self.active,
            "created_at": self.created_at.isoformat(),
            "metadata": self.metadata
        }


@dataclass
class WebhookDelivery:
    """A webhook delivery attempt."""
    id: str
    endpoint_id: str
    event_type: str
    payload: Dict[str, Any]
    status: WebhookStatus = WebhookStatus.PENDING
    attempts: int = 0
    created_at: datetime = field(default_factory=datetime.now)
    next_retry_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    response_status: Optional[int] = None
    response_body: Optional[str] = None
    error_message: Optional[str] = None
    duration_ms: Optional[float] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "endpoint_id": self.endpoint_id,
            "event_type": self.event_type,
            "status": self.status.value,
            "attempts": self.attempts,
            "created_at": self.created_at.isoformat(),
            "delivered_at": self.delivered_at.isoformat() if self.delivered_at else None,
            "response_status": self.response_status,
            "error_message": self.error_message,
            "duration_ms": self.duration_ms
        }


class WebhookSigner:
    """Sign and verify webhook payloads."""

    def __init__(self, algorithm: str = "sha256"):
        self.algorithm = algorithm

    def sign(self, payload: str, secret: str, timestamp: int) -> str:
        """Generate signature for payload."""
        message = f"{timestamp}.{payload}"
        signature = hmac.new(
            secret.encode(),
            message.encode(),
            hashlib.sha256
        ).hexdigest()
        return f"t={timestamp},v1={signature}"

    def verify(self, payload: str, secret: str, signature_header: str, tolerance: int = 300) -> bool:
        """Verify webhook signature."""
        try:
            parts = dict(p.split("=") for p in signature_header.split(","))
            timestamp = int(parts.get("t", 0))
            expected_sig = parts.get("v1", "")

            # Check timestamp tolerance
            now = int(time.time())
            if abs(now - timestamp) > tolerance:
                return False

            # Compute expected signature
            message = f"{timestamp}.{payload}"
            computed = hmac.new(
                secret.encode(),
                message.encode(),
                hashlib.sha256
            ).hexdigest()

            return hmac.compare_digest(computed, expected_sig)

        except Exception:
            return False


class WebhookStore:
    """Store for webhook endpoints and deliveries."""

    def __init__(self, max_deliveries: int = 10000):
        self.endpoints: Dict[str, WebhookEndpoint] = {}
        self.deliveries: Dict[str, WebhookDelivery] = {}
        self.event_subscriptions: Dict[str, Set[str]] = {}  # event_type -> endpoint_ids
        self.max_deliveries = max_deliveries
        self._lock = threading.Lock()

    def add_endpoint(self, endpoint: WebhookEndpoint) -> None:
        """Add webhook endpoint."""
        with self._lock:
            self.endpoints[endpoint.id] = endpoint
            for event in endpoint.events:
                if event not in self.event_subscriptions:
                    self.event_subscriptions[event] = set()
                self.event_subscriptions[event].add(endpoint.id)

    def remove_endpoint(self, endpoint_id: str) -> bool:
        """Remove webhook endpoint."""
        with self._lock:
            endpoint = self.endpoints.pop(endpoint_id, None)
            if endpoint:
                for event in endpoint.events:
                    self.event_subscriptions.get(event, set()).discard(endpoint_id)
                return True
            return False

    def get_endpoint(self, endpoint_id: str) -> Optional[WebhookEndpoint]:
        """Get endpoint by ID."""
        return self.endpoints.get(endpoint_id)

    def get_endpoints_for_event(self, event_type: str) -> List[WebhookEndpoint]:
        """Get all active endpoints subscribed to an event."""
        endpoint_ids = self.event_subscriptions.get(event_type, set())
        # Also check wildcard subscriptions
        endpoint_ids = endpoint_ids.union(self.event_subscriptions.get("*", set()))

        return [
            self.endpoints[eid] for eid in endpoint_ids
            if eid in self.endpoints and self.endpoints[eid].active
        ]

    def save_delivery(self, delivery: WebhookDelivery) -> None:
        """Save delivery record."""
        with self._lock:
            self.deliveries[delivery.id] = delivery

            # Prune old deliveries
            if len(self.deliveries) > self.max_deliveries:
                sorted_deliveries = sorted(
                    self.deliveries.values(),
                    key=lambda d: d.created_at
                )
                to_remove = len(self.deliveries) - self.max_deliveries
                for d in sorted_deliveries[:to_remove]:
                    del self.deliveries[d.id]

    def get_delivery(self, delivery_id: str) -> Optional[WebhookDelivery]:
        """Get delivery by ID."""
        return self.deliveries.get(delivery_id)

    def get_pending_retries(self) -> List[WebhookDelivery]:
        """Get deliveries due for retry."""
        now = datetime.now()
        return [
            d for d in self.deliveries.values()
            if d.status == WebhookStatus.RETRYING
            and d.next_retry_at
            and d.next_retry_at <= now
        ]

    def get_endpoint_deliveries(
        self,
        endpoint_id: str,
        limit: int = 100
    ) -> List[WebhookDelivery]:
        """Get deliveries for an endpoint."""
        deliveries = [
            d for d in self.deliveries.values()
            if d.endpoint_id == endpoint_id
        ]
        return sorted(deliveries, key=lambda d: d.created_at, reverse=True)[:limit]


class WebhookSender:
    """Send webhooks with retry logic."""

    def __init__(self, store: WebhookStore, signer: WebhookSigner):
        self.store = store
        self.signer = signer
        self._http_client = None  # Would use aiohttp/httpx in production

    async def send(self, delivery: WebhookDelivery, endpoint: WebhookEndpoint) -> bool:
        """Send a webhook."""
        delivery.attempts += 1
        start_time = time.time()

        try:
            # Prepare payload
            payload = json.dumps(delivery.payload)
            timestamp = int(time.time())
            signature = self.signer.sign(payload, endpoint.secret, timestamp)

            headers = {
                "Content-Type": "application/json",
                "X-Webhook-Signature": signature,
                "X-Webhook-ID": delivery.id,
                "X-Webhook-Timestamp": str(timestamp),
                **endpoint.headers
            }

            # In production, use actual HTTP client
            logger.info(f"Sending webhook to {endpoint.url}: {delivery.event_type}")

            # Simulate HTTP request
            # response = await self._http_client.post(endpoint.url, json=delivery.payload, headers=headers)

            # For demo, assume success
            delivery.status = WebhookStatus.DELIVERED
            delivery.delivered_at = datetime.now()
            delivery.response_status = 200
            delivery.duration_ms = (time.time() - start_time) * 1000

            self.store.save_delivery(delivery)
            return True

        except Exception as e:
            delivery.error_message = str(e)
            delivery.duration_ms = (time.time() - start_time) * 1000

            # Check if should retry
            retry_config = endpoint.retry_config
            if delivery.attempts < retry_config.get("max_retries", 5):
                delivery.status = WebhookStatus.RETRYING
                delay = min(
                    retry_config.get("initial_delay", 60) * (
                        retry_config.get("exponential_base", 2) ** (delivery.attempts - 1)
                    ),
                    retry_config.get("max_delay", 3600)
                )
                delivery.next_retry_at = datetime.now() + timedelta(seconds=delay)
            else:
                delivery.status = WebhookStatus.FAILED

            self.store.save_delivery(delivery)
            logger.error(f"Webhook failed: {endpoint.url} - {e}")
            return False


class WebhookReceiver:
    """Receive and validate incoming webhooks."""

    def __init__(self):
        self.handlers: Dict[str, List[Callable]] = {}
        self.secrets: Dict[str, str] = {}  # source -> secret
        self.signer = WebhookSigner()

    def register_source(self, source: str, secret: str) -> None:
        """Register a webhook source with its secret."""
        self.secrets[source] = secret

    def add_handler(self, event_type: str, handler: Callable[[Dict], None]) -> None:
        """Add handler for event type."""
        if event_type not in self.handlers:
            self.handlers[event_type] = []
        self.handlers[event_type].append(handler)

    def verify_and_process(
        self,
        source: str,
        payload: str,
        signature: str,
        event_type: str
    ) -> bool:
        """Verify signature and process webhook."""
        secret = self.secrets.get(source)
        if not secret:
            logger.warning(f"Unknown webhook source: {source}")
            return False

        if not self.signer.verify(payload, secret, signature):
            logger.warning(f"Invalid webhook signature from {source}")
            return False

        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            logger.error("Invalid JSON payload")
            return False

        # Call handlers
        handlers = self.handlers.get(event_type, []) + self.handlers.get("*", [])
        for handler in handlers:
            try:
                handler(data)
            except Exception as e:
                logger.error(f"Webhook handler error: {e}")

        return True


class WebhookService:
    """Main webhook service."""

    def __init__(self):
        self.store = WebhookStore()
        self.signer = WebhookSigner()
        self.sender = WebhookSender(self.store, self.signer)
        self._running = False

    def register_endpoint(
        self,
        url: str,
        events: List[str],
        description: str = "",
        headers: Optional[Dict[str, str]] = None,
        retry_config: Optional[Dict[str, Any]] = None
    ) -> WebhookEndpoint:
        """Register a new webhook endpoint."""
        import secrets as sec

        endpoint = WebhookEndpoint(
            id=str(uuid.uuid4()),
            url=url,
            events=set(events),
            secret=sec.token_hex(32),
            description=description,
            headers=headers or {},
            retry_config=retry_config or {}
        )

        self.store.add_endpoint(endpoint)
        logger.info(f"Registered webhook endpoint: {url}")
        return endpoint

    def unregister_endpoint(self, endpoint_id: str) -> bool:
        """Unregister a webhook endpoint."""
        return self.store.remove_endpoint(endpoint_id)

    def update_endpoint(
        self,
        endpoint_id: str,
        url: Optional[str] = None,
        events: Optional[List[str]] = None,
        active: Optional[bool] = None
    ) -> Optional[WebhookEndpoint]:
        """Update endpoint configuration."""
        endpoint = self.store.get_endpoint(endpoint_id)
        if not endpoint:
            return None

        if url:
            endpoint.url = url
        if events is not None:
            # Update subscriptions
            for event in endpoint.events:
                self.store.event_subscriptions.get(event, set()).discard(endpoint_id)
            endpoint.events = set(events)
            for event in endpoint.events:
                if event not in self.store.event_subscriptions:
                    self.store.event_subscriptions[event] = set()
                self.store.event_subscriptions[event].add(endpoint_id)
        if active is not None:
            endpoint.active = active

        return endpoint

    async def trigger(
        self,
        event_type: str,
        payload: Dict[str, Any],
        idempotency_key: Optional[str] = None
    ) -> List[WebhookDelivery]:
        """Trigger webhooks for an event."""
        endpoints = self.store.get_endpoints_for_event(event_type)

        if not endpoints:
            logger.debug(f"No endpoints for event: {event_type}")
            return []

        deliveries = []
        for endpoint in endpoints:
            delivery = WebhookDelivery(
                id=idempotency_key or str(uuid.uuid4()),
                endpoint_id=endpoint.id,
                event_type=event_type,
                payload={
                    "event": event_type,
                    "data": payload,
                    "timestamp": datetime.now().isoformat()
                }
            )

            self.store.save_delivery(delivery)
            await self.sender.send(delivery, endpoint)
            deliveries.append(delivery)

        return deliveries

    def trigger_sync(self, event_type: str, payload: Dict[str, Any]) -> List[WebhookDelivery]:
        """Synchronous trigger."""
        return asyncio.get_event_loop().run_until_complete(
            self.trigger(event_type, payload)
        )

    async def process_retries(self) -> int:
        """Process pending retries."""
        pending = self.store.get_pending_retries()
        count = 0

        for delivery in pending:
            endpoint = self.store.get_endpoint(delivery.endpoint_id)
            if endpoint:
                await self.sender.send(delivery, endpoint)
                count += 1

        return count

    async def retry_loop(self, interval: int = 60) -> None:
        """Background retry loop."""
        self._running = True
        while self._running:
            try:
                count = await self.process_retries()
                if count > 0:
                    logger.info(f"Processed {count} webhook retries")
            except Exception as e:
                logger.error(f"Retry loop error: {e}")

            await asyncio.sleep(interval)

    def stop(self) -> None:
        """Stop retry loop."""
        self._running = False

    def get_endpoint_stats(self, endpoint_id: str) -> Dict[str, Any]:
        """Get statistics for an endpoint."""
        deliveries = self.store.get_endpoint_deliveries(endpoint_id, limit=1000)

        total = len(deliveries)
        delivered = sum(1 for d in deliveries if d.status == WebhookStatus.DELIVERED)
        failed = sum(1 for d in deliveries if d.status == WebhookStatus.FAILED)
        avg_duration = sum(d.duration_ms or 0 for d in deliveries) / max(total, 1)

        return {
            "endpoint_id": endpoint_id,
            "total_deliveries": total,
            "delivered": delivered,
            "failed": failed,
            "success_rate": delivered / max(total, 1),
            "avg_duration_ms": avg_duration
        }

    def list_endpoints(self) -> List[WebhookEndpoint]:
        """List all endpoints."""
        return list(self.store.endpoints.values())


# Example usage
async def example_usage():
    """Example webhook usage."""
    service = WebhookService()

    # Register endpoint
    endpoint = service.register_endpoint(
        url="https://example.com/webhooks",
        events=["user.created", "order.paid"],
        description="Main webhook endpoint"
    )

    print(f"Endpoint secret: {endpoint.secret}")

    # Trigger webhook
    deliveries = await service.trigger(
        event_type="user.created",
        payload={
            "user_id": "user-123",
            "email": "alice@example.com",
            "name": "Alice"
        }
    )

    print(f"Triggered {len(deliveries)} webhooks")

    # Get stats
    stats = service.get_endpoint_stats(endpoint.id)
    print(f"Stats: {stats}")
