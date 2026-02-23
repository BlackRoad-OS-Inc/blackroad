'use client';

import { useState } from 'react';
import { Shield, AlertTriangle, CheckCircle, XCircle, Eye, Lock, FileText, Activity, Zap, Clock } from 'lucide-react';

const POLICIES = [
  { id: 'content-filter', name: 'Content Filter', status: 'active', severity: 'high', description: 'Block harmful, offensive, or policy-violating content from all agent outputs.', triggers: 2341, blocked: 17 },
  { id: 'rate-limit', name: 'Rate Limiter', status: 'active', severity: 'medium', description: 'Limit requests per agent per minute to prevent abuse and runaway loops.', triggers: 98241, blocked: 203 },
  { id: 'data-privacy', name: 'Data Privacy Guard', status: 'active', severity: 'critical', description: 'Detect and redact PII — emails, phone numbers, SSNs, credit cards — before output.', triggers: 1204, blocked: 89 },
  { id: 'tool-allow', name: 'Tool Allowlist', status: 'active', severity: 'high', description: 'Only permit agents to invoke tools explicitly listed in their capability manifest.', triggers: 34102, blocked: 44 },
  { id: 'cost-cap', name: 'Cost Cap', status: 'active', severity: 'medium', description: 'Hard-stop agent inference when monthly spend exceeds $500. Alert at $400.', triggers: 12, blocked: 0 },
  { id: 'hallucination', name: 'Hallucination Guard', status: 'paused', severity: 'medium', description: 'Cross-check factual claims against verified sources. Pause for review if confidence < 0.6.', triggers: 0, blocked: 0 },
];

const AUDIT_LOG = [
  { id: 1, time: '2 min ago', agent: 'CIPHER', action: 'policy_trigger', policy: 'Content Filter', outcome: 'blocked', detail: 'Attempted to output internal system prompt.' },
  { id: 2, time: '7 min ago', agent: 'ALICE', action: 'policy_trigger', policy: 'Rate Limiter', outcome: 'blocked', detail: 'Exceeded 60 req/min threshold.' },
  { id: 3, time: '12 min ago', agent: 'LUCIDIA', action: 'inference', policy: '—', outcome: 'allowed', detail: 'Normal reasoning task completed.' },
  { id: 4, time: '18 min ago', agent: 'PRISM', action: 'policy_trigger', policy: 'Data Privacy Guard', outcome: 'redacted', detail: 'Removed 2 email addresses from output.' },
  { id: 5, time: '23 min ago', agent: 'OCTAVIA', action: 'inference', policy: '—', outcome: 'allowed', detail: 'Deployment completed successfully.' },
  { id: 6, time: '31 min ago', agent: 'ECHO', action: 'policy_trigger', policy: 'Tool Allowlist', outcome: 'blocked', detail: 'Attempted to call fs.writeFile (not in manifest).' },
  { id: 7, time: '45 min ago', agent: 'ARIA', action: 'inference', policy: '—', outcome: 'allowed', detail: 'UI component generated successfully.' },
  { id: 8, time: '1 hr ago', agent: 'CIPHER', action: 'policy_trigger', policy: 'Content Filter', outcome: 'blocked', detail: 'Social engineering attempt pattern detected.' },
];

const GUARDRAILS = [
  { name: 'Prompt injection protection', enabled: true, desc: 'Detect and sanitize adversarial prompt injection in user inputs.' },
  { name: 'Agent-to-agent trust verification', enabled: true, desc: 'Validate agent identity before inter-agent message relay.' },
  { name: 'Memory write approval', enabled: false, desc: 'Require human approval before agents write to long-term memory.' },
  { name: 'External API call logging', enabled: true, desc: 'Log all outbound HTTP calls made by agents to external APIs.' },
  { name: 'Auto-pause on anomaly', enabled: true, desc: 'Automatically pause an agent if behavior deviates from baseline by >3σ.' },
  { name: 'Rollback on error cascade', enabled: false, desc: 'Auto-rollback agent state if 3+ consecutive errors occur within 60s.' },
];

const severityColor: Record<string, string> = {
  critical: 'text-red-400 bg-red-400/10 border-red-400/20',
  high: 'text-orange-400 bg-orange-400/10 border-orange-400/20',
  medium: 'text-yellow-400 bg-yellow-400/10 border-yellow-400/20',
  low: 'text-green-400 bg-green-400/10 border-green-400/20',
};

export default function GovernancePage() {
  const [activeTab, setActiveTab] = useState<'policies' | 'audit' | 'guardrails'>('policies');
  const [guardrails, setGuardrails] = useState(GUARDRAILS);

  const totalBlocked = POLICIES.reduce((sum, p) => sum + p.blocked, 0);
  const totalTriggers = POLICIES.reduce((sum, p) => sum + p.triggers, 0);
  const activePolicies = POLICIES.filter(p => p.status === 'active').length;

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-3">
            <Shield className="h-7 w-7 text-[#FF1D6C]" />
            Governance
          </h1>
          <p className="text-gray-400 mt-1 text-sm">Policy enforcement, audit logs, and agent guardrails.</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="flex items-center gap-1.5 text-xs text-green-400 bg-green-400/10 border border-green-400/20 px-3 py-1.5 rounded-lg">
            <CheckCircle className="h-3.5 w-3.5" />
            All critical policies active
          </span>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Active Policies', value: activePolicies, icon: Shield, color: 'text-[#FF1D6C]' },
          { label: 'Total Triggers', value: totalTriggers.toLocaleString(), icon: Activity, color: 'text-amber-400' },
          { label: 'Requests Blocked', value: totalBlocked, icon: XCircle, color: 'text-red-400' },
          { label: 'Compliance Score', value: '99.4%', icon: CheckCircle, color: 'text-green-400' },
        ].map(stat => (
          <div key={stat.label} className="bg-white/5 border border-white/10 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
              <span className="text-xs text-gray-400">{stat.label}</span>
            </div>
            <div className="text-2xl font-bold text-white">{stat.value}</div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-white/5 border border-white/10 rounded-xl p-1 w-fit">
        {(['policies', 'audit', 'guardrails'] as const).map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-5 py-2 rounded-lg text-sm font-medium transition-all capitalize ${
              activeTab === tab
                ? 'bg-white/10 text-white'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            {tab === 'audit' ? 'Audit Log' : tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {/* Policies Tab */}
      {activeTab === 'policies' && (
        <div className="space-y-3">
          {POLICIES.map(policy => (
            <div key={policy.id} className="bg-white/5 border border-white/10 rounded-xl p-5">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-1">
                    <h3 className="text-white font-semibold">{policy.name}</h3>
                    <span className={`text-xs px-2 py-0.5 rounded border capitalize ${severityColor[policy.severity]}`}>
                      {policy.severity}
                    </span>
                    {policy.status === 'paused' && (
                      <span className="text-xs px-2 py-0.5 rounded border text-gray-400 bg-white/5 border-white/10">
                        paused
                      </span>
                    )}
                  </div>
                  <p className="text-gray-400 text-sm">{policy.description}</p>
                </div>
                <div className="flex items-center gap-6 text-sm shrink-0">
                  <div className="text-right">
                    <div className="text-white font-mono">{policy.triggers.toLocaleString()}</div>
                    <div className="text-gray-500 text-xs">triggers</div>
                  </div>
                  <div className="text-right">
                    <div className={`font-mono ${policy.blocked > 0 ? 'text-red-400' : 'text-gray-400'}`}>
                      {policy.blocked}
                    </div>
                    <div className="text-gray-500 text-xs">blocked</div>
                  </div>
                  <div className={`w-2 h-2 rounded-full ${policy.status === 'active' ? 'bg-green-400' : 'bg-gray-500'}`} />
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Audit Log Tab */}
      {activeTab === 'audit' && (
        <div className="bg-white/5 border border-white/10 rounded-xl overflow-hidden">
          <div className="p-4 border-b border-white/10 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <FileText className="h-4 w-4 text-gray-400" />
              <span className="text-sm font-medium text-white">Recent Events</span>
            </div>
            <span className="text-xs text-gray-500">Last 100 entries · Auto-refreshes every 30s</span>
          </div>
          <div className="divide-y divide-white/5">
            {AUDIT_LOG.map(entry => (
              <div key={entry.id} className="flex items-start gap-4 p-4 hover:bg-white/5 transition-colors">
                <div className={`mt-0.5 shrink-0 ${
                  entry.outcome === 'blocked' ? 'text-red-400' :
                  entry.outcome === 'redacted' ? 'text-yellow-400' :
                  'text-green-400'
                }`}>
                  {entry.outcome === 'blocked' ? <XCircle className="h-4 w-4" /> :
                   entry.outcome === 'redacted' ? <AlertTriangle className="h-4 w-4" /> :
                   <CheckCircle className="h-4 w-4" />}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-0.5">
                    <span className="text-white font-mono text-sm font-medium">{entry.agent}</span>
                    <span className="text-gray-500 text-xs">·</span>
                    <span className="text-gray-400 text-xs">{entry.policy}</span>
                    <span className={`text-xs px-1.5 py-0.5 rounded capitalize ${
                      entry.outcome === 'blocked' ? 'bg-red-400/10 text-red-400' :
                      entry.outcome === 'redacted' ? 'bg-yellow-400/10 text-yellow-400' :
                      'bg-green-400/10 text-green-400'
                    }`}>
                      {entry.outcome}
                    </span>
                  </div>
                  <p className="text-gray-400 text-xs truncate">{entry.detail}</p>
                </div>
                <div className="flex items-center gap-1 text-gray-500 text-xs shrink-0">
                  <Clock className="h-3 w-3" />
                  {entry.time}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Guardrails Tab */}
      {activeTab === 'guardrails' && (
        <div className="space-y-3">
          <p className="text-sm text-gray-400">Runtime guardrails applied to all agent executions. Toggle to enable or disable.</p>
          {guardrails.map((rail, i) => (
            <div key={rail.name} className="flex items-center justify-between gap-4 bg-white/5 border border-white/10 rounded-xl p-4">
              <div className="flex items-start gap-3">
                <Lock className="h-4 w-4 text-gray-400 mt-0.5 shrink-0" />
                <div>
                  <div className="text-white text-sm font-medium">{rail.name}</div>
                  <div className="text-gray-400 text-xs mt-0.5">{rail.desc}</div>
                </div>
              </div>
              <button
                onClick={() => {
                  const updated = [...guardrails];
                  updated[i] = { ...updated[i], enabled: !updated[i].enabled };
                  setGuardrails(updated);
                }}
                className={`shrink-0 w-12 h-6 rounded-full transition-all relative ${
                  rail.enabled ? 'bg-[#FF1D6C]' : 'bg-white/10'
                }`}
              >
                <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-all ${
                  rail.enabled ? 'left-6' : 'left-0.5'
                }`} />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
