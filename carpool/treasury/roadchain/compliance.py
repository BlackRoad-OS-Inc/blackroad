#!/usr/bin/env python3
"""
RoadChain Compliance Module
============================
Immutable audit trail, transaction classification, AML tracking,
and tax reporting for the RoadChain mining pipeline.

Regulatory coverage:
  SEC/FINRA  - Hash-chained audit log, transaction classification
  FinCEN     - AML/KYC counterparty registry, SAR threshold detection
  IRS        - Cost basis lot tracking (FIFO), capital gains reporting

Pipeline:  Pi Fleet (XMR) -> Exchange (BTC) -> Reserve -> Mint (ROAD)
Storage:   ~/.roadchain/compliance/

Every pipeline event is logged to an append-only, hash-chained JSONL file.
Each record contains sha256(content) and parent_hash referencing the previous
entry, forming a tamper-evident chain. Genesis uses "0" * 64 as parent.
"""

import json
import hashlib
import time
import sys
from datetime import datetime, timezone
from pathlib import Path

# ============================================================================
# CONFIGURATION
# ============================================================================

COMPLIANCE_DIR = Path.home() / ".roadchain" / "compliance"
COMPLIANCE_DIR.mkdir(parents=True, exist_ok=True)

AUDIT_LOG = COMPLIANCE_DIR / "audit_log.jsonl"
CLASSIFICATIONS_FILE = COMPLIANCE_DIR / "classifications.json"
AML_FILE = COMPLIANCE_DIR / "aml_records.json"
SAR_FILE = COMPLIANCE_DIR / "sar_flags.json"
TAX_BASIS_FILE = COMPLIANCE_DIR / "tax_basis.json"
TAX_REPORTS_DIR = COMPLIANCE_DIR / "tax_reports"
TAX_REPORTS_DIR.mkdir(parents=True, exist_ok=True)

# Regulatory thresholds
CTR_THRESHOLD = 10_000.00   # FinCEN Currency Transaction Report
SAR_THRESHOLD = 5_000.00    # Suspicious Activity Report review
STRUCTURING_WINDOW = 86400  # 24 hours for structuring detection
STRUCTURING_THRESHOLD = 10_000.00

# Event types
EVENT_TYPES = [
    "mining_earning", "swap_executed", "road_minted",
    "payment_sent", "btc_deposit", "btc_withdrawal",
    "classification_change", "sar_flag", "counterparty_added",
    "tax_lot_opened", "tax_lot_closed", "manual_entry"
]


# ============================================================================
# HASH-CHAINED AUDIT LOG (SEC/FINRA)
# ============================================================================

def _hash_record(record):
    """Compute SHA-256 of a record's content (excluding its own hash fields)."""
    content = {k: v for k, v in record.items() if k not in ("record_hash", "parent_hash")}
    raw = json.dumps(content, sort_keys=True, default=str)
    return hashlib.sha256(raw.encode()).hexdigest()


def _get_last_hash():
    """Read the hash of the last audit log entry, or genesis hash."""
    if not AUDIT_LOG.exists() or AUDIT_LOG.stat().st_size == 0:
        return "0" * 64
    with open(AUDIT_LOG, "rb") as f:
        # Seek to last non-empty line
        f.seek(0, 2)
        pos = f.tell()
        if pos == 0:
            return "0" * 64
        # Walk backward to find last newline
        pos -= 1
        while pos > 0:
            f.seek(pos)
            if f.read(1) == b"\n":
                line = f.readline().strip()
                if line:
                    entry = json.loads(line)
                    return entry.get("record_hash", "0" * 64)
            pos -= 1
        # File has a single line
        f.seek(0)
        line = f.readline().strip()
        if line:
            entry = json.loads(line)
            return entry.get("record_hash", "0" * 64)
    return "0" * 64


def log_event(event_type, asset, amount, fmv_usd=0.0, counterparty="internal",
              securities_flag=False, sar_flag=False, metadata=None):
    """Append a hash-chained audit record to the log.

    Args:
        event_type: One of EVENT_TYPES
        asset: Asset symbol (XMR, BTC, ROAD, USD)
        amount: Quantity of the asset
        fmv_usd: Fair market value in USD at time of event
        counterparty: Who is on the other side (exchange name, address, etc.)
        securities_flag: Whether this event may involve a security
        sar_flag: Whether this event triggered SAR review
        metadata: Additional key-value pairs

    Returns:
        The complete audit record dict.
    """
    parent_hash = _get_last_hash()

    record = {
        "event_id": hashlib.sha256(
            f"{event_type}{asset}{amount}{time.time()}".encode()
        ).hexdigest()[:16],
        "event_type": event_type,
        "timestamp": time.time(),
        "datetime": datetime.now(timezone.utc).isoformat(),
        "asset": asset,
        "amount": float(amount),
        "fmv_usd": float(fmv_usd),
        "counterparty": counterparty,
        "securities_flag": securities_flag,
        "sar_flag": sar_flag,
        "metadata": metadata or {},
        "parent_hash": parent_hash,
    }

    record["record_hash"] = _hash_record(record)

    with open(AUDIT_LOG, "a") as f:
        f.write(json.dumps(record, default=str) + "\n")

    return record


def verify_chain():
    """Verify the integrity of the entire audit log hash chain.

    Returns:
        dict with 'valid' bool, 'total_records', 'broken_at' (index or None),
        and 'error' description if broken.
    """
    if not AUDIT_LOG.exists() or AUDIT_LOG.stat().st_size == 0:
        return {"valid": True, "total_records": 0, "broken_at": None}

    expected_parent = "0" * 64
    count = 0

    with open(AUDIT_LOG) as f:
        for i, line in enumerate(f):
            line = line.strip()
            if not line:
                continue

            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                return {
                    "valid": False, "total_records": count,
                    "broken_at": i, "error": f"Line {i}: invalid JSON"
                }

            # Check parent hash linkage
            if record.get("parent_hash") != expected_parent:
                return {
                    "valid": False, "total_records": count,
                    "broken_at": i,
                    "error": f"Line {i}: parent_hash mismatch "
                             f"(expected {expected_parent[:16]}..., "
                             f"got {record.get('parent_hash', '?')[:16]}...)"
                }

            # Verify record's own hash
            computed = _hash_record(record)
            if computed != record.get("record_hash"):
                return {
                    "valid": False, "total_records": count,
                    "broken_at": i,
                    "error": f"Line {i}: record_hash mismatch (content tampered)"
                }

            expected_parent = record["record_hash"]
            count += 1

    return {"valid": True, "total_records": count, "broken_at": None}


def get_recent_events(limit=20):
    """Return the last N audit events."""
    if not AUDIT_LOG.exists():
        return []
    events = []
    with open(AUDIT_LOG) as f:
        for line in f:
            line = line.strip()
            if line:
                events.append(json.loads(line))
    return events[-limit:]


def get_events_by_type(event_type, limit=50):
    """Return events filtered by type."""
    if not AUDIT_LOG.exists():
        return []
    results = []
    with open(AUDIT_LOG) as f:
        for line in f:
            line = line.strip()
            if line:
                record = json.loads(line)
                if record.get("event_type") == event_type:
                    results.append(record)
    return results[-limit:]


def get_event_by_id(event_id):
    """Find a single event by its event_id."""
    if not AUDIT_LOG.exists():
        return None
    with open(AUDIT_LOG) as f:
        for line in f:
            line = line.strip()
            if line:
                record = json.loads(line)
                if record.get("event_id") == event_id:
                    return record
    return None


# ============================================================================
# TRANSACTION CLASSIFICATION (SEC)
# ============================================================================

def _load_classifications():
    if CLASSIFICATIONS_FILE.exists():
        with open(CLASSIFICATIONS_FILE) as f:
            return json.load(f)
    return {"overrides": {}, "rules": []}


def _save_classifications(data):
    with open(CLASSIFICATIONS_FILE, "w") as f:
        json.dump(data, f, indent=2)


def classify_event(event_id, classification, reason=""):
    """Override the classification for a specific event.

    Classifications: 'utility_token', 'security', 'commodity', 'currency', 'internal'.
    """
    data = _load_classifications()
    data["overrides"][event_id] = {
        "classification": classification,
        "reason": reason,
        "classified_at": datetime.now(timezone.utc).isoformat(),
    }
    _save_classifications(data)

    log_event(
        "classification_change", "ROAD", 0,
        metadata={"event_id": event_id, "classification": classification, "reason": reason}
    )
    return data["overrides"][event_id]


def assess_securities_risk(event=None):
    """Assess whether a ROAD event could be classified as a securities transaction.

    ROAD is a utility token within the BlackRoad ecosystem. It becomes a potential
    security if it exits the internal ecosystem (sold on exchanges, transferred to
    third parties for investment purposes, etc.).

    Returns a risk assessment dict.
    """
    data = _load_classifications()
    risk_factors = []
    risk_level = "LOW"

    if event:
        counterparty = event.get("counterparty", "internal")
        event_type = event.get("event_type", "")

        # Internal transfers are low risk
        if counterparty == "internal":
            risk_factors.append("Internal transfer - low regulatory concern")
        else:
            risk_factors.append(f"External counterparty: {counterparty}")
            risk_level = "MEDIUM"

        # Payments to external billers using ROAD
        if event_type == "payment_sent" and counterparty != "internal":
            risk_factors.append("ROAD used for payment to external entity")
            risk_level = "MEDIUM"

        # Large amounts
        fmv = event.get("fmv_usd", 0)
        if fmv > 100_000:
            risk_factors.append(f"High FMV: ${fmv:,.2f}")
            risk_level = "HIGH" if risk_level == "MEDIUM" else risk_level

        # Check for override
        eid = event.get("event_id")
        if eid and eid in data.get("overrides", {}):
            override = data["overrides"][eid]
            risk_factors.append(f"Manual override: {override['classification']}")
            if override["classification"] == "security":
                risk_level = "HIGH"
            elif override["classification"] == "utility_token":
                risk_level = "LOW"
    else:
        # General assessment
        events = get_recent_events(100)
        external_count = sum(
            1 for e in events if e.get("counterparty", "internal") != "internal"
        )
        risk_factors.append(f"{external_count} external transactions in recent history")
        if external_count > 20:
            risk_level = "HIGH"
        elif external_count > 5:
            risk_level = "MEDIUM"

    return {
        "risk_level": risk_level,
        "risk_factors": risk_factors,
        "recommendation": {
            "LOW": "No action needed - internal utility token usage",
            "MEDIUM": "Monitor - some external exposure detected",
            "HIGH": "Review required - potential securities implications",
        }[risk_level],
        "assessed_at": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================================
# AML / KYC (FinCEN)
# ============================================================================

def _load_aml():
    if AML_FILE.exists():
        with open(AML_FILE) as f:
            return json.load(f)
    return {"counterparties": {}, "transactions": []}


def _save_aml(data):
    with open(AML_FILE, "w") as f:
        json.dump(data, f, indent=2)


def _load_sar():
    if SAR_FILE.exists():
        with open(SAR_FILE) as f:
            return json.load(f)
    return {"flags": [], "total_flagged": 0}


def _save_sar(data):
    with open(SAR_FILE, "w") as f:
        json.dump(data, f, indent=2)


def record_counterparty(name, counterparty_type="exchange", details=None):
    """Register a counterparty in the AML registry.

    Args:
        name: Counterparty identifier (exchange name, wallet address, etc.)
        counterparty_type: 'exchange', 'pool', 'wallet', 'biller', 'individual'
        details: Additional KYC info dict

    Returns:
        The counterparty record.
    """
    data = _load_aml()
    record = {
        "name": name,
        "type": counterparty_type,
        "details": details or {},
        "registered_at": datetime.now(timezone.utc).isoformat(),
        "transaction_count": 0,
        "total_usd_volume": 0.0,
    }
    # Merge with existing if already registered
    if name in data["counterparties"]:
        existing = data["counterparties"][name]
        record["transaction_count"] = existing.get("transaction_count", 0)
        record["total_usd_volume"] = existing.get("total_usd_volume", 0)
        record["registered_at"] = existing.get("registered_at", record["registered_at"])
        if details:
            existing_details = existing.get("details", {})
            existing_details.update(details)
            record["details"] = existing_details

    data["counterparties"][name] = record
    _save_aml(data)

    log_event(
        "counterparty_added", "N/A", 0,
        counterparty=name,
        metadata={"type": counterparty_type}
    )
    return record


def _update_counterparty_volume(counterparty, usd_amount):
    """Update transaction count and volume for a counterparty."""
    data = _load_aml()
    if counterparty in data["counterparties"]:
        data["counterparties"][counterparty]["transaction_count"] += 1
        data["counterparties"][counterparty]["total_usd_volume"] += usd_amount
        _save_aml(data)


def check_sar_thresholds(counterparty, usd_amount):
    """Check if a transaction triggers SAR review thresholds.

    Checks:
      1. Single transaction >= $10,000 (CTR threshold)
      2. Single transaction >= $5,000 (SAR review threshold)
      3. Structuring: multiple transactions to same counterparty within 24h
         that sum to >= $10,000

    Returns:
        dict with 'triggered' bool, 'reasons' list, 'ctr_required' bool.
    """
    reasons = []
    ctr_required = False

    # Single transaction thresholds
    if usd_amount >= CTR_THRESHOLD:
        reasons.append(f"CTR threshold: ${usd_amount:,.2f} >= ${CTR_THRESHOLD:,.2f}")
        ctr_required = True
    elif usd_amount >= SAR_THRESHOLD:
        reasons.append(f"SAR review: ${usd_amount:,.2f} >= ${SAR_THRESHOLD:,.2f}")

    # Structuring detection: sum recent transactions to same counterparty
    if not AUDIT_LOG.exists():
        return {
            "triggered": len(reasons) > 0,
            "reasons": reasons,
            "ctr_required": ctr_required,
        }

    cutoff = time.time() - STRUCTURING_WINDOW
    rolling_sum = usd_amount  # Include current transaction

    with open(AUDIT_LOG) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            record = json.loads(line)
            if (record.get("counterparty") == counterparty
                    and record.get("timestamp", 0) >= cutoff):
                rolling_sum += record.get("fmv_usd", 0)

    if rolling_sum >= STRUCTURING_THRESHOLD and usd_amount < CTR_THRESHOLD:
        reasons.append(
            f"Structuring alert: ${rolling_sum:,.2f} to {counterparty} "
            f"in 24h (individual txns below ${CTR_THRESHOLD:,.2f})"
        )

    return {
        "triggered": len(reasons) > 0,
        "reasons": reasons,
        "ctr_required": ctr_required,
        "rolling_24h_usd": rolling_sum,
    }


def flag_sar(event_id, reason, severity="medium"):
    """Flag an event for Suspicious Activity Report review.

    Args:
        event_id: The audit log event_id to flag
        reason: Why it was flagged
        severity: 'low', 'medium', 'high', 'critical'
    """
    data = _load_sar()
    flag = {
        "event_id": event_id,
        "reason": reason,
        "severity": severity,
        "flagged_at": datetime.now(timezone.utc).isoformat(),
        "status": "open",
        "resolution": None,
    }
    data["flags"].append(flag)
    data["total_flagged"] += 1
    _save_sar(data)

    log_event(
        "sar_flag", "N/A", 0,
        sar_flag=True,
        metadata={"flagged_event": event_id, "reason": reason, "severity": severity}
    )
    return flag


# ============================================================================
# TAX BASIS TRACKING (IRS)
# ============================================================================

def _load_tax_basis():
    if TAX_BASIS_FILE.exists():
        with open(TAX_BASIS_FILE) as f:
            return json.load(f)
    return {"lots": [], "dispositions": [], "method": "FIFO"}


def _save_tax_basis(data):
    with open(TAX_BASIS_FILE, "w") as f:
        json.dump(data, f, indent=2)


def record_tax_lot(asset, quantity, cost_basis_usd, source="", acquisition_date=None):
    """Record acquisition of an asset for cost basis tracking.

    Each lot tracks: asset, quantity remaining, cost basis per unit,
    acquisition date, and source (mining, swap, purchase).

    Returns:
        The new lot record.
    """
    data = _load_tax_basis()

    lot_id = hashlib.sha256(
        f"{asset}{quantity}{cost_basis_usd}{time.time()}".encode()
    ).hexdigest()[:12]

    lot = {
        "lot_id": f"LOT-{lot_id.upper()}",
        "asset": asset,
        "quantity": float(quantity),
        "remaining": float(quantity),
        "cost_basis_usd": float(cost_basis_usd),
        "cost_per_unit": float(cost_basis_usd) / float(quantity) if quantity else 0,
        "source": source,
        "acquisition_date": acquisition_date or datetime.now(timezone.utc).isoformat(),
        "timestamp": time.time(),
        "status": "open",
    }

    data["lots"].append(lot)
    _save_tax_basis(data)

    log_event(
        "tax_lot_opened", asset, quantity,
        fmv_usd=cost_basis_usd,
        metadata={"lot_id": lot["lot_id"], "source": source}
    )
    return lot


def dispose_tax_lot(asset, quantity, proceeds_usd, disposition_type="sale"):
    """Dispose of an asset using FIFO lot matching.

    Matches against open lots in FIFO order, calculates gains/losses.

    Args:
        asset: Asset symbol
        quantity: Amount disposed
        proceeds_usd: Total USD proceeds
        disposition_type: 'sale', 'swap', 'payment', 'transfer'

    Returns:
        dict with matched lots, total cost basis, gain/loss, and term.
    """
    data = _load_tax_basis()
    remaining = float(quantity)
    matched = []
    total_cost_basis = 0.0
    now = datetime.now(timezone.utc)

    # FIFO: match oldest lots first
    for lot in data["lots"]:
        if remaining <= 0:
            break
        if lot["asset"] != asset or lot["remaining"] <= 0:
            continue
        if lot["status"] == "closed":
            continue

        use_qty = min(remaining, lot["remaining"])
        cost = use_qty * lot["cost_per_unit"]
        total_cost_basis += cost

        # Determine holding period
        acq_date = datetime.fromisoformat(lot["acquisition_date"].replace("Z", "+00:00"))
        if acq_date.tzinfo is None:
            acq_date = acq_date.replace(tzinfo=timezone.utc)
        days_held = (now - acq_date).days
        term = "long" if days_held > 365 else "short"

        matched.append({
            "lot_id": lot["lot_id"],
            "quantity_used": use_qty,
            "cost_basis": cost,
            "cost_per_unit": lot["cost_per_unit"],
            "days_held": days_held,
            "term": term,
        })

        lot["remaining"] -= use_qty
        if lot["remaining"] <= 0:
            lot["status"] = "closed"
        remaining -= use_qty

    gain_loss = float(proceeds_usd) - total_cost_basis

    disposition = {
        "disposition_id": hashlib.sha256(
            f"{asset}{quantity}{proceeds_usd}{time.time()}".encode()
        ).hexdigest()[:12],
        "asset": asset,
        "quantity": float(quantity),
        "proceeds_usd": float(proceeds_usd),
        "cost_basis_usd": total_cost_basis,
        "gain_loss_usd": gain_loss,
        "type": disposition_type,
        "lots_matched": matched,
        "unmatched_quantity": remaining,
        "date": now.isoformat(),
        "timestamp": time.time(),
    }

    data["dispositions"].append(disposition)
    _save_tax_basis(data)

    log_event(
        "tax_lot_closed", asset, quantity,
        fmv_usd=proceeds_usd,
        metadata={
            "gain_loss": gain_loss,
            "cost_basis": total_cost_basis,
            "type": disposition_type,
        }
    )
    return disposition


def calculate_cost_basis(asset=None):
    """Calculate current cost basis summary for all or one asset.

    Returns:
        dict with open lots, total basis, average cost per unit.
    """
    data = _load_tax_basis()
    lots = data["lots"]
    if asset:
        lots = [l for l in lots if l["asset"] == asset]

    open_lots = [l for l in lots if l.get("status") != "closed" and l.get("remaining", 0) > 0]
    total_remaining = sum(l["remaining"] for l in open_lots)
    total_basis = sum(l["remaining"] * l["cost_per_unit"] for l in open_lots)
    avg_cost = total_basis / total_remaining if total_remaining > 0 else 0

    return {
        "asset": asset or "ALL",
        "open_lots": len(open_lots),
        "total_quantity": total_remaining,
        "total_cost_basis_usd": total_basis,
        "average_cost_per_unit": avg_cost,
        "lots": [
            {
                "lot_id": l["lot_id"],
                "remaining": l["remaining"],
                "cost_per_unit": l["cost_per_unit"],
                "source": l["source"],
                "acquisition_date": l["acquisition_date"],
            }
            for l in open_lots
        ],
    }


def generate_tax_summary(year):
    """Generate annual tax summary for a given year.

    Aggregates all dispositions in the year, separates short/long-term
    gains, and writes a report to tax_reports/<year>.json.

    Returns:
        The tax summary dict.
    """
    data = _load_tax_basis()
    year = int(year)

    # Filter dispositions for the given year
    year_dispositions = []
    for d in data.get("dispositions", []):
        d_date = d.get("date", "")
        try:
            d_year = datetime.fromisoformat(d_date.replace("Z", "+00:00")).year
        except (ValueError, AttributeError):
            continue
        if d_year == year:
            year_dispositions.append(d)

    short_term_gain = 0.0
    long_term_gain = 0.0
    total_proceeds = 0.0
    total_basis = 0.0

    for d in year_dispositions:
        total_proceeds += d.get("proceeds_usd", 0)
        total_basis += d.get("cost_basis_usd", 0)
        for lot_match in d.get("lots_matched", []):
            gain = (d.get("proceeds_usd", 0) / d.get("quantity", 1)) * lot_match["quantity_used"] - lot_match["cost_basis"]
            if lot_match.get("term") == "long":
                long_term_gain += gain
            else:
                short_term_gain += gain

    # Mining earnings (ordinary income)
    mining_events = []
    if AUDIT_LOG.exists():
        with open(AUDIT_LOG) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                record = json.loads(line)
                if record.get("event_type") != "mining_earning":
                    continue
                try:
                    r_year = datetime.fromisoformat(
                        record["datetime"].replace("Z", "+00:00")
                    ).year
                except (ValueError, KeyError):
                    continue
                if r_year == year:
                    mining_events.append(record)

    mining_income = sum(e.get("fmv_usd", 0) for e in mining_events)

    summary = {
        "tax_year": year,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "ordinary_income": {
            "mining_income_usd": mining_income,
            "mining_events": len(mining_events),
        },
        "capital_gains": {
            "short_term_gain_usd": short_term_gain,
            "long_term_gain_usd": long_term_gain,
            "total_gain_usd": short_term_gain + long_term_gain,
            "total_proceeds_usd": total_proceeds,
            "total_cost_basis_usd": total_basis,
            "dispositions": len(year_dispositions),
        },
        "total_taxable": mining_income + short_term_gain + long_term_gain,
        "dispositions": year_dispositions,
    }

    # Save report
    report_file = TAX_REPORTS_DIR / f"{year}.json"
    with open(report_file, "w") as f:
        json.dump(summary, f, indent=2)

    return summary


# ============================================================================
# DASHBOARD & RISK
# ============================================================================

def compliance_status():
    """Return a compliance dashboard summary."""
    # Chain integrity
    chain = verify_chain()

    # Event counts
    total_events = chain["total_records"]
    recent = get_recent_events(10)

    # SAR status
    sar_data = _load_sar()
    open_sars = [f for f in sar_data.get("flags", []) if f.get("status") == "open"]

    # AML counterparties
    aml_data = _load_aml()
    counterparty_count = len(aml_data.get("counterparties", {}))

    # Tax lots
    basis = calculate_cost_basis()

    # Securities classification
    risk = assess_securities_risk()

    return {
        "audit_chain": {
            "valid": chain["valid"],
            "total_records": total_events,
            "last_event": recent[-1]["event_type"] if recent else "none",
        },
        "aml": {
            "registered_counterparties": counterparty_count,
            "open_sar_flags": len(open_sars),
            "total_sar_flags": sar_data.get("total_flagged", 0),
        },
        "tax": {
            "open_lots": basis["open_lots"],
            "total_basis_usd": basis["total_cost_basis_usd"],
        },
        "securities_risk": risk["risk_level"],
        "status": "COMPLIANT" if chain["valid"] and len(open_sars) == 0 else "REVIEW_NEEDED",
    }


def risk_assessment():
    """Full risk assessment across all regulatory areas."""
    chain = verify_chain()
    sar_data = _load_sar()
    aml_data = _load_aml()
    sec_risk = assess_securities_risk()

    issues = []

    if not chain["valid"]:
        issues.append({
            "area": "SEC/FINRA",
            "severity": "CRITICAL",
            "issue": f"Audit chain integrity broken at record {chain.get('broken_at')}",
            "detail": chain.get("error", ""),
        })

    open_sars = [f for f in sar_data.get("flags", []) if f.get("status") == "open"]
    if open_sars:
        issues.append({
            "area": "FinCEN",
            "severity": "HIGH",
            "issue": f"{len(open_sars)} open SAR flag(s) require review",
            "detail": "; ".join(f["reason"] for f in open_sars[:3]),
        })

    if sec_risk["risk_level"] == "HIGH":
        issues.append({
            "area": "SEC",
            "severity": "HIGH",
            "issue": "Securities risk assessment is HIGH",
            "detail": "; ".join(sec_risk["risk_factors"]),
        })

    # Check for unregistered counterparties in recent events
    registered = set(aml_data.get("counterparties", {}).keys())
    registered.add("internal")
    recent = get_recent_events(50)
    unregistered = set()
    for e in recent:
        cp = e.get("counterparty", "internal")
        if cp not in registered:
            unregistered.add(cp)
    if unregistered:
        issues.append({
            "area": "FinCEN",
            "severity": "MEDIUM",
            "issue": f"{len(unregistered)} unregistered counterparty(ies)",
            "detail": ", ".join(list(unregistered)[:5]),
        })

    overall = "GREEN"
    if any(i["severity"] == "CRITICAL" for i in issues):
        overall = "RED"
    elif any(i["severity"] == "HIGH" for i in issues):
        overall = "YELLOW"
    elif issues:
        overall = "YELLOW"

    return {
        "overall_risk": overall,
        "issues": issues,
        "issue_count": len(issues),
        "assessed_at": datetime.now(timezone.utc).isoformat(),
    }


def missing_documentation():
    """Identify gaps in compliance documentation."""
    gaps = []

    # Check counterparty coverage
    aml_data = _load_aml()
    registered = set(aml_data.get("counterparties", {}).keys())
    registered.add("internal")

    if AUDIT_LOG.exists():
        seen_counterparties = set()
        with open(AUDIT_LOG) as f:
            for line in f:
                line = line.strip()
                if line:
                    record = json.loads(line)
                    cp = record.get("counterparty", "internal")
                    if cp != "internal":
                        seen_counterparties.add(cp)

        unregistered = seen_counterparties - registered
        for cp in unregistered:
            gaps.append({
                "area": "AML/KYC",
                "type": "missing_counterparty",
                "detail": f"Counterparty '{cp}' appears in transactions but is not registered",
            })

    # Check tax lot coverage - any dispositions without lot matches
    tax_data = _load_tax_basis()
    for d in tax_data.get("dispositions", []):
        if d.get("unmatched_quantity", 0) > 0:
            gaps.append({
                "area": "IRS",
                "type": "unmatched_disposition",
                "detail": f"{d['unmatched_quantity']} {d['asset']} disposed without cost basis lots",
            })

    # Check if chain has been verified recently
    chain = verify_chain()
    if not chain["valid"]:
        gaps.append({
            "area": "SEC/FINRA",
            "type": "chain_integrity",
            "detail": f"Audit chain broken: {chain.get('error', 'unknown')}",
        })

    return {
        "gaps": gaps,
        "gap_count": len(gaps),
        "checked_at": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================================
# PIPELINE HOOKS
# Called from cli.py after existing pipeline operations.
# ============================================================================

def on_mining_earning(earning):
    """Hook: called after a mining earning is recorded.

    Args:
        earning: dict from miner.record_earning() with coin, amount, source, tx_hash
    """
    # Fetch FMV - use cached rates if available
    fmv = 0.0
    try:
        rates_file = Path.home() / ".roadchain" / "exchange" / "rates.json"
        if rates_file.exists():
            with open(rates_file) as f:
                rates = json.load(f)
            coin = earning.get("coin", "xmr").lower()
            fmv = earning.get("amount", 0) * rates.get(f"{coin}_usd", 0)
    except Exception:
        pass

    event = log_event(
        "mining_earning",
        asset=earning.get("coin", "XMR").upper(),
        amount=earning.get("amount", 0),
        fmv_usd=fmv,
        counterparty=earning.get("source", "pool"),
        metadata={
            "tx_hash": earning.get("tx_hash"),
            "source": earning.get("source", "mining"),
        }
    )

    # Record tax lot (mining income is ordinary income at FMV on receipt)
    if fmv > 0:
        record_tax_lot(
            asset=earning.get("coin", "XMR").upper(),
            quantity=earning.get("amount", 0),
            cost_basis_usd=fmv,
            source="mining",
        )

    return event


def on_swap_recorded(swap):
    """Hook: called after a swap is recorded in exchange.py.

    Args:
        swap: dict from exchange.record_swap() with coin_in, amount_in,
              btc_out, exchange, usd_value, id
    """
    # Log the swap event
    event = log_event(
        "swap_executed",
        asset=swap.get("coin_in", "XMR"),
        amount=swap.get("amount_in", 0),
        fmv_usd=swap.get("usd_value", 0),
        counterparty=swap.get("exchange", "manual"),
        metadata={
            "swap_id": swap.get("id"),
            "btc_out": swap.get("btc_out", 0),
            "rate": swap.get("rate", 0),
        }
    )

    # Dispose of the mined crypto lot (swap = disposition)
    if swap.get("usd_value", 0) > 0:
        dispose_tax_lot(
            asset=swap.get("coin_in", "XMR"),
            quantity=swap.get("amount_in", 0),
            proceeds_usd=swap.get("usd_value", 0),
            disposition_type="swap",
        )

    # Record new BTC lot from the swap proceeds
    record_tax_lot(
        asset="BTC",
        quantity=swap.get("btc_out", 0),
        cost_basis_usd=swap.get("usd_value", 0),
        source=f"swap_from_{swap.get('coin_in', 'xmr').lower()}",
    )

    # AML check
    sar_check = check_sar_thresholds(
        swap.get("exchange", "manual"),
        swap.get("usd_value", 0),
    )
    if sar_check["triggered"]:
        flag_sar(event["event_id"], "; ".join(sar_check["reasons"]))

    # Update counterparty volume
    _update_counterparty_volume(swap.get("exchange", "manual"), swap.get("usd_value", 0))

    return event


def on_road_minted(conversion):
    """Hook: called after ROAD is minted from BTC.

    Args:
        conversion: dict from mint.mint_road() with btc_in, road_minted,
                    usd_value, source, id
    """
    event = log_event(
        "road_minted",
        asset="ROAD",
        amount=conversion.get("road_minted", 0),
        fmv_usd=conversion.get("usd_value", 0),
        counterparty="internal",
        metadata={
            "conversion_id": conversion.get("id"),
            "btc_in": conversion.get("btc_in", 0),
            "source": conversion.get("source", "btc_deposit"),
        }
    )

    # Dispose of BTC lot (used to mint ROAD)
    if conversion.get("usd_value", 0) > 0:
        dispose_tax_lot(
            asset="BTC",
            quantity=conversion.get("btc_in", 0),
            proceeds_usd=conversion.get("usd_value", 0),
            disposition_type="swap",
        )

    # Record ROAD lot with basis inherited from BTC
    record_tax_lot(
        asset="ROAD",
        quantity=conversion.get("road_minted", 0),
        cost_basis_usd=conversion.get("usd_value", 0),
        source=f"minted_from_btc",
    )

    return event


def on_payment(payment):
    """Hook: called after a ROAD payment is made.

    Args:
        payment: dict from payments.PaymentGateway.pay_bill() result['payment']
    """
    event = log_event(
        "payment_sent",
        asset="ROAD",
        amount=payment.get("road_amount", 0),
        fmv_usd=payment.get("usd_amount", 0),
        counterparty=payment.get("biller_id", "unknown"),
        metadata={
            "confirmation": payment.get("confirmation"),
            "biller": payment.get("biller"),
            "account": payment.get("account"),
            "memo": payment.get("memo"),
        }
    )

    # Dispose of ROAD lot (payment = disposition)
    if payment.get("usd_amount", 0) > 0:
        dispose_tax_lot(
            asset="ROAD",
            quantity=payment.get("road_amount", 0),
            proceeds_usd=payment.get("usd_amount", 0),
            disposition_type="payment",
        )

    # AML check on the payment
    sar_check = check_sar_thresholds(
        payment.get("biller_id", "unknown"),
        payment.get("usd_amount", 0),
    )
    if sar_check["triggered"]:
        flag_sar(event["event_id"], "; ".join(sar_check["reasons"]))

    return event


# ============================================================================
# CLI (standalone)
# ============================================================================

def print_status():
    """Print compliance dashboard."""
    status = compliance_status()

    print()
    print("=" * 62)
    print("  ROADCHAIN COMPLIANCE DASHBOARD")
    print("=" * 62)
    print()

    chain = status["audit_chain"]
    chain_icon = "VALID" if chain["valid"] else "BROKEN"
    print(f"  Audit Chain:     {chain_icon} ({chain['total_records']} records)")
    print(f"  Last Event:      {chain['last_event']}")
    print()

    aml = status["aml"]
    print(f"  Counterparties:  {aml['registered_counterparties']} registered")
    sar_status = f"{aml['open_sar_flags']} open" if aml["open_sar_flags"] > 0 else "none"
    print(f"  SAR Flags:       {sar_status} ({aml['total_sar_flags']} total)")
    print()

    tax = status["tax"]
    print(f"  Tax Lots:        {tax['open_lots']} open")
    print(f"  Total Basis:     ${tax['total_basis_usd']:,.2f}")
    print()

    print(f"  Securities Risk: {status['securities_risk']}")
    print(f"  Status:          {status['status']}")
    print()


def print_audit(limit=15):
    """Print recent audit events."""
    events = get_recent_events(limit)

    print()
    print("=" * 62)
    print("  ROADCHAIN AUDIT LOG")
    print("=" * 62)
    print()

    if not events:
        print("  No audit events recorded yet.")
        print()
        return

    print(f"  {'ID':<18} {'Type':<20} {'Asset':<6} {'Amount':<14} {'FMV USD'}")
    print("  " + "-" * 58)

    for e in events:
        print(
            f"  {e['event_id']:<18} {e['event_type']:<20} "
            f"{e['asset']:<6} {e['amount']:<14.8f} ${e['fmv_usd']:,.2f}"
        )
    print()


def print_verify():
    """Print chain verification result."""
    result = verify_chain()

    print()
    if result["valid"]:
        print(f"  Audit chain VALID - {result['total_records']} records verified")
    else:
        print(f"  AUDIT CHAIN BROKEN at record {result['broken_at']}")
        print(f"  Error: {result['error']}")
    print()


def print_tax_summary(year):
    """Print tax summary for a year."""
    summary = generate_tax_summary(year)

    print()
    print("=" * 62)
    print(f"  ROADCHAIN TAX SUMMARY - {year}")
    print("=" * 62)
    print()

    oi = summary["ordinary_income"]
    print(f"  Ordinary Income (Mining):")
    print(f"    Mining events:       {oi['mining_events']}")
    print(f"    Mining income:       ${oi['mining_income_usd']:,.2f}")
    print()

    cg = summary["capital_gains"]
    print(f"  Capital Gains/Losses:")
    print(f"    Short-term:          ${cg['short_term_gain_usd']:,.2f}")
    print(f"    Long-term:           ${cg['long_term_gain_usd']:,.2f}")
    print(f"    Total:               ${cg['total_gain_usd']:,.2f}")
    print(f"    Proceeds:            ${cg['total_proceeds_usd']:,.2f}")
    print(f"    Cost basis:          ${cg['total_cost_basis_usd']:,.2f}")
    print(f"    Dispositions:        {cg['dispositions']}")
    print()

    print(f"  Total Taxable:         ${summary['total_taxable']:,.2f}")
    print()
    print(f"  Report saved: {TAX_REPORTS_DIR / f'{year}.json'}")
    print()


def print_risk():
    """Print risk assessment."""
    risk = risk_assessment()

    print()
    print("=" * 62)
    print("  ROADCHAIN RISK ASSESSMENT")
    print("=" * 62)
    print()

    print(f"  Overall Risk: {risk['overall_risk']}")
    print(f"  Issues: {risk['issue_count']}")
    print()

    if risk["issues"]:
        for issue in risk["issues"]:
            print(f"  [{issue['severity']}] {issue['area']}: {issue['issue']}")
            if issue.get("detail"):
                print(f"         {issue['detail']}")
        print()
    else:
        print("  No issues found.")
        print()


def print_gaps():
    """Print missing documentation gaps."""
    result = missing_documentation()

    print()
    print("=" * 62)
    print("  ROADCHAIN COMPLIANCE GAPS")
    print("=" * 62)
    print()

    if not result["gaps"]:
        print("  No documentation gaps found.")
    else:
        for gap in result["gaps"]:
            print(f"  [{gap['area']}] {gap['type']}: {gap['detail']}")
    print()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("""
+==============================================================+
|              ROADCHAIN COMPLIANCE MODULE                      |
|     SEC / FINRA / FinCEN / IRS Regulatory Compliance         |
|                                                              |
|  Audit Trail  |  AML/KYC  |  Tax Basis  |  Risk Assessment  |
+==============================================================+

Usage:
  python3 compliance.py status       Compliance dashboard
  python3 compliance.py verify       Verify audit chain integrity
  python3 compliance.py audit [N]    Show recent audit events (default 15)
  python3 compliance.py tax <year>   Generate tax summary
  python3 compliance.py risk         Risk assessment
  python3 compliance.py gaps         Missing documentation
        """)
        sys.exit(0)

    cmd = sys.argv[1]

    if cmd == "status":
        print_status()
    elif cmd == "verify":
        print_verify()
    elif cmd == "audit":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 15
        print_audit(limit)
    elif cmd == "tax":
        if len(sys.argv) < 3:
            print("Usage: python3 compliance.py tax <year>")
            sys.exit(1)
        print_tax_summary(int(sys.argv[2]))
    elif cmd == "risk":
        print_risk()
    elif cmd == "gaps":
        print_gaps()
    else:
        print(f"Unknown command: {cmd}")
