/**
 * RoadCommand Cloudflare Worker
 * THE Platform - API Layer Above Google, OpenAI, Anthropic
 * BlackRoad OS, Inc. © 2026
 */

import RoadCommandOrchestrator from './api-orchestrator.js';

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Routes
    switch (url.pathname) {
      case '/':
        return new Response(await getHomePage(), {
          headers: { ...corsHeaders, 'Content-Type': 'text/html' }
        });

      case '/api/process':
        const orchestrator = new RoadCommandOrchestrator(env);
        return await orchestrator.handleRequest(request);

      case '/api/providers':
        return new Response(JSON.stringify({
          providers: ['google', 'openai', 'anthropic'],
          models: {
            google: ['gemini-pro', 'gemini-pro-vision', 'gemini-ultra'],
            openai: ['gpt-4-turbo', 'gpt-4', 'gpt-3.5-turbo'],
            anthropic: ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku']
          },
          capabilities: {
            intelligent_routing: true,
            memory_continuity: true,
            cost_optimization: true,
            multi_model: true,
            agent_orchestration: true
          }
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });

      case '/api/health':
        return new Response(JSON.stringify({
          status: 'operational',
          version: '2.0.0',
          platform: 'RoadCommand',
          timestamp: new Date().toISOString()
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });

      default:
        return new Response('Not Found', { status: 404 });
    }
  }
};

async function getHomePage() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RoadCommand - AI Operations Platform | BlackRoad OS</title>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --amber: #F5A623;
            --hot-pink: #FF1D6C;
            --electric-blue: #2979FF;
            --violet: #9C27B0;
            --gradient-brand: linear-gradient(135deg, var(--amber) 0%, var(--hot-pink) 38.2%, var(--violet) 61.8%, var(--electric-blue) 100%);
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'JetBrains Mono', monospace;
            background: #000;
            color: #fff;
            line-height: 1.6;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 89px 21px; }
        h1 {
            background: var(--gradient-brand);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 55px;
            margin-bottom: 21px;
        }
        .tagline { font-size: 21px; color: rgba(255,255,255,0.7); margin-bottom: 55px; }
        .api-demo {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 13px;
            padding: 34px;
            margin-bottom: 34px;
        }
        textarea {
            width: 100%;
            min-height: 144px;
            background: rgba(0,0,0,0.5);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 8px;
            padding: 13px;
            color: #fff;
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            margin-bottom: 13px;
        }
        input {
            width: 100%;
            background: rgba(0,0,0,0.5);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 8px;
            padding: 13px;
            color: #fff;
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            margin-bottom: 13px;
        }
        button {
            background: var(--gradient-brand);
            border: none;
            border-radius: 8px;
            padding: 13px 34px;
            color: #fff;
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s;
        }
        button:hover { transform: translateY(-2px); }
        .response {
            background: rgba(0,0,0,0.5);
            border: 1px solid var(--hot-pink);
            border-radius: 8px;
            padding: 21px;
            margin-top: 21px;
            display: none;
        }
        .response.show { display: block; }
        .provider-badge {
            display: inline-block;
            padding: 5px 13px;
            border-radius: 13px;
            font-size: 11px;
            margin-right: 8px;
        }
        .provider-google { background: rgba(66, 133, 244, 0.2); color: #4285F4; }
        .provider-openai { background: rgba(16, 163, 127, 0.2); color: #10A37F; }
        .provider-anthropic { background: rgba(255, 29, 108, 0.2); color: var(--hot-pink); }
    </style>
</head>
<body>
    <div class="container">
        <h1>RoadCommand</h1>
        <div class="tagline">The Platform That Enables Companies to Operate Exclusively by AI</div>

        <div class="api-demo">
            <h2 style="margin-bottom: 21px;">API Orchestration Layer</h2>
            <p style="margin-bottom: 21px; color: rgba(255,255,255,0.6);">
                RoadCommand intelligently routes your requests to the best AI model across Google, OpenAI, and Anthropic.
                Maintains conversation memory and manages 30,000+ agents.
            </p>

            <label style="display: block; margin-bottom: 8px; font-size: 13px;">Your Request:</label>
            <textarea id="prompt" placeholder="Enter your request... RoadCommand will route it to the optimal model.">Write a Python function to calculate Fibonacci numbers</textarea>

            <label style="display: block; margin-bottom: 8px; font-size: 13px;">Session ID (for memory continuity):</label>
            <input type="text" id="sessionId" value="demo-session-${Date.now()}" />

            <label style="display: block; margin-bottom: 8px; font-size: 13px;">API Keys (comma-separated: google,openai,anthropic):</label>
            <input type="password" id="apiKeys" placeholder="your-google-key,your-openai-key,your-anthropic-key" />

            <button onclick="processRequest()">Send to RoadCommand</button>

            <div id="response" class="response"></div>
        </div>

        <div style="margin-top: 55px;">
            <h2 style="margin-bottom: 21px;">How It Works</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 21px;">
                <div style="background: rgba(255,255,255,0.03); padding: 21px; border-radius: 13px;">
                    <h3 style="color: var(--amber); margin-bottom: 13px;">1. Intelligent Routing</h3>
                    <p style="font-size: 13px; color: rgba(255,255,255,0.6);">
                        Analyzes your request and routes to the best model: Google for data analysis,
                        OpenAI for creative tasks, Anthropic for code generation.
                    </p>
                </div>
                <div style="background: rgba(255,255,255,0.03); padding: 21px; border-radius: 13px;">
                    <h3 style="color: var(--hot-pink); margin-bottom: 13px;">2. Memory & Continuity</h3>
                    <p style="font-size: 13px; color: rgba(255,255,255,0.6);">
                        Maintains conversation context across sessions. Switch between models
                        seamlessly without losing context.
                    </p>
                </div>
                <div style="background: rgba(255,255,255,0.03); padding: 21px; border-radius: 13px;">
                    <h3 style="color: var(--electric-blue); margin-bottom: 13px;">3. Cost Optimization</h3>
                    <p style="font-size: 13px; color: rgba(255,255,255,0.6);">
                        Automatically selects the most cost-effective model for your task.
                        Real-time cost tracking included.
                    </p>
                </div>
            </div>
        </div>

        <div style="margin-top: 55px; padding: 34px; background: var(--gradient-brand); border-radius: 13px;">
            <h2 style="margin-bottom: 13px;">Enterprise Pricing</h2>
            <p style="margin-bottom: 21px;">
                For companies operating exclusively by AI, RoadCommand provides the complete
                infrastructure for model management, agent orchestration, and continuity.
            </p>
            <p style="font-size: 21px; font-weight: 600;">Contact: blackroad.systems@gmail.com</p>
        </div>
    </div>

    <script>
        async function processRequest() {
            const prompt = document.getElementById('prompt').value;
            const sessionId = document.getElementById('sessionId').value;
            const apiKeysInput = document.getElementById('apiKeys').value;
            const responseDiv = document.getElementById('response');

            if (!prompt || !apiKeysInput) {
                responseDiv.innerHTML = '<p style="color: #ff6b6b;">Please provide both a prompt and API keys.</p>';
                responseDiv.classList.add('show');
                return;
            }

            // Parse API keys
            const keys = apiKeysInput.split(',').map(k => k.trim());
            const apiKeys = {
                google: keys[0] || null,
                openai: keys[1] || null,
                anthropic: keys[2] || null
            };

            responseDiv.innerHTML = '<p>Processing through RoadCommand...</p>';
            responseDiv.classList.add('show');

            try {
                const response = await fetch('/api/process', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        sessionId,
                        prompt,
                        apiKeys,
                        priority: 'balanced'
                    })
                });

                const data = await response.json();

                if (data.error) {
                    responseDiv.innerHTML = \`<p style="color: #ff6b6b;">Error: \${data.error}</p>\`;
                } else {
                    const providerClass = 'provider-' + data.provider;
                    responseDiv.innerHTML = \`
                        <div>
                            <span class="provider-badge \${providerClass}">\${data.provider.toUpperCase()}</span>
                            <span class="provider-badge provider-badge" style="background: rgba(255,255,255,0.1);">\${data.model}</span>
                        </div>
                        <div style="margin: 13px 0; padding: 13px; background: rgba(255,255,255,0.05); border-radius: 8px;">
                            <pre style="white-space: pre-wrap; font-size: 13px;">\${data.content}</pre>
                        </div>
                        <div style="font-size: 11px; color: rgba(255,255,255,0.4);">
                            Cost: $\${data.cost.total.toFixed(4)} |
                            Input: \${data.usage.input_tokens} tokens |
                            Output: \${data.usage.output_tokens} tokens
                        </div>
                    \`;
                }
            } catch (error) {
                responseDiv.innerHTML = \`<p style="color: #ff6b6b;">Error: \${error.message}</p>\`;
            }
        }
    </script>
</body>
</html>`;
}
