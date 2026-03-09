"""
RoadPayment - Payment Processing for BlackRoad
Process payments, subscriptions, and refunds.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from decimal import Decimal
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import hashlib
import json
import logging
import secrets
import threading
import uuid

logger = logging.getLogger(__name__)


class Currency(str, Enum):
    USD = "USD"
    EUR = "EUR"
    GBP = "GBP"
    BTC = "BTC"
    ETH = "ETH"


class PaymentStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"
    CANCELLED = "cancelled"


class PaymentMethod(str, Enum):
    CARD = "card"
    BANK = "bank"
    WALLET = "wallet"
    CRYPTO = "crypto"


class SubscriptionStatus(str, Enum):
    ACTIVE = "active"
    PAUSED = "paused"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


class BillingInterval(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


@dataclass
class Money:
    amount: Decimal
    currency: Currency

    def __add__(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount + other.amount, self.currency)

    def __sub__(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount - other.amount, self.currency)

    def to_dict(self) -> Dict[str, Any]:
        return {"amount": str(self.amount), "currency": self.currency.value}


@dataclass
class PaymentMethodInfo:
    id: str
    type: PaymentMethod
    last_four: str = ""
    brand: str = ""
    exp_month: int = 0
    exp_year: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Customer:
    id: str
    email: str
    name: str = ""
    payment_methods: List[PaymentMethodInfo] = field(default_factory=list)
    default_payment_method: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)


@dataclass
class Payment:
    id: str
    customer_id: str
    amount: Money
    status: PaymentStatus = PaymentStatus.PENDING
    payment_method_id: Optional[str] = None
    description: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    error: Optional[str] = None


@dataclass
class Refund:
    id: str
    payment_id: str
    amount: Money
    reason: str = ""
    status: PaymentStatus = PaymentStatus.PENDING
    created_at: datetime = field(default_factory=datetime.now)


@dataclass
class Plan:
    id: str
    name: str
    amount: Money
    interval: BillingInterval
    interval_count: int = 1
    trial_days: int = 0
    features: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Subscription:
    id: str
    customer_id: str
    plan_id: str
    status: SubscriptionStatus = SubscriptionStatus.ACTIVE
    current_period_start: datetime = field(default_factory=datetime.now)
    current_period_end: Optional[datetime] = None
    trial_end: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class PaymentProvider:
    async def charge(self, customer: Customer, amount: Money, payment_method_id: str) -> tuple:
        raise NotImplementedError

    async def refund(self, payment_id: str, amount: Money) -> tuple:
        raise NotImplementedError


class MockPaymentProvider(PaymentProvider):
    async def charge(self, customer: Customer, amount: Money, payment_method_id: str) -> tuple:
        logger.info(f"Charging {amount.amount} {amount.currency.value} to {customer.email}")
        return True, {"provider_id": secrets.token_hex(16)}

    async def refund(self, payment_id: str, amount: Money) -> tuple:
        logger.info(f"Refunding {amount.amount} {amount.currency.value} for {payment_id}")
        return True, {"provider_id": secrets.token_hex(16)}


class PaymentProcessor:
    def __init__(self, provider: PaymentProvider = None):
        self.provider = provider or MockPaymentProvider()
        self.customers: Dict[str, Customer] = {}
        self.payments: Dict[str, Payment] = {}
        self.refunds: Dict[str, Refund] = {}
        self.plans: Dict[str, Plan] = {}
        self.subscriptions: Dict[str, Subscription] = {}
        self.hooks: Dict[str, List[Callable]] = {
            "payment.created": [], "payment.completed": [], "payment.failed": [],
            "subscription.created": [], "subscription.cancelled": [],
            "refund.created": [], "refund.completed": []
        }
        self._lock = threading.Lock()

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self.hooks:
            self.hooks[event].append(handler)

    def _emit(self, event: str, data: Any) -> None:
        for handler in self.hooks.get(event, []):
            try:
                handler(data)
            except Exception as e:
                logger.error(f"Hook error: {e}")

    def create_customer(self, email: str, name: str = "", **metadata) -> Customer:
        customer = Customer(
            id=f"cus_{secrets.token_hex(8)}",
            email=email,
            name=name,
            metadata=metadata
        )
        with self._lock:
            self.customers[customer.id] = customer
        return customer

    def get_customer(self, customer_id: str) -> Optional[Customer]:
        return self.customers.get(customer_id)

    def add_payment_method(self, customer_id: str, method_type: PaymentMethod, **kwargs) -> Optional[PaymentMethodInfo]:
        customer = self.customers.get(customer_id)
        if not customer:
            return None
        
        method = PaymentMethodInfo(
            id=f"pm_{secrets.token_hex(8)}",
            type=method_type,
            **kwargs
        )
        customer.payment_methods.append(method)
        if not customer.default_payment_method:
            customer.default_payment_method = method.id
        return method

    async def create_payment(self, customer_id: str, amount: Decimal, currency: Currency, payment_method_id: str = None, description: str = "") -> Payment:
        customer = self.customers.get(customer_id)
        if not customer:
            raise ValueError("Customer not found")
        
        pm_id = payment_method_id or customer.default_payment_method
        if not pm_id:
            raise ValueError("No payment method")
        
        payment = Payment(
            id=f"pay_{secrets.token_hex(8)}",
            customer_id=customer_id,
            amount=Money(amount, currency),
            payment_method_id=pm_id,
            description=description
        )
        
        with self._lock:
            self.payments[payment.id] = payment
        self._emit("payment.created", payment)
        
        payment.status = PaymentStatus.PROCESSING
        success, result = await self.provider.charge(customer, payment.amount, pm_id)
        
        if success:
            payment.status = PaymentStatus.COMPLETED
            payment.completed_at = datetime.now()
            payment.metadata.update(result)
            self._emit("payment.completed", payment)
        else:
            payment.status = PaymentStatus.FAILED
            payment.error = result.get("error", "Payment failed")
            self._emit("payment.failed", payment)
        
        return payment

    async def create_refund(self, payment_id: str, amount: Decimal = None, reason: str = "") -> Optional[Refund]:
        payment = self.payments.get(payment_id)
        if not payment or payment.status != PaymentStatus.COMPLETED:
            return None
        
        refund_amount = Money(amount or payment.amount.amount, payment.amount.currency)
        
        refund = Refund(
            id=f"ref_{secrets.token_hex(8)}",
            payment_id=payment_id,
            amount=refund_amount,
            reason=reason
        )
        
        with self._lock:
            self.refunds[refund.id] = refund
        self._emit("refund.created", refund)
        
        success, result = await self.provider.refund(payment_id, refund_amount)
        
        if success:
            refund.status = PaymentStatus.COMPLETED
            payment.status = PaymentStatus.REFUNDED
            self._emit("refund.completed", refund)
        else:
            refund.status = PaymentStatus.FAILED
        
        return refund

    def create_plan(self, name: str, amount: Decimal, currency: Currency, interval: BillingInterval, **kwargs) -> Plan:
        plan = Plan(
            id=f"plan_{secrets.token_hex(8)}",
            name=name,
            amount=Money(amount, currency),
            interval=interval,
            **kwargs
        )
        with self._lock:
            self.plans[plan.id] = plan
        return plan

    def create_subscription(self, customer_id: str, plan_id: str) -> Optional[Subscription]:
        customer = self.customers.get(customer_id)
        plan = self.plans.get(plan_id)
        
        if not customer or not plan:
            return None
        
        now = datetime.now()
        period_end = self._calculate_period_end(now, plan.interval, plan.interval_count)
        trial_end = now + timedelta(days=plan.trial_days) if plan.trial_days else None
        
        subscription = Subscription(
            id=f"sub_{secrets.token_hex(8)}",
            customer_id=customer_id,
            plan_id=plan_id,
            current_period_end=period_end,
            trial_end=trial_end
        )
        
        with self._lock:
            self.subscriptions[subscription.id] = subscription
        self._emit("subscription.created", subscription)
        
        return subscription

    def cancel_subscription(self, subscription_id: str) -> bool:
        subscription = self.subscriptions.get(subscription_id)
        if not subscription:
            return False
        
        subscription.status = SubscriptionStatus.CANCELLED
        subscription.cancelled_at = datetime.now()
        self._emit("subscription.cancelled", subscription)
        return True

    def _calculate_period_end(self, start: datetime, interval: BillingInterval, count: int) -> datetime:
        if interval == BillingInterval.DAILY:
            return start + timedelta(days=count)
        elif interval == BillingInterval.WEEKLY:
            return start + timedelta(weeks=count)
        elif interval == BillingInterval.MONTHLY:
            return start + timedelta(days=30 * count)
        else:
            return start + timedelta(days=365 * count)

    def list_payments(self, customer_id: str = None) -> List[Payment]:
        payments = list(self.payments.values())
        if customer_id:
            payments = [p for p in payments if p.customer_id == customer_id]
        return sorted(payments, key=lambda p: p.created_at, reverse=True)


async def example_usage():
    processor = PaymentProcessor()
    
    customer = processor.create_customer("alice@example.com", "Alice")
    print(f"Created customer: {customer.id}")
    
    processor.add_payment_method(customer.id, PaymentMethod.CARD, last_four="4242", brand="visa", exp_month=12, exp_year=2025)
    
    payment = await processor.create_payment(customer.id, Decimal("99.99"), Currency.USD, description="Pro Plan")
    print(f"Payment: {payment.id} - {payment.status.value}")
    
    plan = processor.create_plan("Pro", Decimal("29.99"), Currency.USD, BillingInterval.MONTHLY, trial_days=14, features=["Unlimited access", "Priority support"])
    print(f"Plan: {plan.id} - {plan.name}")
    
    subscription = processor.create_subscription(customer.id, plan.id)
    print(f"Subscription: {subscription.id} - {subscription.status.value}")

