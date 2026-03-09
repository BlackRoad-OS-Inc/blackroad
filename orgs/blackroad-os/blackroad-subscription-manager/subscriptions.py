#!/usr/bin/env python3
"""
BlackRoad Subscription Manager
Production-grade SaaS subscription management with plans, billing cycles, MRR, churn, and forecasting.
"""
from __future__ import annotations
import argparse
import json
import os
import sqlite3
import uuid
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta
from typing import List, Optional, Dict

DB_PATH = os.path.expanduser("~/.blackroad/subscriptions.db")


@dataclass
class Plan:
    id: str
    name: str
    price: float
    billing_cycle: str    # monthly | annual
    features: List[str]
    trial_days: int
    currency: str
    active: bool = True
    created_at: str = ""

    @property
    def monthly_price(self) -> float:
        if self.billing_cycle == "annual":
            return round(self.price / 12, 2)
        return self.price

    def to_dict(self) -> dict:
        d = asdict(self)
        d["monthly_price"] = self.monthly_price
        return d


@dataclass
class Subscription:
    id: str
    customer_id: str
    plan_id: str
    status: str           # trial | active | paused | cancelled | expired
    current_period_start: str
    current_period_end: str
    created_at: str
    cancelled_at: Optional[str] = None
    cancel_reason: Optional[str] = None
    stripe_sub_id: Optional[str] = None
    trial_end: Optional[str] = None
    pause_start: Optional[str] = None

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class BillingEvent:
    id: str
    subscription_id: str
    customer_id: str
    plan_id: str
    amount: float
    currency: str
    type: str            # charge | refund | credit
    status: str          # success | failed | pending
    period_start: str
    period_end: str
    created_at: str

    def to_dict(self) -> dict:
        return asdict(self)


def _now() -> str:
    return datetime.utcnow().isoformat()


def _add_period(dt_str: str, billing_cycle: str) -> str:
    dt = datetime.fromisoformat(dt_str)
    if billing_cycle == "annual":
        try:
            return dt.replace(year=dt.year + 1).isoformat()
        except ValueError:
            return (dt + timedelta(days=365)).isoformat()
    else:
        try:
            return dt.replace(month=dt.month + 1).isoformat()
        except ValueError:
            return (dt + timedelta(days=30)).isoformat()


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def get_db(path: str = DB_PATH) -> sqlite3.Connection:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def init_db(path: str = DB_PATH) -> None:
    with get_db(path) as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS plans (
                id            TEXT PRIMARY KEY,
                name          TEXT UNIQUE NOT NULL,
                price         REAL NOT NULL,
                billing_cycle TEXT NOT NULL CHECK(billing_cycle IN ('monthly','annual')),
                features      TEXT NOT NULL DEFAULT '[]',
                trial_days    INTEGER NOT NULL DEFAULT 0,
                currency      TEXT NOT NULL DEFAULT 'USD',
                active        INTEGER NOT NULL DEFAULT 1,
                created_at    TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS subscriptions (
                id                   TEXT PRIMARY KEY,
                customer_id          TEXT NOT NULL,
                plan_id              TEXT NOT NULL REFERENCES plans(id),
                status               TEXT NOT NULL DEFAULT 'trial',
                current_period_start TEXT NOT NULL,
                current_period_end   TEXT NOT NULL,
                created_at           TEXT NOT NULL,
                cancelled_at         TEXT,
                cancel_reason        TEXT,
                stripe_sub_id        TEXT,
                trial_end            TEXT,
                pause_start          TEXT
            );
            CREATE TABLE IF NOT EXISTS billing_events (
                id              TEXT PRIMARY KEY,
                subscription_id TEXT NOT NULL,
                customer_id     TEXT NOT NULL,
                plan_id         TEXT NOT NULL,
                amount          REAL NOT NULL,
                currency        TEXT NOT NULL DEFAULT 'USD',
                type            TEXT NOT NULL,
                status          TEXT NOT NULL DEFAULT 'pending',
                period_start    TEXT NOT NULL,
                period_end      TEXT NOT NULL,
                created_at      TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_sub_customer ON subscriptions(customer_id);
            CREATE INDEX IF NOT EXISTS idx_sub_plan     ON subscriptions(plan_id);
            CREATE INDEX IF NOT EXISTS idx_sub_status   ON subscriptions(status);
            CREATE INDEX IF NOT EXISTS idx_bill_sub     ON billing_events(subscription_id);
        """)


# ---------------------------------------------------------------------------
# Plan management
# ---------------------------------------------------------------------------

def create_plan(
    name: str,
    price: float,
    billing_cycle: str = "monthly",
    features: Optional[List[str]] = None,
    trial_days: int = 0,
    currency: str = "USD",
    path: str = DB_PATH,
) -> Plan:
    if billing_cycle not in ("monthly", "annual"):
        raise ValueError("billing_cycle must be 'monthly' or 'annual'")
    if price < 0:
        raise ValueError("price must be non-negative")
    plan = Plan(
        id=str(uuid.uuid4()),
        name=name,
        price=price,
        billing_cycle=billing_cycle,
        features=features or [],
        trial_days=trial_days,
        currency=currency,
        created_at=_now(),
    )
    with get_db(path) as conn:
        conn.execute(
            """INSERT INTO plans (id, name, price, billing_cycle, features, trial_days, currency, active, created_at)
               VALUES (?,?,?,?,?,?,?,?,?)""",
            (plan.id, plan.name, plan.price, plan.billing_cycle,
             json.dumps(plan.features), plan.trial_days, plan.currency, 1, plan.created_at),
        )
    return plan


def get_plan(plan_id: str, path: str = DB_PATH) -> Plan:
    with get_db(path) as conn:
        row = conn.execute("SELECT * FROM plans WHERE id=?", (plan_id,)).fetchone()
    if not row:
        raise KeyError(f"Plan {plan_id} not found")
    return _row_to_plan(row)


def list_plans(active_only: bool = True, path: str = DB_PATH) -> List[Plan]:
    with get_db(path) as conn:
        if active_only:
            rows = conn.execute("SELECT * FROM plans WHERE active=1 ORDER BY price").fetchall()
        else:
            rows = conn.execute("SELECT * FROM plans ORDER BY price").fetchall()
    return [_row_to_plan(r) for r in rows]


# ---------------------------------------------------------------------------
# Subscription operations
# ---------------------------------------------------------------------------

def subscribe(
    customer_id: str,
    plan_id: str,
    stripe_sub_id: Optional[str] = None,
    path: str = DB_PATH,
) -> Subscription:
    """Create a new subscription, starting with a trial if the plan has trial_days > 0."""
    plan = get_plan(plan_id, path)
    now = datetime.utcnow()
    now_str = now.isoformat()

    if plan.trial_days > 0:
        status = "trial"
        trial_end = (now + timedelta(days=plan.trial_days)).isoformat()
        period_start = now_str
        period_end = trial_end
    else:
        status = "active"
        trial_end = None
        period_start = now_str
        period_end = _add_period(now_str, plan.billing_cycle)

    sub = Subscription(
        id=str(uuid.uuid4()),
        customer_id=customer_id,
        plan_id=plan_id,
        status=status,
        current_period_start=period_start,
        current_period_end=period_end,
        created_at=now_str,
        trial_end=trial_end,
        stripe_sub_id=stripe_sub_id,
    )
    with get_db(path) as conn:
        conn.execute(
            """INSERT INTO subscriptions
               (id, customer_id, plan_id, status, current_period_start, current_period_end,
                created_at, stripe_sub_id, trial_end)
               VALUES (?,?,?,?,?,?,?,?,?)""",
            (sub.id, sub.customer_id, sub.plan_id, sub.status,
             sub.current_period_start, sub.current_period_end,
             sub.created_at, sub.stripe_sub_id, sub.trial_end),
        )
    return sub


def get_subscription(sub_id: str, path: str = DB_PATH) -> Subscription:
    with get_db(path) as conn:
        row = conn.execute("SELECT * FROM subscriptions WHERE id=?", (sub_id,)).fetchone()
    if not row:
        raise KeyError(f"Subscription {sub_id} not found")
    return _row_to_sub(row)


def cancel_subscription(
    sub_id: str,
    reason: str = "",
    path: str = DB_PATH,
) -> Subscription:
    """Cancel a subscription immediately."""
    with get_db(path) as conn:
        row = conn.execute("SELECT * FROM subscriptions WHERE id=?", (sub_id,)).fetchone()
        if not row:
            raise KeyError(f"Subscription {sub_id} not found")
        if row["status"] == "cancelled":
            raise ValueError("Subscription already cancelled")
        conn.execute(
            "UPDATE subscriptions SET status='cancelled', cancelled_at=?, cancel_reason=? WHERE id=?",
            (_now(), reason, sub_id),
        )
    return get_subscription(sub_id, path)


def pause_subscription(sub_id: str, path: str = DB_PATH) -> Subscription:
    """Pause a subscription."""
    with get_db(path) as conn:
        row = conn.execute("SELECT * FROM subscriptions WHERE id=?", (sub_id,)).fetchone()
        if not row:
            raise KeyError(f"Subscription {sub_id} not found")
        if row["status"] not in ("active", "trial"):
            raise ValueError(f"Cannot pause subscription with status '{row['status']}'")
        conn.execute(
            "UPDATE subscriptions SET status='paused', pause_start=? WHERE id=?",
            (_now(), sub_id),
        )
    return get_subscription(sub_id, path)


def resume_subscription(sub_id: str, path: str = DB_PATH) -> Subscription:
    """Resume a paused subscription."""
    with get_db(path) as conn:
        row = conn.execute("SELECT * FROM subscriptions WHERE id=?", (sub_id,)).fetchone()
        if not row:
            raise KeyError(f"Subscription {sub_id} not found")
        if row["status"] != "paused":
            raise ValueError("Subscription is not paused")
        conn.execute(
            "UPDATE subscriptions SET status='active', pause_start=NULL WHERE id=?", (sub_id,)
        )
    return get_subscription(sub_id, path)


def upgrade_plan(
    sub_id: str,
    new_plan_id: str,
    path: str = DB_PATH,
) -> Subscription:
    """Upgrade or downgrade a subscription to a new plan."""
    get_plan(new_plan_id, path)  # validate plan exists
    with get_db(path) as conn:
        row = conn.execute("SELECT * FROM subscriptions WHERE id=?", (sub_id,)).fetchone()
        if not row:
            raise KeyError(f"Subscription {sub_id} not found")
        if row["status"] == "cancelled":
            raise ValueError("Cannot change plan on a cancelled subscription")
        conn.execute(
            "UPDATE subscriptions SET plan_id=? WHERE id=?", (new_plan_id, sub_id)
        )
    return get_subscription(sub_id, path)


def process_renewal(sub_id: str, path: str = DB_PATH) -> BillingEvent:
    """Process a renewal for an active subscription."""
    sub = get_subscription(sub_id, path)
    plan = get_plan(sub.plan_id, path)

    if sub.status not in ("active", "trial"):
        raise ValueError(f"Cannot renew subscription with status '{sub.status}'")

    now = _now()
    new_start = sub.current_period_end
    new_end = _add_period(new_start, plan.billing_cycle)

    event = BillingEvent(
        id=str(uuid.uuid4()),
        subscription_id=sub_id,
        customer_id=sub.customer_id,
        plan_id=sub.plan_id,
        amount=plan.price,
        currency=plan.currency,
        type="charge",
        status="success",
        period_start=new_start,
        period_end=new_end,
        created_at=now,
    )
    with get_db(path) as conn:
        conn.execute(
            """INSERT INTO billing_events
               (id, subscription_id, customer_id, plan_id, amount, currency, type, status,
                period_start, period_end, created_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
            (event.id, event.subscription_id, event.customer_id, event.plan_id,
             event.amount, event.currency, event.type, event.status,
             event.period_start, event.period_end, event.created_at),
        )
        conn.execute(
            """UPDATE subscriptions
               SET status='active', current_period_start=?, current_period_end=?
               WHERE id=?""",
            (new_start, new_end, sub_id),
        )
    return event


# ---------------------------------------------------------------------------
# Analytics
# ---------------------------------------------------------------------------

def get_mrr(path: str = DB_PATH) -> float:
    """Calculate Monthly Recurring Revenue from all active subscriptions."""
    with get_db(path) as conn:
        rows = conn.execute(
            """SELECT s.plan_id FROM subscriptions s
               WHERE s.status IN ('active', 'trial')""",
        ).fetchall()
    total = 0.0
    for r in rows:
        try:
            plan = get_plan(r["plan_id"], path)
            total += plan.monthly_price
        except KeyError:
            pass
    return round(total, 2)


def get_arr(path: str = DB_PATH) -> float:
    """Annual Recurring Revenue = MRR x 12."""
    return round(get_mrr(path) * 12, 2)


def churn_rate(period_days: int = 30, path: str = DB_PATH) -> float:
    """Calculate churn rate for the last N days as a percentage."""
    cutoff = (datetime.utcnow() - timedelta(days=period_days)).isoformat()
    with get_db(path) as conn:
        total_at_start = conn.execute(
            "SELECT COUNT(*) as cnt FROM subscriptions WHERE created_at <= ?", (cutoff,)
        ).fetchone()["cnt"]
        churned = conn.execute(
            "SELECT COUNT(*) as cnt FROM subscriptions WHERE status='cancelled' AND cancelled_at >= ?",
            (cutoff,),
        ).fetchone()["cnt"]
    if total_at_start == 0:
        return 0.0
    return round((churned / total_at_start) * 100, 2)


def revenue_forecast(months: int = 3, path: str = DB_PATH) -> List[Dict]:
    """Forecast revenue for the next N months based on current MRR and historical churn."""
    mrr = get_mrr(path)
    monthly_churn = churn_rate(30, path) / 100
    forecast = []
    running_mrr = mrr
    for m in range(1, months + 1):
        month_dt = datetime.utcnow()
        try:
            month_dt = month_dt.replace(month=(month_dt.month - 1 + m) % 12 + 1)
        except ValueError:
            pass
        running_mrr = round(running_mrr * (1 - monthly_churn), 2)
        forecast.append({
            "month": m,
            "month_label": month_dt.strftime("%Y-%m"),
            "projected_mrr": running_mrr,
            "projected_arr": round(running_mrr * 12, 2),
        })
    return forecast


def subscription_stats(path: str = DB_PATH) -> Dict:
    """Return overall subscription statistics."""
    with get_db(path) as conn:
        total = conn.execute("SELECT COUNT(*) as cnt FROM subscriptions").fetchone()["cnt"]
        by_status = conn.execute(
            "SELECT status, COUNT(*) as cnt FROM subscriptions GROUP BY status"
        ).fetchall()
        by_plan = conn.execute(
            """SELECT p.name, COUNT(*) as cnt
               FROM subscriptions s JOIN plans p ON s.plan_id=p.id
               WHERE s.status IN ('active','trial')
               GROUP BY p.name ORDER BY cnt DESC"""
        ).fetchall()
    return {
        "total_subscriptions": total,
        "by_status": {r["status"]: r["cnt"] for r in by_status},
        "active_by_plan": {r["name"]: r["cnt"] for r in by_plan},
        "mrr": get_mrr(path),
        "arr": get_arr(path),
        "churn_rate_30d": churn_rate(30, path),
    }


def list_subscriptions(
    customer_id: Optional[str] = None,
    status: Optional[str] = None,
    path: str = DB_PATH,
) -> List[Subscription]:
    with get_db(path) as conn:
        query = "SELECT * FROM subscriptions WHERE 1=1"
        params = []
        if customer_id:
            query += " AND customer_id=?"
            params.append(customer_id)
        if status:
            query += " AND status=?"
            params.append(status)
        query += " ORDER BY created_at DESC"
        rows = conn.execute(query, params).fetchall()
    return [_row_to_sub(r) for r in rows]


def get_billing_history(
    subscription_id: Optional[str] = None,
    customer_id: Optional[str] = None,
    path: str = DB_PATH,
) -> List[BillingEvent]:
    with get_db(path) as conn:
        query = "SELECT * FROM billing_events WHERE 1=1"
        params = []
        if subscription_id:
            query += " AND subscription_id=?"
            params.append(subscription_id)
        if customer_id:
            query += " AND customer_id=?"
            params.append(customer_id)
        query += " ORDER BY created_at DESC"
        rows = conn.execute(query, params).fetchall()
    return [_row_to_billing(r) for r in rows]


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _row_to_plan(row: sqlite3.Row) -> Plan:
    return Plan(
        id=row["id"], name=row["name"], price=row["price"],
        billing_cycle=row["billing_cycle"],
        features=json.loads(row["features"]),
        trial_days=row["trial_days"], currency=row["currency"],
        active=bool(row["active"]), created_at=row["created_at"],
    )


def _row_to_sub(row: sqlite3.Row) -> Subscription:
    return Subscription(
        id=row["id"], customer_id=row["customer_id"], plan_id=row["plan_id"],
        status=row["status"], current_period_start=row["current_period_start"],
        current_period_end=row["current_period_end"], created_at=row["created_at"],
        cancelled_at=row["cancelled_at"], cancel_reason=row["cancel_reason"],
        stripe_sub_id=row["stripe_sub_id"], trial_end=row["trial_end"],
        pause_start=row["pause_start"],
    )


def _row_to_billing(row: sqlite3.Row) -> BillingEvent:
    return BillingEvent(
        id=row["id"], subscription_id=row["subscription_id"],
        customer_id=row["customer_id"], plan_id=row["plan_id"],
        amount=row["amount"], currency=row["currency"],
        type=row["type"], status=row["status"],
        period_start=row["period_start"], period_end=row["period_end"],
        created_at=row["created_at"],
    )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _print_json(obj) -> None:
    if hasattr(obj, "to_dict"):
        print(json.dumps(obj.to_dict(), indent=2))
    elif isinstance(obj, list):
        print(json.dumps([o.to_dict() if hasattr(o, "to_dict") else o for o in obj], indent=2))
    else:
        print(json.dumps(obj, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="subscriptions", description="BlackRoad Subscription Manager")
    parser.add_argument("--db", default=DB_PATH)
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("init")

    # Plans
    p = sub.add_parser("create-plan")
    p.add_argument("name")
    p.add_argument("price", type=float)
    p.add_argument("--cycle", default="monthly", choices=["monthly", "annual"])
    p.add_argument("--features", default="[]")
    p.add_argument("--trial-days", type=int, default=0)
    p.add_argument("--currency", default="USD")

    sub.add_parser("list-plans")

    p = sub.add_parser("get-plan")
    p.add_argument("plan_id")

    # Subscriptions
    p = sub.add_parser("subscribe")
    p.add_argument("customer_id")
    p.add_argument("plan_id")
    p.add_argument("--stripe-id", default=None)

    p = sub.add_parser("cancel")
    p.add_argument("sub_id")
    p.add_argument("--reason", default="")

    p = sub.add_parser("pause")
    p.add_argument("sub_id")

    p = sub.add_parser("resume")
    p.add_argument("sub_id")

    p = sub.add_parser("upgrade")
    p.add_argument("sub_id")
    p.add_argument("new_plan_id")

    p = sub.add_parser("renew")
    p.add_argument("sub_id")

    p = sub.add_parser("list")
    p.add_argument("--customer", default=None)
    p.add_argument("--status", default=None)

    p = sub.add_parser("get")
    p.add_argument("sub_id")

    # Analytics
    sub.add_parser("mrr")
    sub.add_parser("arr")

    p = sub.add_parser("churn")
    p.add_argument("--days", type=int, default=30)

    p = sub.add_parser("forecast")
    p.add_argument("--months", type=int, default=3)

    sub.add_parser("stats")

    p = sub.add_parser("billing")
    p.add_argument("--sub-id", default=None)
    p.add_argument("--customer", default=None)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    db = args.db
    init_db(db)

    if args.command == "init":
        print("Database initialized.")
    elif args.command == "create-plan":
        features = json.loads(args.features)
        plan = create_plan(args.name, args.price, args.cycle, features, args.trial_days, args.currency, db)
        _print_json(plan)
    elif args.command == "list-plans":
        _print_json(list_plans(path=db))
    elif args.command == "get-plan":
        _print_json(get_plan(args.plan_id, db))
    elif args.command == "subscribe":
        sub = subscribe(args.customer_id, args.plan_id, args.stripe_id, db)
        _print_json(sub)
    elif args.command == "cancel":
        _print_json(cancel_subscription(args.sub_id, args.reason, db))
    elif args.command == "pause":
        _print_json(pause_subscription(args.sub_id, db))
    elif args.command == "resume":
        _print_json(resume_subscription(args.sub_id, db))
    elif args.command == "upgrade":
        _print_json(upgrade_plan(args.sub_id, args.new_plan_id, db))
    elif args.command == "renew":
        _print_json(process_renewal(args.sub_id, db))
    elif args.command == "list":
        _print_json(list_subscriptions(args.customer, args.status, db))
    elif args.command == "get":
        _print_json(get_subscription(args.sub_id, db))
    elif args.command == "mrr":
        print(json.dumps({"mrr": get_mrr(db)}))
    elif args.command == "arr":
        print(json.dumps({"arr": get_arr(db)}))
    elif args.command == "churn":
        print(json.dumps({"churn_rate_pct": churn_rate(args.days, db), "period_days": args.days}))
    elif args.command == "forecast":
        print(json.dumps(revenue_forecast(args.months, db), indent=2))
    elif args.command == "stats":
        print(json.dumps(subscription_stats(db), indent=2))
    elif args.command == "billing":
        _print_json(get_billing_history(args.sub_id, args.customer, db))
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
