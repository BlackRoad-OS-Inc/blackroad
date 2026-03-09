"""
RoadPay Event System

Comprehensive webhook event handling and event-driven notifications.

Features:
- Type-safe event handling
- Event routing
- Retry logic
- Dead letter queue
- Event logging
- Notification triggers
"""

from typing import Optional, Dict, Any, List, Callable, Awaitable
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from abc import ABC, abstractmethod
import hashlib
import hmac
import json
import stripe


class EventType(str, Enum):
    # Checkout events
    CHECKOUT_SESSION_COMPLETED = "checkout.session.completed"
    CHECKOUT_SESSION_EXPIRED = "checkout.session.expired"
    CHECKOUT_SESSION_ASYNC_PAYMENT_SUCCEEDED = "checkout.session.async_payment_succeeded"
    CHECKOUT_SESSION_ASYNC_PAYMENT_FAILED = "checkout.session.async_payment_failed"

    # Subscription events
    SUBSCRIPTION_CREATED = "customer.subscription.created"
    SUBSCRIPTION_UPDATED = "customer.subscription.updated"
    SUBSCRIPTION_DELETED = "customer.subscription.deleted"
    SUBSCRIPTION_TRIAL_WILL_END = "customer.subscription.trial_will_end"
    SUBSCRIPTION_PAUSED = "customer.subscription.paused"
    SUBSCRIPTION_RESUMED = "customer.subscription.resumed"

    # Invoice events
    INVOICE_CREATED = "invoice.created"
    INVOICE_FINALIZED = "invoice.finalized"
    INVOICE_PAID = "invoice.paid"
    INVOICE_PAYMENT_FAILED = "invoice.payment_failed"
    INVOICE_PAYMENT_ACTION_REQUIRED = "invoice.payment_action_required"
    INVOICE_UPCOMING = "invoice.upcoming"
    INVOICE_MARKED_UNCOLLECTIBLE = "invoice.marked_uncollectible"
    INVOICE_VOIDED = "invoice.voided"

    # Payment events
    PAYMENT_INTENT_SUCCEEDED = "payment_intent.succeeded"
    PAYMENT_INTENT_FAILED = "payment_intent.payment_failed"
    PAYMENT_INTENT_REQUIRES_ACTION = "payment_intent.requires_action"

    # Charge events
    CHARGE_SUCCEEDED = "charge.succeeded"
    CHARGE_FAILED = "charge.failed"
    CHARGE_REFUNDED = "charge.refunded"
    CHARGE_DISPUTE_CREATED = "charge.dispute.created"
    CHARGE_DISPUTE_CLOSED = "charge.dispute.closed"

    # Customer events
    CUSTOMER_CREATED = "customer.created"
    CUSTOMER_UPDATED = "customer.updated"
    CUSTOMER_DELETED = "customer.deleted"

    # Payment method events
    PAYMENT_METHOD_ATTACHED = "payment_method.attached"
    PAYMENT_METHOD_DETACHED = "payment_method.detached"
    PAYMENT_METHOD_UPDATED = "payment_method.updated"

    # Price and product events
    PRODUCT_CREATED = "product.created"
    PRODUCT_UPDATED = "product.updated"
    PRICE_CREATED = "price.created"
    PRICE_UPDATED = "price.updated"


@dataclass
class ProcessedEvent:
    event_id: str
    event_type: str
    processed_at: int
    success: bool
    error: Optional[str] = None
    retry_count: int = 0
    data: Dict[str, Any] = field(default_factory=dict)


class EventHandler(ABC):
    """Base class for event handlers."""

    @abstractmethod
    async def handle(self, event: stripe.Event) -> Dict[str, Any]:
        """Handle the event."""
        pass

    @property
    @abstractmethod
    def event_types(self) -> List[EventType]:
        """List of event types this handler processes."""
        pass


class CheckoutEventHandler(EventHandler):
    """Handle checkout session events."""

    def __init__(self, storage, notification_service=None):
        self.storage = storage
        self.notifications = notification_service

    @property
    def event_types(self) -> List[EventType]:
        return [
            EventType.CHECKOUT_SESSION_COMPLETED,
            EventType.CHECKOUT_SESSION_EXPIRED,
        ]

    async def handle(self, event: stripe.Event) -> Dict[str, Any]:
        session = event.data.object

        if event.type == EventType.CHECKOUT_SESSION_COMPLETED.value:
            return await self._handle_completed(session)
        elif event.type == EventType.CHECKOUT_SESSION_EXPIRED.value:
            return await self._handle_expired(session)

        return {"handled": False}

    async def _handle_completed(self, session) -> Dict[str, Any]:
        # Store successful checkout
        await self.storage.put(f"checkout:{session.id}", {
            "customer_id": session.customer,
            "subscription_id": session.subscription,
            "amount_total": session.amount_total,
            "completed_at": datetime.utcnow().isoformat(),
        })

        # Send notification
        if self.notifications and session.customer_details:
            await self.notifications.send_welcome(
                email=session.customer_details.email,
                customer_id=session.customer,
            )

        return {
            "handled": True,
            "customer_id": session.customer,
            "subscription_id": session.subscription,
        }

    async def _handle_expired(self, session) -> Dict[str, Any]:
        # Track abandoned cart
        if session.customer_details and session.customer_details.email:
            await self.storage.put(f"abandoned:{session.id}", {
                "email": session.customer_details.email,
                "amount": session.amount_total,
                "expired_at": datetime.utcnow().isoformat(),
            })

        return {"handled": True, "action": "tracked_abandoned"}


class SubscriptionEventHandler(EventHandler):
    """Handle subscription lifecycle events."""

    def __init__(self, storage, notification_service=None):
        self.storage = storage
        self.notifications = notification_service

    @property
    def event_types(self) -> List[EventType]:
        return [
            EventType.SUBSCRIPTION_CREATED,
            EventType.SUBSCRIPTION_UPDATED,
            EventType.SUBSCRIPTION_DELETED,
            EventType.SUBSCRIPTION_TRIAL_WILL_END,
        ]

    async def handle(self, event: stripe.Event) -> Dict[str, Any]:
        subscription = event.data.object

        if event.type == EventType.SUBSCRIPTION_CREATED.value:
            return await self._handle_created(subscription)
        elif event.type == EventType.SUBSCRIPTION_UPDATED.value:
            return await self._handle_updated(subscription, event.data.previous_attributes)
        elif event.type == EventType.SUBSCRIPTION_DELETED.value:
            return await self._handle_deleted(subscription)
        elif event.type == EventType.SUBSCRIPTION_TRIAL_WILL_END.value:
            return await self._handle_trial_ending(subscription)

        return {"handled": False}

    async def _handle_created(self, subscription) -> Dict[str, Any]:
        # Store subscription
        await self.storage.put(f"subscription:{subscription.id}", {
            "customer_id": subscription.customer,
            "status": subscription.status,
            "plan_id": subscription.items.data[0].price.id if subscription.items.data else None,
            "created_at": datetime.utcnow().isoformat(),
        })

        return {"handled": True, "subscription_id": subscription.id}

    async def _handle_updated(self, subscription, previous) -> Dict[str, Any]:
        changes = []

        # Check for plan change
        if previous and "items" in previous:
            changes.append("plan_changed")

        # Check for status change
        if previous and "status" in previous:
            old_status = previous["status"]
            new_status = subscription.status
            changes.append(f"status:{old_status}->{new_status}")

            # Handle specific status transitions
            if old_status == "active" and new_status == "past_due":
                if self.notifications:
                    customer = stripe.Customer.retrieve(subscription.customer)
                    await self.notifications.send_payment_failed(
                        email=customer.email,
                        subscription_id=subscription.id,
                    )

        # Update stored subscription
        await self.storage.put(f"subscription:{subscription.id}", {
            "customer_id": subscription.customer,
            "status": subscription.status,
            "updated_at": datetime.utcnow().isoformat(),
            "changes": changes,
        })

        return {"handled": True, "changes": changes}

    async def _handle_deleted(self, subscription) -> Dict[str, Any]:
        # Mark subscription as cancelled
        await self.storage.put(f"subscription:{subscription.id}", {
            "customer_id": subscription.customer,
            "status": "canceled",
            "canceled_at": datetime.utcnow().isoformat(),
        })

        # Send churn notification
        if self.notifications:
            customer = stripe.Customer.retrieve(subscription.customer)
            await self.notifications.send_cancellation_confirmation(
                email=customer.email,
                subscription_id=subscription.id,
            )

        return {"handled": True, "action": "subscription_canceled"}

    async def _handle_trial_ending(self, subscription) -> Dict[str, Any]:
        # Send trial ending notification
        if self.notifications:
            customer = stripe.Customer.retrieve(subscription.customer)
            await self.notifications.send_trial_ending(
                email=customer.email,
                trial_end=subscription.trial_end,
            )

        return {"handled": True, "action": "trial_ending_notified"}


class InvoiceEventHandler(EventHandler):
    """Handle invoice events."""

    def __init__(self, storage, notification_service=None):
        self.storage = storage
        self.notifications = notification_service

    @property
    def event_types(self) -> List[EventType]:
        return [
            EventType.INVOICE_PAID,
            EventType.INVOICE_PAYMENT_FAILED,
            EventType.INVOICE_UPCOMING,
            EventType.INVOICE_MARKED_UNCOLLECTIBLE,
        ]

    async def handle(self, event: stripe.Event) -> Dict[str, Any]:
        invoice = event.data.object

        if event.type == EventType.INVOICE_PAID.value:
            return await self._handle_paid(invoice)
        elif event.type == EventType.INVOICE_PAYMENT_FAILED.value:
            return await self._handle_failed(invoice)
        elif event.type == EventType.INVOICE_UPCOMING.value:
            return await self._handle_upcoming(invoice)
        elif event.type == EventType.INVOICE_MARKED_UNCOLLECTIBLE.value:
            return await self._handle_uncollectible(invoice)

        return {"handled": False}

    async def _handle_paid(self, invoice) -> Dict[str, Any]:
        # Store payment
        await self.storage.put(f"payment:{invoice.id}", {
            "customer_id": invoice.customer,
            "amount": invoice.amount_paid,
            "currency": invoice.currency,
            "paid_at": datetime.utcnow().isoformat(),
        })

        # Send receipt
        if self.notifications and invoice.customer_email:
            await self.notifications.send_receipt(
                email=invoice.customer_email,
                invoice_id=invoice.id,
                amount=invoice.amount_paid,
                hosted_url=invoice.hosted_invoice_url,
            )

        return {"handled": True, "amount_paid": invoice.amount_paid}

    async def _handle_failed(self, invoice) -> Dict[str, Any]:
        # Track failure
        await self.storage.put(f"payment_failed:{invoice.id}", {
            "customer_id": invoice.customer,
            "amount": invoice.amount_due,
            "attempt_count": invoice.attempt_count,
            "failed_at": datetime.utcnow().isoformat(),
        })

        # Notify customer
        if self.notifications and invoice.customer_email:
            await self.notifications.send_payment_failed(
                email=invoice.customer_email,
                invoice_id=invoice.id,
                amount=invoice.amount_due,
            )

        return {"handled": True, "action": "payment_failed_notified"}

    async def _handle_upcoming(self, invoice) -> Dict[str, Any]:
        # Notify about upcoming invoice
        if self.notifications and invoice.customer_email:
            await self.notifications.send_upcoming_invoice(
                email=invoice.customer_email,
                amount=invoice.amount_due,
                due_date=invoice.due_date,
            )

        return {"handled": True, "action": "upcoming_notified"}

    async def _handle_uncollectible(self, invoice) -> Dict[str, Any]:
        # Mark as uncollectible and potentially suspend service
        await self.storage.put(f"uncollectible:{invoice.id}", {
            "customer_id": invoice.customer,
            "amount": invoice.amount_due,
            "marked_at": datetime.utcnow().isoformat(),
        })

        return {"handled": True, "action": "marked_uncollectible"}


class DisputeEventHandler(EventHandler):
    """Handle charge dispute events."""

    def __init__(self, storage, notification_service=None):
        self.storage = storage
        self.notifications = notification_service

    @property
    def event_types(self) -> List[EventType]:
        return [
            EventType.CHARGE_DISPUTE_CREATED,
            EventType.CHARGE_DISPUTE_CLOSED,
        ]

    async def handle(self, event: stripe.Event) -> Dict[str, Any]:
        dispute = event.data.object

        if event.type == EventType.CHARGE_DISPUTE_CREATED.value:
            return await self._handle_created(dispute)
        elif event.type == EventType.CHARGE_DISPUTE_CLOSED.value:
            return await self._handle_closed(dispute)

        return {"handled": False}

    async def _handle_created(self, dispute) -> Dict[str, Any]:
        # Store dispute - this is critical!
        await self.storage.put(f"dispute:{dispute.id}", {
            "charge_id": dispute.charge,
            "amount": dispute.amount,
            "reason": dispute.reason,
            "status": dispute.status,
            "created_at": datetime.utcnow().isoformat(),
            "evidence_due_by": dispute.evidence_details.due_by if dispute.evidence_details else None,
        })

        # Alert admin immediately
        if self.notifications:
            await self.notifications.send_admin_alert(
                subject=f"URGENT: Dispute opened for ${dispute.amount / 100:.2f}",
                message=f"Dispute reason: {dispute.reason}. Evidence due by: {dispute.evidence_details.due_by if dispute.evidence_details else 'N/A'}",
            )

        return {"handled": True, "action": "dispute_alert_sent"}

    async def _handle_closed(self, dispute) -> Dict[str, Any]:
        # Update dispute status
        await self.storage.put(f"dispute:{dispute.id}", {
            "status": dispute.status,
            "closed_at": datetime.utcnow().isoformat(),
        })

        return {"handled": True, "status": dispute.status}


class EventRouter:
    """
    Routes events to appropriate handlers.
    """

    def __init__(self, webhook_secret: str, storage):
        self.webhook_secret = webhook_secret
        self.storage = storage
        self.handlers: Dict[str, EventHandler] = {}

    def register_handler(self, handler: EventHandler) -> None:
        """Register an event handler."""
        for event_type in handler.event_types:
            self.handlers[event_type.value] = handler

    async def process_webhook(
        self,
        payload: bytes,
        signature: str,
    ) -> Dict[str, Any]:
        """
        Process incoming webhook.
        """
        import time

        # Verify signature
        try:
            event = stripe.Webhook.construct_event(
                payload,
                signature,
                self.webhook_secret,
            )
        except ValueError:
            return {"error": "Invalid payload", "status": 400}
        except stripe.error.SignatureVerificationError:
            return {"error": "Invalid signature", "status": 401}

        # Check for duplicate
        event_key = f"event:{event.id}"
        existing = await self.storage.get(event_key)
        if existing:
            return {"status": "already_processed", "event_id": event.id}

        # Route to handler
        handler = self.handlers.get(event.type)
        if not handler:
            # No handler registered - acknowledge but don't process
            return {"status": "unhandled", "event_type": event.type}

        # Process event
        try:
            result = await handler.handle(event)

            # Mark as processed
            processed = ProcessedEvent(
                event_id=event.id,
                event_type=event.type,
                processed_at=int(time.time()),
                success=True,
                data=result,
            )

            await self.storage.put(event_key, {
                "event_id": processed.event_id,
                "event_type": processed.event_type,
                "processed_at": processed.processed_at,
                "success": processed.success,
                "data": processed.data,
            })

            return {"status": "processed", "event_id": event.id, "result": result}

        except Exception as e:
            # Log failure
            processed = ProcessedEvent(
                event_id=event.id,
                event_type=event.type,
                processed_at=int(time.time()),
                success=False,
                error=str(e),
            )

            await self.storage.put(f"failed:{event.id}", {
                "event_id": processed.event_id,
                "event_type": processed.event_type,
                "error": processed.error,
                "failed_at": processed.processed_at,
            })

            raise


class NotificationService:
    """
    Send notifications to customers.
    """

    def __init__(self, email_sender):
        self.email_sender = email_sender

    async def send_welcome(self, email: str, customer_id: str) -> None:
        await self.email_sender.send(
            to=email,
            subject="Welcome!",
            template="welcome",
            data={"customer_id": customer_id},
        )

    async def send_receipt(
        self,
        email: str,
        invoice_id: str,
        amount: int,
        hosted_url: str,
    ) -> None:
        await self.email_sender.send(
            to=email,
            subject=f"Receipt for your payment of ${amount / 100:.2f}",
            template="receipt",
            data={
                "invoice_id": invoice_id,
                "amount": amount,
                "hosted_url": hosted_url,
            },
        )

    async def send_payment_failed(
        self,
        email: str,
        invoice_id: Optional[str] = None,
        subscription_id: Optional[str] = None,
        amount: Optional[int] = None,
    ) -> None:
        await self.email_sender.send(
            to=email,
            subject="Action required: Payment failed",
            template="payment_failed",
            data={
                "invoice_id": invoice_id,
                "subscription_id": subscription_id,
                "amount": amount,
            },
        )

    async def send_trial_ending(self, email: str, trial_end: int) -> None:
        from datetime import datetime
        trial_end_date = datetime.fromtimestamp(trial_end).strftime("%B %d, %Y")

        await self.email_sender.send(
            to=email,
            subject="Your trial is ending soon",
            template="trial_ending",
            data={"trial_end_date": trial_end_date},
        )

    async def send_cancellation_confirmation(
        self,
        email: str,
        subscription_id: str,
    ) -> None:
        await self.email_sender.send(
            to=email,
            subject="Your subscription has been cancelled",
            template="cancellation",
            data={"subscription_id": subscription_id},
        )

    async def send_upcoming_invoice(
        self,
        email: str,
        amount: int,
        due_date: int,
    ) -> None:
        from datetime import datetime
        due = datetime.fromtimestamp(due_date).strftime("%B %d, %Y")

        await self.email_sender.send(
            to=email,
            subject=f"Upcoming invoice: ${amount / 100:.2f}",
            template="upcoming_invoice",
            data={"amount": amount, "due_date": due},
        )

    async def send_admin_alert(self, subject: str, message: str) -> None:
        # Send to admin email
        await self.email_sender.send(
            to="admin@example.com",  # Configure this
            subject=f"[ALERT] {subject}",
            template="admin_alert",
            data={"message": message},
        )


def create_event_router(
    webhook_secret: str,
    storage,
    email_sender=None,
) -> EventRouter:
    """
    Create fully configured event router.
    """
    router = EventRouter(webhook_secret, storage)

    # Create notification service if email sender provided
    notifications = NotificationService(email_sender) if email_sender else None

    # Register all handlers
    router.register_handler(CheckoutEventHandler(storage, notifications))
    router.register_handler(SubscriptionEventHandler(storage, notifications))
    router.register_handler(InvoiceEventHandler(storage, notifications))
    router.register_handler(DisputeEventHandler(storage, notifications))

    return router
