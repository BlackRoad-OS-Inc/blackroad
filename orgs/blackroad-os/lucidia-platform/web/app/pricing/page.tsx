'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Check, ArrowRight, Sparkles } from 'lucide-react'
import { redirectToCheckout } from '@/lib/stripe'

const plans = [
  {
    id: 'free',
    name: 'Free',
    price: 0,
    interval: null,
    description: 'Perfect for trying it out',
    features: [
      '10 problems/month',
      'Basic explanations',
      'Text input only',
    ],
    cta: 'Get Started',
    href: '/signup',
  },
  {
    id: 'student_monthly',
    name: 'Student',
    price: 9.99,
    interval: 'month',
    description: 'Everything you need to succeed',
    features: [
      'Unlimited problems',
      'Visual explanations',
      'Photo & voice upload',
      'Persistent memory',
      'All subjects',
      '7-day free trial',
    ],
    popular: true,
    cta: 'Start Free Trial',
  },
  {
    id: 'student_yearly',
    name: 'Student Annual',
    price: 99.99,
    interval: 'year',
    description: 'Best value for committed learners',
    features: [
      'Everything in Student Monthly',
      '2 months free',
      'Priority support',
    ],
    savings: 'Save $20/year',
    cta: 'Start Free Trial',
  },
  {
    id: 'family_monthly',
    name: 'Family',
    price: 19.99,
    interval: 'month',
    description: 'For the whole household',
    features: [
      'Up to 5 users',
      'Everything in Student',
      'Parent dashboard',
      'Progress tracking',
      'Priority support',
      '7-day free trial',
    ],
    cta: 'Start Free Trial',
  },
  {
    id: 'family_yearly',
    name: 'Family Annual',
    price: 199.99,
    interval: 'year',
    description: 'Best value for families',
    features: [
      'Everything in Family Monthly',
      '2 months free',
      'Dedicated support',
    ],
    savings: 'Save $40/year',
    cta: 'Start Free Trial',
  },
]

export default function PricingPage() {
  const [loading, setLoading] = useState<string | null>(null)
  const [billingInterval, setBillingInterval] = useState<'month' | 'year'>('month')

  const handleCheckout = async (planId: string) => {
    if (planId === 'free') {
      window.location.href = '/signup'
      return
    }

    setLoading(planId)
    try {
      // In production, get real user ID from auth
      const userId = `user_${Date.now()}`
      await redirectToCheckout(planId, userId)
    } catch (error) {
      console.error('Checkout error:', error)
      alert('Something went wrong. Please try again.')
    } finally {
      setLoading(null)
    }
  }

  const filteredPlans = plans.filter(plan => {
    if (plan.id === 'free') return true
    if (billingInterval === 'month') {
      return plan.id.includes('monthly')
    }
    return plan.id.includes('yearly')
  })

  return (
    <div className="min-h-screen animated-gradient">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 px-6 py-4 bg-black/50 backdrop-blur-xl border-b border-white/5">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <a href="/" className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-gradient-brand" />
            <span className="text-xl font-bold">Lucidia</span>
          </a>
          <a href="/login" className="text-sm text-white/70 hover:text-white transition">
            Log in
          </a>
        </div>
      </nav>

      <main className="pt-32 pb-20 px-6">
        <div className="max-w-7xl mx-auto">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-12"
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 text-sm mb-6">
              <Sparkles className="w-4 h-4 text-brand-orange" />
              <span>7-day free trial on all paid plans</span>
            </div>

            <h1 className="text-4xl md:text-5xl font-bold mb-4">
              Simple, transparent pricing
            </h1>
            <p className="text-xl text-white/60 max-w-2xl mx-auto">
              Start free. Upgrade when you're ready. Cancel anytime.
            </p>
          </motion.div>

          {/* Billing Toggle */}
          <div className="flex items-center justify-center gap-4 mb-12">
            <button
              onClick={() => setBillingInterval('month')}
              className={`px-4 py-2 rounded-lg transition ${
                billingInterval === 'month'
                  ? 'bg-white/10 text-white'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setBillingInterval('year')}
              className={`px-4 py-2 rounded-lg transition flex items-center gap-2 ${
                billingInterval === 'year'
                  ? 'bg-white/10 text-white'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Annual
              <span className="text-xs px-2 py-0.5 rounded-full bg-brand-orange/20 text-brand-orange">
                Save 17%
              </span>
            </button>
          </div>

          {/* Pricing Cards */}
          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {filteredPlans.map((plan, i) => (
              <motion.div
                key={plan.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                className={`card relative ${
                  plan.popular ? 'border-brand-orange/50 glow-orange' : ''
                }`}
              >
                {plan.popular && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-gradient-brand text-sm font-semibold">
                    Most Popular
                  </div>
                )}

                {plan.savings && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-green-500/20 text-green-400 text-sm font-semibold">
                    {plan.savings}
                  </div>
                )}

                <h3 className="text-xl font-semibold mb-2">{plan.name}</h3>

                <div className="flex items-baseline gap-1 mb-2">
                  <span className="text-4xl font-bold">
                    ${plan.price === 0 ? '0' : plan.price}
                  </span>
                  {plan.interval && (
                    <span className="text-white/60">/{plan.interval}</span>
                  )}
                </div>

                <p className="text-white/60 mb-6">{plan.description}</p>

                <ul className="space-y-3 mb-8">
                  {plan.features.map((feature, j) => (
                    <li key={j} className="flex items-center gap-2 text-sm">
                      <Check className="w-4 h-4 text-brand-orange flex-shrink-0" />
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>

                <button
                  onClick={() => handleCheckout(plan.id)}
                  disabled={loading === plan.id}
                  className={`w-full justify-center ${
                    plan.popular ? 'btn-primary' : 'btn-secondary'
                  }`}
                >
                  {loading === plan.id ? (
                    <span className="flex items-center gap-2">
                      <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                        <circle
                          className="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          strokeWidth="4"
                          fill="none"
                        />
                        <path
                          className="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        />
                      </svg>
                      Processing...
                    </span>
                  ) : (
                    <>
                      {plan.cta}
                      <ArrowRight className="w-4 h-4 ml-2" />
                    </>
                  )}
                </button>
              </motion.div>
            ))}
          </div>

          {/* Enterprise CTA */}
          <div className="mt-16 text-center">
            <p className="text-white/60 mb-4">
              Need a custom plan for your school or district?
            </p>
            <a
              href="/contact"
              className="inline-flex items-center gap-2 text-brand-orange hover:underline"
            >
              Contact us for volume pricing ($3-8/student/year)
              <ArrowRight className="w-4 h-4" />
            </a>
          </div>

          {/* FAQ */}
          <div className="mt-20 max-w-3xl mx-auto">
            <h2 className="text-2xl font-bold text-center mb-8">
              Frequently Asked Questions
            </h2>

            <div className="space-y-4">
              {[
                {
                  q: 'What happens after my free trial?',
                  a: "You'll be automatically charged unless you cancel before the trial ends. You can cancel anytime from your dashboard.",
                },
                {
                  q: 'Can I switch plans?',
                  a: 'Yes! You can upgrade or downgrade at any time. Changes take effect immediately.',
                },
                {
                  q: 'Is there a student discount?',
                  a: 'Our Student plan is already designed to be affordable. For bulk school purchases, contact us for even better rates.',
                },
                {
                  q: 'What payment methods do you accept?',
                  a: 'We accept all major credit cards, debit cards, and Apple Pay / Google Pay through Stripe.',
                },
              ].map((faq, i) => (
                <div key={i} className="card">
                  <h3 className="font-semibold mb-2">{faq.q}</h3>
                  <p className="text-white/60 text-sm">{faq.a}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="py-12 px-6 border-t border-white/5">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-gradient-brand" />
            <span className="font-semibold">Lucidia</span>
            <span className="text-white/40">by BlackRoad OS</span>
          </div>
          <div className="text-sm text-white/40">
            © 2024 BlackRoad OS, Inc.
          </div>
        </div>
      </footer>
    </div>
  )
}
