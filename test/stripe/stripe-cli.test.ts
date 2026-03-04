// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
// Tests for the br stripe CLI command module
import { describe, it, expect } from 'vitest'

// Test that the stripe command module exports correctly and has expected subcommands
describe('stripe CLI command', () => {
  it('exports stripeCommand', async () => {
    const mod = await import('../../src/cli/commands/stripe.js')
    expect(mod.stripeCommand).toBeDefined()
    expect(mod.stripeCommand.name()).toBe('stripe')
  })

  it('has expected subcommands', async () => {
    const mod = await import('../../src/cli/commands/stripe.js')
    const names = mod.stripeCommand.commands.map((c: { name: () => string }) => c.name())

    expect(names).toContain('health')
    expect(names).toContain('checkout')
    expect(names).toContain('revenue')
    expect(names).toContain('subscriptions')
    expect(names).toContain('portal')
  })

  it('checkout requires --tier option', async () => {
    const mod = await import('../../src/cli/commands/stripe.js')
    const checkout = mod.stripeCommand.commands.find(
      (c: { name: () => string }) => c.name() === 'checkout',
    )
    expect(checkout).toBeDefined()

    const tierOpt = checkout.options.find((o: { long: string }) => o.long === '--tier')
    expect(tierOpt).toBeDefined()
    expect(tierOpt.required).toBe(true)
  })

  it('subscriptions requires --customer option', async () => {
    const mod = await import('../../src/cli/commands/stripe.js')
    const subs = mod.stripeCommand.commands.find(
      (c: { name: () => string }) => c.name() === 'subscriptions',
    )
    expect(subs).toBeDefined()

    const custOpt = subs.options.find((o: { long: string }) => o.long === '--customer')
    expect(custOpt).toBeDefined()
    expect(custOpt.required).toBe(true)
  })

  it('is registered in the main program', async () => {
    const mod = await import('../../src/cli/commands/index.js')
    const names = mod.program.commands.map((c: { name: () => string }) => c.name())
    expect(names).toContain('stripe')
  })
})
