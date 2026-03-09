# 🚀 Clerk + Stripe Integration - Quick Start

## ✅ What's Ready

I've created a complete Clerk + Stripe integration system for BlackRoad OS:

### Files Created:
1. **`clerk-stripe-integration.js`** - Main integration logic
2. **`clerk-stripe-api-routes.js`** - Next.js API routes and helpers
3. **`CLERK_STRIPE_SETUP_GUIDE.md`** - Complete setup documentation
4. **`deploy-clerk-stripe.sh`** - Automated deployment script

---

## 🎯 What This Does

When a user signs up in your app via Clerk:
1. **Automatically creates** a Stripe customer
2. **Syncs user data** (name, email) to Stripe
3. **Links accounts** via metadata (Clerk user ID ↔ Stripe customer ID)

When a user subscribes via Stripe:
1. **Updates Clerk user metadata** with subscription info
2. **Enables subscription checks** in your app code
3. **Manages billing** via Stripe Customer Portal

---

## 🚀 Quick Deploy (5 minutes)

### Option 1: Automatic Deployment
```bash
~/deploy-clerk-stripe.sh
```

This deploys to:
- `blackroad-io-app`
- `dashboard-blackroad-io`
- `blackroad-monitoring-dashboard`

### Option 2: Manual Setup
1. Copy `clerk-stripe-integration.js` to `lib/` in your Next.js app
2. Create webhook routes:
   - `pages/api/webhooks/clerk.js`
   - `pages/api/webhooks/stripe.js`
3. Install dependencies:
   ```bash
   npm install stripe svix @clerk/nextjs
   ```

---

## 🔑 Environment Variables Needed

Add to `.env.local`:

```bash
# Clerk (get from https://dashboard.clerk.com)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
CLERK_WEBHOOK_SECRET=whsec_...

# Stripe (get from https://dashboard.stripe.com)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

### Where to Get These:

**Your Stripe Account:**
- Account ID: `acct_1SUDM8ChUUSEbzyh`
- Already logged into Stripe CLI ✅

**Clerk:**
1. Go to https://dashboard.clerk.com
2. API Keys → Copy keys
3. Webhooks → Add endpoint → Copy secret

**Stripe:**
1. Already have: Test keys in Stripe CLI config
2. Need: Webhook secret from Stripe dashboard

---

## 💡 Usage Examples

### Check if User Has Active Subscription:

```jsx
import { useUser } from '@clerk/nextjs';

function MyComponent() {
  const { user } = useUser();

  if (user?.publicMetadata?.stripe_subscription_status === 'active') {
    return <PremiumFeature />;
  }

  return <UpgradePrompt />;
}
```

### Create Checkout Session:

```jsx
import { createCheckoutSession } from '@/lib/stripe-helpers';

const handleSubscribe = async () => {
  const session = await createCheckoutSession(
    user,
    'price_xxx', // Your Stripe price ID
    '/success',
    '/pricing'
  );

  window.location.href = session.url;
};
```

### Manage Billing:

```jsx
import { createPortalSession } from '@/lib/stripe-helpers';

const handleManageBilling = async () => {
  const session = await createPortalSession(user, '/account');
  window.location.href = session.url;
};
```

---

## 🔄 How It Works

### User Signup Flow:
```
User signs up via Clerk
  ↓
Clerk webhook → /api/webhooks/clerk
  ↓
Create Stripe customer automatically
  ↓
Update Clerk user metadata with Stripe customer ID
```

### Subscription Flow:
```
User subscribes via Stripe Checkout
  ↓
Stripe webhook → /api/webhooks/stripe
  ↓
Find Clerk user by Stripe customer ID
  ↓
Update Clerk user metadata with subscription status
```

---

## 📋 Setup Checklist

- [ ] Deploy integration files to app
- [ ] Install dependencies (`stripe`, `svix`, `@clerk/nextjs`)
- [ ] Add environment variables
- [ ] Set up Clerk webhook endpoint
- [ ] Set up Stripe webhook endpoint
- [ ] Create subscription products in Stripe
- [ ] Test with test mode keys
- [ ] Deploy to production with live keys

---

## 🎨 Example Pricing Page

See `CLERK_STRIPE_SETUP_GUIDE.md` for complete example pricing and billing pages.

---

## 🐛 Testing Locally

```bash
# Terminal 1: Run your Next.js app
npm run dev

# Terminal 2: Forward Clerk webhooks
clerk listen --webhook-url http://localhost:3000/api/webhooks/clerk

# Terminal 3: Forward Stripe webhooks
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```

---

## 📞 Support

Full documentation: `CLERK_STRIPE_SETUP_GUIDE.md`

Your Stripe account is already configured:
- Account: `acct_1SUDM8ChUUSEbzyh`
- CLI: Logged in ✅
- Test mode keys: Available in config

---

**Ready to deploy?**
```bash
~/deploy-clerk-stripe.sh
```

---

*BlackRoad OS, Inc. - 2025-12-28*
