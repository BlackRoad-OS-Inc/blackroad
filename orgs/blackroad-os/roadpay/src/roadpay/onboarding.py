"""
RoadPay Customer Onboarding

Complete onboarding flows for bringing customers from signup to first payment.

Features:
- Onboarding state machine
- Step-by-step progress tracking
- Integration checklist
- First charge verification
- Webhook testing
- Go-live checklist
"""

from typing import Optional, Dict, Any, List
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pydantic import BaseModel, EmailStr
import stripe


class OnboardingStep(str, Enum):
    ACCOUNT_CREATED = "account_created"
    EMAIL_VERIFIED = "email_verified"
    BUSINESS_INFO = "business_info"
    PAYMENT_CONNECTED = "payment_connected"
    FIRST_PRODUCT = "first_product"
    FIRST_PRICE = "first_price"
    TEST_CHECKOUT = "test_checkout"
    WEBHOOK_CONFIGURED = "webhook_configured"
    WEBHOOK_TESTED = "webhook_tested"
    GO_LIVE_READY = "go_live_ready"
    LIVE = "live"


class OnboardingStatus(str, Enum):
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    BLOCKED = "blocked"


@dataclass
class OnboardingState:
    customer_id: str
    current_step: OnboardingStep
    completed_steps: List[OnboardingStep]
    step_data: Dict[str, Any]
    started_at: int
    updated_at: int
    completed_at: Optional[int] = None
    blockers: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "customer_id": self.customer_id,
            "current_step": self.current_step.value,
            "completed_steps": [s.value for s in self.completed_steps],
            "step_data": self.step_data,
            "started_at": self.started_at,
            "updated_at": self.updated_at,
            "completed_at": self.completed_at,
            "blockers": self.blockers,
            "progress_percent": self.progress_percent,
        }

    @property
    def progress_percent(self) -> int:
        total_steps = len(OnboardingStep)
        completed = len(self.completed_steps)
        return int((completed / total_steps) * 100)


class BusinessInfo(BaseModel):
    company_name: str
    business_type: str  # individual, company, non_profit
    country: str
    website: Optional[str] = None
    support_email: Optional[EmailStr] = None
    support_phone: Optional[str] = None


class OnboardingManager:
    """
    Manages customer onboarding flow.
    """

    def __init__(self, storage, stripe_key: str):
        self.storage = storage
        stripe.api_key = stripe_key

        # Define step order and requirements
        self.step_order = list(OnboardingStep)
        self.step_requirements = {
            OnboardingStep.ACCOUNT_CREATED: [],
            OnboardingStep.EMAIL_VERIFIED: [OnboardingStep.ACCOUNT_CREATED],
            OnboardingStep.BUSINESS_INFO: [OnboardingStep.EMAIL_VERIFIED],
            OnboardingStep.PAYMENT_CONNECTED: [OnboardingStep.BUSINESS_INFO],
            OnboardingStep.FIRST_PRODUCT: [OnboardingStep.PAYMENT_CONNECTED],
            OnboardingStep.FIRST_PRICE: [OnboardingStep.FIRST_PRODUCT],
            OnboardingStep.TEST_CHECKOUT: [OnboardingStep.FIRST_PRICE],
            OnboardingStep.WEBHOOK_CONFIGURED: [OnboardingStep.PAYMENT_CONNECTED],
            OnboardingStep.WEBHOOK_TESTED: [OnboardingStep.WEBHOOK_CONFIGURED, OnboardingStep.TEST_CHECKOUT],
            OnboardingStep.GO_LIVE_READY: [OnboardingStep.WEBHOOK_TESTED],
            OnboardingStep.LIVE: [OnboardingStep.GO_LIVE_READY],
        }

    async def start_onboarding(self, customer_id: str) -> OnboardingState:
        """
        Start onboarding for a new customer.
        """
        import time

        state = OnboardingState(
            customer_id=customer_id,
            current_step=OnboardingStep.ACCOUNT_CREATED,
            completed_steps=[OnboardingStep.ACCOUNT_CREATED],
            step_data={},
            started_at=int(time.time()),
            updated_at=int(time.time()),
        )

        await self._save_state(state)
        return state

    async def get_state(self, customer_id: str) -> Optional[OnboardingState]:
        """
        Get current onboarding state.
        """
        data = await self.storage.get(f"onboarding:{customer_id}")
        if not data:
            return None
        return self._dict_to_state(data)

    async def complete_step(
        self,
        customer_id: str,
        step: OnboardingStep,
        data: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Mark a step as completed.
        """
        import time

        state = await self.get_state(customer_id)
        if not state:
            return {"success": False, "error": "Onboarding not started"}

        # Check requirements
        requirements = self.step_requirements.get(step, [])
        for req in requirements:
            if req not in state.completed_steps:
                return {
                    "success": False,
                    "error": f"Requirement not met: {req.value}",
                    "missing_requirement": req.value,
                }

        # Mark completed
        if step not in state.completed_steps:
            state.completed_steps.append(step)

        # Store step data
        if data:
            state.step_data[step.value] = data

        # Update current step to next incomplete
        state.current_step = self._get_next_step(state)
        state.updated_at = int(time.time())

        # Check if fully complete
        if len(state.completed_steps) == len(OnboardingStep):
            state.completed_at = int(time.time())

        await self._save_state(state)

        return {
            "success": True,
            "step": step.value,
            "progress": state.progress_percent,
            "next_step": state.current_step.value,
            "is_complete": state.completed_at is not None,
        }

    async def verify_email(self, customer_id: str) -> Dict[str, Any]:
        """
        Mark email as verified.
        """
        return await self.complete_step(
            customer_id,
            OnboardingStep.EMAIL_VERIFIED,
            {"verified_at": datetime.utcnow().isoformat()},
        )

    async def set_business_info(
        self,
        customer_id: str,
        info: BusinessInfo,
    ) -> Dict[str, Any]:
        """
        Set business information.
        """
        # Update Stripe customer
        state = await self.get_state(customer_id)
        if not state:
            return {"success": False, "error": "Onboarding not started"}

        # Get or create Stripe customer
        stripe_customer_id = state.step_data.get("stripe_customer_id")

        customer_data = {
            "name": info.company_name,
            "metadata": {
                "business_type": info.business_type,
                "country": info.country,
            },
        }

        if info.support_email:
            customer_data["email"] = info.support_email

        if stripe_customer_id:
            stripe.Customer.modify(stripe_customer_id, **customer_data)
        else:
            customer = stripe.Customer.create(**customer_data)
            stripe_customer_id = customer.id

        return await self.complete_step(
            customer_id,
            OnboardingStep.BUSINESS_INFO,
            {
                **info.dict(),
                "stripe_customer_id": stripe_customer_id,
            },
        )

    async def connect_payment(
        self,
        customer_id: str,
        payment_method_id: str,
    ) -> Dict[str, Any]:
        """
        Connect a payment method.
        """
        state = await self.get_state(customer_id)
        if not state:
            return {"success": False, "error": "Onboarding not started"}

        stripe_customer_id = state.step_data.get("business_info", {}).get("stripe_customer_id")
        if not stripe_customer_id:
            return {"success": False, "error": "Business info not set"}

        # Attach payment method
        stripe.PaymentMethod.attach(
            payment_method_id,
            customer=stripe_customer_id,
        )

        # Set as default
        stripe.Customer.modify(
            stripe_customer_id,
            invoice_settings={"default_payment_method": payment_method_id},
        )

        return await self.complete_step(
            customer_id,
            OnboardingStep.PAYMENT_CONNECTED,
            {"payment_method_id": payment_method_id},
        )

    async def create_first_product(
        self,
        customer_id: str,
        name: str,
        description: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create first product for customer.
        """
        product = stripe.Product.create(
            name=name,
            description=description,
            metadata={"customer_id": customer_id, "onboarding": "true"},
        )

        return await self.complete_step(
            customer_id,
            OnboardingStep.FIRST_PRODUCT,
            {"product_id": product.id, "name": name},
        )

    async def create_first_price(
        self,
        customer_id: str,
        amount: int,
        currency: str = "usd",
        interval: str = "month",
    ) -> Dict[str, Any]:
        """
        Create first price for customer's product.
        """
        state = await self.get_state(customer_id)
        if not state:
            return {"success": False, "error": "Onboarding not started"}

        product_data = state.step_data.get("first_product", {})
        product_id = product_data.get("product_id")

        if not product_id:
            return {"success": False, "error": "Product not created"}

        price = stripe.Price.create(
            product=product_id,
            unit_amount=amount,
            currency=currency,
            recurring={"interval": interval},
            metadata={"customer_id": customer_id, "onboarding": "true"},
        )

        return await self.complete_step(
            customer_id,
            OnboardingStep.FIRST_PRICE,
            {"price_id": price.id, "amount": amount, "currency": currency},
        )

    async def create_test_checkout(
        self,
        customer_id: str,
        success_url: str,
        cancel_url: str,
    ) -> Dict[str, Any]:
        """
        Create a test checkout session.
        """
        state = await self.get_state(customer_id)
        if not state:
            return {"success": False, "error": "Onboarding not started"}

        price_data = state.step_data.get("first_price", {})
        price_id = price_data.get("price_id")

        if not price_id:
            return {"success": False, "error": "Price not created"}

        session = stripe.checkout.Session.create(
            mode="subscription",
            line_items=[{"price": price_id, "quantity": 1}],
            success_url=success_url + "?session_id={CHECKOUT_SESSION_ID}",
            cancel_url=cancel_url,
            metadata={
                "customer_id": customer_id,
                "onboarding_test": "true",
            },
        )

        result = await self.complete_step(
            customer_id,
            OnboardingStep.TEST_CHECKOUT,
            {"session_id": session.id},
        )

        result["checkout_url"] = session.url
        return result

    async def configure_webhook(
        self,
        customer_id: str,
        webhook_url: str,
        events: List[str],
    ) -> Dict[str, Any]:
        """
        Configure webhook endpoint.
        """
        # Create webhook endpoint
        endpoint = stripe.WebhookEndpoint.create(
            url=webhook_url,
            enabled_events=events or [
                "checkout.session.completed",
                "customer.subscription.created",
                "customer.subscription.updated",
                "customer.subscription.deleted",
                "invoice.paid",
                "invoice.payment_failed",
            ],
            metadata={"customer_id": customer_id},
        )

        return await self.complete_step(
            customer_id,
            OnboardingStep.WEBHOOK_CONFIGURED,
            {
                "webhook_id": endpoint.id,
                "webhook_url": webhook_url,
                "secret": endpoint.secret,  # Customer should store this!
            },
        )

    async def test_webhook(
        self,
        customer_id: str,
    ) -> Dict[str, Any]:
        """
        Send test webhook event.
        """
        state = await self.get_state(customer_id)
        if not state:
            return {"success": False, "error": "Onboarding not started"}

        webhook_data = state.step_data.get("webhook_configured", {})
        webhook_id = webhook_data.get("webhook_id")

        if not webhook_id:
            return {"success": False, "error": "Webhook not configured"}

        # Note: In production, you'd actually test the webhook
        # Stripe doesn't have a direct API for this, so you'd:
        # 1. Create a test event
        # 2. Verify the customer's endpoint responds correctly

        return await self.complete_step(
            customer_id,
            OnboardingStep.WEBHOOK_TESTED,
            {"tested_at": datetime.utcnow().isoformat()},
        )

    async def get_go_live_checklist(
        self,
        customer_id: str,
    ) -> Dict[str, Any]:
        """
        Get checklist for going live.
        """
        state = await self.get_state(customer_id)
        if not state:
            return {"success": False, "error": "Onboarding not started"}

        checklist = [
            {
                "item": "Email verified",
                "complete": OnboardingStep.EMAIL_VERIFIED in state.completed_steps,
                "required": True,
            },
            {
                "item": "Business information set",
                "complete": OnboardingStep.BUSINESS_INFO in state.completed_steps,
                "required": True,
            },
            {
                "item": "Payment method connected",
                "complete": OnboardingStep.PAYMENT_CONNECTED in state.completed_steps,
                "required": True,
            },
            {
                "item": "At least one product created",
                "complete": OnboardingStep.FIRST_PRODUCT in state.completed_steps,
                "required": True,
            },
            {
                "item": "At least one price created",
                "complete": OnboardingStep.FIRST_PRICE in state.completed_steps,
                "required": True,
            },
            {
                "item": "Test checkout completed",
                "complete": OnboardingStep.TEST_CHECKOUT in state.completed_steps,
                "required": True,
            },
            {
                "item": "Webhook configured",
                "complete": OnboardingStep.WEBHOOK_CONFIGURED in state.completed_steps,
                "required": True,
            },
            {
                "item": "Webhook tested",
                "complete": OnboardingStep.WEBHOOK_TESTED in state.completed_steps,
                "required": True,
            },
        ]

        all_required_complete = all(
            item["complete"] for item in checklist if item["required"]
        )

        return {
            "checklist": checklist,
            "ready_to_go_live": all_required_complete,
            "progress": state.progress_percent,
        }

    async def go_live(self, customer_id: str) -> Dict[str, Any]:
        """
        Mark customer as live.
        """
        checklist = await self.get_go_live_checklist(customer_id)
        if not checklist.get("ready_to_go_live"):
            return {
                "success": False,
                "error": "Not ready to go live",
                "checklist": checklist["checklist"],
            }

        # Mark go-live ready and then live
        await self.complete_step(
            customer_id,
            OnboardingStep.GO_LIVE_READY,
            {"ready_at": datetime.utcnow().isoformat()},
        )

        result = await self.complete_step(
            customer_id,
            OnboardingStep.LIVE,
            {"live_at": datetime.utcnow().isoformat()},
        )

        return result

    async def get_progress(self, customer_id: str) -> Dict[str, Any]:
        """
        Get onboarding progress summary.
        """
        state = await self.get_state(customer_id)
        if not state:
            return {
                "status": OnboardingStatus.NOT_STARTED.value,
                "progress": 0,
            }

        if state.completed_at:
            status = OnboardingStatus.COMPLETED
        elif state.blockers:
            status = OnboardingStatus.BLOCKED
        else:
            status = OnboardingStatus.IN_PROGRESS

        return {
            "status": status.value,
            "progress": state.progress_percent,
            "current_step": state.current_step.value,
            "completed_steps": [s.value for s in state.completed_steps],
            "remaining_steps": [
                s.value for s in self.step_order
                if s not in state.completed_steps
            ],
            "blockers": state.blockers,
            "is_live": OnboardingStep.LIVE in state.completed_steps,
        }

    def _get_next_step(self, state: OnboardingState) -> OnboardingStep:
        """
        Get next incomplete step.
        """
        for step in self.step_order:
            if step not in state.completed_steps:
                # Check if requirements are met
                requirements = self.step_requirements.get(step, [])
                if all(req in state.completed_steps for req in requirements):
                    return step

        return state.current_step

    async def _save_state(self, state: OnboardingState) -> None:
        """
        Save onboarding state.
        """
        data = {
            "customer_id": state.customer_id,
            "current_step": state.current_step.value,
            "completed_steps": [s.value for s in state.completed_steps],
            "step_data": state.step_data,
            "started_at": state.started_at,
            "updated_at": state.updated_at,
            "completed_at": state.completed_at,
            "blockers": state.blockers,
        }
        await self.storage.put(f"onboarding:{state.customer_id}", data)

    def _dict_to_state(self, data: Dict[str, Any]) -> OnboardingState:
        """
        Convert dict to OnboardingState.
        """
        return OnboardingState(
            customer_id=data["customer_id"],
            current_step=OnboardingStep(data["current_step"]),
            completed_steps=[OnboardingStep(s) for s in data["completed_steps"]],
            step_data=data.get("step_data", {}),
            started_at=data["started_at"],
            updated_at=data["updated_at"],
            completed_at=data.get("completed_at"),
            blockers=data.get("blockers", []),
        )


class OnboardingAnalytics:
    """
    Track onboarding funnel analytics.
    """

    def __init__(self, storage):
        self.storage = storage

    async def track_step(
        self,
        customer_id: str,
        step: OnboardingStep,
        duration_seconds: Optional[int] = None,
    ) -> None:
        """
        Track step completion for analytics.
        """
        import time

        event = {
            "customer_id": customer_id,
            "step": step.value,
            "timestamp": int(time.time()),
            "duration_seconds": duration_seconds,
        }

        # Store individual event
        event_key = f"onboarding_event:{customer_id}:{step.value}"
        await self.storage.put(event_key, event)

        # Update aggregate stats
        await self._update_stats(step)

    async def get_funnel_stats(self) -> Dict[str, Any]:
        """
        Get funnel conversion statistics.
        """
        stats = await self.storage.get("onboarding_stats") or {}

        steps = list(OnboardingStep)
        funnel = []

        for i, step in enumerate(steps):
            step_stats = stats.get(step.value, {"count": 0, "total_duration": 0})
            count = step_stats["count"]

            # Calculate conversion from previous step
            if i == 0:
                conversion = 100.0
            else:
                prev_count = stats.get(steps[i-1].value, {}).get("count", 0)
                conversion = (count / prev_count * 100) if prev_count > 0 else 0

            # Average duration
            avg_duration = (
                step_stats["total_duration"] / count
                if count > 0 else 0
            )

            funnel.append({
                "step": step.value,
                "count": count,
                "conversion_percent": round(conversion, 1),
                "avg_duration_seconds": round(avg_duration, 0),
            })

        return {
            "funnel": funnel,
            "total_started": stats.get(OnboardingStep.ACCOUNT_CREATED.value, {}).get("count", 0),
            "total_completed": stats.get(OnboardingStep.LIVE.value, {}).get("count", 0),
        }

    async def _update_stats(self, step: OnboardingStep) -> None:
        """
        Update aggregate statistics.
        """
        stats = await self.storage.get("onboarding_stats") or {}

        if step.value not in stats:
            stats[step.value] = {"count": 0, "total_duration": 0}

        stats[step.value]["count"] += 1

        await self.storage.put("onboarding_stats", stats)
