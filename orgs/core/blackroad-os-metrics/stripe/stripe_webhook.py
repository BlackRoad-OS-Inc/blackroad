#!/usr/bin/env python3
"""
Stripe Webhook Relay for BlackRoad OS Raspberry Pi Infrastructure

Receives Stripe events relayed from pay.blackroad.io (Cloudflare Worker)
and processes them locally on the Pi cluster.

Runs on: 192.168.4.64 (blackroad-pi) or 192.168.4.38 (aria64)
Accessible via Cloudflare Tunnel: agent.blackroad.ai/webhooks/stripe

Copyright: BlackRoad OS, Inc.
"""

import os
import json
import sqlite3
from datetime import datetime
from pathlib import Path
from flask import Flask, request, jsonify

app = Flask(__name__)

# Local SQLite for subscription tracking (Pi-side)
DB_PATH = Path.home() / '.blackroad' / 'stripe-subscriptions.db'
DB_PATH.parent.mkdir(parents=True, exist_ok=True)

LOG_PATH = Path.home() / '.blackroad' / 'stripe-events.jsonl'


def get_db():
    db = sqlite3.connect(str(DB_PATH))
    db.execute('''CREATE TABLE IF NOT EXISTS subscriptions (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        tier TEXT,
        status TEXT,
        amount INTEGER,
        interval TEXT,
        created_at TEXT,
        updated_at TEXT
    )''')
    db.execute('''CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        type TEXT,
        customer_id TEXT,
        processed_at TEXT
    )''')
    db.execute('''CREATE TABLE IF NOT EXISTS revenue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT,
        amount INTEGER,
        currency TEXT,
        event_type TEXT,
        created_at TEXT
    )''')
    db.commit()
    return db


def log_event(event):
    """Append event to JSONL audit log."""
    with open(LOG_PATH, 'a') as f:
        f.write(json.dumps({
            'id': event.get('id'),
            'type': event.get('type'),
            'received_at': datetime.utcnow().isoformat(),
        }) + '\n')


@app.route('/webhooks/stripe', methods=['POST'])
def webhook_relay():
    """Receive Stripe events relayed from pay.blackroad.io worker."""
    source = request.headers.get('X-BlackRoad-Source', 'unknown')
    event_type = request.headers.get('X-BlackRoad-Event', '')

    try:
        event = request.get_json(force=True)
    except Exception:
        return jsonify({'error': 'Invalid JSON'}), 400

    log_event(event)

    db = get_db()
    now = datetime.utcnow().isoformat()

    # Idempotency: skip duplicate events
    existing = db.execute(
        'SELECT id FROM events WHERE id = ?', (event.get('id'),)
    ).fetchone()
    if existing:
        return jsonify({'received': True, 'duplicate': True})

    obj = event.get('data', {}).get('object', {})
    etype = event.get('type', '')

    if etype == 'checkout.session.completed':
        cust = obj.get('customer', '')
        sub_id = obj.get('subscription', '')
        email = obj.get('customer_email', '')
        amount = obj.get('amount_total', 0)
        db.execute(
            'INSERT OR REPLACE INTO subscriptions (id, customer_id, status, amount, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
            (sub_id, cust, 'active', amount, now, now),
        )
        db.execute(
            'INSERT INTO revenue (customer_id, amount, currency, event_type, created_at) VALUES (?, ?, ?, ?, ?)',
            (cust, amount, 'usd', etype, now),
        )

    elif etype in ('customer.subscription.created', 'customer.subscription.updated'):
        sub_id = obj.get('id', '')
        cust = obj.get('customer', '')
        status = obj.get('status', '')
        tier = obj.get('metadata', {}).get('tier', '')
        db.execute(
            'INSERT OR REPLACE INTO subscriptions (id, customer_id, tier, status, updated_at) VALUES (?, ?, ?, ?, ?)',
            (sub_id, cust, tier, status, now),
        )

    elif etype == 'customer.subscription.deleted':
        sub_id = obj.get('id', '')
        db.execute(
            'UPDATE subscriptions SET status = ?, updated_at = ? WHERE id = ?',
            ('canceled', now, sub_id),
        )

    elif etype == 'invoice.payment_succeeded':
        cust = obj.get('customer', '')
        amount = obj.get('amount_paid', 0)
        db.execute(
            'INSERT INTO revenue (customer_id, amount, currency, event_type, created_at) VALUES (?, ?, ?, ?, ?)',
            (cust, amount, obj.get('currency', 'usd'), etype, now),
        )

    elif etype == 'invoice.payment_failed':
        cust = obj.get('customer', '')
        app.logger.warning(f'Payment failed for customer {cust}')

    # Record event for idempotency
    db.execute(
        'INSERT INTO events (id, type, customer_id, processed_at) VALUES (?, ?, ?, ?)',
        (event.get('id', ''), etype, obj.get('customer', ''), now),
    )
    db.commit()

    return jsonify({
        'received': True,
        'type': etype,
        'source': source,
        'processed_at': now,
    })


@app.route('/webhooks/stripe/stats', methods=['GET'])
def stats():
    """Return local subscription stats for monitoring."""
    db = get_db()
    active = db.execute(
        "SELECT COUNT(*) FROM subscriptions WHERE status = 'active'"
    ).fetchone()[0]
    total_events = db.execute('SELECT COUNT(*) FROM events').fetchone()[0]
    total_revenue = db.execute(
        'SELECT COALESCE(SUM(amount), 0) FROM revenue'
    ).fetchone()[0]

    return jsonify({
        'active_subscriptions': active,
        'total_events_processed': total_events,
        'total_revenue_cents': total_revenue,
        'db_path': str(DB_PATH),
    })


@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'ok',
        'service': 'stripe-webhook-relay',
        'host': os.uname().nodename,
        'timestamp': datetime.utcnow().isoformat(),
    })


if __name__ == '__main__':
    print(f'Stripe webhook relay starting on port 5000')
    print(f'DB: {DB_PATH}')
    print(f'Log: {LOG_PATH}')
    app.run(host='0.0.0.0', port=5000)
