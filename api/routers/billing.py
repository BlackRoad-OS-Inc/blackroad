"""Stripe billing integration for Lucidia Platform."""

import os
from datetime import datetime
from typing import Optional

import stripe
from fastapi import APIRouter, HTTPException, Request, Header
from pydantic import BaseModel

router = APIRouter(prefix="/billing", tags=["billing"])

# Initialize Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")

# Price IDs (set these in Stripe Dashboard)
PRICE_IDS = {
    "student_monthly": os.getenv("STRIPE_PRICE_STUDENT_MONTHLY", "price_student_monthly"),
    "student_yearly": os.getenv("STRIPE_PRICE_STUDENT_YEARLY", "price_student_yearly"),
    "family_monthly": os.getenv("STRIPE_PRICE_FAMILY_MONTHLY", "price_family_monthly"),
    "family_yearly": os.getenv("STRIPE_PRICE_FAMILY_YEARLY", "price_family_yearly"),
}


class CreateCheckoutRequest(BaseModel):
    """Request to create a checkout session."""
    plan: str  # student_monthly, student_yearly, family_monthly, family_yearly
    user_id: str
    success_url: str = "https://lucidia.ai/dashboard?success=true"
    cancel_url: str = "https://lucidia.ai/pricing?canceled=true"


class CreatePortalRequest(BaseModel):
    """Request to create a customer portal session."""
    customer_id: str
    return_url: str = "https://lucidia.ai/dashboard"


class SubscriptionStatus(BaseModel):
    """Subscription status response."""
    user_id: str
    status: str  # active, canceled, past_due, trialing, none
    plan: Optional[str] = None
    current_period_end: Optional[datetime] = None
    cancel_at_period_end: bool = False


# In-memory subscription storage (replace with database)
user_subscriptions: dict = {}
user_customers: dict = {}  # user_id -> stripe_customer_id


@router.post("/create-checkout-session")
async def create_checkout_session(request: CreateCheckoutRequest):
    """
    Create a Stripe Checkout session for subscription.

    Returns a URL to redirect the user to Stripe Checkout.
    """
    if not stripe.api_key:
        raise HTTPException(500, "Stripe not configured")

    price_id = PRICE_IDS.get(request.plan)
    if not price_id:
        raise HTTPException(400, f"Invalid plan: {request.plan}")

    try:
        # Get or create customer
        customer_id = user_customers.get(request.user_id)

        if not customer_id:
            customer = stripe.Customer.create(
                metadata={"user_id": request.user_id}
            )
            customer_id = customer.id
            user_customers[request.user_id] = customer_id

        # Create checkout session
        session = stripe.checkout.Session.create(
            customer=customer_id,
            payment_method_types=["card"],
            line_items=[
                {
                    "price": price_id,
                    "quantity": 1,
                }
            ],
            mode="subscription",
            success_url=request.success_url,
            cancel_url=request.cancel_url,
            metadata={
                "user_id": request.user_id,
                "plan": request.plan,
            },
            subscription_data={
                "trial_period_days": 7,  # 7-day free trial
                "metadata": {
                    "user_id": request.user_id,
                    "plan": request.plan,
                }
            },
            allow_promotion_codes=True,
        )

        return {
            "checkout_url": session.url,
            "session_id": session.id,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(400, str(e))


@router.post("/create-portal-session")
async def create_portal_session(request: CreatePortalRequest):
    """
    Create a Stripe Customer Portal session.

    Allows users to manage their subscription, update payment methods, etc.
    """
    if not stripe.api_key:
        raise HTTPException(500, "Stripe not configured")

    try:
        session = stripe.billing_portal.Session.create(
            customer=request.customer_id,
            return_url=request.return_url,
        )

        return {"portal_url": session.url}

    except stripe.error.StripeError as e:
        raise HTTPException(400, str(e))


@router.get("/subscription/{user_id}", response_model=SubscriptionStatus)
async def get_subscription_status(user_id: str):
    """Get subscription status for a user."""

    # Check in-memory storage
    if user_id in user_subscriptions:
        sub = user_subscriptions[user_id]
        return SubscriptionStatus(
            user_id=user_id,
            status=sub.get("status", "none"),
            plan=sub.get("plan"),
            current_period_end=sub.get("current_period_end"),
            cancel_at_period_end=sub.get("cancel_at_period_end", False),
        )

    # Check Stripe directly if we have a customer
    customer_id = user_customers.get(user_id)
    if customer_id and stripe.api_key:
        try:
            subscriptions = stripe.Subscription.list(
                customer=customer_id,
                status="all",
                limit=1,
            )

            if subscriptions.data:
                sub = subscriptions.data[0]
                return SubscriptionStatus(
                    user_id=user_id,
                    status=sub.status,
                    plan=sub.metadata.get("plan"),
                    current_period_end=datetime.fromtimestamp(sub.current_period_end),
                    cancel_at_period_end=sub.cancel_at_period_end,
                )
        except stripe.error.StripeError:
            pass

    return SubscriptionStatus(
        user_id=user_id,
        status="none",
    )


@router.post("/webhook")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="Stripe-Signature"),
):
    """
    Handle Stripe webhooks.

    Events:
    - checkout.session.completed: Subscription started
    - customer.subscription.updated: Subscription changed
    - customer.subscription.deleted: Subscription canceled
    - invoice.payment_failed: Payment failed
    """
    if not STRIPE_WEBHOOK_SECRET:
        raise HTTPException(500, "Webhook secret not configured")

    payload = await request.body()

    try:
        event = stripe.Webhook.construct_event(
            payload, stripe_signature, STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(400, "Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(400, "Invalid signature")

    # Handle events
    if event.type == "checkout.session.completed":
        session = event.data.object
        user_id = session.metadata.get("user_id")
        plan = session.metadata.get("plan")

        if user_id:
            user_subscriptions[user_id] = {
                "status": "active",
                "plan": plan,
                "customer_id": session.customer,
                "subscription_id": session.subscription,
            }
            user_customers[user_id] = session.customer
            print(f"Subscription started for user {user_id}: {plan}")

    elif event.type == "customer.subscription.updated":
        subscription = event.data.object
        user_id = subscription.metadata.get("user_id")

        if user_id and user_id in user_subscriptions:
            user_subscriptions[user_id].update({
                "status": subscription.status,
                "cancel_at_period_end": subscription.cancel_at_period_end,
                "current_period_end": datetime.fromtimestamp(
                    subscription.current_period_end
                ),
            })
            print(f"Subscription updated for user {user_id}: {subscription.status}")

    elif event.type == "customer.subscription.deleted":
        subscription = event.data.object
        user_id = subscription.metadata.get("user_id")

        if user_id and user_id in user_subscriptions:
            user_subscriptions[user_id]["status"] = "canceled"
            print(f"Subscription canceled for user {user_id}")

    elif event.type == "invoice.payment_failed":
        invoice = event.data.object
        customer_id = invoice.customer

        # Find user by customer ID
        for uid, cid in user_customers.items():
            if cid == customer_id:
                user_subscriptions[uid]["status"] = "past_due"
                print(f"Payment failed for user {uid}")
                break

    return {"status": "success"}


# ============================================================================
# Pricing Info Endpoint (public)
# ============================================================================

@router.get("/pricing")
async def get_pricing():
    """Get current pricing information."""
    return {
        "plans": [
            {
                "id": "free",
                "name": "Free",
                "price": 0,
                "interval": None,
                "features": [
                    "10 problems/month",
                    "Basic explanations",
                    "Text input only",
                ],
            },
            {
                "id": "student_monthly",
                "name": "Student",
                "price": 9.99,
                "interval": "month",
                "features": [
                    "Unlimited problems",
                    "Visual explanations",
                    "Photo & voice upload",
                    "Persistent memory",
                    "All subjects",
                ],
                "popular": True,
            },
            {
                "id": "student_yearly",
                "name": "Student (Annual)",
                "price": 99.99,
                "interval": "year",
                "savings": "Save $20",
                "features": [
                    "Everything in Student Monthly",
                    "2 months free",
                ],
            },
            {
                "id": "family_monthly",
                "name": "Family",
                "price": 19.99,
                "interval": "month",
                "features": [
                    "Up to 5 users",
                    "Everything in Student",
                    "Parent dashboard",
                    "Progress tracking",
                    "Priority support",
                ],
            },
            {
                "id": "family_yearly",
                "name": "Family (Annual)",
                "price": 199.99,
                "interval": "year",
                "savings": "Save $40",
                "features": [
                    "Everything in Family Monthly",
                    "2 months free",
                ],
            },
        ],
        "trial_days": 7,
        "currency": "usd",
    }
