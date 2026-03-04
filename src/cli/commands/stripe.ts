// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { logger } from '../../core/logger.js'

const PAY_GATEWAY = process.env['BLACKROAD_PAY_URL'] ?? 'https://pay.blackroad.io'

interface HealthResponse {
  status: string
  service: string
  version: string
  pricing: {
    pro_monthly: number
    pro_yearly: number
    enterprise_monthly: number
    enterprise_yearly: number
  }
}

interface CheckoutResponse {
  url?: string
  session_id?: string
  error?: string
}

interface RevenueResponse {
  balance: { available: number; pending: number; currency: string }
  active_subscriptions: number
  error?: string
}

interface SubscriptionItem {
  id: string
  status: string
  tier: string
  current_period_end: number
  cancel_at_period_end: boolean
  items: { price_id: string; amount: number; interval: string }[]
}

interface SubscriptionsResponse {
  subscriptions: SubscriptionItem[]
  error?: string
}

async function payAPI<T>(method: string, path: string, body?: unknown): Promise<T> {
  const url = `${PAY_GATEWAY}${path}`
  const opts: RequestInit = {
    method,
    headers: { 'Content-Type': 'application/json' },
  }
  if (body) opts.body = JSON.stringify(body)
  const res = await fetch(url, opts)
  return res.json() as Promise<T>
}

function fmtCents(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`
}

export const stripeCommand = new Command('stripe')
  .description('Stripe billing — checkout, subscriptions, revenue')

stripeCommand
  .command('health')
  .description('Check payment gateway health')
  .action(async () => {
    try {
      const h = await payAPI<HealthResponse>('GET', '/health')
      logger.success(`${h.service} is ${h.status} (v${h.version})`)
      logger.info(`Pro: ${fmtCents(h.pricing.pro_monthly)}/mo | ${fmtCents(h.pricing.pro_yearly)}/yr`)
      logger.info(`Enterprise: ${fmtCents(h.pricing.enterprise_monthly)}/mo | ${fmtCents(h.pricing.enterprise_yearly)}/yr`)
    } catch {
      logger.error(`Payment gateway unreachable at ${PAY_GATEWAY}`)
    }
  })

stripeCommand
  .command('checkout')
  .description('Create a checkout session')
  .requiredOption('-t, --tier <tier>', 'Pricing tier (pro | enterprise)')
  .option('-i, --interval <interval>', 'Billing interval (month | year)', 'month')
  .option('-e, --email <email>', 'Customer email')
  .action(async (opts: { tier: string; interval: string; email?: string }) => {
    try {
      const res = await payAPI<CheckoutResponse>('POST', '/checkout', {
        tier: opts.tier,
        interval: opts.interval,
        customer_email: opts.email,
      })
      if (res.error) {
        logger.error(res.error)
        return
      }
      logger.success(`Checkout session created: ${res.session_id}`)
      console.log(`\n  ${res.url}\n`)
    } catch {
      logger.error('Failed to create checkout session')
    }
  })

stripeCommand
  .command('revenue')
  .description('Show revenue dashboard')
  .action(async () => {
    try {
      const rev = await payAPI<RevenueResponse>('GET', '/revenue')
      if (rev.error) {
        logger.error(rev.error)
        return
      }
      console.log()
      logger.success(`Available: ${fmtCents(rev.balance.available)}`)
      logger.info(`Pending:   ${fmtCents(rev.balance.pending)}`)
      logger.info(`Active subscriptions: ${rev.active_subscriptions}`)
      console.log()
    } catch {
      logger.error('Failed to fetch revenue data')
    }
  })

stripeCommand
  .command('subscriptions')
  .description('List customer subscriptions')
  .requiredOption('-c, --customer <id>', 'Stripe customer ID (cus_...)')
  .action(async (opts: { customer: string }) => {
    try {
      const res = await payAPI<SubscriptionsResponse>('GET', `/subscriptions?customer_id=${opts.customer}`)
      if (res.error) {
        logger.error(res.error)
        return
      }
      if (res.subscriptions.length === 0) {
        logger.warn('No subscriptions found')
        return
      }
      console.log()
      for (const sub of res.subscriptions) {
        const status = sub.status === 'active' ? '●' : '○'
        logger.info(`${status} ${sub.id} [${sub.status}] tier=${sub.tier || 'unknown'}`)
        for (const item of sub.items) {
          console.log(`    ${fmtCents(item.amount)}/${item.interval} (${item.price_id})`)
        }
        if (sub.cancel_at_period_end) {
          logger.warn('  Cancels at period end')
        }
      }
      console.log()
    } catch {
      logger.error('Failed to fetch subscriptions')
    }
  })

stripeCommand
  .command('portal')
  .description('Open billing portal for a customer')
  .requiredOption('-c, --customer <id>', 'Stripe customer ID (cus_...)')
  .action(async (opts: { customer: string }) => {
    try {
      const res = await payAPI<{ url?: string; error?: string }>('POST', '/portal', {
        customer_id: opts.customer,
      })
      if (res.error) {
        logger.error(res.error)
        return
      }
      logger.success('Billing portal URL:')
      console.log(`\n  ${res.url}\n`)
    } catch {
      logger.error('Failed to create portal session')
    }
  })
