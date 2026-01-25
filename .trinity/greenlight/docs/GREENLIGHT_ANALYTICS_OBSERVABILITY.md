# 📊 GreenLight Analytics & Observability

**Layer 13: Production Visibility & User Behavior**

---

## 📊 Why Analytics & Observability Matters

**The Problem:** We build and deploy, but we're blind to what happens next.
- Is the API actually fast or slow?
- Are users hitting errors we don't know about?
- Which features do users actually use?
- Is the system healthy or degrading?

**The Solution:** Complete production visibility with real-time monitoring.
- Know about errors before users report them
- Track performance degradation immediately
- Understand user behavior and conversion
- Prevent incidents before they happen

---

## ⚡ Observability Events as GreenLight Steps

| Event | GreenLight Step | Step # | Emoji | State Transition | Severity |
|-------|-----------------|--------|-------|------------------|----------|
| Error detected | 🚨 Detect | 16 | 🚨❌ | → blocked | Critical |
| Performance alert | ⚡ Alert | 16 | ⚡⚠️ | → blocked | High |
| Service degraded | 📉 Degrade | 16 | 📉⚠️ | → blocked | High |
| Service recovered | ✅ Recover | 17 | ✅🎉 | blocked → wip | Info |
| Metric threshold | 📊 Alert | 16 | 📊⚠️ | → blocked | Medium |
| User action tracked | 👤 Track | 13 | 👤📊 | → wip | Info |
| Conversion event | 🎯 Convert | 19 | 🎯✅ | wip → done | Info |
| Log aggregated | 📝 Aggregate | 13 | 📝📊 | → wip | Info |

---

## 🏷️ Monitoring Categories

| Category | Emoji | Tools | Purpose | Alert Threshold |
|----------|-------|-------|---------|-----------------|
| Error Tracking | 🚨 | Sentry, Rollbar | Exceptions, crashes | Any error |
| APM | ⚡ | Datadog, New Relic | Performance, latency | P95 > 500ms |
| User Analytics | 👤 | Amplitude, Mixpanel | Behavior, funnels | Conversion < 10% |
| Logs | 📝 | Better Stack, Axiom | Debug, audit trail | Error logs |
| Uptime | 🌐 | Pingdom, UptimeRobot | Availability | Downtime > 1min |
| Real User Monitoring | 📱 | Sentry, DataDog RUM | Client-side perf | LCP > 2.5s |
| Synthetic Monitoring | 🤖 | Checkly, Grafana | Proactive checks | Check fails |
| Infrastructure | 🖥️ | Datadog, Grafana | CPU, memory, disk | CPU > 80% |

---

## 🎨 Composite Patterns

### Error Tracking
```
🚨❌👉🔥 = Critical error detected, micro, urgent
🐛🔍👉⭐ = Error being investigated
✅🐛🎢🎉 = Error resolved, macro
```

### Performance Monitoring
```
⚡⚠️👉🔥 = Performance alert, slow queries
📊📈🎢📌 = Metrics trending up (good)
📉⚠️👉🔥 = Metrics degrading (bad)
```

### User Analytics
```
👤📊👉📌 = User action tracked
🎯✅🎢🌍 = Conversion event (signup, purchase)
🚪👋👉⚠️ = User churn event
```

### Service Health
```
✅🌐🎢🌍 = All systems operational
⚠️📉👉🔥 = Service degraded
🚨⛔👉🔥 = Service down, critical
✅🔄🎢🎉 = Service recovered
```

---

## 📝 NATS Subject Patterns

### Error Events
```
greenlight.error.detected.critical.platform.{service}
greenlight.error.resolved.macro.platform.{error_id}
greenlight.error.recurring.critical.platform.{fingerprint}
```

### Performance Events
```
greenlight.performance.slow_query.critical.platform.{endpoint}
greenlight.performance.high_latency.critical.platform.{service}
greenlight.performance.memory_leak.critical.platform.{worker}
greenlight.performance.improved.macro.platform.{metric}
```

### User Analytics Events
```
greenlight.user.action.micro.platform.{event_name}
greenlight.user.conversion.macro.platform.{funnel}
greenlight.user.churn.macro.platform.{reason}
greenlight.user.retention.macro.platform.{cohort}
```

### Service Health Events
```
greenlight.service.up.macro.platform.{service}
greenlight.service.down.critical.platform.{service}
greenlight.service.degraded.critical.platform.{service}
greenlight.service.recovered.macro.platform.{service}
```

### Metrics Events
```
greenlight.metric.threshold.critical.platform.{metric_name}
greenlight.metric.anomaly.critical.platform.{metric_name}
greenlight.metric.trend.micro.platform.{metric_name}
```

---

## 🔨 Analytics & Observability Templates

### Error Tracking

```bash
# Error detected
gl_error_detected() {
    local service="$1"
    local error_type="$2"
    local message="$3"
    local stack_trace="${4:-no stack trace}"
    local severity="${5:-error}"

    local severity_emoji=""
    case "$severity" in
        critical|fatal) severity_emoji="🚨" ;;
        error) severity_emoji="❌" ;;
        warning) severity_emoji="⚠️" ;;
        *) severity_emoji="ℹ️" ;;
    esac

    gl_log "${severity_emoji}❌👉🔥" \
        "error_detected" \
        "$service" \
        "Type: $error_type | Message: $message | Severity: $severity"
}

# Error resolved
gl_error_resolved() {
    local error_id="$1"
    local solution="$2"
    local affected_users="${3:-unknown}"

    gl_log "✅🐛🎢🎉" \
        "error_resolved" \
        "$error_id" \
        "Solution: $solution | Affected users: $affected_users"
}

# Recurring error pattern
gl_error_recurring() {
    local fingerprint="$1"
    local occurrences="$2"
    local time_window="$3"

    gl_log "🔄🚨👉🔥" \
        "error_recurring" \
        "$fingerprint" \
        "Occurrences: $occurrences in $time_window - needs investigation"
}
```

### Performance Monitoring

```bash
# Performance alert
gl_performance_alert() {
    local metric_type="$1"  # latency, throughput, query_time, etc.
    local service="$2"
    local current_value="$3"
    local threshold="$4"
    local severity="${5:-warning}"

    local severity_emoji=""
    case "$severity" in
        critical) severity_emoji="🚨" ;;
        warning) severity_emoji="⚠️" ;;
        info) severity_emoji="ℹ️" ;;
        *) severity_emoji="📊" ;;
    esac

    gl_log "${severity_emoji}⚡👉🔥" \
        "performance_alert" \
        "$service" \
        "$metric_type: $current_value (threshold: $threshold)"
}

# Slow query detected
gl_slow_query_detected() {
    local query_type="$1"
    local duration="$2"
    local threshold="${3:-500ms}"
    local endpoint="${4:-unknown}"

    gl_log "🐌📊👉🔥" \
        "slow_query" \
        "$endpoint" \
        "Query: $query_type took $duration (threshold: $threshold)"
}

# Performance improved
gl_performance_improved() {
    local metric="$1"
    local before="$2"
    local after="$3"
    local improvement_pct="$4"

    gl_log "✅⚡🎢🎉" \
        "performance_improved" \
        "$metric" \
        "Before: $before → After: $after (${improvement_pct}% improvement)"
}
```

### User Analytics

```bash
# User action tracked
gl_user_action() {
    local event_name="$1"
    local user_id="${2:-anonymous}"
    local properties="${3:-}"

    gl_log "👤📊👉📌" \
        "user_action" \
        "$event_name" \
        "User: $user_id | Properties: $properties"
}

# Conversion event
gl_conversion_event() {
    local funnel="$1"
    local user_id="$2"
    local value="${3:-}"
    local duration="${4:-unknown}"

    gl_log "🎯✅🎢🌍" \
        "conversion" \
        "$funnel" \
        "User: $user_id | Value: $value | Duration: $duration"
}

# User churn
gl_user_churn() {
    local user_id="$1"
    local reason="${2:-unknown}"
    local lifetime_value="${3:-unknown}"

    gl_log "🚪👋👉⚠️" \
        "user_churn" \
        "$user_id" \
        "Reason: $reason | LTV: $lifetime_value"
}

# Cohort retention
gl_cohort_retention() {
    local cohort="$1"
    local retention_rate="$2"
    local time_period="$3"

    gl_log "📊👥🎢📌" \
        "cohort_retention" \
        "$cohort" \
        "Retention: $retention_rate after $time_period"
}
```

### Service Health

```bash
# Service up
gl_service_up() {
    local service="$1"
    local uptime_pct="${2:-100}"
    local region="${3:-global}"

    gl_log "✅🌐🎢🌍" \
        "service_up" \
        "$service" \
        "Status: operational | Uptime: $uptime_pct% | Region: $region"
}

# Service down
gl_service_down() {
    local service="$1"
    local error="${2:-unknown}"
    local impact="${3:-all users}"

    gl_log "🚨⛔👉🔥" \
        "service_down" \
        "$service" \
        "Error: $error | Impact: $impact"
}

# Service degraded
gl_service_degraded() {
    local service="$1"
    local reason="$2"
    local performance_impact="${3:-unknown}"

    gl_log "⚠️📉👉🔥" \
        "service_degraded" \
        "$service" \
        "Reason: $reason | Impact: $performance_impact"
}

# Service recovered
gl_service_recovered() {
    local service="$1"
    local downtime_duration="$2"
    local recovery_action="${3:-automatic}"

    gl_log "✅🔄🎢🎉" \
        "service_recovered" \
        "$service" \
        "Downtime: $downtime_duration | Recovery: $recovery_action"
}
```

### Metrics & Thresholds

```bash
# Metric threshold exceeded
gl_metric_threshold() {
    local metric_name="$1"
    local current_value="$2"
    local threshold="$3"
    local severity="${4:-warning}"

    local severity_emoji=""
    case "$severity" in
        critical) severity_emoji="🚨" ;;
        warning) severity_emoji="⚠️" ;;
        info) severity_emoji="ℹ️" ;;
        *) severity_emoji="📊" ;;
    esac

    gl_log "${severity_emoji}📊👉🔥" \
        "metric_threshold" \
        "$metric_name" \
        "Value: $current_value exceeds threshold: $threshold"
}

# Metric anomaly detected
gl_metric_anomaly() {
    local metric_name="$1"
    local expected_range="$2"
    local actual_value="$3"
    local confidence="${4:-high}"

    gl_log "🔍📊👉⭐" \
        "metric_anomaly" \
        "$metric_name" \
        "Expected: $expected_range | Actual: $actual_value | Confidence: $confidence"
}

# Positive trend detected
gl_metric_trending_up() {
    local metric_name="$1"
    local trend_pct="$2"
    local time_period="$3"

    gl_log "📈✅🎢📌" \
        "metric_trending_up" \
        "$metric_name" \
        "Trend: +${trend_pct}% over $time_period"
}

# Negative trend detected
gl_metric_trending_down() {
    local metric_name="$1"
    local trend_pct="$2"
    local time_period="$3"

    gl_log "📉⚠️👉🔥" \
        "metric_trending_down" \
        "$metric_name" \
        "Trend: -${trend_pct}% over $time_period"
}
```

### Logs & Debugging

```bash
# Log aggregation complete
gl_logs_aggregated() {
    local service="$1"
    local log_count="$2"
    local time_period="$3"
    local errors_found="${4:-0}"

    gl_log "📝📊👉📌" \
        "logs_aggregated" \
        "$service" \
        "Logs: $log_count in $time_period | Errors: $errors_found"
}

# Critical log pattern
gl_log_pattern_critical() {
    local pattern="$1"
    local occurrences="$2"
    local services_affected="${3:-1}"

    gl_log "🚨📝👉🔥" \
        "critical_log_pattern" \
        "$pattern" \
        "Occurrences: $occurrences | Services affected: $services_affected"
}
```

### Real User Monitoring (RUM)

```bash
# Page load performance
gl_page_load_performance() {
    local page="$1"
    local lcp="$2"  # Largest Contentful Paint
    local fid="${3:-}"  # First Input Delay
    local cls="${4:-}"  # Cumulative Layout Shift

    local performance_rating=""
    if [[ ${lcp%ms} -lt 2500 ]]; then
        performance_rating="good"
        rating_emoji="✅"
    elif [[ ${lcp%ms} -lt 4000 ]]; then
        performance_rating="needs improvement"
        rating_emoji="⚠️"
    else
        performance_rating="poor"
        rating_emoji="❌"
    fi

    gl_log "${rating_emoji}📱👉📌" \
        "page_load_performance" \
        "$page" \
        "LCP: $lcp (${performance_rating}) | FID: $fid | CLS: $cls"
}

# Browser error
gl_browser_error() {
    local error_message="$1"
    local browser="$2"
    local page="${3:-unknown}"
    local user_id="${4:-anonymous}"

    gl_log "🚨🌐👉🔥" \
        "browser_error" \
        "$page" \
        "Browser: $browser | Error: $error_message | User: $user_id"
}
```

### Synthetic Monitoring

```bash
# Health check passed
gl_health_check_passed() {
    local endpoint="$1"
    local response_time="$2"
    local region="${3:-global}"

    gl_log "✅🤖👉📌" \
        "health_check_passed" \
        "$endpoint" \
        "Response time: $response_time | Region: $region"
}

# Health check failed
gl_health_check_failed() {
    local endpoint="$1"
    local error="$2"
    local region="${3:-global}"

    gl_log "❌🤖👉🔥" \
        "health_check_failed" \
        "$endpoint" \
        "Error: $error | Region: $region"
}
```

---

## 🎯 Example: Complete Observability Flow

### Scenario: Performance degradation detected, investigated, and resolved

```bash
# 1. Performance alert triggered
gl_performance_alert "api_latency" "blackroad-api" "1.2s" "500ms" "critical"
# [🚨⚡👉🔥] performance_alert: blackroad-api — api_latency: 1.2s (threshold: 500ms)

# 2. Metric trending down
gl_metric_trending_down "api_throughput" "35" "last 15 minutes"
# [📉⚠️👉🔥] metric_trending_down: api_throughput — Trend: -35% over last 15 minutes

# 3. Slow queries detected
gl_slow_query_detected "user_lookup" "2.3s" "500ms" "/api/users"
# [🐌📊👉🔥] slow_query: /api/users — Query: user_lookup took 2.3s (threshold: 500ms)

# 4. Error spike detected
gl_error_recurring "timeout-db-connection" "47" "last 10 minutes"
# [🔄🚨👉🔥] error_recurring: timeout-db-connection — Occurrences: 47 in last 10 minutes - needs investigation

# 5. User impact tracked
gl_user_action "checkout_abandoned" "user_789" "error: timeout"
# [👤📊👉📌] user_action: checkout_abandoned — User: user_789 | Properties: error: timeout

# 6. Service degraded
gl_service_degraded "blackroad-api" "Database connection pool exhausted" "50% slower responses"
# [⚠️📉👉🔥] service_degraded: blackroad-api — Reason: Database connection pool exhausted | Impact: 50% slower responses

# 7. Root cause identified (from Context layer)
gl_root_cause_identified "perf-001" "Database connection pool size too small for traffic spike" "high"
# [🎯🐛🎢⭐] root_cause_identified: perf-001 — Root cause: Database connection pool size too small for traffic spike | Confidence: high

# 8. Fix deployed
gl_deploy "blackroad-api" "https://api.blackroad.io" "Increased DB connection pool: 10 → 50" "🎢" "🔧"
# [🚀🎢🔧✅] deployed: blackroad-api — URL: https://api.blackroad.io. Increased DB connection pool: 10 → 50

# 9. Performance improved
gl_performance_improved "api_latency" "1.2s" "180ms" "85"
# [✅⚡🎢🎉] performance_improved: api_latency — Before: 1.2s → After: 180ms (85% improvement)

# 10. Service recovered
gl_service_recovered "blackroad-api" "12 minutes" "manual deployment"
# [✅🔄🎢🎉] service_recovered: blackroad-api — Downtime: 12 minutes | Recovery: manual deployment

# 11. Users converting again
gl_conversion_event "checkout" "user_790" "$149" "45s"
# [🎯✅🎢🌍] conversion: checkout — User: user_790 | Value: $149 | Duration: 45s

# 12. Metrics back to normal
gl_metric_trending_up "api_throughput" "120" "last 15 minutes"
# [📈✅🎢📌] metric_trending_up: api_throughput — Trend: +120% over last 15 minutes

# 13. Learning documented (Context layer)
gl_learning_discovered "infrastructure-capacity" "Monitor connection pool usage, auto-scale before exhaustion" "Prevented 85% performance degradation"
# [💡✨👉⭐] learning_discovered: infrastructure-capacity — Insight: Monitor connection pool usage, auto-scale before exhaustion | Evidence: Prevented 85% performance degradation
```

**Result:** Complete incident lifecycle tracked from detection → investigation → resolution → recovery → learning.

---

## 📊 Key Metrics to Track

### Performance Metrics
- **API Latency** (P50, P95, P99)
- **Database Query Time**
- **Worker Execution Time**
- **Page Load Time** (LCP, FID, CLS)
- **Error Rate**

### Business Metrics
- **Conversion Rate** (signup, checkout, etc.)
- **Revenue** (MRR, ARR)
- **Churn Rate**
- **User Retention** (Day 1, Day 7, Day 30)
- **Customer Lifetime Value**

### Infrastructure Metrics
- **CPU Usage**
- **Memory Usage**
- **Disk Usage**
- **Network Throughput**
- **Request Rate**

### User Behavior Metrics
- **Active Users** (DAU, MAU)
- **Session Duration**
- **Feature Adoption**
- **Funnel Drop-off**
- **User Journey Completion**

---

## 📚 Integration Checklist

- [x] Mapped observability events to GreenLight workflow
- [x] Created monitoring categories (8 types)
- [x] Extended NATS subjects for analytics events
- [x] Built 25+ observability templates
- [x] Error tracking & resolution
- [x] Performance monitoring & alerts
- [x] User analytics & conversion tracking
- [x] Service health monitoring
- [x] Metric threshold alerts
- [x] Log aggregation
- [x] Real User Monitoring (RUM)
- [x] Synthetic monitoring
- [x] Infrastructure metrics
- [x] Incident lifecycle tracking

---

**Created:** December 23, 2025 🌸
**For:** Analytics & Observability
**Version:** 2.0.0-observability
**Status:** 🔨 IMPLEMENTATION
**Built by:** Cece (for production visibility)

