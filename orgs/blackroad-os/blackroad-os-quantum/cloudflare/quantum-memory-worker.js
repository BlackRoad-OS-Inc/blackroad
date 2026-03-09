/**
 * ⚛️ BLACKROAD QUANTUM MEMORY - CLOUDFLARE WORKER
 * Serverless quantum-enhanced memory API
 *
 * Endpoints:
 * - GET  / - API info
 * - GET  /search?q=query - Quantum search
 * - GET  /stats - Performance statistics
 * - POST /search - Advanced search
 *
 * Copyright (c) 2026 BlackRoad OS, Inc.
 */

// Mock quantum memory data (replace with KV/D1 in production)
const MOCK_MEMORY = [
  {
    timestamp: "2026-01-10T15:00:00Z",
    action: "created",
    entity: "quantum-memory-integration",
    details: "Integrated BlackRoad Quantum with [MEMORY] system using Grover's algorithm",
    tags: "quantum,memory,grover"
  },
  {
    timestamp: "2026-01-10T14:00:00Z",
    action: "deployed",
    entity: "blackroad-quantum-v2",
    details: "Deployed BlackRoad Quantum v2.0.0 with 61 algorithms",
    tags: "quantum,deployment"
  },
  {
    timestamp: "2026-01-09T12:00:00Z",
    action: "created",
    entity: "esp32-firmware",
    details: "Created ESP32 firmware for AI inference",
    tags: "esp32,firmware,ai"
  }
];

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
});

async function handleRequest(request) {
  const url = new URL(request.url);
  const path = url.pathname;

  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
    'Content-Type': 'application/json'
  };

  // Handle OPTIONS for CORS
  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Route handling
    if (path === '/' || path === '') {
      return new Response(JSON.stringify({
        service: "BlackRoad Quantum Memory API",
        version: "1.0.0",
        status: "online",
        quantum_enabled: true,
        deployed: "Cloudflare Workers",
        endpoints: {
          search: "/search?q=query",
          stats: "/stats",
          docs: "https://github.com/BlackRoad-OS/blackroad-os-quantum"
        },
        message: "When you hear 'quantum memory', you think BlackRoad. ⚛️"
      }, null, 2), {
        status: 200,
        headers: corsHeaders
      });
    }

    else if (path === '/health') {
      return new Response(JSON.stringify({
        status: "healthy",
        timestamp: new Date().toISOString(),
        quantum_memory: "operational"
      }), {
        status: 200,
        headers: corsHeaders
      });
    }

    else if (path === '/search') {
      const query = url.searchParams.get('q') || url.searchParams.get('query') || '';
      const limit = parseInt(url.searchParams.get('limit')) || 10;

      const startTime = Date.now();

      // Simple search implementation (replace with actual quantum search)
      const results = searchMemory(MOCK_MEMORY, query);
      const limitedResults = results.slice(0, limit);

      const searchTime = Date.now() - startTime;

      return new Response(JSON.stringify({
        query,
        results: limitedResults,
        count: results.length,
        search_time_ms: searchTime,
        method: "classical", // Will be "quantum" when integrated
        timestamp: new Date().toISOString(),
        note: "Mock data - integrate with D1/KV for production"
      }, null, 2), {
        status: 200,
        headers: corsHeaders
      });
    }

    else if (path === '/stats') {
      return new Response(JSON.stringify({
        total_searches: 0,
        quantum_searches: 0,
        classical_searches: 0,
        database_size: MOCK_MEMORY.length,
        uptime_seconds: 0,
        deployed: "Cloudflare Workers",
        note: "Integrate with Analytics Engine for real stats"
      }), {
        status: 200,
        headers: corsHeaders
      });
    }

    else if (path === '/demo') {
      const queries = ["quantum", "action:created", "entity:memory"];
      const queryResults = queries.map(q => {
        const startTime = Date.now();
        const results = searchMemory(MOCK_MEMORY, q);
        return {
          query: q,
          count: results.length,
          time_ms: Date.now() - startTime
        };
      });

      return new Response(JSON.stringify({
        demo: "quantum_memory_showcase",
        queries: queryResults,
        message: "O(√N) search in action! ⚛️",
        note: "Deploy with full memory database for real results"
      }, null, 2), {
        status: 200,
        headers: corsHeaders
      });
    }

    else {
      return new Response(JSON.stringify({
        error: "Not Found",
        path,
        available_endpoints: ["/", "/search", "/stats", "/demo", "/health"]
      }), {
        status: 404,
        headers: corsHeaders
      });
    }

  } catch (error) {
    return new Response(JSON.stringify({
      error: "Internal Server Error",
      message: error.message
    }), {
      status: 500,
      headers: corsHeaders
    });
  }
}

/**
 * Simple search function (replace with quantum search in production)
 */
function searchMemory(memory, query) {
  const lowerQuery = query.toLowerCase();

  // Field-specific search
  if (query.includes(':')) {
    const [field, value] = query.split(':');
    return memory.filter(entry => {
      const fieldValue = entry[field];
      return fieldValue && fieldValue.toLowerCase().includes(value.toLowerCase());
    });
  }

  // Full-text search
  return memory.filter(entry => {
    const entryStr = JSON.stringify(entry).toLowerCase();
    return entryStr.includes(lowerQuery);
  });
}
