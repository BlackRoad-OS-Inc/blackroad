// Shared real-time data client for all BlackRoad sites
// Fetches from the blackroad-live-data Cloudflare Worker

const LIVE_API = 'https://blackroad-live-hub.amundsonalexa.workers.dev';

export interface GitHubStats {
  total_repos: number;
  os_repos: number;
  inc_repos: number;
  followers: number;
  recent_repos: Array<{
    name: string;
    description: string | null;
    stars: number;
    url: string;
    pushed: string;
    language: string | null;
  }>;
  updated_at: string;
}

export interface AgentFleetStatus {
  fleet: Array<{ name: string; ip: string; online: boolean; models?: number }>;
  online_count: number;
  total_count: number;
  agent_capacity: number;
  active_agents: number;
  updated_at: string;
}

export interface LiveData {
  blackroad: {
    orgs: number;
    total_repos: number;
    domains: number;
    custom_domains: number;
    agents: number;
    pi_fleet: string[];
  };
  github: { os_repos: number; inc_repos: number; followers: number };
  infrastructure: {
    cloudflare_pages: number;
    cloudflare_workers: number;
    railway_projects: number;
    vercel_projects: number;
  };
  updated_at: string;
}

// Cache with TTL
const cache = new Map<string, { data: unknown; expires: number }>();

async function fetchWithCache<T>(endpoint: string, ttlMs = 60_000): Promise<T | null> {
  const key = endpoint;
  const now = Date.now();
  const cached = cache.get(key);
  if (cached && cached.expires > now) return cached.data as T;

  try {
    const res = await fetch(`${LIVE_API}${endpoint}`, {
      next: { revalidate: 60 }, // Next.js ISR
    });
    if (!res.ok) return null;
    const data = await res.json() as T;
    cache.set(key, { data, expires: now + ttlMs });
    return data;
  } catch {
    return cached?.data as T ?? null;
  }
}

export async function getGitHubStats(): Promise<GitHubStats | null> {
  return fetchWithCache<GitHubStats>('/github/stats');
}

export async function getAgentFleet(): Promise<AgentFleetStatus | null> {
  return fetchWithCache<AgentFleetStatus>('/agents/status', 30_000);
}

export async function getLiveData(): Promise<LiveData | null> {
  return fetchWithCache<LiveData>('/all');
}

export async function getGitHubActivity() {
  return fetchWithCache<{ events: Array<{ type: string; repo: string; actor: string; created_at: string }> }>('/github/activity');
}
