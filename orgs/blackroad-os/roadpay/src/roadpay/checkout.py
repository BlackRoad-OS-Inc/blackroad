"""
RoadPay Checkout - Production-Ready Checkout Flows

Features:
- Multi-item checkout
- Coupon/discount support
- Trial periods
- Tax collection
- Custom fields
- Embeddable pricing tables
- Checkout recovery (abandoned carts)
"""

from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field
from enum import Enum
from pydantic import BaseModel, EmailStr
import stripe


class CheckoutMode(str, Enum):
    PAYMENT = "payment"  # One-time payment
    SUBSCRIPTION = "subscription"  # Recurring
    SETUP = "setup"  # Save payment method


class TaxBehavior(str, Enum):
    INCLUSIVE = "inclusive"
    EXCLUSIVE = "exclusive"


@dataclass
class LineItem:
    price_id: str
    quantity: int = 1
    adjustable_quantity: bool = False
    min_quantity: int = 1
    max_quantity: int = 99


@dataclass
class CheckoutConfig:
    success_url: str
    cancel_url: str
    mode: CheckoutMode = CheckoutMode.SUBSCRIPTION
    customer_id: Optional[str] = None
    customer_email: Optional[str] = None
    line_items: List[LineItem] = field(default_factory=list)
    coupon_id: Optional[str] = None
    trial_days: Optional[int] = None
    collect_tax: bool = False
    collect_phone: bool = False
    collect_shipping: bool = False
    allow_promotion_codes: bool = True
    custom_fields: List[Dict[str, Any]] = field(default_factory=list)
    metadata: Dict[str, str] = field(default_factory=dict)
    client_reference_id: Optional[str] = None
    expires_after_minutes: int = 30


class CheckoutSessionCreate(BaseModel):
    success_url: str
    cancel_url: str
    mode: str = "subscription"
    customer_id: Optional[str] = None
    customer_email: Optional[EmailStr] = None
    price_ids: List[str]
    quantities: Optional[List[int]] = None
    coupon: Optional[str] = None
    trial_days: Optional[int] = None
    allow_promotion_codes: bool = True
    collect_tax: bool = False
    metadata: Optional[Dict[str, str]] = None


class CheckoutManager:
    """
    Manages Stripe Checkout sessions with best practices.
    """

    def __init__(self, stripe_key: str, webhook_secret: str):
        stripe.api_key = stripe_key
        self.webhook_secret = webhook_secret

    async def create_session(self, config: CheckoutConfig) -> Dict[str, Any]:
        """
        Create a checkout session with all configurations.
        """
        # Build line items
        line_items = []
        for item in config.line_items:
            li = {
                "price": item.price_id,
                "quantity": item.quantity,
            }
            if item.adjustable_quantity:
                li["adjustable_quantity"] = {
                    "enabled": True,
                    "minimum": item.min_quantity,
                    "maximum": item.max_quantity,
                }
            line_items.append(li)

        # Build session params
        params: Dict[str, Any] = {
            "mode": config.mode.value,
            "success_url": config.success_url + "?session_id={CHECKOUT_SESSION_ID}",
            "cancel_url": config.cancel_url,
            "line_items": line_items,
            "allow_promotion_codes": config.allow_promotion_codes,
            "expires_at": int(__import__('time').time()) + (config.expires_after_minutes * 60),
        }

        # Customer handling
        if config.customer_id:
            params["customer"] = config.customer_id
        elif config.customer_email:
            params["customer_email"] = config.customer_email
            params["customer_creation"] = "always"

        # Apply coupon
        if config.coupon_id:
            params["discounts"] = [{"coupon": config.coupon_id}]

        # Trial period
        if config.trial_days and config.mode == CheckoutMode.SUBSCRIPTION:
            params["subscription_data"] = {
                "trial_period_days": config.trial_days,
            }

        # Tax collection
        if config.collect_tax:
            params["automatic_tax"] = {"enabled": True}
            params["tax_id_collection"] = {"enabled": True}

        # Phone collection
        if config.collect_phone:
            params["phone_number_collection"] = {"enabled": True}

        # Shipping
        if config.collect_shipping:
            params["shipping_address_collection"] = {
                "allowed_countries": ["US", "CA", "GB", "AU", "DE", "FR", "NL"],
            }

        # Custom fields
        if config.custom_fields:
            params["custom_fields"] = config.custom_fields

        # Metadata
        if config.metadata:
            params["metadata"] = config.metadata

        if config.client_reference_id:
            params["client_reference_id"] = config.client_reference_id

        # Create session
        session = stripe.checkout.Session.create(**params)

        return {
            "id": session.id,
            "url": session.url,
            "expires_at": session.expires_at,
            "status": session.status,
            "customer": session.customer,
            "payment_status": session.payment_status,
        }

    async def retrieve_session(self, session_id: str) -> Dict[str, Any]:
        """
        Retrieve checkout session details.
        """
        session = stripe.checkout.Session.retrieve(
            session_id,
            expand=["line_items", "customer", "subscription"],
        )

        return {
            "id": session.id,
            "status": session.status,
            "payment_status": session.payment_status,
            "customer": {
                "id": session.customer.id if session.customer else None,
                "email": session.customer_details.email if session.customer_details else None,
            },
            "subscription_id": session.subscription.id if session.subscription else None,
            "amount_total": session.amount_total,
            "currency": session.currency,
            "line_items": [
                {
                    "price_id": item.price.id,
                    "quantity": item.quantity,
                    "amount_total": item.amount_total,
                }
                for item in session.line_items.data
            ] if session.line_items else [],
            "metadata": session.metadata,
            "custom_fields": session.custom_fields,
        }

    async def expire_session(self, session_id: str) -> bool:
        """
        Manually expire a checkout session.
        """
        try:
            stripe.checkout.Session.expire(session_id)
            return True
        except stripe.error.StripeError:
            return False


class AbandonedCartRecovery:
    """
    Handle abandoned checkout recovery.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def get_abandoned_sessions(
        self,
        hours_ago: int = 24,
        limit: int = 100,
    ) -> List[Dict[str, Any]]:
        """
        Get expired checkout sessions that weren't completed.
        """
        import time

        cutoff = int(time.time()) - (hours_ago * 3600)

        sessions = stripe.checkout.Session.list(
            limit=limit,
            created={"gte": cutoff},
            status="expired",
        )

        abandoned = []
        for session in sessions.data:
            if session.customer_details and session.customer_details.email:
                abandoned.append({
                    "session_id": session.id,
                    "email": session.customer_details.email,
                    "amount": session.amount_total,
                    "currency": session.currency,
                    "created": session.created,
                    "expired_at": session.expires_at,
                    "line_items": session.metadata.get("line_items", ""),
                    "recovery_url": session.url if session.url else None,
                })

        return abandoned

    async def create_recovery_session(
        self,
        original_session_id: str,
        success_url: str,
        cancel_url: str,
    ) -> Dict[str, Any]:
        """
        Create a new session based on an abandoned one.
        """
        original = stripe.checkout.Session.retrieve(
            original_session_id,
            expand=["line_items"],
        )

        # Recreate with same items
        line_items = []
        for item in original.line_items.data:
            line_items.append({
                "price": item.price.id,
                "quantity": item.quantity,
            })

        new_session = stripe.checkout.Session.create(
            mode=original.mode,
            customer_email=original.customer_details.email if original.customer_details else None,
            line_items=line_items,
            success_url=success_url + "?session_id={CHECKOUT_SESSION_ID}&recovered=true",
            cancel_url=cancel_url,
            metadata={
                "recovered_from": original_session_id,
            },
        )

        return {
            "id": new_session.id,
            "url": new_session.url,
            "original_session": original_session_id,
        }


class PricingTableGenerator:
    """
    Generate pricing table data for frontend display.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def get_pricing_table(
        self,
        product_ids: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Get all products and prices formatted for a pricing table.
        """
        # Get products
        if product_ids:
            products = [stripe.Product.retrieve(pid) for pid in product_ids]
        else:
            products = stripe.Product.list(active=True, limit=100).data

        pricing_data = []

        for product in products:
            # Get prices for this product
            prices = stripe.Price.list(product=product.id, active=True)

            monthly_price = None
            yearly_price = None
            one_time_price = None

            for price in prices.data:
                price_data = {
                    "id": price.id,
                    "amount": price.unit_amount,
                    "currency": price.currency,
                }

                if price.recurring:
                    if price.recurring.interval == "month":
                        monthly_price = price_data
                    elif price.recurring.interval == "year":
                        yearly_price = price_data
                        # Calculate monthly equivalent
                        yearly_price["monthly_equivalent"] = price.unit_amount // 12
                else:
                    one_time_price = price_data

            # Get features from metadata
            features = []
            for key, value in product.metadata.items():
                if key.startswith("feature_"):
                    features.append(value)

            pricing_data.append({
                "id": product.id,
                "name": product.name,
                "description": product.description,
                "features": features,
                "monthly": monthly_price,
                "yearly": yearly_price,
                "one_time": one_time_price,
                "popular": product.metadata.get("popular", "false") == "true",
                "order": int(product.metadata.get("order", "0")),
            })

        # Sort by order
        pricing_data.sort(key=lambda x: x["order"])

        return {
            "products": pricing_data,
            "currency": pricing_data[0]["monthly"]["currency"] if pricing_data and pricing_data[0]["monthly"] else "usd",
        }

    async def get_pricing_html(
        self,
        checkout_base_url: str,
        success_url: str,
        cancel_url: str,
    ) -> str:
        """
        Generate embeddable pricing table HTML.
        """
        data = await self.get_pricing_table()

        cards_html = ""
        for product in data["products"]:
            popular_badge = '<span class="popular-badge">Most Popular</span>' if product["popular"] else ""

            features_html = ""
            for feature in product["features"]:
                features_html += f'<li class="feature-item">✓ {feature}</li>'

            if product["monthly"]:
                price_amount = product["monthly"]["amount"] / 100
                price_display = f"${price_amount:.2f}/mo"
                price_id = product["monthly"]["id"]
            elif product["one_time"]:
                price_amount = product["one_time"]["amount"] / 100
                price_display = f"${price_amount:.2f}"
                price_id = product["one_time"]["id"]
            else:
                continue

            checkout_url = f"{checkout_base_url}?price_id={price_id}&success_url={success_url}&cancel_url={cancel_url}"

            cards_html += f'''
            <div class="pricing-card {'popular' if product["popular"] else ''}">
                {popular_badge}
                <h3 class="plan-name">{product["name"]}</h3>
                <p class="plan-description">{product["description"] or ""}</p>
                <div class="price">{price_display}</div>
                <ul class="features-list">{features_html}</ul>
                <a href="{checkout_url}" class="cta-button">Get Started</a>
            </div>
            '''

        return f'''
<!DOCTYPE html>
<html>
<head>
<style>
.pricing-container {{ display: flex; gap: 24px; justify-content: center; flex-wrap: wrap; padding: 40px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #000; }}
.pricing-card {{ background: #111; border: 1px solid #333; border-radius: 16px; padding: 32px; width: 320px; position: relative; transition: transform 0.2s, border-color 0.2s; }}
.pricing-card:hover {{ transform: translateY(-4px); border-color: #F5A623; }}
.pricing-card.popular {{ border-color: #F5A623; }}
.popular-badge {{ position: absolute; top: -12px; left: 50%; transform: translateX(-50%); background: linear-gradient(135deg, #F5A623, #FF1D6C); color: white; padding: 4px 16px; border-radius: 20px; font-size: 12px; font-weight: 600; }}
.plan-name {{ color: #F5A623; font-size: 24px; margin: 0 0 8px; }}
.plan-description {{ color: #888; font-size: 14px; margin: 0 0 24px; }}
.price {{ font-size: 48px; font-weight: 700; color: #fff; margin-bottom: 24px; }}
.features-list {{ list-style: none; padding: 0; margin: 0 0 32px; }}
.feature-item {{ color: #ccc; padding: 8px 0; border-bottom: 1px solid #222; }}
.cta-button {{ display: block; background: linear-gradient(135deg, #F5A623, #FF1D6C); color: white; text-decoration: none; padding: 16px 32px; border-radius: 8px; text-align: center; font-weight: 600; transition: opacity 0.2s; }}
.cta-button:hover {{ opacity: 0.9; }}
</style>
</head>
<body>
<div class="pricing-container">
{cards_html}
</div>
</body>
</html>
'''


class CouponManager:
    """
    Manage discount coupons and promotion codes.
    """

    def __init__(self, stripe_key: str):
        stripe.api_key = stripe_key

    async def create_coupon(
        self,
        name: str,
        percent_off: Optional[int] = None,
        amount_off: Optional[int] = None,
        currency: str = "usd",
        duration: str = "once",  # once, repeating, forever
        duration_in_months: Optional[int] = None,
        max_redemptions: Optional[int] = None,
        redeem_by: Optional[int] = None,  # Unix timestamp
    ) -> Dict[str, Any]:
        """
        Create a coupon.
        """
        params: Dict[str, Any] = {
            "name": name,
            "duration": duration,
        }

        if percent_off:
            params["percent_off"] = percent_off
        elif amount_off:
            params["amount_off"] = amount_off
            params["currency"] = currency

        if duration == "repeating" and duration_in_months:
            params["duration_in_months"] = duration_in_months

        if max_redemptions:
            params["max_redemptions"] = max_redemptions

        if redeem_by:
            params["redeem_by"] = redeem_by

        coupon = stripe.Coupon.create(**params)

        return {
            "id": coupon.id,
            "name": coupon.name,
            "percent_off": coupon.percent_off,
            "amount_off": coupon.amount_off,
            "duration": coupon.duration,
            "valid": coupon.valid,
        }

    async def create_promotion_code(
        self,
        coupon_id: str,
        code: str,
        max_redemptions: Optional[int] = None,
        first_time_transaction: bool = False,
    ) -> Dict[str, Any]:
        """
        Create a promotion code for a coupon.
        """
        params: Dict[str, Any] = {
            "coupon": coupon_id,
            "code": code,
        }

        if max_redemptions:
            params["max_redemptions"] = max_redemptions

        restrictions = {}
        if first_time_transaction:
            restrictions["first_time_transaction"] = True

        if restrictions:
            params["restrictions"] = restrictions

        promo = stripe.PromotionCode.create(**params)

        return {
            "id": promo.id,
            "code": promo.code,
            "coupon_id": promo.coupon.id,
            "active": promo.active,
            "times_redeemed": promo.times_redeemed,
        }

    async def validate_code(self, code: str) -> Dict[str, Any]:
        """
        Validate a promotion code.
        """
        promos = stripe.PromotionCode.list(code=code, limit=1)

        if not promos.data:
            return {"valid": False, "error": "Code not found"}

        promo = promos.data[0]

        if not promo.active:
            return {"valid": False, "error": "Code is no longer active"}

        coupon = stripe.Coupon.retrieve(promo.coupon.id)

        if not coupon.valid:
            return {"valid": False, "error": "Coupon has expired"}

        return {
            "valid": True,
            "code": promo.code,
            "percent_off": coupon.percent_off,
            "amount_off": coupon.amount_off,
            "duration": coupon.duration,
        }
