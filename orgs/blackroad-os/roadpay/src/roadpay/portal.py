"""
RoadPay Customer Portal

Dashboard data and customer self-service portal.

Features:
- Customer dashboard data
- Usage metrics
- Invoice history
- Payment method management
- Subscription overview
- Account settings
"""

from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
import stripe


class TimeRange(str, Enum):
    DAY = "day"
    WEEK = "week"
    MONTH = "month"
    YEAR = "year"
    ALL = "all"


@dataclass
class DashboardMetrics:
    total_revenue: int
    mrr: int  # Monthly recurring revenue
    active_subscriptions: int
    total_customers: int
    churn_rate: float
    average_revenue_per_user: int

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_revenue": self.total_revenue,
            "mrr": self.mrr,
            "active_subscriptions": self.active_subscriptions,
            "total_customers": self.total_customers,
            "churn_rate": self.churn_rate,
            "arpu": self.average_revenue_per_user,
        }


class CustomerPortal:
    """
    Customer-facing portal with dashboard data.
    """

    def __init__(self, stripe_key: str, portal_configuration_id: Optional[str] = None):
        stripe.api_key = stripe_key
        self.portal_config_id = portal_configuration_id

    async def create_portal_session(
        self,
        customer_id: str,
        return_url: str,
    ) -> Dict[str, Any]:
        """
        Create a Stripe Customer Portal session.
        """
        params: Dict[str, Any] = {
            "customer": customer_id,
            "return_url": return_url,
        }

        if self.portal_config_id:
            params["configuration"] = self.portal_config_id

        session = stripe.billing_portal.Session.create(**params)

        return {
            "url": session.url,
            "id": session.id,
            "customer": session.customer,
            "return_url": session.return_url,
        }

    async def get_customer_dashboard(
        self,
        customer_id: str,
    ) -> Dict[str, Any]:
        """
        Get complete dashboard data for a customer.
        """
        # Get customer
        customer = stripe.Customer.retrieve(
            customer_id,
            expand=["subscriptions", "default_source"],
        )

        # Get recent invoices
        invoices = stripe.Invoice.list(
            customer=customer_id,
            limit=10,
        )

        # Get payment methods
        payment_methods = stripe.PaymentMethod.list(
            customer=customer_id,
            type="card",
        )

        # Calculate totals
        total_paid = sum(
            inv.amount_paid for inv in invoices.data
            if inv.status == "paid"
        )

        # Active subscriptions
        active_subs = [
            sub for sub in customer.subscriptions.data
            if sub.status in ("active", "trialing")
        ]

        return {
            "customer": {
                "id": customer.id,
                "email": customer.email,
                "name": customer.name,
                "created": customer.created,
                "balance": customer.balance,
                "currency": customer.currency or "usd",
            },
            "subscriptions": [
                {
                    "id": sub.id,
                    "status": sub.status,
                    "plan": sub.items.data[0].price.id if sub.items.data else None,
                    "amount": sub.items.data[0].price.unit_amount if sub.items.data else 0,
                    "interval": sub.items.data[0].price.recurring.interval if sub.items.data and sub.items.data[0].price.recurring else None,
                    "current_period_end": sub.current_period_end,
                    "cancel_at_period_end": sub.cancel_at_period_end,
                    "trial_end": sub.trial_end,
                }
                for sub in active_subs
            ],
            "invoices": [
                {
                    "id": inv.id,
                    "number": inv.number,
                    "status": inv.status,
                    "amount_due": inv.amount_due,
                    "amount_paid": inv.amount_paid,
                    "currency": inv.currency,
                    "created": inv.created,
                    "due_date": inv.due_date,
                    "hosted_invoice_url": inv.hosted_invoice_url,
                    "invoice_pdf": inv.invoice_pdf,
                }
                for inv in invoices.data
            ],
            "payment_methods": [
                {
                    "id": pm.id,
                    "type": pm.type,
                    "brand": pm.card.brand if pm.card else None,
                    "last4": pm.card.last4 if pm.card else None,
                    "exp_month": pm.card.exp_month if pm.card else None,
                    "exp_year": pm.card.exp_year if pm.card else None,
                    "is_default": pm.id == customer.invoice_settings.default_payment_method if customer.invoice_settings else False,
                }
                for pm in payment_methods.data
            ],
            "stats": {
                "total_paid": total_paid,
                "active_subscriptions": len(active_subs),
                "next_invoice_date": active_subs[0].current_period_end if active_subs else None,
            },
        }

    async def get_usage_summary(
        self,
        customer_id: str,
        subscription_item_id: str,
    ) -> Dict[str, Any]:
        """
        Get usage summary for metered billing.
        """
        # Get current period usage
        usage = stripe.SubscriptionItem.list_usage_record_summaries(
            subscription_item_id,
            limit=12,  # Last 12 periods
        )

        return {
            "subscription_item_id": subscription_item_id,
            "summaries": [
                {
                    "period_start": summary.period.start,
                    "period_end": summary.period.end,
                    "total_usage": summary.total_usage,
                }
                for summary in usage.data
            ],
        }

    async def get_invoice_history(
        self,
        customer_id: str,
        limit: int = 25,
        starting_after: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get paginated invoice history.
        """
        params: Dict[str, Any] = {
            "customer": customer_id,
            "limit": limit,
        }

        if starting_after:
            params["starting_after"] = starting_after

        invoices = stripe.Invoice.list(**params)

        return {
            "invoices": [
                {
                    "id": inv.id,
                    "number": inv.number,
                    "status": inv.status,
                    "amount_due": inv.amount_due,
                    "amount_paid": inv.amount_paid,
                    "amount_remaining": inv.amount_remaining,
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
                        for line in inv.lines.data[:5]  # First 5 line items
                    ],
                }
                for inv in invoices.data
            ],
            "has_more": invoices.has_more,
        }

    async def download_invoice(
        self,
        invoice_id: str,
        customer_id: str,
    ) -> Optional[str]:
        """
        Get invoice PDF URL (with verification).
        """
        invoice = stripe.Invoice.retrieve(invoice_id)

        # Verify customer owns this invoice
        if invoice.customer != customer_id:
            return None

        return invoice.invoice_pdf


class AnalyticsDashboard:
    """
    Business analytics dashboard for operators.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def get_revenue_metrics(
        self,
        time_range: TimeRange = TimeRange.MONTH,
    ) -> Dict[str, Any]:
        """
        Get revenue metrics for dashboard.
        """
        import time

        # Calculate time bounds
        now = int(time.time())
        if time_range == TimeRange.DAY:
            start = now - 86400
        elif time_range == TimeRange.WEEK:
            start = now - 86400 * 7
        elif time_range == TimeRange.MONTH:
            start = now - 86400 * 30
        elif time_range == TimeRange.YEAR:
            start = now - 86400 * 365
        else:
            start = 0

        # Get charges in range
        charges = stripe.Charge.list(
            created={"gte": start},
            limit=100,
        )

        # Calculate metrics
        total_revenue = sum(c.amount for c in charges.data if c.paid)
        successful_charges = len([c for c in charges.data if c.paid])
        failed_charges = len([c for c in charges.data if c.status == "failed"])

        # Get subscriptions
        subscriptions = stripe.Subscription.list(
            status="active",
            limit=100,
        )

        # Calculate MRR
        mrr = 0
        for sub in subscriptions.data:
            for item in sub.items.data:
                if item.price.recurring:
                    amount = item.price.unit_amount * item.quantity
                    if item.price.recurring.interval == "year":
                        amount = amount // 12
                    elif item.price.recurring.interval == "week":
                        amount = amount * 4
                    mrr += amount

        return {
            "time_range": time_range.value,
            "total_revenue": total_revenue,
            "mrr": mrr,
            "arr": mrr * 12,  # Annual recurring revenue
            "successful_charges": successful_charges,
            "failed_charges": failed_charges,
            "success_rate": (
                successful_charges / (successful_charges + failed_charges) * 100
                if (successful_charges + failed_charges) > 0 else 100
            ),
            "active_subscriptions": len(subscriptions.data),
        }

    async def get_customer_metrics(self) -> Dict[str, Any]:
        """
        Get customer-related metrics.
        """
        # Get customers
        customers = stripe.Customer.list(limit=100)

        # Count active vs churned
        active_count = 0
        churned_count = 0

        for customer in customers.data:
            subs = stripe.Subscription.list(
                customer=customer.id,
                limit=1,
            )
            if subs.data and subs.data[0].status in ("active", "trialing"):
                active_count += 1
            elif subs.data and subs.data[0].status == "canceled":
                churned_count += 1

        total = active_count + churned_count
        churn_rate = (churned_count / total * 100) if total > 0 else 0

        return {
            "total_customers": len(customers.data),
            "active_customers": active_count,
            "churned_customers": churned_count,
            "churn_rate": round(churn_rate, 2),
        }

    async def get_subscription_breakdown(self) -> Dict[str, Any]:
        """
        Get subscription breakdown by plan.
        """
        subscriptions = stripe.Subscription.list(
            status="active",
            limit=100,
            expand=["data.items.data.price.product"],
        )

        breakdown: Dict[str, Dict[str, Any]] = {}

        for sub in subscriptions.data:
            for item in sub.items.data:
                product = item.price.product
                product_name = product.name if hasattr(product, 'name') else str(product)

                if product_name not in breakdown:
                    breakdown[product_name] = {
                        "count": 0,
                        "mrr": 0,
                    }

                breakdown[product_name]["count"] += 1

                amount = item.price.unit_amount * item.quantity
                if item.price.recurring:
                    if item.price.recurring.interval == "year":
                        amount = amount // 12
                breakdown[product_name]["mrr"] += amount

        return {
            "plans": [
                {
                    "name": name,
                    "count": data["count"],
                    "mrr": data["mrr"],
                    "percentage": round(data["count"] / len(subscriptions.data) * 100, 1) if subscriptions.data else 0,
                }
                for name, data in breakdown.items()
            ],
            "total_active": len(subscriptions.data),
        }

    async def get_revenue_chart(
        self,
        days: int = 30,
    ) -> Dict[str, Any]:
        """
        Get daily revenue for chart display.
        """
        import time
        from collections import defaultdict

        now = int(time.time())
        start = now - (days * 86400)

        charges = stripe.Charge.list(
            created={"gte": start},
            limit=100,
        )

        # Group by day
        daily_revenue: Dict[str, int] = defaultdict(int)

        for charge in charges.data:
            if charge.paid:
                day = datetime.fromtimestamp(charge.created).strftime("%Y-%m-%d")
                daily_revenue[day] += charge.amount

        # Fill in missing days
        chart_data = []
        current = datetime.fromtimestamp(start)
        end = datetime.fromtimestamp(now)

        while current <= end:
            day_str = current.strftime("%Y-%m-%d")
            chart_data.append({
                "date": day_str,
                "revenue": daily_revenue.get(day_str, 0),
            })
            current += timedelta(days=1)

        return {
            "data": chart_data,
            "total": sum(d["revenue"] for d in chart_data),
            "average": sum(d["revenue"] for d in chart_data) // len(chart_data) if chart_data else 0,
        }


class PortalConfiguration:
    """
    Configure the Stripe Customer Portal.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def create_configuration(
        self,
        business_name: str,
        privacy_policy_url: Optional[str] = None,
        terms_of_service_url: Optional[str] = None,
        allow_cancel: bool = True,
        allow_update_payment: bool = True,
        allow_update_subscription: bool = True,
        proration_behavior: str = "create_prorations",
    ) -> Dict[str, Any]:
        """
        Create a portal configuration.
        """
        features: Dict[str, Any] = {
            "payment_method_update": {"enabled": allow_update_payment},
            "invoice_history": {"enabled": True},
        }

        if allow_cancel:
            features["subscription_cancel"] = {
                "enabled": True,
                "mode": "at_period_end",
                "proration_behavior": proration_behavior,
            }

        if allow_update_subscription:
            features["subscription_update"] = {
                "enabled": True,
                "default_allowed_updates": ["price", "quantity"],
                "proration_behavior": proration_behavior,
            }

        config = stripe.billing_portal.Configuration.create(
            business_profile={
                "headline": f"Manage your {business_name} subscription",
                "privacy_policy_url": privacy_policy_url,
                "terms_of_service_url": terms_of_service_url,
            },
            features=features,
        )

        return {
            "id": config.id,
            "is_default": config.is_default,
            "active": config.active,
            "features": {
                "payment_method_update": config.features.payment_method_update.enabled,
                "invoice_history": config.features.invoice_history.enabled,
                "subscription_cancel": config.features.subscription_cancel.enabled if config.features.subscription_cancel else False,
                "subscription_update": config.features.subscription_update.enabled if config.features.subscription_update else False,
            },
        }

    async def list_configurations(self) -> List[Dict[str, Any]]:
        """
        List all portal configurations.
        """
        configs = stripe.billing_portal.Configuration.list(limit=10)

        return [
            {
                "id": config.id,
                "is_default": config.is_default,
                "active": config.active,
                "created": config.created,
            }
            for config in configs.data
        ]

    async def set_default(self, configuration_id: str) -> bool:
        """
        Set a configuration as default.
        """
        try:
            stripe.billing_portal.Configuration.modify(
                configuration_id,
                is_default=True,
            )
            return True
        except stripe.error.StripeError:
            return False


# FastAPI endpoints
def create_portal_routes(portal: CustomerPortal, analytics: AnalyticsDashboard):
    """
    Create FastAPI routes for portal.
    """
    from fastapi import APIRouter, HTTPException, Query

    router = APIRouter(prefix="/portal", tags=["portal"])

    @router.get("/dashboard/{customer_id}")
    async def get_dashboard(customer_id: str):
        try:
            return await portal.get_customer_dashboard(customer_id)
        except stripe.error.StripeError as e:
            raise HTTPException(status_code=400, detail=str(e))

    @router.post("/session")
    async def create_session(customer_id: str, return_url: str):
        try:
            return await portal.create_portal_session(customer_id, return_url)
        except stripe.error.StripeError as e:
            raise HTTPException(status_code=400, detail=str(e))

    @router.get("/invoices/{customer_id}")
    async def get_invoices(
        customer_id: str,
        limit: int = Query(25, le=100),
        starting_after: Optional[str] = None,
    ):
        return await portal.get_invoice_history(customer_id, limit, starting_after)

    @router.get("/analytics/revenue")
    async def get_revenue(time_range: str = "month"):
        try:
            tr = TimeRange(time_range)
        except ValueError:
            tr = TimeRange.MONTH
        return await analytics.get_revenue_metrics(tr)

    @router.get("/analytics/customers")
    async def get_customers():
        return await analytics.get_customer_metrics()

    @router.get("/analytics/subscriptions")
    async def get_subscriptions():
        return await analytics.get_subscription_breakdown()

    @router.get("/analytics/chart")
    async def get_chart(days: int = Query(30, le=365)):
        return await analytics.get_revenue_chart(days)

    return router
