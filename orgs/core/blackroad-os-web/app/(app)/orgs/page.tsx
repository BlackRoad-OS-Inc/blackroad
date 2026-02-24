'use client';
import { useState } from 'react';
import { Building2, ExternalLink, Users, GitBranch, Lock, Globe } from 'lucide-react';

const ORGS = [
  { name: 'BlackRoad-OS-Inc', repos: 7, private: true, focus: 'Corporate core', color: '#FF1D6C' },
  { name: 'BlackRoad-OS', repos: 1332, private: false, focus: 'Core platform', color: '#2979FF' },
  { name: 'blackboxprogramming', repos: 68, private: false, focus: 'Personal SDKs', color: '#9C27B0' },
  { name: 'BlackRoad-AI', repos: 52, private: false, focus: 'AI/ML stack', color: '#F5A623' },
  { name: 'BlackRoad-Cloud', repos: 30, private: false, focus: 'Infrastructure', color: '#2979FF' },
  { name: 'BlackRoad-Security', repos: 30, private: false, focus: 'Security tools', color: '#FF1D6C' },
  { name: 'BlackRoad-Foundation', repos: 30, private: false, focus: 'CRM/projects', color: '#9C27B0' },
  { name: 'BlackRoad-Hardware', repos: 30, private: false, focus: 'IoT/hardware', color: '#F5A623' },
  { name: 'BlackRoad-Media', repos: 29, private: false, focus: 'Social/content', color: '#FF1D6C' },
  { name: 'BlackRoad-Interactive', repos: 29, private: false, focus: 'Games/graphics', color: '#2979FF' },
  { name: 'BlackRoad-Education', repos: 24, private: false, focus: 'Learning', color: '#9C27B0' },
  { name: 'BlackRoad-Gov', repos: 23, private: false, focus: 'Governance', color: '#F5A623' },
  { name: 'Blackbox-Enterprises', repos: 21, private: false, focus: 'Enterprise', color: '#FF1D6C' },
  { name: 'BlackRoad-Archive', repos: 21, private: false, focus: 'Archival', color: '#2979FF' },
  { name: 'BlackRoad-Labs', repos: 20, private: false, focus: 'Research', color: '#9C27B0' },
  { name: 'BlackRoad-Studio', repos: 19, private: false, focus: 'Creative tools', color: '#F5A623' },
  { name: 'BlackRoad-Ventures', repos: 17, private: false, focus: 'Investment', color: '#FF1D6C' },
];

export default function OrgsPage() {
  const [search, setSearch] = useState('');
  const filtered = ORGS.filter(o => o.name.toLowerCase().includes(search.toLowerCase()) || o.focus.toLowerCase().includes(search.toLowerCase()));
  const total = ORGS.reduce((s, o) => s + o.repos, 0);

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2"><Building2 size={24} /> Organizations</h1>
          <p className="text-gray-400 mt-1">{ORGS.length} organizations · {total.toLocaleString()} repositories</p>
        </div>
        <input
          placeholder="Search orgs..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-sm focus:outline-none focus:border-pink-500 w-48"
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map(org => (
          <div key={org.name} className="bg-gray-900 border border-gray-800 rounded-xl p-4 hover:border-gray-600 transition-all group">
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ backgroundColor: org.color + '20', border: `1px solid ${org.color}40` }}>
                  {org.private ? <Lock size={14} style={{ color: org.color }} /> : <Globe size={14} style={{ color: org.color }} />}
                </div>
                <div>
                  <p className="font-medium text-sm leading-tight">{org.name}</p>
                  <p className="text-xs text-gray-500">{org.focus}</p>
                </div>
              </div>
              <a href={`https://github.com/${org.name}`} target="_blank" rel="noopener noreferrer" className="opacity-0 group-hover:opacity-100 transition-opacity">
                <ExternalLink size={14} className="text-gray-400" />
              </a>
            </div>
            <div className="flex items-center gap-4 text-xs text-gray-400">
              <span className="flex items-center gap-1"><GitBranch size={12} /> {org.repos.toLocaleString()} repos</span>
              <span className={`px-1.5 py-0.5 rounded text-xs ${org.private ? 'bg-red-900/30 text-red-400' : 'bg-green-900/30 text-green-400'}`}>
                {org.private ? 'Private' : 'Public'}
              </span>
            </div>
          </div>
        ))}
      </div>

      <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
        <p className="text-xs text-gray-500 text-center">© BlackRoad OS, Inc. — All {ORGS.length} organizations and {total.toLocaleString()} repositories are proprietary.</p>
      </div>
    </div>
  );
}
