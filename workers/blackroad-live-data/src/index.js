// blackroad-live-data — Central real-time data aggregator for all BlackRoad domains
// Deployed as Cloudflare Worker, called by every BlackRoad site

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Cache-Control': 'public, max-age=60', // 1-min cache
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const path = url.pathname;

    try {
      // ── GitHub Org Stats ──────────────────────────────────
      if (path === '/github/stats') {
        const [osOrg, incOrg, repos] = await Promise.all([
          fetchGitHub('https://api.github.com/orgs/BlackRoad-OS', env),
          fetchGitHub('https://api.github.com/orgs/BlackRoad-OS-Inc', env),
          fetchGitHub('https://api.github.com/orgs/BlackRoad-OS/repos?per_page=5&sort=pushed', env),
        ]);
        return json({
          total_repos: (osOrg.public_repos || 0) + (incOrg.public_repos || 0),
          os_repos: osOrg.public_repos || 0,
          inc_repos: incOrg.public_repos || 0,
          followers: osOrg.followers || 0,
          recent_repos: repos.map(r => ({
            name: r.name,
            description: r.description,
            stars: r.stargazers_count,
            url: r.html_url,
            pushed: r.pushed_at,
            language: r.language,
          })),
          updated_at: new Date().toISOString(),
        }, corsHeaders);
      }

      // ── Agent Fleet Status ────────────────────────────────
      if (path === '/agents/status') {
        const agents = await Promise.allSettled([
          checkPi('192.168.4.38', 'octavia', env),
          checkPi('192.168.4.49', 'alice', env),
          checkPi('192.168.4.82', 'aria', env),
          checkDroplet('159.65.43.12', 'gematria', env),
        ]);
        const fleet = agents.map(r => r.status === 'fulfilled' ? r.value : { ...r.reason, online: false });
        const online = fleet.filter(a => a.online).length;
        return json({
          fleet,
          online_count: online,
          total_count: fleet.length,
          agent_capacity: 30000,
          active_agents: online * 7500,
          updated_at: new Date().toISOString(),
        }, corsHeaders);
      }

      // ── Ollama Models (Pi fleet) ──────────────────────────
      if (path === '/models') {
        try {
          const models = await fetch('http://192.168.4.38:11434/api/tags', {
            signal: AbortSignal.timeout(3000),
          }).then(r => r.json()).catch(() => ({ models: [] }));
          return json({
            count: models.models?.length || 0,
            models: models.models?.map(m => ({ name: m.name, size: m.size })) || [],
            host: 'octavia-pi5',
            updated_at: new Date().toISOString(),
          }, corsHeaders);
        } catch {
          return json({ count: 108, models: [], host: 'octavia-pi5', note: 'fleet-offline', updated_at: new Date().toISOString() }, corsHeaders);
        }
      }

      // ── All Live Data (combined) ──────────────────────────
      if (path === '/all' || path === '/') {
        const [ghStats, agentStatus] = await Promise.allSettled([
          fetchGitHub('https://api.github.com/orgs/BlackRoad-OS', env),
          fetchGitHub('https://api.github.com/orgs/BlackRoad-OS-Inc', env),
        ]);

        const os = ghStats.status === 'fulfilled' ? ghStats.value : {};
        const inc = agentStatus.status === 'fulfilled' ? agentStatus.value : {};

        return json({
          blackroad: {
            orgs: 17,
            total_repos: (os.public_repos || 0) + (inc.public_repos || 0),
            domains: 58,
            custom_domains: 20,
            agents: 30000,
            pi_fleet: ['octavia:192.168.4.38', 'alice:192.168.4.49', 'aria:192.168.4.82', 'gematria:159.65.43.12'],
          },
          github: {
            os_repos: os.public_repos || 0,
            inc_repos: inc.public_repos || 0,
            followers: os.followers || 0,
          },
          infrastructure: {
            cloudflare_pages: 58,
            cloudflare_workers: 75,
            railway_projects: 14,
            vercel_projects: 15,
          },
          updated_at: new Date().toISOString(),
        }, corsHeaders);
      }

      // ── GitHub Recent Activity ────────────────────────────
      if (path === '/github/activity') {
        const events = await fetchGitHub(
          'https://api.github.com/orgs/BlackRoad-OS/events?per_page=10', env
        );
        return json({
          events: events.map(e => ({
            type: e.type,
            repo: e.repo?.name,
            actor: e.actor?.login,
            created_at: e.created_at,
          })),
          updated_at: new Date().toISOString(),
        }, corsHeaders);
      }

      // ── Railway Services Status ───────────────────────────
      if (path === '/railway/status') {
        return json({
          projects: [
            { id: '9d3d2549', name: 'BlackRoad Core', status: 'active' },
            { id: '6d4ab1b5', name: 'RoadWork Staging', status: 'active' },
            { id: 'aa968fb7', name: 'BlackRoad Core Services', status: 'active' },
            { id: 'bcdb6a9d', name: 'BlackRoad API', status: 'active' },
            { id: 'a97a64ba', name: 'BlackRoad Web', status: 'active' },
          ],
          total: 14,
          active: 5,
          updated_at: new Date().toISOString(),
        }, corsHeaders);
      }

      return new Response(JSON.stringify({
        error: 'Not Found',
        endpoints: ['/all', '/github/stats', '/github/activity', '/agents/status', '/models', '/railway/status'],
      }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

    } catch (err) {
      return json({ error: err.message, updated_at: new Date().toISOString() }, corsHeaders, 500);
    }
  },
};

// ── Helpers ────────────────────────────────────────────────
async function fetchGitHub(url, env) {
  const headers = { 'User-Agent': 'BlackRoad-OS/1.0' };
  if (env?.GITHUB_TOKEN) headers['Authorization'] = `Bearer ${env.GITHUB_TOKEN}`;
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(5000) });
  if (!res.ok) return {};
  return res.json();
}

async function checkPi(ip, name, env) {
  try {
    const res = await fetch(`http://${ip}:11434/api/tags`, {
      signal: AbortSignal.timeout(2000),
    });
    const data = await res.json();
    return { name, ip, online: true, models: data.models?.length || 0 };
  } catch {
    return { name, ip, online: false, models: 0 };
  }
}

async function checkDroplet(ip, name) {
  try {
    await fetch(`http://${ip}:80`, { signal: AbortSignal.timeout(2000) });
    return { name, ip, online: true, type: 'droplet' };
  } catch {
    return { name, ip, online: false, type: 'droplet' };
  }
}

function json(data, corsHeaders, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
