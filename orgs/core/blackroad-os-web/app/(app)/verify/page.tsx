'use client';

import { useState } from 'react';
import { ShieldCheck, AlertTriangle, XCircle, HelpCircle, Loader2 } from 'lucide-react';
import { cn } from '@/lib/cn';

type Verdict = 'true' | 'false' | 'unverified' | 'conflicting';

interface VerifyResult {
  status: string;
  verdict: Verdict;
  confidence: number;
  reasoning: string;
  agent_used: string;
  sources_checked: number;
  flags: string[];
  timestamp: string;
}

const VERDICT_CONFIG: Record<Verdict, { label: string; icon: typeof ShieldCheck; color: string; bg: string; border: string }> = {
  true:        { label: 'Verified True',   icon: ShieldCheck,    color: 'text-green-400',  bg: 'bg-green-950/50',  border: 'border-green-800' },
  false:       { label: 'Likely False',    icon: XCircle,        color: 'text-red-400',    bg: 'bg-red-950/50',    border: 'border-red-800' },
  unverified:  { label: 'Unverified',      icon: HelpCircle,     color: 'text-yellow-400', bg: 'bg-yellow-950/50', border: 'border-yellow-800' },
  conflicting: { label: 'Conflicting',     icon: AlertTriangle,  color: 'text-orange-400', bg: 'bg-orange-950/50', border: 'border-orange-800' },
};

const GATEWAY_URL = process.env.NEXT_PUBLIC_GATEWAY_URL || 'http://127.0.0.1:8787';

export default function VerifyPage() {
  const [claim, setClaim] = useState('');
  const [threshold, setThreshold] = useState(0.7);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<VerifyResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleVerify() {
    if (!claim.trim()) return;
    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const res = await fetch(`${GATEWAY_URL}/v1/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ claim: claim.trim(), confidence_threshold: threshold }),
      });
      const data: VerifyResult = await res.json();
      if (!res.ok || data.status === 'error') throw new Error((data as any).error || 'Verification failed');
      setResult(data);
    } catch (e: any) {
      setError(e.message || 'Verification failed');
    } finally {
      setLoading(false);
    }
  }

  const cfg = result ? VERDICT_CONFIG[result.verdict] ?? VERDICT_CONFIG.unverified : null;

  return (
    <div className="flex flex-col items-center min-h-full px-4 py-12">
      {/* Header */}
      <div className="w-full max-w-2xl mb-10 text-center">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gradient-to-br from-amber-500 via-[#FF1D6C] to-violet-600 mb-4">
          <ShieldCheck className="h-7 w-7 text-white" />
        </div>
        <h1 className="text-3xl font-bold text-white mb-2">
          Information <span className="bg-gradient-to-r from-[#FF1D6C] to-[#2979FF] bg-clip-text text-transparent">Verify</span>
        </h1>
        <p className="text-gray-500 text-sm">AI-powered claim verification via PRISM &amp; CIPHER agents</p>
      </div>

      {/* Input card */}
      <div className="w-full max-w-2xl bg-black/60 border border-white/10 rounded-2xl p-6 mb-4">
        <label className="block text-xs text-gray-500 mb-2 uppercase tracking-wider">Claim to verify</label>
        <textarea
          className="w-full min-h-[100px] bg-black border border-white/10 rounded-xl text-white text-sm p-3 resize-y focus:outline-none focus:border-[#FF1D6C] transition-colors placeholder-gray-600"
          placeholder="Enter a statement, fact, or claim to verify…"
          value={claim}
          onChange={e => setClaim(e.target.value)}
          onKeyDown={e => { if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) handleVerify(); }}
        />

        <div className="flex items-end gap-4 mt-4">
          <div>
            <label className="block text-xs text-gray-500 mb-1">Confidence threshold</label>
            <input
              type="number"
              min={0} max={1} step={0.05}
              value={threshold}
              onChange={e => setThreshold(parseFloat(e.target.value))}
              className="w-28 bg-black border border-white/10 rounded-lg text-white text-sm px-3 py-2 focus:outline-none focus:border-[#FF1D6C]"
            />
          </div>
          <button
            onClick={handleVerify}
            disabled={loading || !claim.trim()}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 px-6 bg-gradient-to-r from-[#FF1D6C] to-violet-600 hover:opacity-90 disabled:opacity-40 rounded-xl text-sm font-semibold text-white transition-opacity"
          >
            {loading ? <><Loader2 className="h-4 w-4 animate-spin" /> Analyzing…</> : 'Analyze Claim'}
          </button>
        </div>

        {error && (
          <p className="mt-3 text-red-400 text-sm">{error}</p>
        )}
      </div>

      {/* Result card */}
      {result && cfg && (
        <div className={cn('w-full max-w-2xl border rounded-2xl p-6', cfg.bg, cfg.border)}>
          {/* Verdict badge */}
          <div className="flex items-center gap-2 mb-4">
            <cfg.icon className={cn('h-5 w-5', cfg.color)} />
            <span className={cn('text-sm font-bold uppercase tracking-wider', cfg.color)}>
              {cfg.label}
            </span>
          </div>

          {/* Confidence meter */}
          <div className="mb-4">
            <div className="flex justify-between text-xs text-gray-500 mb-1">
              <span>Confidence</span>
              <span>{Math.round(result.confidence * 100)}%</span>
            </div>
            <div className="h-2 bg-black/40 rounded-full overflow-hidden">
              <div
                className="h-full rounded-full bg-gradient-to-r from-amber-500 via-[#FF1D6C] to-violet-600 transition-all duration-500"
                style={{ width: `${Math.round(result.confidence * 100)}%` }}
              />
            </div>
          </div>

          {/* Reasoning */}
          <p className="text-gray-300 text-sm leading-relaxed mb-4">{result.reasoning}</p>

          {/* Flags */}
          {result.flags.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-4">
              {result.flags.map((f, i) => (
                <span key={i} className="px-2 py-0.5 text-xs bg-black/30 border border-white/10 rounded-md text-gray-400">
                  {f}
                </span>
              ))}
            </div>
          )}

          {/* Meta */}
          <p className="text-xs text-gray-600">
            Agent: {result.agent_used} · Sources checked: {result.sources_checked} ·{' '}
            {result.timestamp ? new Date(result.timestamp).toLocaleTimeString() : ''}
          </p>
        </div>
      )}
    </div>
  );
}
