#!/usr/bin/env node
/**
 * 🔗 CLERK + STRIPE INTEGRATION
 * Syncs user authentication (Clerk) with billing/payments (Stripe)
 *
 * Features:
 * - Auto-create Stripe customers when users sign up in Clerk
 * - Sync user metadata between Clerk and Stripe
 * - Handle subscription webhooks from Stripe
 * - Update Clerk user metadata with subscription status
 */

const { Webhook } = require('svix');
const Stripe = require('stripe');

// Configuration
const CLERK_WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;
const STRIPE_API_KEY = process.env.STRIPE_SECRET_KEY;
const stripe = new Stripe(STRIPE_API_KEY);

/**
 * Handle Clerk user.created webhook
 * Creates corresponding Stripe customer
 */
async function handleClerkUserCreated(event) {
  const { id, email_addresses, first_name, last_name } = event.data;

  try {
    // Create Stripe customer
    const customer = await stripe.customers.create({
      email: email_addresses[0].email_address,
      name: `${first_name} ${last_name}`.trim(),
      metadata: {
        clerk_user_id: id,
        created_via: 'clerk_webhook'
      }
    });

    console.log(`✅ Created Stripe customer ${customer.id} for Clerk user ${id}`);

    // TODO: Update Clerk user metadata with Stripe customer ID
    // This requires Clerk API call

    return customer;
  } catch (error) {
    console.error(`❌ Failed to create Stripe customer:`, error);
    throw error;
  }
}

/**
 * Handle Clerk user.updated webhook
 * Syncs updated info to Stripe
 */
async function handleClerkUserUpdated(event) {
  const { id, email_addresses, first_name, last_name, public_metadata } = event.data;

  try {
    const stripeCustomerId = public_metadata?.stripe_customer_id;

    if (!stripeCustomerId) {
      console.warn(`⚠️  No Stripe customer ID for Clerk user ${id}`);
      return;
    }

    // Update Stripe customer
    await stripe.customers.update(stripeCustomerId, {
      email: email_addresses[0].email_address,
      name: `${first_name} ${last_name}`.trim()
    });

    console.log(`✅ Updated Stripe customer ${stripeCustomerId}`);
  } catch (error) {
    console.error(`❌ Failed to update Stripe customer:`, error);
    throw error;
  }
}

/**
 * Handle Clerk user.deleted webhook
 * Optionally delete or deactivate Stripe customer
 */
async function handleClerkUserDeleted(event) {
  const { id, public_metadata } = event.data;

  try {
    const stripeCustomerId = public_metadata?.stripe_customer_id;

    if (!stripeCustomerId) {
      console.warn(`⚠️  No Stripe customer ID for deleted Clerk user ${id}`);
      return;
    }

    // Delete Stripe customer (or you could just deactivate)
    await stripe.customers.del(stripeCustomerId);

    console.log(`✅ Deleted Stripe customer ${stripeCustomerId}`);
  } catch (error) {
    console.error(`❌ Failed to delete Stripe customer:`, error);
    throw error;
  }
}

/**
 * Handle Stripe customer.subscription.created webhook
 * Updates Clerk user with subscription info
 */
async function handleStripeSubscriptionCreated(event) {
  const subscription = event.data.object;
  const customerId = subscription.customer;

  try {
    // Get Stripe customer to find Clerk user ID
    const customer = await stripe.customers.retrieve(customerId);
    const clerkUserId = customer.metadata?.clerk_user_id;

    if (!clerkUserId) {
      console.warn(`⚠️  No Clerk user ID for Stripe customer ${customerId}`);
      return;
    }

    console.log(`✅ Subscription ${subscription.id} created for Clerk user ${clerkUserId}`);

    // TODO: Update Clerk user metadata with subscription info
    // This requires Clerk API call

  } catch (error) {
    console.error(`❌ Failed to handle subscription creation:`, error);
    throw error;
  }
}

/**
 * Handle Stripe customer.subscription.updated webhook
 */
async function handleStripeSubscriptionUpdated(event) {
  const subscription = event.data.object;
  const customerId = subscription.customer;

  try {
    const customer = await stripe.customers.retrieve(customerId);
    const clerkUserId = customer.metadata?.clerk_user_id;

    if (!clerkUserId) {
      console.warn(`⚠️  No Clerk user ID for Stripe customer ${customerId}`);
      return;
    }

    console.log(`✅ Subscription ${subscription.id} updated - Status: ${subscription.status}`);

    // TODO: Update Clerk user metadata

  } catch (error) {
    console.error(`❌ Failed to handle subscription update:`, error);
    throw error;
  }
}

/**
 * Main webhook handler for Clerk events
 */
async function handleClerkWebhook(payload, headers) {
  const wh = new Webhook(CLERK_WEBHOOK_SECRET);

  try {
    const evt = wh.verify(payload, headers);

    switch (evt.type) {
      case 'user.created':
        await handleClerkUserCreated(evt);
        break;
      case 'user.updated':
        await handleClerkUserUpdated(evt);
        break;
      case 'user.deleted':
        await handleClerkUserDeleted(evt);
        break;
      default:
        console.log(`ℹ️  Unhandled Clerk event type: ${evt.type}`);
    }

    return { success: true };
  } catch (error) {
    console.error('❌ Clerk webhook verification failed:', error);
    throw error;
  }
}

/**
 * Main webhook handler for Stripe events
 */
async function handleStripeWebhook(payload, signature) {
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  try {
    const event = stripe.webhooks.constructEvent(payload, signature, webhookSecret);

    switch (event.type) {
      case 'customer.subscription.created':
        await handleStripeSubscriptionCreated(event);
        break;
      case 'customer.subscription.updated':
        await handleStripeSubscriptionUpdated(event);
        break;
      case 'customer.subscription.deleted':
        await handleStripeSubscriptionUpdated(event);
        break;
      default:
        console.log(`ℹ️  Unhandled Stripe event type: ${event.type}`);
    }

    return { success: true };
  } catch (error) {
    console.error('❌ Stripe webhook verification failed:', error);
    throw error;
  }
}

// Export for use in Next.js API routes, Express, etc.
module.exports = {
  handleClerkWebhook,
  handleStripeWebhook,
  handleClerkUserCreated,
  handleClerkUserUpdated,
  handleClerkUserDeleted,
  handleStripeSubscriptionCreated,
  handleStripeSubscriptionUpdated
};
