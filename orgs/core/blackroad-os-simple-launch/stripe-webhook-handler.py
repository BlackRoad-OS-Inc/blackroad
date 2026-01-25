#!/usr/bin/env python3
"""
BlackRoad OS - Stripe Webhook Handler
Handles payment events and automates customer onboarding
"""

import os
import json
import stripe
from datetime import datetime, timedelta
from flask import Flask, request, jsonify

app = Flask(__name__)

# Load Stripe API key from environment or ~/.stripe_keys
STRIPE_SECRET_KEY = os.environ.get('STRIPE_SECRET_KEY')

if not STRIPE_SECRET_KEY:
    try:
        with open(os.path.expanduser('~/.stripe_keys'), 'r') as f:
            for line in f:
                if line.startswith('STRIPE_SECRET_KEY='):
                    STRIPE_SECRET_KEY = line.split('=', 1)[1].strip()
                    break
    except FileNotFoundError:
        pass

if not STRIPE_SECRET_KEY:
    raise ValueError("STRIPE_SECRET_KEY not configured. Set env var or create ~/.stripe_keys")

stripe.api_key = STRIPE_SECRET_KEY

# Webhook secret (get this from Stripe dashboard)
WEBHOOK_SECRET = os.environ.get('STRIPE_WEBHOOK_SECRET', 'whsec_...')  # Set this in production

@app.route('/webhook/stripe', methods=['POST'])
def stripe_webhook():
    """Handle incoming Stripe webhook events"""
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')

    try:
        # Verify webhook signature
        event = stripe.Webhook.construct_event(
            payload, sig_header, WEBHOOK_SECRET
        )
    except ValueError:
        return jsonify({'error': 'Invalid payload'}), 400
    except stripe.error.SignatureVerificationError:
        return jsonify({'error': 'Invalid signature'}), 400

    # Handle the event
    event_type = event['type']
    data = event['data']['object']

    print(f"[{datetime.now()}] Received event: {event_type}")

    # Handle different event types
    if event_type == 'checkout.session.completed':
        handle_checkout_completed(data)

    elif event_type == 'customer.subscription.created':
        handle_subscription_created(data)

    elif event_type == 'customer.subscription.updated':
        handle_subscription_updated(data)

    elif event_type == 'customer.subscription.deleted':
        handle_subscription_deleted(data)

    elif event_type == 'invoice.payment_succeeded':
        handle_payment_succeeded(data)

    elif event_type == 'invoice.payment_failed':
        handle_payment_failed(data)

    return jsonify({'status': 'success'}), 200


def handle_checkout_completed(session):
    """New customer signed up"""
    customer_id = session.get('customer')
    customer_email = session.get('customer_email')
    subscription_id = session.get('subscription')

    print(f"✅ New signup: {customer_email}")

    # Get customer details
    customer = stripe.Customer.retrieve(customer_id)

    # Determine if they're a founding member
    is_founding_member = False
    if subscription_id:
        subscription = stripe.Subscription.retrieve(subscription_id)
        for item in subscription['items']['data']:
            price = item['price']
            if price['unit_amount'] == 2900:  # $29 = founding member
                is_founding_member = True
                break

    # Send welcome email
    send_welcome_email(
        email=customer_email,
        name=customer.get('name', 'there'),
        is_founding_member=is_founding_member,
        customer_id=customer_id
    )

    # Create user account in database (TODO: implement)
    create_user_account(
        customer_id=customer_id,
        email=customer_email,
        name=customer.get('name'),
        is_founding_member=is_founding_member
    )

    # Log to file
    log_event('new_signup', {
        'customer_id': customer_id,
        'email': customer_email,
        'is_founding_member': is_founding_member,
        'timestamp': datetime.now().isoformat()
    })


def handle_subscription_created(subscription):
    """Subscription activated"""
    customer_id = subscription['customer']
    status = subscription['status']

    print(f"🎉 Subscription created for customer {customer_id}: {status}")

    log_event('subscription_created', {
        'customer_id': customer_id,
        'subscription_id': subscription['id'],
        'status': status,
        'timestamp': datetime.now().isoformat()
    })


def handle_subscription_updated(subscription):
    """Subscription changed (upgrade, downgrade, cancel)"""
    customer_id = subscription['customer']
    status = subscription['status']

    print(f"📝 Subscription updated for customer {customer_id}: {status}")

    # Check if subscription was canceled
    if subscription.get('cancel_at_period_end'):
        send_cancellation_email(customer_id)

    log_event('subscription_updated', {
        'customer_id': customer_id,
        'subscription_id': subscription['id'],
        'status': status,
        'timestamp': datetime.now().isoformat()
    })


def handle_subscription_deleted(subscription):
    """Subscription ended"""
    customer_id = subscription['customer']

    print(f"❌ Subscription deleted for customer {customer_id}")

    # Disable user access (TODO: implement)
    disable_user_access(customer_id)

    log_event('subscription_deleted', {
        'customer_id': customer_id,
        'subscription_id': subscription['id'],
        'timestamp': datetime.now().isoformat()
    })


def handle_payment_succeeded(invoice):
    """Payment successful"""
    customer_id = invoice['customer']
    amount_paid = invoice['amount_paid'] / 100  # Convert cents to dollars

    print(f"💰 Payment succeeded: ${amount_paid} from customer {customer_id}")

    log_event('payment_succeeded', {
        'customer_id': customer_id,
        'amount': amount_paid,
        'invoice_id': invoice['id'],
        'timestamp': datetime.now().isoformat()
    })


def handle_payment_failed(invoice):
    """Payment failed"""
    customer_id = invoice['customer']

    print(f"⚠️ Payment failed for customer {customer_id}")

    # Send payment failed email
    send_payment_failed_email(customer_id)

    log_event('payment_failed', {
        'customer_id': customer_id,
        'invoice_id': invoice['id'],
        'timestamp': datetime.now().isoformat()
    })


def send_welcome_email(email, name, is_founding_member, customer_id):
    """Send welcome email to new customer"""
    # TODO: Integrate with email service (SendGrid, Mailgun, etc.)
    print(f"📧 Sending welcome email to {email}")

    # For now, just log the email content
    trial_end_date = (datetime.now() + timedelta(days=14)).strftime('%B %d, %Y')

    email_data = {
        'to': email,
        'subject': '🎉 Welcome to BlackRoad OS!',
        'template': 'welcome-email.html',
        'variables': {
            'customer_name': name,
            'trial_end_date': trial_end_date,
            'unsubscribe_url': f'https://app.blackroad.io/unsubscribe?customer={customer_id}'
        }
    }

    log_event('email_sent', email_data)


def send_payment_failed_email(customer_id):
    """Send payment failure notification"""
    # TODO: Implement email sending
    print(f"📧 Sending payment failed email to customer {customer_id}")


def send_cancellation_email(customer_id):
    """Send cancellation confirmation"""
    # TODO: Implement email sending
    print(f"📧 Sending cancellation email to customer {customer_id}")


def create_user_account(customer_id, email, name, is_founding_member):
    """Create user account in database"""
    # TODO: Implement database integration
    print(f"👤 Creating user account for {email}")

    user_data = {
        'customer_id': customer_id,
        'email': email,
        'name': name,
        'is_founding_member': is_founding_member,
        'created_at': datetime.now().isoformat(),
        'status': 'trial'
    }

    log_event('user_created', user_data)


def disable_user_access(customer_id):
    """Disable user access after subscription ends"""
    # TODO: Implement access control
    print(f"🔒 Disabling access for customer {customer_id}")


def log_event(event_type, data):
    """Log event to file"""
    log_dir = '/Users/alexa/projects/blackroad-simple-launch/logs'
    os.makedirs(log_dir, exist_ok=True)

    log_file = f"{log_dir}/webhook-events.jsonl"

    event = {
        'event_type': event_type,
        'timestamp': datetime.now().isoformat(),
        'data': data
    }

    with open(log_file, 'a') as f:
        f.write(json.dumps(event) + '\n')


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'blackroad-webhook-handler',
        'timestamp': datetime.now().isoformat()
    })


if __name__ == '__main__':
    print("🚀 Starting BlackRoad OS Webhook Handler...")
    print(f"📝 Logs will be saved to: /Users/alexa/projects/blackroad-simple-launch/logs/")

    # Run in development mode
    # In production, use gunicorn or similar: gunicorn -w 4 -b 0.0.0.0:5000 stripe-webhook-handler:app
    app.run(host='0.0.0.0', port=5000, debug=True)
