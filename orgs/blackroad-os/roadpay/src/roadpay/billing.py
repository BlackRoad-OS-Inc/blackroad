"""
RoadPay Billing - Complete Billing Management

Features:
- Usage-based billing
- Metered subscriptions
- Invoice management
- Payment method management
- Billing history
- Dunning management
"""

from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from enum import Enum
from pydantic import BaseModel
import stripe


class UsageType(str, Enum):
    API_CALLS = "api_calls"
    STORAGE_GB = "storage_gb"
    BANDWIDTH_GB = "bandwidth_gb"
    COMPUTE_HOURS = "compute_hours"
    SEATS = "seats"
    CUSTOM = "custom"


class BillingInterval(str, Enum):
    DAILY = "day"
    WEEKLY = "week"
    MONTHLY = "month"
    YEARLY = "year"


class UsageRecord(BaseModel):
    customer_id: str
    subscription_item_id: str
    quantity: int
    timestamp: Optional[int] = None
    action: str = "increment"  # increment, set


class UsageBasedBilling:
    """
    Handle metered/usage-based billing.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def create_metered_price(
        self,
        product_id: str,
        unit_amount: int,
        currency: str = "usd",
        usage_type: str = "licensed",  # metered, licensed
        aggregate_usage: str = "sum",  # sum, last_during_period, last_ever, max
        billing_scheme: str = "per_unit",  # per_unit, tiered
        tiers: Optional[List[Dict]] = None,
    ) -> Dict[str, Any]:
        """
        Create a metered price for usage-based billing.
        """
        params: Dict[str, Any] = {
            "product": product_id,
            "currency": currency,
            "recurring": {
                "interval": "month",
                "usage_type": usage_type,
            },
            "billing_scheme": billing_scheme,
        }

        if billing_scheme == "per_unit":
            params["unit_amount"] = unit_amount
        elif billing_scheme == "tiered" and tiers:
            params["tiers_mode"] = "graduated"  # or "volume"
            params["tiers"] = tiers

        if usage_type == "metered":
            params["recurring"]["aggregate_usage"] = aggregate_usage

        price = stripe.Price.create(**params)

        return {
            "id": price.id,
            "product": price.product,
            "unit_amount": price.unit_amount,
            "billing_scheme": price.billing_scheme,
            "recurring": {
                "interval": price.recurring.interval,
                "usage_type": price.recurring.usage_type,
            },
        }

    async def report_usage(
        self,
        subscription_item_id: str,
        quantity: int,
        timestamp: Optional[int] = None,
        action: str = "increment",
    ) -> Dict[str, Any]:
        """
        Report usage for a metered subscription.
        """
        import time

        params = {
            "quantity": quantity,
            "timestamp": timestamp or int(time.time()),
            "action": action,
        }

        record = stripe.SubscriptionItem.create_usage_record(
            subscription_item_id,
            **params,
        )

        return {
            "id": record.id,
            "quantity": record.quantity,
            "timestamp": record.timestamp,
            "subscription_item": record.subscription_item,
        }

    async def get_usage_summary(
        self,
        subscription_item_id: str,
    ) -> Dict[str, Any]:
        """
        Get usage summary for current billing period.
        """
        records = stripe.SubscriptionItem.list_usage_record_summaries(
            subscription_item_id,
            limit=1,
        )

        if not records.data:
            return {
                "total_usage": 0,
                "period_start": None,
                "period_end": None,
            }

        summary = records.data[0]
        return {
            "total_usage": summary.total_usage,
            "period_start": summary.period.start,
            "period_end": summary.period.end,
            "invoice": summary.invoice,
        }

    async def create_usage_alert(
        self,
        subscription_item_id: str,
        threshold: int,
        webhook_url: str,
    ) -> Dict[str, Any]:
        """
        Create a usage alert (via billing threshold on customer).
        Note: Stripe alerts are limited, implementing custom tracking is better.
        """
        # Store alert config in metadata
        item = stripe.SubscriptionItem.modify(
            subscription_item_id,
            metadata={
                "usage_alert_threshold": str(threshold),
                "usage_alert_webhook": webhook_url,
            },
        )

        return {
            "subscription_item_id": subscription_item_id,
            "threshold": threshold,
            "webhook_url": webhook_url,
            "created": True,
        }


class PaymentMethodManager:
    """
    Manage customer payment methods.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def list_payment_methods(
        self,
        customer_id: str,
        type: str = "card",
    ) -> List[Dict[str, Any]]:
        """
        List customer's payment methods.
        """
        methods = stripe.PaymentMethod.list(
            customer=customer_id,
            type=type,
        )

        # Get default payment method
        customer = stripe.Customer.retrieve(customer_id)
        default_pm = customer.invoice_settings.default_payment_method

        return [
            {
                "id": pm.id,
                "type": pm.type,
                "card": {
                    "brand": pm.card.brand,
                    "last4": pm.card.last4,
                    "exp_month": pm.card.exp_month,
                    "exp_year": pm.card.exp_year,
                } if pm.card else None,
                "is_default": pm.id == default_pm,
                "created": pm.created,
            }
            for pm in methods.data
        ]

    async def add_payment_method(
        self,
        customer_id: str,
        payment_method_id: str,
        set_default: bool = True,
    ) -> Dict[str, Any]:
        """
        Attach a payment method to a customer.
        """
        # Attach to customer
        pm = stripe.PaymentMethod.attach(
            payment_method_id,
            customer=customer_id,
        )

        # Set as default if requested
        if set_default:
            stripe.Customer.modify(
                customer_id,
                invoice_settings={
                    "default_payment_method": payment_method_id,
                },
            )

        return {
            "id": pm.id,
            "type": pm.type,
            "card": {
                "brand": pm.card.brand,
                "last4": pm.card.last4,
                "exp_month": pm.card.exp_month,
                "exp_year": pm.card.exp_year,
            } if pm.card else None,
            "is_default": set_default,
        }

    async def remove_payment_method(
        self,
        payment_method_id: str,
    ) -> bool:
        """
        Detach a payment method.
        """
        try:
            stripe.PaymentMethod.detach(payment_method_id)
            return True
        except stripe.error.StripeError:
            return False

    async def set_default_payment_method(
        self,
        customer_id: str,
        payment_method_id: str,
    ) -> bool:
        """
        Set default payment method.
        """
        try:
            stripe.Customer.modify(
                customer_id,
                invoice_settings={
                    "default_payment_method": payment_method_id,
                },
            )
            return True
        except stripe.error.StripeError:
            return False

    async def create_setup_intent(
        self,
        customer_id: str,
    ) -> Dict[str, Any]:
        """
        Create a SetupIntent for adding a new card.
        """
        intent = stripe.SetupIntent.create(
            customer=customer_id,
            payment_method_types=["card"],
        )

        return {
            "id": intent.id,
            "client_secret": intent.client_secret,
            "status": intent.status,
        }


class InvoiceManager:
    """
    Manage invoices and billing history.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def list_invoices(
        self,
        customer_id: str,
        limit: int = 10,
        status: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        List customer invoices.
        """
        params: Dict[str, Any] = {
            "customer": customer_id,
            "limit": limit,
        }

        if status:
            params["status"] = status

        invoices = stripe.Invoice.list(**params)

        return [
            {
                "id": inv.id,
                "number": inv.number,
                "status": inv.status,
                "amount_due": inv.amount_due,
                "amount_paid": inv.amount_paid,
                "currency": inv.currency,
                "created": inv.created,
                "due_date": inv.due_date,
                "paid_at": inv.status_transitions.paid_at if inv.status_transitions else None,
                "hosted_invoice_url": inv.hosted_invoice_url,
                "invoice_pdf": inv.invoice_pdf,
                "lines": [
                    {
                        "description": line.description,
                        "amount": line.amount,
                        "quantity": line.quantity,
                    }
                    for line in inv.lines.data[:5]  # First 5 lines
                ],
            }
            for inv in invoices.data
        ]

    async def get_upcoming_invoice(
        self,
        customer_id: str,
        subscription_id: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Get upcoming invoice preview.
        """
        try:
            params: Dict[str, Any] = {"customer": customer_id}
            if subscription_id:
                params["subscription"] = subscription_id

            invoice = stripe.Invoice.upcoming(**params)

            return {
                "amount_due": invoice.amount_due,
                "currency": invoice.currency,
                "period_start": invoice.period_start,
                "period_end": invoice.period_end,
                "lines": [
                    {
                        "description": line.description,
                        "amount": line.amount,
                        "quantity": line.quantity,
                        "proration": line.proration,
                    }
                    for line in invoice.lines.data
                ],
                "subtotal": invoice.subtotal,
                "tax": invoice.tax,
                "total": invoice.total,
            }
        except stripe.error.InvalidRequestError:
            return None

    async def pay_invoice(
        self,
        invoice_id: str,
        payment_method_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Pay an open invoice.
        """
        params: Dict[str, Any] = {}
        if payment_method_id:
            params["payment_method"] = payment_method_id

        invoice = stripe.Invoice.pay(invoice_id, **params)

        return {
            "id": invoice.id,
            "status": invoice.status,
            "amount_paid": invoice.amount_paid,
            "paid": invoice.paid,
        }

    async def void_invoice(self, invoice_id: str) -> bool:
        """
        Void an open invoice.
        """
        try:
            stripe.Invoice.void_invoice(invoice_id)
            return True
        except stripe.error.StripeError:
            return False

    async def send_invoice(self, invoice_id: str) -> bool:
        """
        Send invoice email to customer.
        """
        try:
            stripe.Invoice.send_invoice(invoice_id)
            return True
        except stripe.error.StripeError:
            return False


class SubscriptionManager:
    """
    Advanced subscription management.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def change_plan(
        self,
        subscription_id: str,
        new_price_id: str,
        proration_behavior: str = "create_prorations",  # create_prorations, none, always_invoice
    ) -> Dict[str, Any]:
        """
        Change subscription plan (upgrade/downgrade).
        """
        # Get current subscription
        subscription = stripe.Subscription.retrieve(subscription_id)
        current_item = subscription["items"]["data"][0]

        # Update subscription
        updated = stripe.Subscription.modify(
            subscription_id,
            items=[
                {
                    "id": current_item.id,
                    "price": new_price_id,
                }
            ],
            proration_behavior=proration_behavior,
        )

        return {
            "id": updated.id,
            "status": updated.status,
            "current_period_end": updated.current_period_end,
            "items": [
                {
                    "id": item.id,
                    "price_id": item.price.id,
                }
                for item in updated["items"]["data"]
            ],
        }

    async def add_addon(
        self,
        subscription_id: str,
        price_id: str,
        quantity: int = 1,
    ) -> Dict[str, Any]:
        """
        Add an addon to existing subscription.
        """
        item = stripe.SubscriptionItem.create(
            subscription=subscription_id,
            price=price_id,
            quantity=quantity,
        )

        return {
            "id": item.id,
            "price_id": item.price.id,
            "quantity": item.quantity,
        }

    async def remove_addon(
        self,
        subscription_item_id: str,
        proration_behavior: str = "create_prorations",
    ) -> bool:
        """
        Remove an addon from subscription.
        """
        try:
            stripe.SubscriptionItem.delete(
                subscription_item_id,
                proration_behavior=proration_behavior,
            )
            return True
        except stripe.error.StripeError:
            return False

    async def pause_subscription(
        self,
        subscription_id: str,
        resume_at: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Pause a subscription.
        """
        params: Dict[str, Any] = {
            "pause_collection": {
                "behavior": "void",  # void, keep_as_draft, mark_uncollectible
            }
        }

        if resume_at:
            params["pause_collection"]["resumes_at"] = resume_at

        subscription = stripe.Subscription.modify(subscription_id, **params)

        return {
            "id": subscription.id,
            "status": subscription.status,
            "pause_collection": subscription.pause_collection,
        }

    async def resume_subscription(
        self,
        subscription_id: str,
    ) -> Dict[str, Any]:
        """
        Resume a paused subscription.
        """
        subscription = stripe.Subscription.modify(
            subscription_id,
            pause_collection="",  # Empty string to clear
        )

        return {
            "id": subscription.id,
            "status": subscription.status,
        }

    async def get_subscription_details(
        self,
        subscription_id: str,
    ) -> Dict[str, Any]:
        """
        Get detailed subscription information.
        """
        subscription = stripe.Subscription.retrieve(
            subscription_id,
            expand=["customer", "default_payment_method", "latest_invoice"],
        )

        return {
            "id": subscription.id,
            "status": subscription.status,
            "created": subscription.created,
            "current_period_start": subscription.current_period_start,
            "current_period_end": subscription.current_period_end,
            "cancel_at_period_end": subscription.cancel_at_period_end,
            "canceled_at": subscription.canceled_at,
            "trial_start": subscription.trial_start,
            "trial_end": subscription.trial_end,
            "customer": {
                "id": subscription.customer.id,
                "email": subscription.customer.email,
            } if hasattr(subscription.customer, 'id') else {"id": subscription.customer},
            "items": [
                {
                    "id": item.id,
                    "price_id": item.price.id,
                    "product_id": item.price.product,
                    "quantity": item.quantity,
                }
                for item in subscription["items"]["data"]
            ],
            "default_payment_method": {
                "id": subscription.default_payment_method.id,
                "type": subscription.default_payment_method.type,
                "card": {
                    "brand": subscription.default_payment_method.card.brand,
                    "last4": subscription.default_payment_method.card.last4,
                } if subscription.default_payment_method and subscription.default_payment_method.card else None,
            } if subscription.default_payment_method else None,
            "latest_invoice": {
                "id": subscription.latest_invoice.id,
                "status": subscription.latest_invoice.status,
                "amount_due": subscription.latest_invoice.amount_due,
            } if subscription.latest_invoice else None,
        }


class DunningManager:
    """
    Handle failed payment recovery.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def get_past_due_subscriptions(
        self,
        limit: int = 100,
    ) -> List[Dict[str, Any]]:
        """
        Get subscriptions with past due payments.
        """
        subscriptions = stripe.Subscription.list(
            status="past_due",
            limit=limit,
            expand=["data.customer", "data.latest_invoice"],
        )

        return [
            {
                "id": sub.id,
                "customer_id": sub.customer.id if hasattr(sub.customer, 'id') else sub.customer,
                "customer_email": sub.customer.email if hasattr(sub.customer, 'email') else None,
                "status": sub.status,
                "current_period_end": sub.current_period_end,
                "latest_invoice": {
                    "id": sub.latest_invoice.id,
                    "amount_due": sub.latest_invoice.amount_due,
                    "attempt_count": sub.latest_invoice.attempt_count,
                    "next_payment_attempt": sub.latest_invoice.next_payment_attempt,
                } if sub.latest_invoice else None,
            }
            for sub in subscriptions.data
        ]

    async def retry_payment(
        self,
        invoice_id: str,
    ) -> Dict[str, Any]:
        """
        Retry a failed invoice payment.
        """
        try:
            invoice = stripe.Invoice.pay(invoice_id)
            return {
                "success": invoice.paid,
                "invoice_id": invoice.id,
                "status": invoice.status,
                "amount_paid": invoice.amount_paid,
            }
        except stripe.error.CardError as e:
            return {
                "success": False,
                "error": str(e),
                "decline_code": e.error.decline_code if e.error else None,
            }

    async def update_card_and_retry(
        self,
        customer_id: str,
        payment_method_id: str,
        invoice_id: str,
    ) -> Dict[str, Any]:
        """
        Update payment method and retry failed payment.
        """
        # Set new default payment method
        stripe.Customer.modify(
            customer_id,
            invoice_settings={
                "default_payment_method": payment_method_id,
            },
        )

        # Retry payment
        return await self.retry_payment(invoice_id)
