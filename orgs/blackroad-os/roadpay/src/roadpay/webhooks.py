"""
RoadPay Webhook System
Handle Stripe webhooks with retry logic and event processing
"""

import json
import time
import hmac
import hashlib
from typing import Optional, Callable, Dict, Any, List
from dataclasses import dataclass, asdict
from enum import Enum
from functools import wraps

import stripe
from fastapi import Request, HTTPException


class WebhookEventType(str, Enum):
    """Stripe webhook event types we handle."""
    # Payment events
    PAYMENT_INTENT_SUCCEEDED = "payment_intent.succeeded"
    PAYMENT_INTENT_FAILED = "payment_intent.payment_failed"
    PAYMENT_INTENT_CANCELED = "payment_intent.canceled"

    # Charge events
    CHARGE_SUCCEEDED = "charge.succeeded"
    CHARGE_FAILED = "charge.failed"
    CHARGE_REFUNDED = "charge.refunded"
    CHARGE_DISPUTED = "charge.dispute.created"

    # Subscription events
    SUBSCRIPTION_CREATED = "customer.subscription.created"
    SUBSCRIPTION_UPDATED = "customer.subscription.updated"
    SUBSCRIPTION_DELETED = "customer.subscription.deleted"
    SUBSCRIPTION_TRIAL_ENDING = "customer.subscription.trial_will_end"

    # Invoice events
    INVOICE_PAID = "invoice.paid"
    INVOICE_PAYMENT_FAILED = "invoice.payment_failed"
    INVOICE_UPCOMING = "invoice.upcoming"
    INVOICE_FINALIZED = "invoice.finalized"

    # Customer events
    CUSTOMER_CREATED = "customer.created"
    CUSTOMER_UPDATED = "customer.updated"
    CUSTOMER_DELETED = "customer.deleted"

    # Checkout events
    CHECKOUT_COMPLETED = "checkout.session.completed"
    CHECKOUT_EXPIRED = "checkout.session.expired"

    # Payout events
    PAYOUT_PAID = "payout.paid"
    PAYOUT_FAILED = "payout.failed"


@dataclass
class WebhookEvent:
    """Processed webhook event."""
    id: str
    type: str
    data: Dict[str, Any]
    created: int
    processed_at: Optional[float] = None
    attempts: int = 0
    last_error: Optional[str] = None

    def to_dict(self) -> dict:
        return asdict(self)


class WebhookProcessor:
    """
    Process Stripe webhooks with handlers and retry logic.

    Usage:
        processor = WebhookProcessor(webhook_secret="whsec_...")

        @processor.on(WebhookEventType.PAYMENT_INTENT_SUCCEEDED)
        async def handle_payment(event, data):
            # Process payment
            pass
    """

    def __init__(
        self,
        webhook_secret: str,
        max_retries: int = 3,
        retry_delay: int = 60,
    ):
        self.webhook_secret = webhook_secret
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self.handlers: Dict[str, List[Callable]] = {}
        self.event_log: List[WebhookEvent] = []
        self.failed_events: List[WebhookEvent] = []

    def on(self, event_type: WebhookEventType):
        """Decorator to register an event handler."""
        def decorator(func: Callable):
            if event_type.value not in self.handlers:
                self.handlers[event_type.value] = []
            self.handlers[event_type.value].append(func)
            return func
        return decorator

    def verify_signature(self, payload: bytes, signature: str) -> bool:
        """Verify Stripe webhook signature."""
        try:
            stripe.Webhook.construct_event(
                payload,
                signature,
                self.webhook_secret
            )
            return True
        except (ValueError, stripe.error.SignatureVerificationError):
            return False

    async def process(self, request: Request) -> Dict[str, Any]:
        """Process incoming webhook request."""
        payload = await request.body()
        signature = request.headers.get("Stripe-Signature", "")

        # Verify signature
        if not self.verify_signature(payload, signature):
            raise HTTPException(status_code=400, detail="Invalid signature")

        # Parse event
        try:
            event_data = json.loads(payload)
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="Invalid JSON")

        event = WebhookEvent(
            id=event_data["id"],
            type=event_data["type"],
            data=event_data["data"]["object"],
            created=event_data["created"],
        )

        # Check for duplicate
        if any(e.id == event.id for e in self.event_log):
            return {"status": "duplicate", "event_id": event.id}

        # Process event
        result = await self._process_event(event)

        return result

    async def _process_event(self, event: WebhookEvent) -> Dict[str, Any]:
        """Process a single event with retry logic."""
        handlers = self.handlers.get(event.type, [])

        if not handlers:
            # No handlers, just log
            self.event_log.append(event)
            return {"status": "ignored", "type": event.type}

        errors = []

        for handler in handlers:
            for attempt in range(self.max_retries):
                event.attempts = attempt + 1

                try:
                    await handler(event, event.data)
                    break
                except Exception as e:
                    event.last_error = str(e)
                    errors.append(f"{handler.__name__}: {e}")

                    if attempt < self.max_retries - 1:
                        # Wait before retry
                        await self._async_sleep(self.retry_delay * (attempt + 1))
            else:
                # All retries failed
                self.failed_events.append(event)

        event.processed_at = time.time()
        self.event_log.append(event)

        if errors:
            return {
                "status": "partial_failure",
                "event_id": event.id,
                "errors": errors,
            }

        return {"status": "processed", "event_id": event.id}

    async def _async_sleep(self, seconds: float):
        """Async sleep for retry delay."""
        import asyncio
        await asyncio.sleep(seconds)

    def get_event(self, event_id: str) -> Optional[WebhookEvent]:
        """Get event by ID."""
        for event in self.event_log:
            if event.id == event_id:
                return event
        return None

    def get_failed_events(self) -> List[WebhookEvent]:
        """Get list of failed events."""
        return self.failed_events.copy()

    async def retry_failed(self, event_id: str) -> Dict[str, Any]:
        """Retry a failed event."""
        event = None
        for i, e in enumerate(self.failed_events):
            if e.id == event_id:
                event = self.failed_events.pop(i)
                break

        if not event:
            return {"status": "not_found"}

        event.attempts = 0
        event.last_error = None

        return await self._process_event(event)

    def stats(self) -> Dict[str, Any]:
        """Get webhook processing statistics."""
        by_type: Dict[str, int] = {}
        for event in self.event_log:
            by_type[event.type] = by_type.get(event.type, 0) + 1

        return {
            "total_processed": len(self.event_log),
            "failed": len(self.failed_events),
            "by_type": by_type,
            "handlers_registered": len(self.handlers),
        }


# Pre-built handlers for common scenarios
class PaymentHandlers:
    """Pre-built payment event handlers."""

    def __init__(self, processor: WebhookProcessor):
        self.processor = processor
        self._register_handlers()

    def _register_handlers(self):
        @self.processor.on(WebhookEventType.PAYMENT_INTENT_SUCCEEDED)
        async def on_payment_success(event: WebhookEvent, data: dict):
            """Handle successful payment."""
            print(f"💰 Payment succeeded: {data['id']} - ${data['amount'] / 100:.2f}")
            # TODO: Fulfill order, send confirmation email, etc.

        @self.processor.on(WebhookEventType.PAYMENT_INTENT_FAILED)
        async def on_payment_failed(event: WebhookEvent, data: dict):
            """Handle failed payment."""
            print(f"❌ Payment failed: {data['id']}")
            # TODO: Notify customer, retry logic, etc.

        @self.processor.on(WebhookEventType.CHARGE_REFUNDED)
        async def on_refund(event: WebhookEvent, data: dict):
            """Handle refund."""
            print(f"↩️ Refund processed: {data['id']} - ${data['amount_refunded'] / 100:.2f}")
            # TODO: Update order status, inventory, etc.

        @self.processor.on(WebhookEventType.CHARGE_DISPUTED)
        async def on_dispute(event: WebhookEvent, data: dict):
            """Handle dispute/chargeback."""
            print(f"⚠️ Dispute created: {data['id']}")
            # TODO: Alert team, gather evidence, etc.


class SubscriptionHandlers:
    """Pre-built subscription event handlers."""

    def __init__(self, processor: WebhookProcessor):
        self.processor = processor
        self._register_handlers()

    def _register_handlers(self):
        @self.processor.on(WebhookEventType.SUBSCRIPTION_CREATED)
        async def on_sub_created(event: WebhookEvent, data: dict):
            """Handle new subscription."""
            print(f"🎉 New subscription: {data['id']} - {data['status']}")
            # TODO: Provision access, welcome email, etc.

        @self.processor.on(WebhookEventType.SUBSCRIPTION_UPDATED)
        async def on_sub_updated(event: WebhookEvent, data: dict):
            """Handle subscription update."""
            print(f"📝 Subscription updated: {data['id']} - {data['status']}")
            # TODO: Update user permissions based on plan changes

        @self.processor.on(WebhookEventType.SUBSCRIPTION_DELETED)
        async def on_sub_deleted(event: WebhookEvent, data: dict):
            """Handle subscription cancellation."""
            print(f"👋 Subscription cancelled: {data['id']}")
            # TODO: Revoke access, send feedback survey, etc.

        @self.processor.on(WebhookEventType.SUBSCRIPTION_TRIAL_ENDING)
        async def on_trial_ending(event: WebhookEvent, data: dict):
            """Handle trial ending warning."""
            print(f"⏰ Trial ending soon: {data['id']}")
            # TODO: Send reminder email, offer discount, etc.


class InvoiceHandlers:
    """Pre-built invoice event handlers."""

    def __init__(self, processor: WebhookProcessor):
        self.processor = processor
        self._register_handlers()

    def _register_handlers(self):
        @self.processor.on(WebhookEventType.INVOICE_PAID)
        async def on_invoice_paid(event: WebhookEvent, data: dict):
            """Handle paid invoice."""
            print(f"✅ Invoice paid: {data['id']} - ${data['amount_paid'] / 100:.2f}")
            # TODO: Send receipt, update subscription status

        @self.processor.on(WebhookEventType.INVOICE_PAYMENT_FAILED)
        async def on_invoice_failed(event: WebhookEvent, data: dict):
            """Handle failed invoice payment."""
            print(f"❌ Invoice payment failed: {data['id']}")
            # TODO: Send dunning email, retry payment

        @self.processor.on(WebhookEventType.INVOICE_UPCOMING)
        async def on_invoice_upcoming(event: WebhookEvent, data: dict):
            """Handle upcoming invoice notification."""
            print(f"📅 Upcoming invoice: {data['id']}")
            # TODO: Send upcoming charge notification


# Factory function to create processor with all handlers
def create_webhook_processor(
    webhook_secret: str,
    enable_payment_handlers: bool = True,
    enable_subscription_handlers: bool = True,
    enable_invoice_handlers: bool = True,
) -> WebhookProcessor:
    """Create webhook processor with pre-configured handlers."""
    processor = WebhookProcessor(webhook_secret=webhook_secret)

    if enable_payment_handlers:
        PaymentHandlers(processor)

    if enable_subscription_handlers:
        SubscriptionHandlers(processor)

    if enable_invoice_handlers:
        InvoiceHandlers(processor)

    return processor
