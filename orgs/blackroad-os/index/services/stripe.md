# Stripe Configuration

## Account
- **ID**: `acct_1SUDM8ChUUSEbzyh`
- **Business**: BlackRoad OS, Inc.
- **Dashboard**: https://dashboard.stripe.com/acct_1SUDM8ChUUSEbzyh

## Quick Actions

### Create Product + Payment Link
```
1. Stripe:create_product {name, description}
2. Stripe:create_price {product_id, unit_amount, currency}
3. Stripe:create_payment_link {price_id, quantity}
```

### List Customers
```
Stripe:list_customers {limit: 100}
```
