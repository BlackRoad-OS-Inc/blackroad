/**
 * RoadDocs - Documentation Platform
 *
 * Features:
 * - Markdown rendering
 * - Sidebar navigation
 * - Search
 * - Versioning
 * - Multi-project support
 * - API reference generation
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Env {
  DOCS: KVNamespace;
}

interface Doc {
  id: string;
  project: string;
  version: string;
  slug: string;
  title: string;
  content: string; // Markdown
  order: number;
  parent?: string;
  createdAt: number;
  updatedAt: number;
}

interface Project {
  id: string;
  name: string;
  description?: string;
  logo?: string;
  versions: string[];
  defaultVersion: string;
  github?: string;
  createdAt: number;
}

interface SearchResult {
  id: string;
  title: string;
  slug: string;
  excerpt: string;
  score: number;
}

const app = new Hono<{ Bindings: Env }>();

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));

// Health check
app.get('/health', (c) => c.json({ status: 'healthy', service: 'roaddocs' }));

// Root
app.get('/', (c) => c.json({
  name: 'RoadDocs',
  version: '0.1.0',
  description: 'Documentation Platform',
  endpoints: {
    projects: 'GET /projects',
    docs: 'GET /projects/:project/docs',
    doc: 'GET /projects/:project/:version/:slug',
    search: 'GET /projects/:project/search',
  },
}));

// Projects
app.get('/projects', async (c) => {
  const list = await c.env.DOCS.list({ prefix: 'project:' });

  const projects = await Promise.all(
    list.keys.map(async (key) => {
      const data = await c.env.DOCS.get(key.name);
      return data ? JSON.parse(data) : null;
    })
  );

  return c.json({ projects: projects.filter(Boolean) });
});

app.post('/projects', async (c) => {
  const body = await c.req.json<Partial<Project>>();

  if (!body.name) {
    return c.json({ error: 'Missing required field: name' }, 400);
  }

  const project: Project = {
    id: body.id || body.name.toLowerCase().replace(/\s+/g, '-'),
    name: body.name,
    description: body.description,
    logo: body.logo,
    versions: body.versions || ['latest'],
    defaultVersion: body.defaultVersion || 'latest',
    github: body.github,
    createdAt: Date.now(),
  };

  await c.env.DOCS.put(`project:${project.id}`, JSON.stringify(project));

  return c.json({ id: project.id, name: project.name });
});

app.get('/projects/:id', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.DOCS.get(`project:${id}`);

  if (!data) {
    return c.json({ error: 'Project not found' }, 404);
  }

  return c.json(JSON.parse(data));
});

// Docs - List
app.get('/projects/:project/docs', async (c) => {
  const project = c.req.param('project');
  const version = c.req.query('version') || 'latest';

  const list = await c.env.DOCS.list({ prefix: `doc:${project}:${version}:` });

  const docs = await Promise.all(
    list.keys.map(async (key) => {
      const data = await c.env.DOCS.get(key.name);
      if (!data) return null;
      const doc = JSON.parse(data) as Doc;
      return {
        id: doc.id,
        slug: doc.slug,
        title: doc.title,
        order: doc.order,
        parent: doc.parent,
      };
    })
  );

  // Build navigation tree
  const tree = buildNavTree(docs.filter(Boolean) as any[]);

  return c.json({ project, version, docs: tree });
});

// Docs - Create/Update
app.post('/projects/:project/docs', async (c) => {
  const project = c.req.param('project');
  const body = await c.req.json<Partial<Doc>>();

  if (!body.title || !body.content) {
    return c.json({ error: 'Missing required fields: title, content' }, 400);
  }

  const version = body.version || 'latest';
  const slug = body.slug || body.title.toLowerCase().replace(/\s+/g, '-');

  const doc: Doc = {
    id: body.id || crypto.randomUUID(),
    project,
    version,
    slug,
    title: body.title,
    content: body.content,
    order: body.order ?? 0,
    parent: body.parent,
    createdAt: body.createdAt || Date.now(),
    updatedAt: Date.now(),
  };

  await c.env.DOCS.put(`doc:${project}:${version}:${slug}`, JSON.stringify(doc));

  // Update search index
  await updateSearchIndex(doc, c.env);

  return c.json({ id: doc.id, slug: doc.slug });
});

// Docs - Get single
app.get('/projects/:project/:version/:slug', async (c) => {
  const { project, version, slug } = c.req.param();

  const data = await c.env.DOCS.get(`doc:${project}:${version}:${slug}`);

  if (!data) {
    return c.json({ error: 'Document not found' }, 404);
  }

  const doc = JSON.parse(data) as Doc;

  // Get prev/next for navigation
  const nav = await getDocNavigation(project, version, slug, c.env);

  return c.json({
    ...doc,
    html: renderMarkdown(doc.content),
    prev: nav.prev,
    next: nav.next,
  });
});

// Docs - Delete
app.delete('/projects/:project/:version/:slug', async (c) => {
  const { project, version, slug } = c.req.param();

  await c.env.DOCS.delete(`doc:${project}:${version}:${slug}`);

  return c.json({ deleted: true });
});

// Search
app.get('/projects/:project/search', async (c) => {
  const project = c.req.param('project');
  const query = c.req.query('q');
  const version = c.req.query('version') || 'latest';

  if (!query) {
    return c.json({ error: 'Missing query parameter: q' }, 400);
  }

  const results = await searchDocs(project, version, query, c.env);

  return c.json({ query, results });
});

// Bulk import
app.post('/projects/:project/import', async (c) => {
  const project = c.req.param('project');
  const body = await c.req.json<{
    version: string;
    docs: Partial<Doc>[];
  }>();

  const imported = [];

  for (const docData of body.docs) {
    const version = body.version || 'latest';
    const slug = docData.slug || docData.title!.toLowerCase().replace(/\s+/g, '-');

    const doc: Doc = {
      id: crypto.randomUUID(),
      project,
      version,
      slug,
      title: docData.title!,
      content: docData.content!,
      order: docData.order ?? 0,
      parent: docData.parent,
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    await c.env.DOCS.put(`doc:${project}:${version}:${slug}`, JSON.stringify(doc));
    await updateSearchIndex(doc, c.env);

    imported.push({ slug, title: doc.title });
  }

  return c.json({ imported: imported.length, docs: imported });
});

// Render docs site
app.get('/projects/:project/site/*', async (c) => {
  const project = c.req.param('project');
  const path = c.req.path.replace(`/projects/${project}/site`, '') || '/';

  const projectData = await c.env.DOCS.get(`project:${project}`);
  if (!projectData) {
    return c.html(renderError('Project not found'));
  }

  const proj = JSON.parse(projectData) as Project;
  const version = c.req.query('v') || proj.defaultVersion;

  if (path === '/' || path === '') {
    // Render index/landing
    const list = await c.env.DOCS.list({ prefix: `doc:${project}:${version}:` });
    const docs = await Promise.all(
      list.keys.map(async (key) => {
        const data = await c.env.DOCS.get(key.name);
        if (!data) return null;
        const doc = JSON.parse(data) as Doc;
        return { slug: doc.slug, title: doc.title, order: doc.order, parent: doc.parent };
      })
    );

    return c.html(renderDocsPage(proj, version, null, buildNavTree(docs.filter(Boolean) as any[])));
  }

  // Get specific doc
  const slug = path.replace(/^\//, '');
  const docData = await c.env.DOCS.get(`doc:${project}:${version}:${slug}`);

  if (!docData) {
    return c.html(renderError('Document not found'));
  }

  const doc = JSON.parse(docData) as Doc;
  const list = await c.env.DOCS.list({ prefix: `doc:${project}:${version}:` });
  const docs = await Promise.all(
    list.keys.map(async (key) => {
      const data = await c.env.DOCS.get(key.name);
      if (!data) return null;
      const d = JSON.parse(data) as Doc;
      return { slug: d.slug, title: d.title, order: d.order, parent: d.parent };
    })
  );

  return c.html(renderDocsPage(proj, version, doc, buildNavTree(docs.filter(Boolean) as any[])));
});

// Helper functions
function buildNavTree(docs: { slug: string; title: string; order: number; parent?: string }[]) {
  const sorted = docs.sort((a, b) => a.order - b.order);
  const roots: any[] = [];
  const map: Record<string, any> = {};

  // First pass: create map
  for (const doc of sorted) {
    map[doc.slug] = { ...doc, children: [] };
  }

  // Second pass: build tree
  for (const doc of sorted) {
    if (doc.parent && map[doc.parent]) {
      map[doc.parent].children.push(map[doc.slug]);
    } else {
      roots.push(map[doc.slug]);
    }
  }

  return roots;
}

async function getDocNavigation(project: string, version: string, currentSlug: string, env: Env) {
  const list = await env.DOCS.list({ prefix: `doc:${project}:${version}:` });

  const docs = await Promise.all(
    list.keys.map(async (key) => {
      const data = await env.DOCS.get(key.name);
      if (!data) return null;
      const doc = JSON.parse(data) as Doc;
      return { slug: doc.slug, title: doc.title, order: doc.order };
    })
  );

  const sorted = docs.filter(Boolean).sort((a, b) => a!.order - b!.order);
  const currentIndex = sorted.findIndex(d => d?.slug === currentSlug);

  return {
    prev: currentIndex > 0 ? sorted[currentIndex - 1] : null,
    next: currentIndex < sorted.length - 1 ? sorted[currentIndex + 1] : null,
  };
}

async function updateSearchIndex(doc: Doc, env: Env) {
  // Simple search index - store searchable text
  const searchable = `${doc.title} ${doc.content}`.toLowerCase();
  await env.DOCS.put(
    `search:${doc.project}:${doc.version}:${doc.slug}`,
    JSON.stringify({ title: doc.title, content: searchable, slug: doc.slug })
  );
}

async function searchDocs(project: string, version: string, query: string, env: Env): Promise<SearchResult[]> {
  const list = await env.DOCS.list({ prefix: `search:${project}:${version}:` });
  const queryLower = query.toLowerCase();
  const results: SearchResult[] = [];

  for (const key of list.keys) {
    const data = await env.DOCS.get(key.name);
    if (!data) continue;

    const { title, content, slug } = JSON.parse(data);

    if (content.includes(queryLower)) {
      // Find excerpt
      const index = content.indexOf(queryLower);
      const start = Math.max(0, index - 50);
      const end = Math.min(content.length, index + query.length + 50);
      const excerpt = content.substring(start, end);

      results.push({
        id: slug,
        title,
        slug,
        excerpt: `...${excerpt}...`,
        score: title.toLowerCase().includes(queryLower) ? 2 : 1,
      });
    }
  }

  return results.sort((a, b) => b.score - a.score).slice(0, 20);
}

function renderMarkdown(content: string): string {
  // Simple markdown renderer
  let html = content
    // Code blocks
    .replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code class="language-$1">$2</code></pre>')
    // Inline code
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    // Headers
    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
    // Bold
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    // Italic
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    // Links
    .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2">$1</a>')
    // Lists
    .replace(/^- (.+)$/gm, '<li>$1</li>')
    // Paragraphs
    .replace(/\n\n/g, '</p><p>');

  // Wrap lists
  html = html.replace(/(<li>.*<\/li>)+/g, '<ul>$&</ul>');

  return `<p>${html}</p>`;
}

function renderDocsPage(project: Project, version: string, doc: Doc | null, nav: any[]): string {
  const sidebarHTML = renderSidebar(nav, project.id, version);
  const contentHTML = doc ? renderMarkdown(doc.content) : '<h1>Welcome</h1><p>Select a document from the sidebar.</p>';
  const title = doc ? doc.title : project.name;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - ${project.name}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #000; color: #fff; display: flex; min-height: 100vh; }
    .sidebar { width: 280px; background: #0a0a0a; border-right: 1px solid #222; padding: 20px; overflow-y: auto; }
    .sidebar h2 { color: #F5A623; margin-bottom: 20px; font-size: 18px; }
    .sidebar ul { list-style: none; }
    .sidebar li { margin-bottom: 8px; }
    .sidebar a { color: #ccc; text-decoration: none; display: block; padding: 8px 12px; border-radius: 6px; transition: all 0.2s; }
    .sidebar a:hover { background: #111; color: #F5A623; }
    .sidebar .children { margin-left: 16px; margin-top: 8px; }
    .main { flex: 1; padding: 40px 60px; max-width: 900px; }
    .main h1 { color: #F5A623; margin-bottom: 24px; }
    .main h2 { color: #FF1D6C; margin: 32px 0 16px; }
    .main h3 { color: #2979FF; margin: 24px 0 12px; }
    .main p { line-height: 1.8; margin-bottom: 16px; color: #ddd; }
    .main pre { background: #111; padding: 16px; border-radius: 8px; overflow-x: auto; margin: 16px 0; }
    .main code { font-family: 'SF Mono', Monaco, monospace; font-size: 14px; }
    .main a { color: #F5A623; }
    .main ul { margin: 16px 0; padding-left: 24px; }
    .main li { margin-bottom: 8px; line-height: 1.6; }
    .search { width: 100%; padding: 10px 14px; background: #111; border: 1px solid #333; border-radius: 6px; color: #fff; margin-bottom: 20px; }
    .search:focus { outline: none; border-color: #F5A623; }
  </style>
</head>
<body>
  <nav class="sidebar">
    <h2>${project.name}</h2>
    <input type="search" class="search" placeholder="Search docs..." id="search">
    ${sidebarHTML}
  </nav>
  <main class="main">
    ${doc ? `<h1>${doc.title}</h1>` : ''}
    ${contentHTML}
  </main>
  <script>
    document.getElementById('search').addEventListener('input', async (e) => {
      const q = e.target.value;
      if (q.length < 2) return;
      const res = await fetch('/projects/${project.id}/search?q=' + encodeURIComponent(q) + '&version=${version}');
      const data = await res.json();
      console.log('Search results:', data.results);
    });
  </script>
</body>
</html>`;
}

function renderSidebar(nav: any[], projectId: string, version: string): string {
  const renderItems = (items: any[]): string => {
    return items.map(item => `
      <li>
        <a href="/projects/${projectId}/site/${item.slug}?v=${version}">${item.title}</a>
        ${item.children?.length ? `<ul class="children">${renderItems(item.children)}</ul>` : ''}
      </li>
    `).join('');
  };

  return `<ul>${renderItems(nav)}</ul>`;
}

function renderError(message: string): string {
  return `<!DOCTYPE html>
<html><head><title>Error</title></head>
<body style="background:#000;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;">
<div style="text-align:center"><h1 style="color:#F5A623">404</h1><p>${message}</p></div>
</body></html>`;
}

export default app;
