# BlackRoad OS - Stripe Setup Guide
**Execute this NOW to start taking payments**

## Step 1: Access Stripe Dashboard (1 minute)

1. Go to: https://dashboard.stripe.com
2. Log in with your account (or create one if needed)
3. Switch to **Test Mode** first (toggle in top right)

---

## Step 2: Create Products (3 minutes)

### Product 1: BlackRoad OS Pro (Founding Member)

1. Click **Products** in left sidebar
2. Click **+ Add product**
3. Fill in:
   - **Name:** `BlackRoad OS - Pro (Founding Member - 50% OFF FOREVER)`
   - **Description:** `AI operating system for teams. Founding member gets 50% off for life.`
   - **Pricing model:** `Standard pricing`
   - **Price:** `$14.50` (this is 50% of $29)
   - **Billing period:** `Monthly`
   - **Currency:** `USD`
4. Click **Save product**
5. **COPY THE PRICE ID** (starts with `price_...`) - you'll need this

### Product 2: BlackRoad OS Pro (Regular Price)

1. Click **+ Add product**
2. Fill in:
   - **Name:** `BlackRoad OS - Pro`
   - **Description:** `AI operating system for teams. Full-featured platform.`
   - **Pricing model:** `Standard pricing`
   - **Price:** `$29`
   - **Billing period:** `Monthly`
   - **Currency:** `USD`
3. Click **Save product**
4. **COPY THE PRICE ID**

### Product 3: BlackRoad OS Enterprise

1. Click **+ Add product**
2. Fill in:
   - **Name:** `BlackRoad OS - Enterprise`
   - **Description:** `AI operating system for large teams. Custom integrations, dedicated support.`
   - **Pricing model:** `Standard pricing`
   - **Price:** `$99`
   - **Billing period:** `Monthly`
   - **Currency:** `USD`
3. Click **Save product**
4. **COPY THE PRICE ID**

---

## Step 3: Create Payment Links (5 minutes)

### Payment Link 1: Founding Member (50% OFF)

1. Click **Payment links** in left sidebar
2. Click **+ New**
3. Select: `BlackRoad OS - Pro (Founding Member - 50% OFF FOREVER)` product
4. Configure:
   - **Allow promotion codes:** `Yes`
   - **Trial period:** `14 days`
   - **Collect customer information:** `Email address`
   - **After payment:** `Show a confirmation page`
   - **Custom message:** `Welcome to BlackRoad OS! Check your email for login details.`
5. Click **Create link**
6. **COPY THE PAYMENT LINK URL** (starts with `https://buy.stripe.com/...`)

Save this as: `FOUNDING_MEMBER_PAYMENT_LINK`

### Payment Link 2: Regular Pro

1. Click **+ New**
2. Select: `BlackRoad OS - Pro` product
3. Configure same settings as above
4. Click **Create link**
5. **COPY THE PAYMENT LINK URL**

Save this as: `PRO_PAYMENT_LINK`

### Payment Link 3: Enterprise

1. Click **+ New**
2. Select: `BlackRoad OS - Enterprise` product
3. Configure:
   - **Allow promotion codes:** `Yes`
   - **Trial period:** `30 days` (longer for enterprise)
   - **Collect customer information:** `Email address and billing address`
   - **After payment:** `Redirect to a page` → `https://app.blackroad.io/welcome`
4. Click **Create link**
5. **COPY THE PAYMENT LINK URL**

Save this as: `ENTERPRISE_PAYMENT_LINK`

---

## Step 4: Get API Keys (2 minutes)

1. Click **Developers** in left sidebar
2. Click **API keys**
3. You'll see:
   - **Publishable key:** `pk_test_...`
   - **Secret key:** `sk_test_...` (click "Reveal test key")
4. **COPY BOTH KEYS**

---

## Step 5: Switch to Live Mode (WHEN READY)

⚠️ **DO THIS ONLY AFTER TESTING IN TEST MODE**

1. Toggle **Test Mode** → **Live Mode** (top right)
2. Repeat Steps 2-4 in Live Mode
3. Get Live API keys:
   - **Publishable key:** `pk_live_...`
   - **Secret key:** `sk_live_...`

---

## Step 6: Set Up Webhooks (Optional but Recommended)

1. Click **Developers** → **Webhooks**
2. Click **+ Add endpoint**
3. Endpoint URL: `https://api.blackroad.io/webhooks/stripe`
4. Select events to listen for:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Click **Add endpoint**
6. **COPY THE SIGNING SECRET** (starts with `whsec_...`)

---

## Step 7: Update Environment Variables

Add these to your deployment (Railway, Vercel, etc.):

```bash
# Test Mode (for development)
STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE
STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET_HERE

# Price IDs
STRIPE_PRICE_FOUNDING=price_YOUR_FOUNDING_PRICE_ID
STRIPE_PRICE_PRO=price_YOUR_PRO_PRICE_ID
STRIPE_PRICE_ENTERPRISE=price_YOUR_ENTERPRISE_PRICE_ID

# Live Mode (for production - when ready)
STRIPE_SECRET_KEY_LIVE=sk_live_YOUR_KEY_HERE
STRIPE_PUBLISHABLE_KEY_LIVE=pk_live_YOUR_KEY_HERE
STRIPE_WEBHOOK_SECRET_LIVE=whsec_YOUR_SECRET_HERE
```

---

## Step 8: Test Payment Flow

1. Visit your payment link in Test Mode
2. Use test card: `4242 4242 4242 4242`
3. Expiry: Any future date
4. CVC: Any 3 digits
5. Click **Subscribe**
6. Verify success page shows

---

## Quick Reference: Test Cards

- **Success:** `4242 4242 4242 4242`
- **Decline:** `4000 0000 0000 0002`
- **Requires Authentication:** `4000 0025 0000 3155`
- **Insufficient Funds:** `4000 0000 0000 9995`

---

## AFTER YOU COMPLETE THIS:

Send me the payment links and I'll:
1. Update the landing page with real Stripe checkout
2. Deploy the updated page
3. Create the launch tweet
4. Deploy the backend API

**LET'S MAKE MONEY** 🚀
