'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Bot, Zap, Globe, ChevronRight, Check, Terminal, Sparkles } from 'lucide-react';
import { useAuthStore } from '@/stores/auth-store';

const AGENTS = [
  { id: 'lucidia',   name: 'Lucidia',   icon: '🌀', desc: 'Philosopher. Deep reasoning, strategy, synthesis.', color: '#2979FF' },
  { id: 'alice',     name: 'Alice',     icon: '🚪', desc: 'Executor. Tasks, code, automation, deployments.', color: '#34d399' },
  { id: 'octavia',   name: 'Octavia',   icon: '⚡', desc: 'Architect. Infra, monitoring, system health.', color: '#F5A623' },
  { id: 'cecilia',   name: 'Cecilia',   icon: '💜', desc: 'Core. Identity, memory, meta-cognition.', color: '#9C27B0' },
  { id: 'shellfish', name: 'Shellfish', icon: '🔐', desc: 'Hacker. Security, exploits, pen testing.', color: '#ef4444' },
  { id: 'cipher',    name: 'Cipher',    icon: '🛡️', desc: 'Guardian. Auth, encryption, access control.', color: '#FF1D6C' },
];

const STEPS = ['Welcome', 'Your name', 'First agent', 'Gateway', 'Done'];

export default function OnboardingPage() {
  const router = useRouter();
  const setUser = useAuthStore((s) => s.setUser);
  const [step, setStep] = useState(0);
  const [name, setName] = useState('');
  const [agent, setAgent] = useState('lucidia');
  const [gateway, setGateway] = useState('http://127.0.0.1:8787');
  const [saving, setSaving] = useState(false);

  function next() { setStep(s => Math.min(s + 1, STEPS.length - 1)); }
  function back() { setStep(s => Math.max(s - 1, 0)); }

  async function finish() {
    setSaving(true);
    const displayName = name.trim() || 'Alexa';
    // Save to localStorage
    if (typeof window !== 'undefined') {
      const existing = JSON.parse(localStorage.getItem('br-settings') || '{}');
      localStorage.setItem('br-settings', JSON.stringify({
        ...existing,
        displayName,
        gatewayUrl: gateway,
        defaultAgent: agent,
        onboarded: true,
      }));
    }
    setUser({ id: 'local', name: displayName, email: `${displayName.toLowerCase()}@blackroad.io`, role: 'admin' });
    setSaving(false);
    router.push(`/conversations/new?agent=${agent}`);
  }

  const selected = AGENTS.find(a => a.id === agent)!;

  return (
    <div className="min-h-screen bg-black flex items-center justify-center p-6">
      <div className="w-full max-w-lg">

        {/* Progress */}
        <div className="flex items-center gap-2 mb-10 justify-center">
          {STEPS.map((s, i) => (
            <div key={s} className="flex items-center gap-2">
              <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all ${
                i < step ? 'bg-[#FF1D6C] text-white' :
                i === step ? 'bg-white text-black' :
                'bg-white/10 text-gray-500'
              }`}>
                {i < step ? <Check className="w-3.5 h-3.5" /> : i + 1}
              </div>
              {i < STEPS.length - 1 && (
                <div className={`h-px w-6 transition-all ${i < step ? 'bg-[#FF1D6C]' : 'bg-white/10'}`} />
              )}
            </div>
          ))}
        </div>

        {/* Step 0: Welcome */}
        {step === 0 && (
          <div className="text-center space-y-6">
            <div className="text-5xl mb-2">🚀</div>
            <h1 className="text-4xl font-bold text-white">Welcome to<br />
              <span className="bg-gradient-to-r from-amber-500 via-[#FF1D6C] to-violet-500 bg-clip-text text-transparent">
                BlackRoad OS
              </span>
            </h1>
            <p className="text-gray-400 text-lg leading-relaxed">
              Your AI. Your Hardware. Your Rules.
            </p>
            <div className="grid grid-cols-3 gap-3 pt-2">
              {[['30,000', 'Agent slots', Bot], ['499', 'CF Workers', Zap], ['20', 'Domains', Globe]].map(([v, l, I]) => (
                <div key={String(l)} className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
                  <div className="text-xl font-bold text-white">{String(v)}</div>
                  <div className="text-xs text-gray-500 mt-0.5">{String(l)}</div>
                </div>
              ))}
            </div>
            <button onClick={next}
              className="w-full py-3 bg-gradient-to-r from-[#FF1D6C] to-violet-600 rounded-xl text-white font-semibold flex items-center justify-center gap-2 hover:opacity-90 transition-all">
              Get started <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Step 1: Name */}
        {step === 1 && (
          <div className="space-y-6">
            <div>
              <h2 className="text-2xl font-bold text-white mb-1">What should I call you?</h2>
              <p className="text-gray-500 text-sm">This shows in the workspace greeting.</p>
            </div>
            <input
              type="text"
              placeholder="Your first name"
              value={name}
              onChange={e => setName(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && next()}
              autoFocus
              className="w-full bg-white/5 border border-white/20 rounded-xl px-4 py-3 text-white placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/60 text-lg"
            />
            <div className="flex gap-3">
              <button onClick={back} className="px-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-gray-400 hover:text-white transition-all">Back</button>
              <button onClick={next} className="flex-1 py-2.5 bg-gradient-to-r from-[#FF1D6C] to-violet-600 rounded-xl text-white font-semibold hover:opacity-90 transition-all flex items-center justify-center gap-2">
                Continue <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 2: Agent */}
        {step === 2 && (
          <div className="space-y-5">
            <div>
              <h2 className="text-2xl font-bold text-white mb-1">Pick your first agent</h2>
              <p className="text-gray-500 text-sm">You can talk to all of them. Who do you want to start with?</p>
            </div>
            <div className="grid grid-cols-2 gap-2">
              {AGENTS.map(a => (
                <button key={a.id} onClick={() => setAgent(a.id)}
                  className={`p-3 rounded-xl border text-left transition-all ${
                    agent === a.id ? 'border-[#FF1D6C]/60 bg-[#FF1D6C]/10' : 'border-white/10 bg-white/5 hover:border-white/20'
                  }`}>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-lg">{a.icon}</span>
                    <span className="text-sm font-semibold text-white">{a.name}</span>
                    {agent === a.id && <Check className="w-3.5 h-3.5 text-[#FF1D6C] ml-auto" />}
                  </div>
                  <p className="text-xs text-gray-500 leading-relaxed">{a.desc}</p>
                </button>
              ))}
            </div>
            <div className="flex gap-3">
              <button onClick={back} className="px-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-gray-400 hover:text-white transition-all">Back</button>
              <button onClick={next} className="flex-1 py-2.5 bg-gradient-to-r from-[#FF1D6C] to-violet-600 rounded-xl text-white font-semibold hover:opacity-90 transition-all flex items-center justify-center gap-2">
                Continue <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Gateway */}
        {step === 3 && (
          <div className="space-y-5">
            <div>
              <h2 className="text-2xl font-bold text-white mb-1">Gateway URL</h2>
              <p className="text-gray-500 text-sm">Where your local BlackRoad Gateway is running. Default is fine for most setups.</p>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-xl p-4 font-mono text-sm">
              <div className="text-gray-500 text-xs mb-1"># Start your gateway</div>
              <div className="text-[#FF1D6C]">cd blackroad-core && ./start.sh</div>
            </div>
            <input
              type="text"
              value={gateway}
              onChange={e => setGateway(e.target.value)}
              className="w-full bg-white/5 border border-white/20 rounded-xl px-4 py-3 text-white font-mono focus:outline-none focus:border-[#FF1D6C]/60"
            />
            <div className="flex gap-3">
              <button onClick={back} className="px-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-gray-400 hover:text-white transition-all">Back</button>
              <button onClick={next} className="flex-1 py-2.5 bg-gradient-to-r from-[#FF1D6C] to-violet-600 rounded-xl text-white font-semibold hover:opacity-90 transition-all flex items-center justify-center gap-2">
                Continue <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 4: Done */}
        {step === 4 && (
          <div className="text-center space-y-6">
            <div className="text-5xl">✨</div>
            <h2 className="text-3xl font-bold text-white">
              Ready, {name.trim() || 'Alexa'}!
            </h2>
            <p className="text-gray-400">
              Starting your first conversation with{' '}
              <span style={{ color: selected.color }} className="font-semibold">{selected.name}</span> {selected.icon}
            </p>
            <div className="bg-white/5 border border-white/10 rounded-xl p-4 font-mono text-xs text-left space-y-1">
              <div className="text-gray-500"># Your setup</div>
              <div><span className="text-[#FF1D6C]">gateway</span> <span className="text-gray-300">=</span> <span className="text-green-400">{gateway}</span></div>
              <div><span className="text-[#FF1D6C]">agent</span>   <span className="text-gray-300">=</span> <span className="text-green-400">{agent}</span></div>
              <div><span className="text-[#FF1D6C]">name</span>    <span className="text-gray-300">=</span> <span className="text-green-400">{name.trim() || 'Alexa'}</span></div>
            </div>
            <button onClick={finish} disabled={saving}
              className="w-full py-3 bg-gradient-to-r from-amber-500 via-[#FF1D6C] to-violet-600 rounded-xl text-white font-bold text-lg flex items-center justify-center gap-2 hover:opacity-90 transition-all disabled:opacity-60">
              <Sparkles className="w-5 h-5" />
              {saving ? 'Launching...' : 'Launch BlackRoad OS'}
            </button>
          </div>
        )}

      </div>
    </div>
  );
}
