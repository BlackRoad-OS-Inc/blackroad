'use client';

import { useState } from 'react';
import { Settings, Cpu, Key, Globe, Bell, Moon, Zap, Save, CheckCircle, RefreshCw } from 'lucide-react';

const DEFAULT_SETTINGS = {
  gatewayUrl: 'http://127.0.0.1:8787',
  workerUrl: 'https://blackroad-os-api.amundsonalexa.workers.dev',
  defaultModel: 'cece3b',
  theme: 'dark',
  notifications: true,
  streamResponses: true,
  maxTokens: '4096',
  temperature: '0.7',
  workspaceName: 'BlackRoad OS',
  displayName: 'Alexa',
  email: 'alexa@blackroad.io',
};

export default function SettingsPage() {
  const [saved, setSaved] = useState(false);
  const [form, setForm] = useState(() => {
    if (typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem('br-settings');
        if (stored) return { ...DEFAULT_SETTINGS, ...JSON.parse(stored) };
      } catch { /* ignore */ }
    }
    return DEFAULT_SETTINGS;
  });
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  });

  const update = (key: string, value: string | boolean) =>
    setForm(f => ({ ...f, [key]: value }));

  const handleSave = () => {
    try { localStorage.setItem('br-settings', JSON.stringify(form)); } catch { /* ignore */ }
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const MODELS = ['cece3b', 'cece2', 'cece', 'qwen3:8b', 'qwen2.5:3b', 'llama3.2:3b', 'deepseek-r1:7b'];

  return (
    <div className="p-6 max-w-3xl space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white flex items-center gap-3">
          <Settings className="h-7 w-7 text-[#FF1D6C]" />
          Settings
        </h1>
        <p className="text-gray-400 mt-1 text-sm">Workspace configuration, gateway, and AI preferences.</p>
      </div>

      {/* Profile */}
      <section className="space-y-4">
        <h2 className="text-white font-semibold flex items-center gap-2 text-sm uppercase tracking-wider">
          <span className="w-6 h-px bg-white/20" />
          Profile
        </h2>
        <div className="bg-white/5 border border-white/10 rounded-xl p-5 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">Display Name</label>
              <input
                value={form.displayName}
                onChange={e => update('displayName', e.target.value)}
                className="w-full bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/50"
              />
            </div>
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">Email</label>
              <input
                value={form.email}
                onChange={e => update('email', e.target.value)}
                className="w-full bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/50"
              />
            </div>
          </div>
          <div>
            <label className="block text-xs text-gray-400 mb-1.5">Workspace Name</label>
            <input
              value={form.workspaceName}
              onChange={e => update('workspaceName', e.target.value)}
              className="w-full bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/50"
            />
          </div>
        </div>
      </section>

      {/* Gateway / API */}
      <section className="space-y-4">
        <h2 className="text-white font-semibold flex items-center gap-2 text-sm uppercase tracking-wider">
          <span className="w-6 h-px bg-white/20" />
          Gateway & API
        </h2>
        <div className="bg-white/5 border border-white/10 rounded-xl p-5 space-y-4">
          <div>
            <label className="block text-xs text-gray-400 mb-1.5">Gateway URL (local)</label>
            <div className="flex gap-2">
              <input
                value={form.gatewayUrl}
                onChange={e => update('gatewayUrl', e.target.value)}
                className="flex-1 bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white font-mono placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/50"
              />
              <button className="flex items-center gap-1.5 px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-xs text-gray-400 hover:text-white hover:bg-white/10 transition-colors">
                <RefreshCw className="h-3.5 w-3.5" />
                Ping
              </button>
            </div>
            <p className="text-xs text-gray-500 mt-1">Local tokenless gateway. Run <code className="text-gray-300 font-mono">blackroad-core/gateway/start.sh</code> to start.</p>
          </div>
          <div>
            <label className="block text-xs text-gray-400 mb-1.5">Worker URL (fallback)</label>
            <input
              value={form.workerUrl}
              onChange={e => update('workerUrl', e.target.value)}
              className="w-full bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white font-mono placeholder-gray-600 focus:outline-none focus:border-[#FF1D6C]/50"
            />
            <p className="text-xs text-gray-500 mt-1">Cloudflare Worker used when gateway is unreachable.</p>
          </div>
        </div>
      </section>

      {/* AI Model */}
      <section className="space-y-4">
        <h2 className="text-white font-semibold flex items-center gap-2 text-sm uppercase tracking-wider">
          <span className="w-6 h-px bg-white/20" />
          AI Model
        </h2>
        <div className="bg-white/5 border border-white/10 rounded-xl p-5 space-y-4">
          <div>
            <label className="block text-xs text-gray-400 mb-1.5">Default Model</label>
            <select
              value={form.defaultModel}
              onChange={e => update('defaultModel', e.target.value)}
              className="w-full bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-[#FF1D6C]/50 appearance-none"
            >
              {MODELS.map(m => (
                <option key={m} value={m}>{m}</option>
              ))}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">Max Tokens</label>
              <input
                value={form.maxTokens}
                onChange={e => update('maxTokens', e.target.value)}
                type="number"
                className="w-full bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white font-mono focus:outline-none focus:border-[#FF1D6C]/50"
              />
            </div>
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">Temperature</label>
              <input
                value={form.temperature}
                onChange={e => update('temperature', e.target.value)}
                type="number" min="0" max="2" step="0.1"
                className="w-full bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm text-white font-mono focus:outline-none focus:border-[#FF1D6C]/50"
              />
            </div>
          </div>
          <label className="flex items-center gap-3 cursor-pointer">
            <button
              onClick={() => update('streamResponses', !form.streamResponses)}
              className={`w-10 h-5 rounded-full transition-all relative ${form.streamResponses ? 'bg-[#FF1D6C]' : 'bg-white/10'}`}
            >
              <span className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-all ${form.streamResponses ? 'left-5' : 'left-0.5'}`} />
            </button>
            <span className="text-sm text-gray-300">Stream responses</span>
          </label>
        </div>
      </section>

      {/* Notifications */}
      <section className="space-y-4">
        <h2 className="text-white font-semibold flex items-center gap-2 text-sm uppercase tracking-wider">
          <span className="w-6 h-px bg-white/20" />
          Notifications
        </h2>
        <div className="bg-white/5 border border-white/10 rounded-xl p-5 space-y-3">
          {[
            { key: 'notifications', label: 'Enable notifications', desc: 'System alerts, agent completions, policy violations' },
          ].map(item => (
            <label key={item.key} className="flex items-start gap-3 cursor-pointer">
              <button
                onClick={() => update(item.key, !(form as any)[item.key])}
                className={`mt-0.5 w-10 h-5 rounded-full transition-all relative shrink-0 ${(form as any)[item.key] ? 'bg-[#FF1D6C]' : 'bg-white/10'}`}
              >
                <span className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-all ${(form as any)[item.key] ? 'left-5' : 'left-0.5'}`} />
              </button>
              <div>
                <div className="text-sm text-gray-300">{item.label}</div>
                <div className="text-xs text-gray-500">{item.desc}</div>
              </div>
            </label>
          ))}
        </div>
      </section>

      {/* Save */}
      <div className="flex items-center gap-3 pt-2">
        <button
          onClick={handleSave}
          className="flex items-center gap-2 px-6 py-2.5 bg-gradient-to-r from-[#FF1D6C] to-violet-600 text-white text-sm font-medium rounded-xl hover:opacity-90 transition-opacity"
        >
          {saved ? <CheckCircle className="h-4 w-4" /> : <Save className="h-4 w-4" />}
          {saved ? 'Saved!' : 'Save Settings'}
        </button>
        <span className="text-xs text-gray-500">Settings are saved to localStorage for now. Real backend coming soon.</span>
      </div>
    </div>
  );
}
