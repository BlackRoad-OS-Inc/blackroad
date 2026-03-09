"""
RoadPay - Payment Processing Platform
Stripe-based payments, subscriptions, and invoicing
"""

from datetime import datetime
from typing import Optional, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
import stripe

from .config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle."""
    print("💳 RoadPay starting...")
    stripe.api_key = settings.stripe_secret_key
    yield
    print("💳 RoadPay shutting down...")


app = FastAPI(
    title="RoadPay",
    description="Payment Processing Platform",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Models
class CustomerCreate(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    metadata: Optional[dict] = None


class PaymentIntentCreate(BaseModel):
    amount: int  # in cents
    currency: str = "usd"
    customer_id: Optional[str] = None
    metadata: Optional[dict] = None


class SubscriptionCreate(BaseModel):
    customer_id: str
    price_id: str
    metadata: Optional[dict] = None


class PriceCreate(BaseModel):
    product_id: str
    unit_amount: int  # in cents
    currency: str = "usd"
    recurring_interval: Optional[str] = None  # month, year, etc.


class ProductCreate(BaseModel):
    name: str
    description: Optional[str] = None
    metadata: Optional[dict] = None


class InvoiceCreate(BaseModel):
    customer_id: str
    items: List[dict]  # [{"price_id": "...", "quantity": 1}]
    auto_advance: bool = True


# Routes
@app.get("/")
async def root():
    return {
        "name": "RoadPay",
        "version": "0.1.0",
        "description": "Payment Processing Platform",
        "endpoints": {
            "customers": "/customers",
            "payments": "/payments",
            "subscriptions": "/subscriptions",
            "products": "/products",
            "prices": "/prices",
            "invoices": "/invoices",
            "webhooks": "/webhooks",
        },
    }


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "roadpay"}


# Customers
@app.post("/customers")
async def create_customer(data: CustomerCreate):
    """Create a new Stripe customer."""
    try:
        customer = stripe.Customer.create(
            email=data.email,
            name=data.name,
            metadata=data.metadata or {},
        )
        return {
            "id": customer.id,
            "email": customer.email,
            "name": customer.name,
            "created": customer.created,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/customers/{customer_id}")
async def get_customer(customer_id: str):
    """Get customer details."""
    try:
        customer = stripe.Customer.retrieve(customer_id)
        return {
            "id": customer.id,
            "email": customer.email,
            "name": customer.name,
            "created": customer.created,
            "balance": customer.balance,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.get("/customers/{customer_id}/subscriptions")
async def get_customer_subscriptions(customer_id: str):
    """Get customer's subscriptions."""
    try:
        subscriptions = stripe.Subscription.list(customer=customer_id)
        return {
            "customer_id": customer_id,
            "subscriptions": [
                {
                    "id": sub.id,
                    "status": sub.status,
                    "current_period_end": sub.current_period_end,
                    "items": [{"price_id": item.price.id} for item in sub["items"]["data"]],
                }
                for sub in subscriptions.data
            ],
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Payment Intents
@app.post("/payments/intent")
async def create_payment_intent(data: PaymentIntentCreate):
    """Create a payment intent for one-time payment."""
    try:
        intent = stripe.PaymentIntent.create(
            amount=data.amount,
            currency=data.currency,
            customer=data.customer_id,
            metadata=data.metadata or {},
            automatic_payment_methods={"enabled": True},
        )
        return {
            "id": intent.id,
            "client_secret": intent.client_secret,
            "amount": intent.amount,
            "currency": intent.currency,
            "status": intent.status,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/payments/{payment_id}")
async def get_payment(payment_id: str):
    """Get payment intent status."""
    try:
        intent = stripe.PaymentIntent.retrieve(payment_id)
        return {
            "id": intent.id,
            "amount": intent.amount,
            "currency": intent.currency,
            "status": intent.status,
            "created": intent.created,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=404, detail=str(e))


# Products
@app.post("/products")
async def create_product(data: ProductCreate):
    """Create a product."""
    try:
        product = stripe.Product.create(
            name=data.name,
            description=data.description,
            metadata=data.metadata or {},
        )
        return {
            "id": product.id,
            "name": product.name,
            "description": product.description,
            "active": product.active,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/products")
async def list_products(limit: int = 10):
    """List products."""
    try:
        products = stripe.Product.list(limit=limit, active=True)
        return {
            "products": [
                {
                    "id": p.id,
                    "name": p.name,
                    "description": p.description,
                    "active": p.active,
                }
                for p in products.data
            ]
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Prices
@app.post("/prices")
async def create_price(data: PriceCreate):
    """Create a price for a product."""
    try:
        price_data = {
            "product": data.product_id,
            "unit_amount": data.unit_amount,
            "currency": data.currency,
        }

        if data.recurring_interval:
            price_data["recurring"] = {"interval": data.recurring_interval}

        price = stripe.Price.create(**price_data)
        return {
            "id": price.id,
            "product": price.product,
            "unit_amount": price.unit_amount,
            "currency": price.currency,
            "recurring": price.recurring,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/prices")
async def list_prices(product_id: Optional[str] = None, limit: int = 10):
    """List prices."""
    try:
        params = {"limit": limit, "active": True}
        if product_id:
            params["product"] = product_id

        prices = stripe.Price.list(**params)
        return {
            "prices": [
                {
                    "id": p.id,
                    "product": p.product,
                    "unit_amount": p.unit_amount,
                    "currency": p.currency,
                    "recurring": p.recurring,
                }
                for p in prices.data
            ]
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Subscriptions
@app.post("/subscriptions")
async def create_subscription(data: SubscriptionCreate):
    """Create a subscription."""
    try:
        subscription = stripe.Subscription.create(
            customer=data.customer_id,
            items=[{"price": data.price_id}],
            metadata=data.metadata or {},
            payment_behavior="default_incomplete",
            expand=["latest_invoice.payment_intent"],
        )
        return {
            "id": subscription.id,
            "status": subscription.status,
            "current_period_end": subscription.current_period_end,
            "client_secret": subscription.latest_invoice.payment_intent.client_secret
            if subscription.latest_invoice
            else None,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/subscriptions/{subscription_id}")
async def get_subscription(subscription_id: str):
    """Get subscription details."""
    try:
        subscription = stripe.Subscription.retrieve(subscription_id)
        return {
            "id": subscription.id,
            "status": subscription.status,
            "current_period_start": subscription.current_period_start,
            "current_period_end": subscription.current_period_end,
            "cancel_at_period_end": subscription.cancel_at_period_end,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.post("/subscriptions/{subscription_id}/cancel")
async def cancel_subscription(subscription_id: str, immediately: bool = False):
    """Cancel a subscription."""
    try:
        if immediately:
            subscription = stripe.Subscription.delete(subscription_id)
        else:
            subscription = stripe.Subscription.modify(
                subscription_id,
                cancel_at_period_end=True,
            )
        return {
            "id": subscription.id,
            "status": subscription.status,
            "cancel_at_period_end": subscription.cancel_at_period_end,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Invoices
@app.post("/invoices")
async def create_invoice(data: InvoiceCreate):
    """Create and optionally finalize an invoice."""
    try:
        # Create invoice
        invoice = stripe.Invoice.create(
            customer=data.customer_id,
            auto_advance=data.auto_advance,
        )

        # Add line items
        for item in data.items:
            stripe.InvoiceItem.create(
                customer=data.customer_id,
                invoice=invoice.id,
                price=item["price_id"],
                quantity=item.get("quantity", 1),
            )

        # Finalize
        if data.auto_advance:
            invoice = stripe.Invoice.finalize_invoice(invoice.id)

        return {
            "id": invoice.id,
            "status": invoice.status,
            "amount_due": invoice.amount_due,
            "hosted_invoice_url": invoice.hosted_invoice_url,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/invoices/{invoice_id}")
async def get_invoice(invoice_id: str):
    """Get invoice details."""
    try:
        invoice = stripe.Invoice.retrieve(invoice_id)
        return {
            "id": invoice.id,
            "status": invoice.status,
            "amount_due": invoice.amount_due,
            "amount_paid": invoice.amount_paid,
            "hosted_invoice_url": invoice.hosted_invoice_url,
            "pdf": invoice.invoice_pdf,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=404, detail=str(e))


# Webhooks
@app.post("/webhooks")
async def handle_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="Stripe-Signature"),
):
    """Handle Stripe webhooks."""
    payload = await request.body()

    try:
        event = stripe.Webhook.construct_event(
            payload,
            stripe_signature,
            settings.stripe_webhook_secret,
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle events
    event_type = event["type"]
    data = event["data"]["object"]

    handlers = {
        "payment_intent.succeeded": handle_payment_succeeded,
        "payment_intent.failed": handle_payment_failed,
        "customer.subscription.created": handle_subscription_created,
        "customer.subscription.updated": handle_subscription_updated,
        "customer.subscription.deleted": handle_subscription_deleted,
        "invoice.paid": handle_invoice_paid,
        "invoice.payment_failed": handle_invoice_failed,
    }

    handler = handlers.get(event_type)
    if handler:
        await handler(data)

    return {"received": True, "type": event_type}


async def handle_payment_succeeded(data: dict):
    """Handle successful payment."""
    print(f"Payment succeeded: {data['id']}")


async def handle_payment_failed(data: dict):
    """Handle failed payment."""
    print(f"Payment failed: {data['id']}")


async def handle_subscription_created(data: dict):
    """Handle new subscription."""
    print(f"Subscription created: {data['id']}")


async def handle_subscription_updated(data: dict):
    """Handle subscription update."""
    print(f"Subscription updated: {data['id']}")


async def handle_subscription_deleted(data: dict):
    """Handle subscription cancellation."""
    print(f"Subscription deleted: {data['id']}")


async def handle_invoice_paid(data: dict):
    """Handle paid invoice."""
    print(f"Invoice paid: {data['id']}")


async def handle_invoice_failed(data: dict):
    """Handle failed invoice payment."""
    print(f"Invoice payment failed: {data['id']}")


# Checkout Sessions
@app.post("/checkout/session")
async def create_checkout_session(
    price_id: str,
    success_url: str,
    cancel_url: str,
    customer_id: Optional[str] = None,
    mode: str = "subscription",  # subscription, payment, setup
):
    """Create a Stripe Checkout session."""
    try:
        session = stripe.checkout.Session.create(
            customer=customer_id,
            payment_method_types=["card"],
            line_items=[{"price": price_id, "quantity": 1}],
            mode=mode,
            success_url=success_url,
            cancel_url=cancel_url,
        )
        return {
            "id": session.id,
            "url": session.url,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# Billing Portal
@app.post("/billing/portal")
async def create_billing_portal(customer_id: str, return_url: str):
    """Create a Stripe Billing Portal session."""
    try:
        session = stripe.billing_portal.Session.create(
            customer=customer_id,
            return_url=return_url,
        )
        return {"url": session.url}
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


def cli():
    """CLI entry point."""
    import uvicorn
    uvicorn.run(
        "roadpay.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )


if __name__ == "__main__":
    cli()
