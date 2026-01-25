'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  Camera,
  Mic,
  FileText,
  Sparkles,
  Brain,
  Eye,
  Gamepad2,
  ArrowRight,
  Check,
  Star,
  Play,
  Upload
} from 'lucide-react'

export default function LandingPage() {
  const [email, setEmail] = useState('')

  return (
    <div className="min-h-screen animated-gradient">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 px-6 py-4 bg-black/50 backdrop-blur-xl border-b border-white/5">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-gradient-brand" />
            <span className="text-xl font-bold">Lucidia</span>
          </div>
          <div className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-sm text-white/70 hover:text-white transition">Features</a>
            <a href="#pricing" className="text-sm text-white/70 hover:text-white transition">Pricing</a>
            <a href="#demo" className="text-sm text-white/70 hover:text-white transition">Demo</a>
          </div>
          <div className="flex items-center gap-4">
            <a href="/login" className="text-sm text-white/70 hover:text-white transition">Log in</a>
            <a href="/signup" className="btn-primary text-sm">Get Started Free</a>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative pt-32 pb-20 px-6">
        <div className="max-w-7xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 text-sm mb-8">
              <Sparkles className="w-4 h-4 text-brand-orange" />
              <span>AI-powered learning that actually works</span>
            </div>

            {/* Headline */}
            <h1 className="text-5xl md:text-7xl font-bold leading-tight mb-6">
              Upload a problem.
              <br />
              <span className="gradient-text">Actually understand it.</span>
            </h1>

            {/* Subheadline */}
            <p className="text-xl text-white/60 max-w-2xl mx-auto mb-10">
              60% of parents can't help with homework. EdTech creates anxiety, not understanding.
              <br />
              <strong className="text-white">Lucidia builds real comprehension through visual explanations.</strong>
            </p>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
              <a href="/signup" className="btn-primary text-lg px-8 py-4">
                Try Free - No Credit Card
                <ArrowRight className="w-5 h-5 ml-2" />
              </a>
              <a href="#demo" className="btn-secondary text-lg px-8 py-4">
                <Play className="w-5 h-5 mr-2" />
                Watch Demo
              </a>
            </div>

            {/* Input Methods Demo */}
            <div className="relative max-w-4xl mx-auto">
              <div className="card glow-orange p-8">
                <div className="flex items-center justify-center gap-4 mb-6">
                  <span className="text-white/60">Upload via:</span>
                  <button className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/10 hover:bg-white/20 transition">
                    <Camera className="w-5 h-5 text-brand-orange" />
                    <span>Photo</span>
                  </button>
                  <button className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/10 hover:bg-white/20 transition">
                    <Mic className="w-5 h-5 text-brand-pink" />
                    <span>Voice</span>
                  </button>
                  <button className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/10 hover:bg-white/20 transition">
                    <FileText className="w-5 h-5 text-brand-violet" />
                    <span>Type</span>
                  </button>
                </div>

                <div className="flex items-center gap-4 p-4 rounded-xl bg-white/5 border border-dashed border-white/20">
                  <Upload className="w-8 h-8 text-white/40" />
                  <span className="text-white/40">Drop your homework problem here, or click to upload</span>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Decorative elements */}
        <div className="absolute top-1/4 left-10 w-72 h-72 bg-brand-orange/20 rounded-full blur-3xl opacity-30 float" />
        <div className="absolute bottom-1/4 right-10 w-96 h-96 bg-brand-violet/20 rounded-full blur-3xl opacity-30 float" style={{ animationDelay: '2s' }} />
      </section>

      {/* Problem / Solution Section */}
      <section className="py-20 px-6 border-t border-white/5">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-2 gap-16">
            {/* Problem */}
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
            >
              <h2 className="text-3xl font-bold mb-6 text-white/40">The Problem</h2>
              <div className="space-y-4">
                {[
                  '60% of parents cannot help with homework',
                  '40% of 4th graders below basic reading level',
                  'EdTech shows answers, doesn\'t build understanding',
                  'AI tutors forget every conversation',
                  '$124.5B spent on tutoring - most doesn\'t work',
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-3 text-white/60">
                    <span className="text-red-500 mt-1">✕</span>
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            </motion.div>

            {/* Solution */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
            >
              <h2 className="text-3xl font-bold mb-6 gradient-text">The Lucidia Difference</h2>
              <div className="space-y-4">
                {[
                  'Visual explanations that build real understanding',
                  'Remembers your learning journey across sessions',
                  'Adapts to YOUR learning style automatically',
                  'Contextual problems in game-like scenarios',
                  'One platform for all subjects, all levels',
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <Check className="w-5 h-5 text-brand-orange mt-0.5" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 px-6 border-t border-white/5">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">How Lucidia Works</h2>
            <p className="text-xl text-white/60">From confusion to clarity in seconds</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                icon: Upload,
                title: '1. Upload Anything',
                description: 'Photo of homework, voice question, or just type. However you communicate best.',
                color: 'text-brand-orange',
              },
              {
                icon: Eye,
                title: '2. See It Clearly',
                description: 'AI generates personalized visual explanations. 3D models, animations, step-by-step breakdowns.',
                color: 'text-brand-pink',
              },
              {
                icon: Brain,
                title: '3. Actually Learn',
                description: 'Practice with contextual problems. Build understanding, not just memorize procedures.',
                color: 'text-brand-violet',
              },
            ].map((feature, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="card card-hover"
              >
                <feature.icon className={`w-12 h-12 ${feature.color} mb-4`} />
                <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                <p className="text-white/60">{feature.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 px-6 border-t border-white/5">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">Simple, Transparent Pricing</h2>
            <p className="text-xl text-white/60">Start free. Upgrade when you're ready.</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {/* Free */}
            <div className="card">
              <h3 className="text-xl font-semibold mb-2">Free</h3>
              <div className="text-4xl font-bold mb-4">$0</div>
              <p className="text-white/60 mb-6">Perfect for trying it out</p>
              <ul className="space-y-3 mb-8">
                {['10 problems/month', 'Basic explanations', 'Text input only'].map((item, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm">
                    <Check className="w-4 h-4 text-brand-orange" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
              <a href="/signup" className="btn-secondary w-full justify-center">Get Started</a>
            </div>

            {/* Student - Featured */}
            <div className="card border-brand-orange/50 glow-orange relative">
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-gradient-brand text-sm font-semibold">
                Most Popular
              </div>
              <h3 className="text-xl font-semibold mb-2">Student</h3>
              <div className="text-4xl font-bold mb-4">
                $9.99<span className="text-lg font-normal text-white/60">/mo</span>
              </div>
              <p className="text-white/60 mb-6">Everything you need to succeed</p>
              <ul className="space-y-3 mb-8">
                {[
                  'Unlimited problems',
                  'Visual explanations',
                  'Photo & voice upload',
                  'Persistent memory',
                  'All subjects',
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm">
                    <Check className="w-4 h-4 text-brand-orange" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
              <a href="/signup?plan=student" className="btn-primary w-full justify-center">Start Free Trial</a>
            </div>

            {/* Family */}
            <div className="card">
              <h3 className="text-xl font-semibold mb-2">Family</h3>
              <div className="text-4xl font-bold mb-4">
                $19.99<span className="text-lg font-normal text-white/60">/mo</span>
              </div>
              <p className="text-white/60 mb-6">For the whole household</p>
              <ul className="space-y-3 mb-8">
                {[
                  'Up to 5 users',
                  'Everything in Student',
                  'Parent dashboard',
                  'Progress tracking',
                  'Priority support',
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm">
                    <Check className="w-4 h-4 text-brand-orange" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
              <a href="/signup?plan=family" className="btn-secondary w-full justify-center">Start Free Trial</a>
            </div>
          </div>

          <p className="text-center text-white/40 mt-8">
            Schools & Districts: <a href="/contact" className="text-brand-orange hover:underline">Contact us</a> for volume pricing ($3-8/student/year)
          </p>
        </div>
      </section>

      {/* Social Proof */}
      <section className="py-20 px-6 border-t border-white/5">
        <div className="max-w-7xl mx-auto text-center">
          <div className="flex items-center justify-center gap-1 mb-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <Star key={i} className="w-6 h-6 fill-brand-orange text-brand-orange" />
            ))}
          </div>
          <blockquote className="text-2xl italic mb-4 max-w-3xl mx-auto">
            "For the first time, my daughter actually understands math instead of just memorizing steps. The visual explanations are incredible."
          </blockquote>
          <cite className="text-white/60">— Parent of 7th grader</cite>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-20 px-6 border-t border-white/5">
        <div className="max-w-3xl mx-auto text-center">
          <h2 className="text-4xl font-bold mb-4">Ready to actually understand?</h2>
          <p className="text-xl text-white/60 mb-8">
            Join thousands of students who've moved from frustration to mastery.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full sm:w-80 px-4 py-3 rounded-lg bg-white/10 border border-white/20 focus:border-brand-orange focus:outline-none"
            />
            <button className="btn-primary whitespace-nowrap">
              Get Started Free
              <ArrowRight className="w-5 h-5 ml-2" />
            </button>
          </div>
          <p className="text-sm text-white/40 mt-4">No credit card required. Cancel anytime.</p>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-6 border-t border-white/5">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-gradient-brand" />
            <span className="font-semibold">Lucidia</span>
            <span className="text-white/40">by BlackRoad OS</span>
          </div>
          <div className="flex items-center gap-6 text-sm text-white/60">
            <a href="/privacy" className="hover:text-white transition">Privacy</a>
            <a href="/terms" className="hover:text-white transition">Terms</a>
            <a href="/contact" className="hover:text-white transition">Contact</a>
          </div>
          <div className="text-sm text-white/40">
            © 2024 BlackRoad OS, Inc.
          </div>
        </div>
      </footer>
    </div>
  )
}
