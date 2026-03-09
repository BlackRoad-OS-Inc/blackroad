"""
RoadWebhook - Webhook Handling for BlackRoad
Send and receive webhooks with retries and signature verification.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import asyncio
import base64
import hashlib
import hmac
import json
import logging
import secrets
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class WebhookStatus(str, Enum):
    PENDING = "pending"
    SENDING = "sending"
    DELIVERED = "delivered"
    FAILED = "failed"
    RETRYING = "retrying"


class RetryStrategy(str, Enum):
    NONE = "none"
    LINEAR = "linear"
    EXPONENTIAL = "exponential"


@dataclass
class WebhookEndpoint:
    id: str
    url: str
    secret: str
    events: List[str] = field(default_factory=list)
    active: bool = True
    headers: Dict[str, str] = field(default_factory=dict)
    retry_strategy: RetryStrategy = RetryStrategy.EXPONENTIAL
    max_retries: int = 5
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class WebhookPayload:
    id: str
    event: str
    data: Dict[str, Any]
    timestamp: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "event": self.event,
            "data": self.data,
            "timestamp": self.timestamp.isoformat(),
            "metadata": self.metadata
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict())


@dataclass
class WebhookDelivery:
    id: str
    endpoint_id: str
    payload: WebhookPayload
    status: WebhookStatus = WebhookStatus.PENDING
    attempts: int = 0
    last_attempt: Optional[datetime] = None
    next_attempt: Optional[datetime] = None
    response_code: Optional[int] = None
    response_body: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)
    delivered_at: Optional[datetime] = None


class SignatureGenerator:
    @staticmethod
    def generate(payload: str, secret: str, algorithm: str = "sha256") -> str:
        signature = hmac.new(secret.encode(), payload.encode(), algorithm).hexdigest()
        return f"{algorithm}={signature}"

    @staticmethod
    def verify(payload: str, signature: str, secret: str) -> bool:
        if "=" not in signature:
            return False
        algorithm, received = signature.split("=", 1)
        expected = hmac.new(secret.encode(), payload.encode(), algorithm).hexdigest()
        return hmac.compare_digest(received, expected)


class WebhookSender:
    def __init__(self, timeout: int = 30):
        self.timeout = timeout

    async def send(self, endpoint: WebhookEndpoint, payload: WebhookPayload) -> tuple:
        """Simulate sending webhook. Returns (success, status_code, response)."""
        json_payload = payload.to_json()
        signature = SignatureGenerator.generate(json_payload, endpoint.secret)
        
        headers = {
            "Content-Type": "application/json",
            "X-Webhook-ID": payload.id,
            "X-Webhook-Signature": signature,
            "X-Webhook-Event": payload.event,
            **endpoint.headers
        }
        
        # Simulate HTTP request
        await asyncio.sleep(0.1)
        
        # Simulate success (in real implementation, use aiohttp)
        logger.info(f"Sending webhook {payload.id} to {endpoint.url}")
        return True, 200, "OK"

    def calculate_next_attempt(self, attempt: int, strategy: RetryStrategy) -> timedelta:
        if strategy == RetryStrategy.NONE:
            return timedelta(0)
        elif strategy == RetryStrategy.LINEAR:
            return timedelta(minutes=attempt * 5)
        else:  # EXPONENTIAL
            return timedelta(minutes=min(2 ** attempt, 60))


class WebhookReceiver:
    def __init__(self):
        self.handlers: Dict[str, List[Callable]] = {}
        self._lock = threading.Lock()

    def register(self, event: str, handler: Callable) -> None:
        with self._lock:
            if event not in self.handlers:
                self.handlers[event] = []
            self.handlers[event].append(handler)

    def unregister(self, event: str, handler: Callable) -> bool:
        with self._lock:
            if event in self.handlers:
                if handler in self.handlers[event]:
                    self.handlers[event].remove(handler)
                    return True
        return False

    def verify_signature(self, payload: str, signature: str, secret: str) -> bool:
        return SignatureGenerator.verify(payload, signature, secret)

    async def process(self, event: str, payload: Dict[str, Any]) -> List[Any]:
        handlers = self.handlers.get(event, []) + self.handlers.get("*", [])
        results = []
        
        for handler in handlers:
            try:
                result = handler(payload)
                if asyncio.iscoroutine(result):
                    result = await result
                results.append(result)
            except Exception as e:
                logger.error(f"Webhook handler error: {e}")
                results.append(None)
        
        return results


class WebhookQueue:
    def __init__(self, max_size: int = 10000):
        self.max_size = max_size
        self.deliveries: Dict[str, WebhookDelivery] = {}
        self.pending: List[str] = []
        self._lock = threading.Lock()

    def enqueue(self, delivery: WebhookDelivery) -> None:
        with self._lock:
            self.deliveries[delivery.id] = delivery
            self.pending.append(delivery.id)
            
            if len(self.deliveries) > self.max_size:
                self._cleanup()

    def dequeue(self) -> Optional[WebhookDelivery]:
        with self._lock:
            now = datetime.now()
            for delivery_id in list(self.pending):
                delivery = self.deliveries.get(delivery_id)
                if delivery and delivery.status == WebhookStatus.PENDING:
                    if delivery.next_attempt is None or delivery.next_attempt <= now:
                        self.pending.remove(delivery_id)
                        return delivery
            return None

    def update(self, delivery: WebhookDelivery) -> None:
        with self._lock:
            self.deliveries[delivery.id] = delivery
            if delivery.status == WebhookStatus.RETRYING:
                self.pending.append(delivery.id)

    def _cleanup(self) -> None:
        old = [d for d in self.deliveries.values() 
               if d.status in [WebhookStatus.DELIVERED, WebhookStatus.FAILED]]
        old.sort(key=lambda d: d.created_at)
        for d in old[:len(old)//2]:
            del self.deliveries[d.id]

    def get(self, delivery_id: str) -> Optional[WebhookDelivery]:
        return self.deliveries.get(delivery_id)

    def list_pending(self) -> List[WebhookDelivery]:
        return [self.deliveries[d] for d in self.pending if d in self.deliveries]


class WebhookManager:
    def __init__(self):
        self.endpoints: Dict[str, WebhookEndpoint] = {}
        self.sender = WebhookSender()
        self.receiver = WebhookReceiver()
        self.queue = WebhookQueue()
        self._running = False

    def register_endpoint(self, url: str, events: List[str] = None, **kwargs) -> WebhookEndpoint:
        endpoint = WebhookEndpoint(
            id=str(uuid.uuid4())[:12],
            url=url,
            secret=secrets.token_hex(32),
            events=events or ["*"],
            **kwargs
        )
        self.endpoints[endpoint.id] = endpoint
        return endpoint

    def unregister_endpoint(self, endpoint_id: str) -> bool:
        if endpoint_id in self.endpoints:
            del self.endpoints[endpoint_id]
            return True
        return False

    async def trigger(self, event: str, data: Dict[str, Any]) -> List[str]:
        payload = WebhookPayload(id=str(uuid.uuid4()), event=event, data=data)
        delivery_ids = []
        
        for endpoint in self.endpoints.values():
            if not endpoint.active:
                continue
            if "*" not in endpoint.events and event not in endpoint.events:
                continue
            
            delivery = WebhookDelivery(
                id=str(uuid.uuid4())[:12],
                endpoint_id=endpoint.id,
                payload=payload
            )
            self.queue.enqueue(delivery)
            delivery_ids.append(delivery.id)
        
        return delivery_ids

    async def process_queue(self) -> int:
        processed = 0
        while True:
            delivery = self.queue.dequeue()
            if not delivery:
                break
            
            endpoint = self.endpoints.get(delivery.endpoint_id)
            if not endpoint:
                delivery.status = WebhookStatus.FAILED
                delivery.error = "Endpoint not found"
                self.queue.update(delivery)
                continue
            
            delivery.status = WebhookStatus.SENDING
            delivery.attempts += 1
            delivery.last_attempt = datetime.now()
            
            success, code, response = await self.sender.send(endpoint, delivery.payload)
            
            if success and 200 <= code < 300:
                delivery.status = WebhookStatus.DELIVERED
                delivery.delivered_at = datetime.now()
            elif delivery.attempts < endpoint.max_retries:
                delivery.status = WebhookStatus.RETRYING
                delay = self.sender.calculate_next_attempt(delivery.attempts, endpoint.retry_strategy)
                delivery.next_attempt = datetime.now() + delay
            else:
                delivery.status = WebhookStatus.FAILED
            
            delivery.response_code = code
            delivery.response_body = response
            self.queue.update(delivery)
            processed += 1
        
        return processed

    def on_receive(self, event: str) -> Callable:
        def decorator(handler: Callable) -> Callable:
            self.receiver.register(event, handler)
            return handler
        return decorator

    async def handle_incoming(self, event: str, payload: Dict, signature: str = None, secret: str = None) -> List[Any]:
        if signature and secret:
            if not self.receiver.verify_signature(json.dumps(payload), signature, secret):
                raise ValueError("Invalid signature")
        return await self.receiver.process(event, payload)

    def list_endpoints(self) -> List[Dict[str, Any]]:
        return [
            {"id": e.id, "url": e.url, "events": e.events, "active": e.active}
            for e in self.endpoints.values()
        ]

    def get_delivery(self, delivery_id: str) -> Optional[WebhookDelivery]:
        return self.queue.get(delivery_id)


async def example_usage():
    manager = WebhookManager()
    
    # Register outgoing webhook endpoint
    endpoint = manager.register_endpoint(
        url="https://example.com/webhook",
        events=["order.created", "order.updated"]
    )
    print(f"Registered endpoint: {endpoint.id}")
    print(f"Secret: {endpoint.secret}")
    
    # Trigger webhook
    delivery_ids = await manager.trigger("order.created", {
        "order_id": "ORD-123",
        "amount": 99.99,
        "customer": "Alice"
    })
    print(f"Triggered {len(delivery_ids)} deliveries")
    
    # Process queue
    processed = await manager.process_queue()
    print(f"Processed {processed} deliveries")
    
    # Check delivery status
    for did in delivery_ids:
        delivery = manager.get_delivery(did)
        print(f"Delivery {did}: {delivery.status.value}")
    
    # Register incoming webhook handler
    @manager.on_receive("payment.received")
    async def handle_payment(payload):
        print(f"Payment received: {payload}")
        return {"status": "processed"}
    
    # Handle incoming webhook
    result = await manager.handle_incoming("payment.received", {"amount": 100})
    print(f"Handler result: {result}")
