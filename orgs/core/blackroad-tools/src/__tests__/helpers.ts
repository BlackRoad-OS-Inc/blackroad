/**
 * Mock implementations for Cloudflare Workers bindings (KV, D1).
 * These let us unit-test handler logic without the Workers runtime.
 */

export function createMockKV(): KVNamespace {
  const store = new Map<string, { value: string; expiration?: number }>();

  return {
    get: async (key: string) => store.get(key)?.value ?? null,
    put: async (key: string, value: string, opts?: { expirationTtl?: number }) => {
      store.set(key, { value, expiration: opts?.expirationTtl });
    },
    delete: async (key: string) => {
      store.delete(key);
    },
    list: async () => ({ keys: [...store.keys()].map((name) => ({ name })), list_complete: true, cacheStatus: null }),
    getWithMetadata: async () => ({ value: null, metadata: null, cacheStatus: null }),
  } as unknown as KVNamespace;
}

export interface MockD1Row {
  [key: string]: unknown;
}

export function createMockD1(rows: MockD1Row[] = []): D1Database {
  return {
    prepare: (_sql: string) => ({
      bind: (..._params: unknown[]) => ({
        all: async () => ({ results: rows, success: true, meta: {} }),
        first: async () => rows[0] ?? null,
        run: async () => ({ success: true, meta: {} }),
      }),
      all: async () => ({ results: rows, success: true, meta: {} }),
      first: async () => rows[0] ?? null,
      run: async () => ({ success: true, meta: {} }),
    }),
    batch: async () => [],
    exec: async () => ({ count: 0, duration: 0 }),
    dump: async () => new ArrayBuffer(0),
  } as unknown as D1Database;
}

export function createMockEnv(options: { rows?: MockD1Row[] } = {}) {
  return {
    DB: createMockD1(options.rows || []),
    TOOLS_KV: createMockKV(),
  };
}

const defaultCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Agent-ID',
};

export function corsHeaders() {
  return { ...defaultCors };
}

export function jsonRequest(url: string, body: unknown, headers: Record<string, string> = {}): Request {
  return new Request(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
}

export function getRequest(url: string, headers: Record<string, string> = {}): Request {
  return new Request(url, { method: 'GET', headers });
}
