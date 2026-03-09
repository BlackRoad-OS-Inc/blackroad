# roadpay

[![GitHub](https://img.shields.io/badge/GitHub-BlackRoad-OS-purple?style=for-the-badge&logo=github)](https://github.com/BlackRoad-OS/roadpay)
[![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)](https://github.com/BlackRoad-OS/roadpay)
[![BlackRoad](https://img.shields.io/badge/BlackRoad-OS-black?style=for-the-badge)](https://blackroad.io)

# RoadPay

Payment processing platform for the BlackRoad ecosystem.

## Features

- **Stripe Integration** - Full Stripe API support
- **Subscriptions** - Recurring billing management
- **One-time Payments** - Payment intents
- **Invoicing** - Create and manage invoices
- **Checkout** - Hosted checkout sessions
- **Billing Portal** - Customer self-service
- **Webhooks** - Real-time event handling

## Quick Start

```bash
# Install
pip install -e .

# Set environment
export ROADPAY_STRIPE_SECRET_KEY=sk_test_...
export ROADPAY_STRIPE_WEBHOOK_SECRET=whsec_...

# Run
roadpay
```

## API Endpoints

### Customers
- `POST /customers` - Create customer
- `GET /customers/{id}` - Get customer
- `GET /customers/{id}/subscriptions` - Customer subscriptions

### Payments
- `POST /payments/intent` - Create payment intent
- `GET /payments/{id}` - Get payment status

### Products & Prices
- `POST /products` - Create product
- `GET /products` - List products
- `POST /prices` - Create price
- `GET /prices` - List prices

### Subscriptions
- `POST /subscriptions` - Create subscription
- `GET /subscriptions/{id}` - Get subscription
- `POST /subscriptions/{id}/cancel` - Cancel subscription

### Invoices
- `POST /invoices` - Create invoice
- `GET /invoices/{id}` - Get invoice

### Checkout
- `POST /checkout/session` - Create checkout session
- `POST /billing/portal` - Create billing portal session

## License

Proprietary - BlackRoad OS, Inc.
