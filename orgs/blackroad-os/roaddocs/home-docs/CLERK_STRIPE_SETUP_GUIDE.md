# 🔗 Clerk + Stripe Integration Setup Guide

Complete guide to integrate Clerk (authentication) with Stripe (payments/billing) for BlackRoad OS.

## What This Does

- **Auto-creates Stripe customers** when users sign up via Clerk
- **Syncs user data** between Clerk and Stripe automatically
- **Updates subscription status** in Clerk when users subscribe in Stripe
- **Enables billing portal** for users to manage subscriptions

---

## Prerequisites

1. **Clerk Account** - https://clerk.com
2. **Stripe Account** - https://stripe.com
3. **Next.js App** - Running with Clerk already integrated

---

## Step 1: Install Dependencies

```bash
npm install stripe svix @clerk/nextjs
```

Or if using yarn:
```bash
yarn add stripe svix @clerk/nextjs
```

---

## Step 2: Environment Variables

Add to your `.env.local`:

```bash
# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
CLERK_WEBHOOK_SECRET=whsec_...

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

### How to Get These Keys:

**Clerk Keys:**
1. Go to https://dashboard.clerk.com
2. Select your app
3. Go to "API Keys"
4. Copy publishable and secret keys

**Clerk Webhook Secret:**
1. In Clerk dashboard, go to "Webhooks"
2. Click "Add Endpoint"
3. URL: `https://yourdomain.com/api/webhooks/clerk`
4. Subscribe to events: `user.created`, `user.updated`, `user.deleted`
5. Copy the signing secret

**Stripe Keys:**
1. Go to https://dashboard.stripe.com
2. Developers → API Keys
3. Copy publishable and secret keys

**Stripe Webhook Secret:**
1. In Stripe dashboard, go to "Developers" → "Webhooks"
2. Click "Add endpoint"
3. URL: `https://yourdomain.com/api/webhooks/stripe`
4. Subscribe to events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
5. Copy the signing secret

---

## Step 3: Add Integration Files

### File 1: `lib/clerk-stripe-integration.js`
Copy from `/Users/alexa/clerk-stripe-integration.js`

### File 2: API Routes
Copy the routes from `/Users/alexa/clerk-stripe-api-routes.js`:
- `pages/api/webhooks/clerk.js`
- `pages/api/webhooks/stripe.js`
- `lib/clerk-api.js`
- `lib/stripe-helpers.js`

---

## Step 4: Create Pricing Page

```jsx
// pages/pricing.jsx
import { useUser } from '@clerk/nextjs';
import { createCheckoutSession } from '@/lib/stripe-helpers';

export default function Pricing() {
  const { user } = useUser();

  const handleSubscribe = async (priceId) => {
    const session = await createCheckoutSession(
      user,
      priceId,
      `${window.location.origin}/success`,
      `${window.location.origin}/pricing`
    );

    // Redirect to Stripe Checkout
    window.location.href = session.url;
  };

  return (
    <div className="pricing-container">
      <h1>Choose Your Plan</h1>

      <div className="plan">
        <h2>Pro Plan</h2>
        <p>$29/month</p>
        <button onClick={() => handleSubscribe('price_xxx')}>
          Subscribe
        </button>
      </div>

      <div className="plan">
        <h2>Enterprise</h2>
        <p>$99/month</p>
        <button onClick={() => handleSubscribe('price_yyy')}>
          Subscribe
        </button>
      </div>
    </div>
  );
}
```

---

## Step 5: Create Billing Portal

```jsx
// pages/account/billing.jsx
import { useUser } from '@clerk/nextjs';
import { createPortalSession } from '@/lib/stripe-helpers';

export default function Billing() {
  const { user } = useUser();

  const handleManageBilling = async () => {
    const session = await createPortalSession(
      user,
      `${window.location.origin}/account`
    );

    // Redirect to Stripe Customer Portal
    window.location.href = session.url;
  };

  return (
    <div>
      <h1>Billing</h1>

      {user?.publicMetadata?.stripe_subscription_status === 'active' ? (
        <div>
          <p>Status: Active ✅</p>
          <p>Plan: {user.publicMetadata.stripe_plan}</p>
        </div>
      ) : (
        <p>No active subscription</p>
      )}

      <button onClick={handleManageBilling}>
        Manage Billing
      </button>
    </div>
  );
}
```

---

## Step 6: Protect Routes with Subscription Check

```jsx
// middleware.ts
import { authMiddleware } from '@clerk/nextjs';

export default authMiddleware({
  publicRoutes: ['/pricing', '/'],

  async afterAuth(auth, req) {
    // Require active subscription for premium routes
    if (req.nextUrl.pathname.startsWith('/premium')) {
      const user = auth.user;
      const hasSubscription = user?.publicMetadata?.stripe_subscription_status === 'active';

      if (!hasSubscription) {
        return NextResponse.redirect(new URL('/pricing', req.url));
      }
    }
  }
});

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
};
```

---

## Step 7: Test the Integration

### Test User Creation:
1. Sign up a new user in your app (Clerk)
2. Check Stripe dashboard → Customers
3. New customer should appear automatically

### Test Subscription:
1. Go to `/pricing` page
2. Click "Subscribe"
3. Complete Stripe Checkout
4. Check Clerk user metadata (should show subscription info)

### Test Webhooks Locally:

**For Clerk:**
```bash
clerk listen --webhook-url http://localhost:3000/api/webhooks/clerk
```

**For Stripe:**
```bash
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```

---

## Step 8: Deploy

When deploying to production:

1. **Update webhook URLs** in Clerk and Stripe dashboards to your production domain
2. **Use production API keys** (not test keys)
3. **Update CORS settings** if needed
4. **Test webhooks** with real events

---

## Common Use Cases

### Check if User Has Active Subscription:

```jsx
import { useUser } from '@clerk/nextjs';

function MyComponent() {
  const { user } = useUser();

  const hasActiveSubscription =
    user?.publicMetadata?.stripe_subscription_status === 'active';

  return hasActiveSubscription ? (
    <PremiumFeature />
  ) : (
    <UpgradePrompt />
  );
}
```

### Get Stripe Customer ID:

```jsx
const stripeCustomerId = user?.publicMetadata?.stripe_customer_id;
```

### Server-Side Subscription Check:

```jsx
import { currentUser } from '@clerk/nextjs/server';

export async function getServerSideProps() {
  const user = await currentUser();

  const hasSubscription =
    user?.publicMetadata?.stripe_subscription_status === 'active';

  if (!hasSubscription) {
    return {
      redirect: {
        destination: '/pricing',
        permanent: false,
      },
    };
  }

  return { props: {} };
}
```

---

## Troubleshooting

### Webhook Not Firing:
- Check webhook URL is correct and accessible
- Verify signing secret is correct
- Check server logs for errors
- Use webhook testing tools in Clerk/Stripe dashboards

### User Metadata Not Updating:
- Make sure `clerkClient` is properly imported
- Check Clerk API permissions
- Verify user ID is correct

### Stripe Customer Not Creating:
- Check Stripe API key is valid
- Verify email address is available
- Check for rate limits

---

## Security Best Practices

1. **Always verify webhook signatures** (already implemented)
2. **Use environment variables** for all secrets
3. **Never expose secret keys** in client-side code
4. **Validate user permissions** before creating subscriptions
5. **Use HTTPS** in production for all webhook endpoints

---

## Next Steps

1. Create subscription plans in Stripe
2. Set up pricing tiers
3. Add subscription analytics
4. Implement usage-based billing (if needed)
5. Add cancellation flows

---

**Need Help?**
- Clerk Docs: https://clerk.com/docs
- Stripe Docs: https://stripe.com/docs
- This integration: `/Users/alexa/clerk-stripe-integration.js`

---

*Last Updated: 2025-12-28*
*BlackRoad OS, Inc.*
