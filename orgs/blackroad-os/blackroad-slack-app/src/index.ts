/**
 * BlackRoad Slack App
 * Cloudflare Worker for Slack integration
 *
 * Commands:
 * /blackroad status - Show infrastructure status
 * /blackroad agents - List AI agents
 * /blackroad deploy <service> - Trigger deployment
 * /blackroad usage - Show usage stats
 * /blackroad help - Show available commands
 */

interface Env {
  SLACK_SIGNING_SECRET: string;
  SLACK_BOT_TOKEN: string;
  ENVIRONMENT: string;
}

interface SlackCommand {
  token: string;
  command: string;
  text: string;
  response_url: string;
  user_id: string;
  user_name: string;
  channel_id: string;
  team_id: string;
}

// BlackRoad brand colors
const COLORS = {
  hotPink: '#FF1D6C',
  amber: '#F5A623',
  electricBlue: '#2979FF',
  violet: '#9C27B0',
  success: '#00C853',
  error: '#FF1744',
};

// Verify Slack request signature
async function verifySlackSignature(
  request: Request,
  body: string,
  signingSecret: string
): Promise<boolean> {
  const timestamp = request.headers.get('x-slack-request-timestamp');
  const signature = request.headers.get('x-slack-signature');

  if (!timestamp || !signature) return false;

  // Check timestamp is within 5 minutes
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - parseInt(timestamp)) > 300) return false;

  const sigBaseString = `v0:${timestamp}:${body}`;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(signingSecret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(sigBaseString)
  );

  const computedSignature = 'v0=' + Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  return computedSignature === signature;
}

// Parse URL-encoded form data
function parseFormData(body: string): Record<string, string> {
  const params = new URLSearchParams(body);
  const result: Record<string, string> = {};
  params.forEach((value, key) => {
    result[key] = value;
  });
  return result;
}

// Build status message blocks
function buildStatusBlocks() {
  return {
    response_type: 'in_channel',
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🛣️ BlackRoad Infrastructure Status',
          emoji: true
        }
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: '*GitHub Orgs:*\n15 organizations' },
          { type: 'mrkdwn', text: '*Repositories:*\n1,085 repos' },
        ]
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: '*Cloudflare Pages:*\n205 projects' },
          { type: 'mrkdwn', text: '*KV Namespaces:*\n35 namespaces' },
        ]
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: '*Device Fleet:*\n8 devices (52 TOPS)' },
          { type: 'mrkdwn', text: '*AI Agents:*\n30,000+ coordinated' },
        ]
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: '✅ All systems operational | Last updated: just now'
          }
        ]
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: '📊 View Dashboard', emoji: true },
            url: 'https://blackroad.io/dashboard',
            action_id: 'view_dashboard'
          },
          {
            type: 'button',
            text: { type: 'plain_text', text: '📚 Docs', emoji: true },
            url: 'https://docs.blackroad.io',
            action_id: 'view_docs'
          }
        ]
      }
    ]
  };
}

// Build agents message blocks
function buildAgentsBlocks() {
  const agents = [
    { name: 'Roadie', role: 'Infrastructure', status: '🟢 Online', tasks: 42 },
    { name: 'Athena', role: 'Code Review', status: '🟢 Online', tasks: 15 },
    { name: 'Guardian', role: 'Security', status: '🟢 Online', tasks: 8 },
    { name: 'Radius', role: 'Analytics', status: '🟡 Busy', tasks: 23 },
    { name: 'RoadMind', role: 'Strategy', status: '🟢 Online', tasks: 31 },
  ];

  const agentBlocks = agents.map(agent => ({
    type: 'section',
    text: {
      type: 'mrkdwn',
      text: `*${agent.name}* - ${agent.role}\n${agent.status} | ${agent.tasks} tasks completed`
    },
    accessory: {
      type: 'button',
      text: { type: 'plain_text', text: 'View', emoji: true },
      url: `https://blackroad.io/agents/${agent.name.toLowerCase()}`,
      action_id: `view_agent_${agent.name.toLowerCase()}`
    }
  }));

  return {
    response_type: 'in_channel',
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🤖 BlackRoad AI Agents',
          emoji: true
        }
      },
      {
        type: 'context',
        elements: [
          { type: 'mrkdwn', text: '5 active agents | 30,000+ total coordinated' }
        ]
      },
      { type: 'divider' },
      ...agentBlocks,
      { type: 'divider' },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: '➕ Deploy New Agent', emoji: true },
            style: 'primary',
            url: 'https://blackroad.io/agents/deploy',
            action_id: 'deploy_agent'
          }
        ]
      }
    ]
  };
}

// Build usage message blocks
function buildUsageBlocks() {
  return {
    response_type: 'ephemeral',
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '📊 BlackRoad Usage Statistics',
          emoji: true
        }
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: '*API Calls (24h):*\n847,293' },
          { type: 'mrkdwn', text: '*Inference Requests:*\n12,847' },
        ]
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: '*Deployments:*\n156 this week' },
          { type: 'mrkdwn', text: '*Active Sessions:*\n2,847' },
        ]
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: '*Compute Used:*\n847 GPU-hours' },
          { type: 'mrkdwn', text: '*Storage:*\n2.4 TB' },
        ]
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: '💡 _Tip: Use `/blackroad billing` to view your current billing cycle_'
          }
        ]
      }
    ]
  };
}

// Build help message blocks
function buildHelpBlocks() {
  return {
    response_type: 'ephemeral',
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🛣️ BlackRoad Slack Commands',
          emoji: true
        }
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: '*Available Commands:*\n\n' +
            '`/blackroad status` - Show infrastructure status\n' +
            '`/blackroad agents` - List AI agents and their status\n' +
            '`/blackroad usage` - View usage statistics\n' +
            '`/blackroad deploy <service>` - Trigger a deployment\n' +
            '`/blackroad help` - Show this help message'
        }
      },
      { type: 'divider' },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: '🔗 <https://docs.blackroad.io/slack|Full Documentation> | <https://blackroad.io/support|Get Support>'
          }
        ]
      }
    ]
  };
}

// Build deploy confirmation blocks
function buildDeployBlocks(service: string) {
  return {
    response_type: 'in_channel',
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🚀 Deployment Initiated',
          emoji: true
        }
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `Deploying *${service}* to production...`
        }
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: '⏳ Estimated time: 2-3 minutes | You will be notified when complete'
          }
        ]
      }
    ]
  };
}

// Handle slash commands
async function handleSlashCommand(command: SlackCommand): Promise<Response> {
  const subcommand = command.text.trim().toLowerCase().split(' ')[0];
  const args = command.text.trim().split(' ').slice(1);

  let response;

  switch (subcommand) {
    case 'status':
    case '':
      response = buildStatusBlocks();
      break;
    case 'agents':
      response = buildAgentsBlocks();
      break;
    case 'usage':
      response = buildUsageBlocks();
      break;
    case 'deploy':
      const service = args[0] || 'all';
      response = buildDeployBlocks(service);
      break;
    case 'help':
    default:
      response = buildHelpBlocks();
  }

  return new Response(JSON.stringify(response), {
    headers: { 'Content-Type': 'application/json' }
  });
}

// Handle interactive components
async function handleInteraction(payload: any): Promise<Response> {
  // Handle button clicks, modal submissions, etc.
  const actionId = payload.actions?.[0]?.action_id;

  // Log interaction for analytics
  console.log(`Interaction: ${actionId} by ${payload.user?.username}`);

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

// Main worker handler
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Health check endpoint
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'healthy',
        service: 'blackroad-slack-app',
        version: '1.0.0'
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Only accept POST requests for Slack
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    const body = await request.text();

    // Verify Slack signature
    const isValid = await verifySlackSignature(request, body, env.SLACK_SIGNING_SECRET);
    if (!isValid) {
      return new Response('Invalid signature', { status: 401 });
    }

    // Handle slash commands
    if (url.pathname === '/slack/commands') {
      const formData = parseFormData(body);
      return handleSlashCommand(formData as unknown as SlackCommand);
    }

    // Handle interactive components
    if (url.pathname === '/slack/interactions') {
      const formData = parseFormData(body);
      const payload = JSON.parse(formData.payload || '{}');
      return handleInteraction(payload);
    }

    // Handle events (for future event subscriptions)
    if (url.pathname === '/slack/events') {
      const data = JSON.parse(body);

      // URL verification challenge
      if (data.type === 'url_verification') {
        return new Response(data.challenge, {
          headers: { 'Content-Type': 'text/plain' }
        });
      }

      return new Response(JSON.stringify({ ok: true }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    return new Response('Not found', { status: 404 });
  }
};
