"""Tests for BlackRoad Subscription Manager."""
import pytest
from subscriptions import (
    init_db, create_plan, get_plan, list_plans,
    subscribe, get_subscription, cancel_subscription,
    pause_subscription, resume_subscription, upgrade_plan,
    process_renewal, get_mrr, get_arr, churn_rate, revenue_forecast,
    subscription_stats, list_subscriptions, get_billing_history,
)


@pytest.fixture
def db(tmp_path):
    path = str(tmp_path / "test_subs.db")
    init_db(path)
    return path


@pytest.fixture
def basic_plan(db):
    return create_plan("Starter", 29.0, "monthly", ["feature_a", "feature_b"], path=db)


@pytest.fixture
def annual_plan(db):
    return create_plan("Pro Annual", 240.0, "annual", ["all_features"], path=db)


@pytest.fixture
def trial_plan(db):
    return create_plan("Trial Plan", 49.0, "monthly", ["feature_x"], trial_days=14, path=db)


def test_create_plan(db):
    plan = create_plan("Basic", 19.0, "monthly", ["f1", "f2"], path=db)
    assert plan.name == "Basic"
    assert plan.price == 19.0
    assert plan.billing_cycle == "monthly"
    assert "f1" in plan.features
    assert plan.active is True


def test_plan_monthly_price(db):
    monthly = create_plan("M", 30.0, "monthly", path=db)
    annual = create_plan("A", 240.0, "annual", path=db)
    assert monthly.monthly_price == 30.0
    assert annual.monthly_price == 20.0


def test_create_plan_invalid_cycle(db):
    with pytest.raises(ValueError, match="billing_cycle"):
        create_plan("Bad", 10.0, "weekly", path=db)


def test_create_plan_negative_price(db):
    with pytest.raises(ValueError, match="price"):
        create_plan("Neg", -5.0, path=db)


def test_list_plans(db, basic_plan, annual_plan):
    plans = list_plans(path=db)
    names = [p.name for p in plans]
    assert "Starter" in names
    assert "Pro Annual" in names


def test_get_plan_not_found(db):
    with pytest.raises(KeyError):
        get_plan("nonexistent", db)


def test_subscribe_no_trial(db, basic_plan):
    sub = subscribe("cust_001", basic_plan.id, path=db)
    assert sub.customer_id == "cust_001"
    assert sub.status == "active"
    assert sub.trial_end is None
    assert sub.current_period_end > sub.current_period_start


def test_subscribe_with_trial(db, trial_plan):
    sub = subscribe("cust_002", trial_plan.id, path=db)
    assert sub.status == "trial"
    assert sub.trial_end is not None


def test_subscribe_annual(db, annual_plan):
    sub = subscribe("cust_003", annual_plan.id, path=db)
    assert sub.status == "active"
    # annual period should be ~365 days
    from datetime import datetime
    start = datetime.fromisoformat(sub.current_period_start)
    end = datetime.fromisoformat(sub.current_period_end)
    assert (end - start).days >= 364


def test_cancel_subscription(db, basic_plan):
    sub = subscribe("cust_004", basic_plan.id, path=db)
    cancelled = cancel_subscription(sub.id, "testing", db)
    assert cancelled.status == "cancelled"
    assert cancelled.cancel_reason == "testing"
    assert cancelled.cancelled_at is not None


def test_cancel_already_cancelled(db, basic_plan):
    sub = subscribe("cust_005", basic_plan.id, path=db)
    cancel_subscription(sub.id, path=db)
    with pytest.raises(ValueError, match="already cancelled"):
        cancel_subscription(sub.id, path=db)


def test_pause_subscription(db, basic_plan):
    sub = subscribe("cust_006", basic_plan.id, path=db)
    paused = pause_subscription(sub.id, db)
    assert paused.status == "paused"
    assert paused.pause_start is not None


def test_pause_cancelled_fails(db, basic_plan):
    sub = subscribe("cust_007", basic_plan.id, path=db)
    cancel_subscription(sub.id, path=db)
    with pytest.raises(ValueError):
        pause_subscription(sub.id, db)


def test_resume_subscription(db, basic_plan):
    sub = subscribe("cust_008", basic_plan.id, path=db)
    pause_subscription(sub.id, db)
    resumed = resume_subscription(sub.id, db)
    assert resumed.status == "active"


def test_resume_not_paused_fails(db, basic_plan):
    sub = subscribe("cust_009", basic_plan.id, path=db)
    with pytest.raises(ValueError, match="not paused"):
        resume_subscription(sub.id, db)


def test_upgrade_plan(db, basic_plan, annual_plan):
    sub = subscribe("cust_010", basic_plan.id, path=db)
    upgraded = upgrade_plan(sub.id, annual_plan.id, db)
    assert upgraded.plan_id == annual_plan.id


def test_upgrade_cancelled_fails(db, basic_plan, annual_plan):
    sub = subscribe("cust_011", basic_plan.id, path=db)
    cancel_subscription(sub.id, path=db)
    with pytest.raises(ValueError, match="cancelled"):
        upgrade_plan(sub.id, annual_plan.id, db)


def test_process_renewal(db, basic_plan):
    sub = subscribe("cust_012", basic_plan.id, path=db)
    event = process_renewal(sub.id, db)
    assert event.status == "success"
    assert event.amount == basic_plan.price
    assert event.type == "charge"
    refreshed = get_subscription(sub.id, db)
    assert refreshed.current_period_start == sub.current_period_end


def test_process_renewal_cancelled_fails(db, basic_plan):
    sub = subscribe("cust_013", basic_plan.id, path=db)
    cancel_subscription(sub.id, path=db)
    with pytest.raises(ValueError):
        process_renewal(sub.id, db)


def test_get_mrr(db, basic_plan):
    subscribe("cust_m1", basic_plan.id, path=db)
    subscribe("cust_m2", basic_plan.id, path=db)
    mrr = get_mrr(db)
    assert mrr >= basic_plan.monthly_price * 2


def test_get_arr(db, basic_plan):
    subscribe("cust_a1", basic_plan.id, path=db)
    arr = get_arr(db)
    assert arr == pytest.approx(get_mrr(db) * 12)


def test_churn_rate_no_churn(db, basic_plan):
    subscribe("cust_nc1", basic_plan.id, path=db)
    rate = churn_rate(30, db)
    assert rate == 0.0


def test_churn_rate_with_churn(db, basic_plan):
    sub = subscribe("cust_ch1", basic_plan.id, path=db)
    cancel_subscription(sub.id, "churn test", db)
    rate = churn_rate(30, db)
    assert rate > 0


def test_revenue_forecast(db, basic_plan):
    subscribe("cust_f1", basic_plan.id, path=db)
    forecast = revenue_forecast(3, db)
    assert len(forecast) == 3
    assert all("projected_mrr" in f for f in forecast)
    assert all("month_label" in f for f in forecast)


def test_subscription_stats(db, basic_plan):
    subscribe("cust_s1", basic_plan.id, path=db)
    sub2 = subscribe("cust_s2", basic_plan.id, path=db)
    cancel_subscription(sub2.id, path=db)
    stats = subscription_stats(db)
    assert stats["total_subscriptions"] >= 2
    assert "active" in stats["by_status"]
    assert stats["mrr"] > 0


def test_list_subscriptions_by_customer(db, basic_plan):
    subscribe("filter_cust", basic_plan.id, path=db)
    subscribe("filter_cust", basic_plan.id, path=db)
    subscribe("other_cust", basic_plan.id, path=db)
    results = list_subscriptions(customer_id="filter_cust", path=db)
    assert all(s.customer_id == "filter_cust" for s in results)
    assert len(results) == 2


def test_list_subscriptions_by_status(db, basic_plan):
    sub = subscribe("cust_ls1", basic_plan.id, path=db)
    cancel_subscription(sub.id, path=db)
    cancelled = list_subscriptions(status="cancelled", path=db)
    assert any(s.id == sub.id for s in cancelled)


def test_billing_history(db, basic_plan):
    sub = subscribe("cust_bh1", basic_plan.id, path=db)
    process_renewal(sub.id, db)
    history = get_billing_history(subscription_id=sub.id, path=db)
    assert len(history) >= 1
    assert history[0].amount == basic_plan.price
