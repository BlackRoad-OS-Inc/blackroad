# 💳 GreenLight Billing & Payment Extension

**Extension to GreenLight for Stripe Billing Integration**

---

## 💰 Billing Lifecycle States

Add these to the **Lifecycle States** category:

| Emoji | State | Code | Trinary | Description |
|-------|-------|------|---------|-------------|
| 💳 | CHECKOUT | `checkout` | 0 | Checkout session initiated |
| 💵 | PAYMENT_PENDING | `payment_pending` | +1 | Payment processing |
| 💰 | PAYMENT_SUCCESS | `payment_success` | +1 | Payment completed |
| ❌ | PAYMENT_FAILED | `payment_failed` | -1 | Payment declined/failed |
| 🔁 | RETRY | `retry` | 0 | Payment retry attempt |
| ⏸️ | PAST_DUE | `past_due` | -1 | Subscription past due |
| 🎟️ | TRIAL | `trial` | 0 | Trial period active |
| 🎁 | COUPON_APPLIED | `coupon_applied` | +1 | Discount code applied |

---

## 📦 Subscription States

| Emoji | State | Code | Stripe Status | Description |
|-------|-------|------|---------------|-------------|
| 🆕 | SUB_CREATED | `sub_created` | active | New subscription |
| ✅ | SUB_ACTIVE | `sub_active` | active | Subscription active |
| 🔄 | SUB_UPDATED | `sub_updated` | active | Plan changed |
| ⏸️ | SUB_PAUSED | `sub_paused` | paused | Subscription paused |
| 🚫 | SUB_CANCELED | `sub_canceled` | canceled | Subscription ended |
| ⚠️ | SUB_INCOMPLETE | `sub_incomplete` | incomplete | Payment incomplete |
| 📅 | SUB_EXPIRING | `sub_expiring` | active | Canceling at period end |
| 🔄 | SUB_PAST_DUE | `sub_past_due` | past_due | Payment failed |

---

## 🎯 Billing Tiers

Add to **Domain Tags**:

| Emoji | Tier | Code | Price | Description |
|-------|------|------|-------|-------------|
| 🆓 | FREE | `free` | $0 | Free tier |
| 👤 | INDIVIDUAL | `individual` | $29/mo | Individual plan |
| 💼 | PRO | `pro` | $58/mo | Professional plan |
| 👥 | TEAM | `team` | $99/mo | Team plan |
| 🏢 | ENTERPRISE | `enterprise` | $199/mo | Enterprise plan |
| 🌟 | FOUNDER | `founder` | $5000 | Lifetime founding member |
| 💎 | FOUNDING_PRO | `founding_pro` | $29/mo | 50% founding discount |

---

## 🔔 Webhook Events

Map Stripe webhook events to GreenLight:

| Stripe Event | GreenLight Step | Emoji | State |
|--------------|-----------------|-------|-------|
| webhook received | Step 1: Impulse | ⚡📥 | void → inbox |
| customer.created | Step 4: Record | 📝👤 | inbox → recorded |
| checkout.session.completed | Step 7: Approve | ✅💳 | evaluate → approved |
| subscription.created | Step 13: Execute | ⚙️🆕 | plan → executing |
| invoice.paid | Step 19: Complete | 🎉💰 | executing → complete |
| subscription.updated | Step 14: Iterate | 🔄🔄 | executing → iterate |
| invoice.payment_failed | Step 16: Detect | 🚨❌ | executing → detect |
| subscription.deleted | Step 21: Accept | 🤝🚫 | complete → accepted |
| payment_method.attached | Step 6: Verify | 🔍💳 | record → verified |
| customer.updated | Step 10: Refine | ✨👤 | configure → refined |

---

## 🎨 Composite Patterns for Billing

### Checkout Events
```
⚡📥💳👉  = Checkout started, micro scale
✅💳💰🎢  = Payment successful, macro impact
❌💳🚨🔥  = Payment failed, fire priority
🎁💳✅📌  = Coupon applied, medium priority
```

### Subscription Events
```
🆕🎯💼✅  = New pro subscription created
🔄🎯👥📌  = Team plan upgrade
🚫⚠️💼🔥  = Pro subscription canceled, urgent
⏸️📅💼⭐  = Subscription expiring, high priority
```

### Payment Events
```
💰✅🎢🌍  = Invoice paid, planetary impact
❌🔁💳⭐  = Payment retry, high priority
⚠️🚨💼🔥  = Past due, fire priority
🎟️🆕👤📌  = Trial started, medium priority
```

### Combined Billing Flow
```
[⚡📥] [✅💳] [🆕💼] [💰✅] = Checkout → Payment → Subscription → Paid
[🔄💼→👥] [💰✅] = Upgrade Pro → Team, payment success
[🚨❌] [🔁💳] = Payment failed → retry
```

---

## 📝 NATS Subject Patterns (Billing)

### Checkout Events
```
greenlight.checkout.started.micro.billing.{session_id}
greenlight.checkout.completed.macro.billing.{session_id}
greenlight.checkout.abandoned.micro.billing.{session_id}
```

### Payment Events
```
greenlight.payment.succeeded.macro.billing.{customer_id}
greenlight.payment.failed.micro.billing.{customer_id}
greenlight.payment.retry.micro.billing.{customer_id}
```

### Subscription Events
```
greenlight.subscription.created.{tier}.{customer_id}
greenlight.subscription.updated.{old_tier}.{new_tier}.{customer_id}
greenlight.subscription.canceled.{tier}.{customer_id}
greenlight.subscription.expired.{tier}.{customer_id}
```

### Webhook Events
```
greenlight.webhook.received.stripe.{event_type}
greenlight.webhook.processed.stripe.{event_type}
greenlight.webhook.failed.stripe.{event_type}
```

---

## 🔨 Billing Memory Templates

### Stripe Webhook Events

```bash
# Webhook received
gl_webhook_received() {
    local event_type="$1"
    local event_id="$2"

    gl_log "⚡📥💳👉" "webhook_received" "$event_type" "Stripe webhook: $event_id"
}

# Checkout session completed
gl_checkout_complete() {
    local customer_email="$1"
    local tier="$2"
    local amount="$3"

    local tier_emoji=""
    case "$tier" in
        individual) tier_emoji="👤" ;;
        pro) tier_emoji="💼" ;;
        team) tier_emoji="👥" ;;
        enterprise) tier_emoji="🏢" ;;
        founder) tier_emoji="🌟" ;;
        *) tier_emoji="🎯" ;;
    esac

    gl_log "✅💳${tier_emoji}🎢" "checkout_complete" "$customer_email" \
        "Checkout complete: $tier plan, $$amount"
}

# Subscription created
gl_subscription_created() {
    local customer="$1"
    local tier="$2"
    local subscription_id="$3"

    local tier_emoji=""
    case "$tier" in
        individual) tier_emoji="👤" ;;
        pro) tier_emoji="💼" ;;
        team) tier_emoji="👥" ;;
        enterprise) tier_emoji="🏢" ;;
        founder) tier_emoji="🌟" ;;
        *) tier_emoji="🎯" ;;
    esac

    gl_log "🆕⚙️${tier_emoji}✅" "subscription_created" "$customer" \
        "Subscription created: $tier ($subscription_id)"
}

# Subscription updated (plan change)
gl_subscription_updated() {
    local customer="$1"
    local old_tier="$2"
    local new_tier="$3"

    gl_log "🔄🎯💼📌" "subscription_updated" "$customer" \
        "Plan change: $old_tier → $new_tier"
}

# Subscription canceled
gl_subscription_canceled() {
    local customer="$1"
    local tier="$2"
    local reason="${3:-not specified}"

    gl_log "🚫⚠️💼🔥" "subscription_canceled" "$customer" \
        "Canceled $tier plan. Reason: $reason"
}

# Invoice paid
gl_invoice_paid() {
    local customer="$1"
    local amount="$2"
    local currency="${3:-usd}"

    gl_log "💰✅🎢🌍" "invoice_paid" "$customer" \
        "Payment successful: \$$amount $currency"
}

# Invoice payment failed
gl_invoice_failed() {
    local customer="$1"
    local amount="$2"
    local error="${3:-declined}"

    gl_log "❌🚨💳🔥" "invoice_failed" "$customer" \
        "Payment failed: \$$amount ($error)"
}

# Payment retry
gl_payment_retry() {
    local customer="$1"
    local attempt="$2"

    gl_log "🔁💳⚡⭐" "payment_retry" "$customer" \
        "Payment retry attempt #$attempt"
}

# Coupon applied
gl_coupon_applied() {
    local customer="$1"
    local coupon_code="$2"
    local discount="$3"

    gl_log "🎁💳✅📌" "coupon_applied" "$customer" \
        "Coupon $coupon_code applied: $discount"
}

# Trial started
gl_trial_started() {
    local customer="$1"
    local tier="$2"
    local trial_days="$3"

    gl_log "🎟️🆕👤📌" "trial_started" "$customer" \
        "Trial started: $tier plan, $trial_days days"
}

# Customer created
gl_customer_created() {
    local email="$1"
    local customer_id="$2"

    gl_log "📝👤✅👉" "customer_created" "$email" \
        "Stripe customer: $customer_id"
}

# Payment method attached
gl_payment_method_attached() {
    local customer="$1"
    local pm_type="$2"  # card, bank_account, etc.
    local last4="${3:-****}"

    gl_log "🔍💳✅📌" "payment_method" "$customer" \
        "Payment method added: $pm_type ending in $last4"
}

# Subscription past due
gl_subscription_past_due() {
    local customer="$1"
    local days_overdue="$2"

    gl_log "⚠️🚨💼🔥" "past_due" "$customer" \
        "Subscription past due: $days_overdue days"
}

# Churn prevention (cancellation scheduled)
gl_cancel_scheduled() {
    local customer="$1"
    local tier="$2"
    local cancel_date="$3"

    gl_log "📅⚠️💼⭐" "cancel_scheduled" "$customer" \
        "$tier subscription ends on $cancel_date - retention opportunity!"
}
```

---

## 🎯 Example Integration: Full Checkout Flow

### Scenario: User subscribes to Pro plan

```bash
# 1. Webhook received
gl_webhook_received "checkout.session.completed" "evt_1abc123"
# [⚡📥💳👉] webhook_received: checkout.session.completed — Stripe webhook: evt_1abc123

# 2. Customer created (if new)
gl_customer_created "user@example.com" "cus_abc123"
# [📝👤✅👉] customer_created: user@example.com — Stripe customer: cus_abc123

# 3. Checkout complete
gl_checkout_complete "user@example.com" "pro" "58"
# [✅💳💼🎢] checkout_complete: user@example.com — Checkout complete: pro plan, $58

# 4. Subscription created
gl_subscription_created "user@example.com" "pro" "sub_abc123"
# [🆕⚙️💼✅] subscription_created: user@example.com — Subscription created: pro (sub_abc123)

# 5. Invoice paid
gl_invoice_paid "user@example.com" "58" "usd"
# [💰✅🎢🌍] invoice_paid: user@example.com — Payment successful: $58 usd
```

### Scenario: Payment failed, retry, then cancel

```bash
# 1. Payment failed
gl_invoice_failed "user@example.com" "58" "card_declined"
# [❌🚨💳🔥] invoice_failed: user@example.com — Payment failed: $58 (card_declined)

# 2. Subscription past due
gl_subscription_past_due "user@example.com" "3"
# [⚠️🚨💼🔥] past_due: user@example.com — Subscription past due: 3 days

# 3. Payment retry
gl_payment_retry "user@example.com" "1"
# [🔁💳⚡⭐] payment_retry: user@example.com — Payment retry attempt #1

# 4. Payment retry #2
gl_payment_retry "user@example.com" "2"
# [🔁💳⚡⭐] payment_retry: user@example.com — Payment retry attempt #2

# 5. Subscription canceled (after retry exhaustion)
gl_subscription_canceled "user@example.com" "pro" "payment_failed"
# [🚫⚠️💼🔥] subscription_canceled: user@example.com — Canceled pro plan. Reason: payment_failed
```

### Scenario: Upgrade from Individual to Team

```bash
# 1. Subscription updated
gl_subscription_updated "team@company.com" "individual" "team"
# [🔄🎯💼📌] subscription_updated: team@company.com — Plan change: individual → team

# 2. Invoice paid (proration)
gl_invoice_paid "team@company.com" "70" "usd"
# [💰✅🎢🌍] invoice_paid: team@company.com — Payment successful: $70 usd
```

---

## 📊 Billing Analytics Integration

### Revenue Tracking
```bash
# Daily revenue
gl_log "📊💰🎢📌" "revenue_daily" "billing" "Daily revenue: $1,247.00 (43 invoices)"

# MRR (Monthly Recurring Revenue)
gl_log "📊💰🌌⭐" "mrr_update" "billing" "MRR: $24,567 (+$1,234 this month)"

# Churn rate
gl_log "📊⚠️🎢📌" "churn_rate" "billing" "Churn rate: 3.2% (12 cancellations)"
```

### Customer Lifecycle
```bash
# Customer lifetime value
gl_log "📊💎🎢⭐" "ltv_update" "analytics" "Avg LTV: $1,847 (+15% MoM)"

# Trial conversion
gl_log "📊🎟️👉📌" "trial_conversion" "analytics" "Trial conversion: 42% (21 of 50)"
```

---

## 🔐 Security & Compliance

### Webhook Signature Verification
```bash
# Valid webhook
gl_log "🔐✅💳👉" "webhook_verified" "stripe" "Webhook signature valid"

# Invalid webhook
gl_log "🔐❌💳🚨" "webhook_invalid" "stripe" "Webhook signature INVALID - rejected"
```

### PCI Compliance
```bash
# Payment method tokenization
gl_log "🔒💳✅📌" "tokenized" "stripe" "Payment method tokenized (no PAN stored)"
```

---

## 📚 Integration Checklist

- [x] Extended lifecycle states for billing
- [x] Added subscription state tracking
- [x] Created billing tier tags
- [x] Mapped Stripe webhook events to GreenLight steps
- [x] Created composite patterns for checkout/payment/subscription flows
- [x] Extended NATS subjects for billing events
- [x] Built 14 billing-specific templates
- [x] Integrated with 27-step GreenLight workflow
- [x] Added analytics tracking patterns
- [x] Added security/compliance patterns

---

## 🎯 Stripe Account Details

**Account ID:** `acct_1SUDM8ChUUSEbzyh`
**Display Name:** BlackRoad OS, Inc.
**Dashboard:** https://dashboard.stripe.com/acct_1SUDM8ChUUSEbzyh

### Product IDs
```
individual     = prod_TTNH7uTYVlPbVV
team           = prod_TTNHfJE07G7dty
enterprise     = prod_TTNHTnkdlC00Vk
pro_monthly    = prod_TZp5dIXyukAtLx
founder        = prod_TZp5ecvCkxHcQh
founding_pro   = prod_TefgSJ9T70wriE
pro_full       = prod_Tefg4jmio5PjnR
enterprise_v2  = prod_Tefg0LHPUjS7xn
```

### Price IDs
```
individual:      price_1SWQXAChUUSEbzyhAykgEy5K ($29/mo)
team:            price_1SWQXKChUUSEbzyhLSObMBLT ($99/mo)
pro_monthly:     price_1ScfRCChUUSEbzyh5CXWtrTl ($29/mo)
pro_full:        price_1ShMKtChUUSEbzyhitCMw6z3 ($58/mo)
founding_pro:    price_1ShMKtChUUSEbzyhve1z7RA1 ($29/mo - 50% off)
enterprise:      price_1ShMKuChUUSEbzyhVxRH4mjK ($199/mo)
founder_lifetime: price_1ScfRCChUUSEbzyhhCiqFmUB ($5000 once)
```

---

**Created:** December 23, 2025
**For:** Stripe Billing Integration
**Version:** 2.0.0-billing
**Status:** 🔨 IMPLEMENTATION
