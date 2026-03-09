# blackroad.io

The Hub — BlackRoad's central platform with template library and dynamic content.

## Features

- **Template Library** (`/templates/*`) — Fetch components, layouts, and page templates for other BlackRoad sites
- **Dynamic Content** — D1-backed pages, domains, GitHub orgs, and redirects
- **API Endpoints** — `/api/stats`, `/api/domains`, `/api/orgs`, `/api/health`
- **Design System** — Grayscale-first with accent gradient

## Stack

- **Runtime**: Cloudflare Workers
- **Database**: Cloudflare D1 (`blackroad-os-main`)
- **Cache**: Cloudflare KV (`TEMPLATES`, `CONTENT`)
- **DNS**: Cloudflare

## Development

```bash
npm install
npm run dev        # Local development
npm run deploy     # Deploy to Cloudflare
```

## Database Setup

```bash
npm run db:init    # Create tables
npm run db:seed    # Seed initial data
```

## Project Structure

```
├── src/
│   ├── index.js           # Main worker entry
│   ├── pages/
│   │   └── index.js       # All site pages
│   ├── templates/
│   │   ├── base.js        # CSS, header, footer, layout
│   │   └── library.js     # Raw templates for fetching
│   └── lib/
│       └── ...            # Utilities
├── schema.sql             # D1 schema
├── seed.sql               # Initial data
├── wrangler.toml          # Cloudflare config
└── package.json
```

## Template Library

Other sites can fetch templates:

```js
const css = await fetch('https://blackroad.io/templates/base.css').then(r => r.text());
const header = await fetch('https://blackroad.io/templates/components/header').then(r => r.text());
const layout = await fetch('https://blackroad.io/templates/layouts/base').then(r => r.text());

const page = layout
  .replace('{Title}', 'My Page')
  .replace('{Header}', header)
  .replace('{Body}', '<h1>Hello</h1>')
  .replace('{Footer}', footer);
```

## API

| Endpoint | Description |
|----------|-------------|
| `GET /api/stats` | Returns agent count, domains, orgs, repos |
| `GET /api/domains` | List all domains from D1 |
| `GET /api/orgs` | List all GitHub orgs from D1 |
| `GET /api/health` | Health check |

## Routes

| Path | Description |
|------|-------------|
| `/` | Home |
| `/connect` | Platform connections |
| `/ecosystem` | Infrastructure overview |
| `/github` | GitHub orgs |
| `/domains` | Domain registry |
| `/templates` | Template library index |
| `/design` | Design system reference |
| `/about` | Company info |

## License

MIT — BlackRoad OS, Inc.
