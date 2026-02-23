// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.

export interface ProjectTemplate {
  name: string
  description: string
  files: Record<string, string>
}

export const templates: ProjectTemplate[] = [
  {
    name: 'worker',
    description: 'Cloudflare Worker project',
    files: {
      'src/index.ts': '// Copyright (c) 2025-2026 BlackRoad OS, Inc.\nexport default { fetch: () => new Response("Hello") }',
      'wrangler.toml': 'name = "my-worker"\nmain = "src/index.ts"\ncompatibility_date = "2024-12-01"',
    },
  },
  {
    name: 'api',
    description: 'Hono API service',
    files: {
      'src/index.ts': '// Copyright (c) 2025-2026 BlackRoad OS, Inc.\nimport { Hono } from "hono"\nconst app = new Hono()\nexport default app',
      'package.json': '{ "type": "module", "dependencies": { "hono": "^4.0.0" } }',
    },
  },
]
