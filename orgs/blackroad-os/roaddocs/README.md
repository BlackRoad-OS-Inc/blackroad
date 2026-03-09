# RoadDocs

Documentation platform for the BlackRoad ecosystem.

## Features

- **Markdown Rendering** - Write docs in Markdown
- **Sidebar Navigation** - Hierarchical doc structure
- **Search** - Full-text search across docs
- **Versioning** - Multiple doc versions
- **Multi-Project** - Host docs for multiple projects
- **Theming** - BlackRoad design system built-in
- **API Reference** - Programmatic doc management

## Quick Start

```bash
npm install
wrangler deploy
```

## API Endpoints

### Projects
- `GET /projects` - List projects
- `POST /projects` - Create project
- `GET /projects/:id` - Get project

### Documents
- `GET /projects/:project/docs` - List docs
- `POST /projects/:project/docs` - Create/update doc
- `GET /projects/:project/:version/:slug` - Get doc
- `DELETE /projects/:project/:version/:slug` - Delete doc

### Search & Import
- `GET /projects/:project/search?q=query` - Search docs
- `POST /projects/:project/import` - Bulk import

### Rendered Site
- `GET /projects/:project/site/*` - View rendered docs

## Document Schema

```json
{
  "title": "Getting Started",
  "slug": "getting-started",
  "content": "# Getting Started\n\nWelcome to the docs...",
  "order": 1,
  "parent": null,
  "version": "latest"
}
```

## Project Schema

```json
{
  "name": "RoadAI",
  "description": "AI Platform Documentation",
  "versions": ["latest", "v1.0", "v0.9"],
  "defaultVersion": "latest",
  "github": "https://github.com/BlackRoad-OS/roadai"
}
```

## Markdown Support

- Headers (#, ##, ###)
- Bold (**text**)
- Italic (*text*)
- Links ([text](url))
- Code blocks (```)
- Inline code (`code`)
- Lists (- item)

## License

Proprietary - BlackRoad OS, Inc.
