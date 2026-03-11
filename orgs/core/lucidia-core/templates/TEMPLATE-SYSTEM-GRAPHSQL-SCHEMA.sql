-- ============================================================================
-- BlackRoad OS Template System - GraphSQL Schema
-- Complete graph database schema for all 200+ templates
-- ============================================================================

-- ============================================================================
-- TEMPLATE 001: INFRA RUNBOOK / DEPLOY SCRIPT
-- ============================================================================

-- Main template structure (sections/blocks)
CREATE TABLE IF NOT EXISTS template_001_nodes (
  id        TEXT PRIMARY KEY,
  label     TEXT NOT NULL,
  kind      TEXT NOT NULL,         -- 'section', 'block', 'component'
  emoji     TEXT,                  -- Canonical emoji from EMOJI-REFERENCE.md
  description TEXT
);

CREATE TABLE IF NOT EXISTS template_001_edges (
  from_id   TEXT NOT NULL,
  to_id     TEXT NOT NULL,
  label     TEXT,                  -- 'flows_to', 'contains', 'depends_on'
  FOREIGN KEY (from_id) REFERENCES template_001_nodes(id),
  FOREIGN KEY (to_id)   REFERENCES template_001_nodes(id),
  PRIMARY KEY (from_id, to_id, label)
);

-- Template 001 nodes (sections)
INSERT OR REPLACE INTO template_001_nodes (id, label, kind, emoji, description) VALUES
  ('header',          'Header Bar',                      'section', '🛣',  'Title bar with context and system name'),
  ('context',         'Context Line (tools/env)',        'section', '⛅️', 'Tool versions, environment, region'),
  ('bindings_card',   'Worker / Service Bindings Card',  'block',   '📦', 'Resource bindings table'),
  ('infra_status',    'Infrastructure Status Card',      'block',   '📡', 'Status of all infrastructure resources'),
  ('steps_pipeline',  'Execute N Steps Pipeline',        'section', '🚀', 'Numbered deployment steps'),
  ('value_card',      'Value Delivered Card',            'block',   '💎', 'Cost vs value comparison'),
  ('docs_block',      'Documentation List',              'block',   '📚', 'Links to documentation files'),
  ('checklist_block', 'Checklist',                       'block',   '🗒', 'Manual verification checklist'),
  ('next_steps',      'Next Steps',                      'block',   '🎯', 'Post-deployment actions'),
  ('tips_block',      'Tips',                            'block',   '💡', 'Pro tips and best practices'),
  ('footer',          'Footer Strip (Epic Done)',        'section', '🔥', 'Summary celebration line');

-- Template 001 edges (flow order)
INSERT OR REPLACE INTO template_001_edges (from_id, to_id, label) VALUES
  ('header',         'context',        'flows_to'),
  ('context',        'bindings_card',  'flows_to'),
  ('bindings_card',  'infra_status',   'flows_to'),
  ('infra_status',   'steps_pipeline', 'flows_to'),
  ('steps_pipeline', 'value_card',     'flows_to'),
  ('value_card',     'docs_block',     'flows_to'),
  ('docs_block',     'checklist_block','flows_to'),
  ('checklist_block','next_steps',     'flows_to'),
  ('next_steps',     'tips_block',     'flows_to'),
  ('tips_block',     'footer',         'flows_to');

-- Template 001 step pipeline substructure
CREATE TABLE IF NOT EXISTS template_001_step_nodes (
  id        TEXT PRIMARY KEY,
  step_no   INTEGER NOT NULL,
  label     TEXT NOT NULL,
  emoji     TEXT DEFAULT '▶️',
  command   TEXT                   -- Optional: the actual command to run
);

CREATE TABLE IF NOT EXISTS template_001_step_edges (
  from_id   TEXT NOT NULL,
  to_id     TEXT NOT NULL,
  label     TEXT DEFAULT 'next',
  FOREIGN KEY (from_id) REFERENCES template_001_step_nodes(id),
  FOREIGN KEY (to_id)   REFERENCES template_001_step_nodes(id),
  PRIMARY KEY (from_id, to_id)
);

INSERT OR REPLACE INTO template_001_step_nodes (id, step_no, label, emoji) VALUES
  ('step_1', 1, 'Step 1: <STEP_TITLE_1>', '🚀'),
  ('step_2', 2, 'Step 2: <STEP_TITLE_2>', '🔄'),
  ('step_3', 3, 'Step 3: <STEP_TITLE_3>', '📥'),
  ('step_n', 4, 'Step N: <FINAL_STEP_TITLE>', '✅');

INSERT OR REPLACE INTO template_001_step_edges (from_id, to_id, label) VALUES
  ('step_1', 'step_2', 'next'),
  ('step_2', 'step_3', 'next'),
  ('step_3', 'step_n', 'next');

-- ============================================================================
-- TEMPLATE 002: ARCHITECTURE / SYSTEM OVERVIEW
-- ============================================================================

CREATE TABLE IF NOT EXISTS template_002_nodes (
  id        TEXT PRIMARY KEY,
  label     TEXT NOT NULL,
  kind      TEXT NOT NULL,        -- 'section', 'diagram', 'component'
  emoji     TEXT,
  description TEXT
);

CREATE TABLE IF NOT EXISTS template_002_edges (
  from_id   TEXT NOT NULL,
  to_id     TEXT NOT NULL,
  label     TEXT,
  FOREIGN KEY (from_id) REFERENCES template_002_nodes(id),
  FOREIGN KEY (to_id)   REFERENCES template_002_nodes(id),
  PRIMARY KEY (from_id, to_id, label)
);

-- Template 002 top-level sections
INSERT OR REPLACE INTO template_002_nodes (id, label, kind, emoji, description) VALUES
  ('header',          'Header Bar',                        'section', '🛣', 'System name and context'),
  ('overview',        'Overview',                          'section', '🧭', 'What the system is and does'),
  ('diagram',         'High-Level System Diagram',         'diagram', '🏗', 'ASCII diagram of system topology'),
  ('components',      'Component Breakdown',               'section', '📦', 'Detailed component descriptions'),
  ('flows',           'Request / Data Flows',              'section', '👉', 'Numbered data flow diagrams'),
  ('non_functional',  'Reliability / Security / Limits',   'section', '🔐', 'Non-functional requirements'),
  ('operations',      'Operations: Deploy / Observe / Debug','section', '🧰', 'Operational procedures'),
  ('docs_block',      'Documentation & References',        'section', '📚', 'Links to related docs'),
  ('checklist_block', 'Checklists',                        'block',   '🗒', 'Verification checklists'),
  ('next_steps',      'Next Steps',                        'block',   '🎯', 'What to do next'),
  ('tips_block',      'Tips',                              'block',   '💡', 'Pro tips and gotchas');

-- Template 002 linear reading order
INSERT OR REPLACE INTO template_002_edges (from_id, to_id, label) VALUES
  ('header',         'overview',        'flows_to'),
  ('overview',       'diagram',         'flows_to'),
  ('diagram',        'components',      'flows_to'),
  ('components',     'flows',           'flows_to'),
  ('flows',          'non_functional',  'flows_to'),
  ('non_functional', 'operations',      'flows_to'),
  ('operations',     'docs_block',      'flows_to'),
  ('docs_block',     'checklist_block', 'flows_to'),
  ('checklist_block','next_steps',      'flows_to'),
  ('next_steps',     'tips_block',      'flows_to');

-- Template 002 component nodes (system architecture components)
CREATE TABLE IF NOT EXISTS template_002_component_nodes (
  id         TEXT PRIMARY KEY,
  label      TEXT NOT NULL,
  kind       TEXT NOT NULL,       -- 'user', 'edge', 'service', 'data', 'integration'
  emoji      TEXT,
  description TEXT,
  tech_stack TEXT                 -- e.g. "Cloudflare Workers", "Flask + Python", "D1 SQLite"
);

CREATE TABLE IF NOT EXISTS template_002_component_edges (
  from_id    TEXT NOT NULL,
  to_id      TEXT NOT NULL,
  label      TEXT,                -- 'https_request', 'route_api', 'reads_writes', etc.
  protocol   TEXT,                -- 'HTTPS', 'WebSocket', 'Queue', 'gRPC', etc.
  FOREIGN KEY (from_id) REFERENCES template_002_component_nodes(id),
  FOREIGN KEY (to_id)   REFERENCES template_002_component_nodes(id),
  PRIMARY KEY (from_id, to_id, label)
);

INSERT OR REPLACE INTO template_002_component_nodes (id, label, kind, emoji, description) VALUES
  ('user',       'Users / Clients',            'user',        '👤', 'End users and API clients'),
  ('edge',       'Edge / Gateway (Cloudflare)','edge',        '⛅️', 'CDN and routing layer'),
  ('service_a',  'Service A (Core API)',       'service',     '🛰', 'Main API service'),
  ('service_b',  'Service B (Web / UI)',       'service',     '🖥', 'Web frontend / dashboard'),
  ('db_layer',   'Databases',                  'data',        '🧱', 'Persistent data storage'),
  ('queue_layer','Queues',                     'data',        '📨', 'Message queues for async jobs'),
  ('storage',    'Object / KV Storage',        'data',        '🗂', 'File and key-value storage'),
  ('integrations','External Integrations',     'integration', '🧩', 'Third-party services');

INSERT OR REPLACE INTO template_002_component_edges (from_id, to_id, label, protocol) VALUES
  ('user',        'edge',        'https_request',  'HTTPS'),
  ('edge',        'service_a',   'route_api',      'HTTPS'),
  ('edge',        'service_b',   'route_web',      'HTTPS'),
  ('service_a',   'db_layer',    'reads_writes',   'SQL'),
  ('service_a',   'queue_layer', 'enqueue_jobs',   'Queue'),
  ('service_a',   'storage',     'store_assets',   'HTTP'),
  ('service_b',   'service_a',   'api_calls',      'HTTPS'),
  ('service_a',   'integrations','external_calls', 'HTTPS');

-- ============================================================================
-- TEMPLATE 003: DOMAIN / DNS / ROUTING MAP
-- For 16 domains × 364 subdomains = 5,216 total sites
-- ============================================================================

CREATE TABLE IF NOT EXISTS template_003_domain_nodes (
  id              TEXT PRIMARY KEY,
  domain          TEXT NOT NULL UNIQUE,
  emoji           TEXT DEFAULT '🌐',
  purpose         TEXT,
  status          TEXT DEFAULT 'active',     -- 'active', 'pending', 'inactive'
  cloudflare_zone TEXT,                      -- Cloudflare Zone ID
  subdomain_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS template_003_subdomain_nodes (
  id          TEXT PRIMARY KEY,
  subdomain   TEXT NOT NULL,
  domain_id   TEXT NOT NULL,
  full_url    TEXT NOT NULL,
  emoji       TEXT,
  category    TEXT,                         -- 'api', 'dashboard', 'docs', 'auth', etc.
  backend     TEXT,                         -- Railway service, Worker, etc.
  status      TEXT DEFAULT 'pending',       -- 'live', 'pending', 'failed'
  FOREIGN KEY (domain_id) REFERENCES template_003_domain_nodes(id)
);

CREATE TABLE IF NOT EXISTS template_003_routing_edges (
  from_id     TEXT NOT NULL,
  to_id       TEXT NOT NULL,
  route_type  TEXT,                         -- 'dns', 'worker_route', 'service_route'
  priority    INTEGER DEFAULT 100,
  FOREIGN KEY (from_id) REFERENCES template_003_subdomain_nodes(id),
  PRIMARY KEY (from_id, to_id)
);

-- 16 primary domains
INSERT OR REPLACE INTO template_003_domain_nodes (id, domain, emoji, purpose, subdomain_count) VALUES
  ('blackroad-io',         'blackroad.io',         '🛣', 'Main platform', 364),
  ('lucidia-earth',        'lucidia.earth',        '🔮', 'Lucidia OS', 364),
  ('blackroadai-com',      'blackroadai.com',      '🤖', 'AI services', 364),
  ('blackroadquantum-com', 'blackroadquantum.com', '⚛️', 'Quantum computing', 364),
  ('blackroad-network',    'blackroad.network',    '📡', 'Network services', 364),
  ('blackroad-systems',    'blackroad.systems',    '🏗', 'System services', 364),
  ('blackroad-me',         'blackroad.me',         '👤', 'Personal brand', 364),
  ('blackroadinc-us',      'blackroad-inc.us',     '🏢', 'Corporate entity', 364),
  ('aliceqi-com',          'aliceqi.com',          '👩‍💻', 'Alice Qi brand', 364),
  ('blackroadqi-com',      'blackroadqi.com',      '🧠', 'Quantum intelligence', 364),
  ('lucidiaqi-com',        'lucidiaqi.com',        '💎', 'Lucidia intelligence', 364),
  ('lucidiastud-io',       'lucidiastud.io',       '🎨', 'Lucidia studio', 364),
  ('blackroadquantum-info','blackroadquantum.info','ℹ️', 'Quantum info', 364),
  ('blackroadquantum-net', 'blackroadquantum.net', '🖧', 'Quantum network', 364),
  ('blackroadquantum-shop','blackroadquantum.shop','🛒', 'Quantum shop', 364),
  ('blackroadquantum-store','blackroadquantum.store','🏪', 'Quantum store', 364);

-- Example subdomains for blackroad.io (would be 364 total)
INSERT OR REPLACE INTO template_003_subdomain_nodes (id, subdomain, domain_id, full_url, emoji, category, status) VALUES
  ('blackroad-io-api',       'api',       'blackroad-io', 'https://api.blackroad.io',       '🔌', 'api',       'live'),
  ('blackroad-io-dashboard', 'dashboard', 'blackroad-io', 'https://dashboard.blackroad.io', '📊', 'dashboard', 'live'),
  ('blackroad-io-docs',      'docs',      'blackroad-io', 'https://docs.blackroad.io',      '📚', 'docs',      'live'),
  ('blackroad-io-auth',      'auth',      'blackroad-io', 'https://auth.blackroad.io',      '🔐', 'auth',      'live'),
  ('blackroad-io-payment',   'payment',   'blackroad-io', 'https://payment.blackroad.io',   '💳', 'payment',   'live'),
  ('blackroad-io-agents',    'agents',    'blackroad-io', 'https://agents.blackroad.io',    '🤖', 'agents',    'live'),
  ('blackroad-io-quantum',   'quantum',   'blackroad-io', 'https://quantum.blackroad.io',   '⚛️', 'quantum',   'live'),
  ('blackroad-io-vector',    'vector',    'blackroad-io', 'https://vector.blackroad.io',    '🧬', 'data',      'live'),
  ('blackroad-io-stream',    'stream',    'blackroad-io', 'https://stream.blackroad.io',    '📡', 'data',      'live'),
  ('blackroad-io-mq',        'mq',        'blackroad-io', 'https://mq.blackroad.io',        '📨', 'data',      'live');

-- ============================================================================
-- MASTER TEMPLATE CATALOG
-- All 200+ templates with metadata
-- ============================================================================

CREATE TABLE IF NOT EXISTS template_catalog (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  category        TEXT NOT NULL,     -- 'core', 'cloudflare', 'railway', 'google-drive', etc.
  type            TEXT NOT NULL,     -- 'document', 'code', 'config', 'script'
  file_path       TEXT NOT NULL,
  emoji           TEXT,
  description     TEXT,
  variables       TEXT,              -- JSON array of variable placeholders
  usage_count     INTEGER DEFAULT 0,
  last_used       TIMESTAMP,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS template_dependencies (
  template_id     TEXT NOT NULL,
  depends_on      TEXT NOT NULL,
  dependency_type TEXT,              -- 'requires', 'extends', 'includes'
  FOREIGN KEY (template_id) REFERENCES template_catalog(id),
  FOREIGN KEY (depends_on)  REFERENCES template_catalog(id),
  PRIMARY KEY (template_id, depends_on)
);

-- Core templates
INSERT OR REPLACE INTO template_catalog (id, name, category, type, file_path, emoji, description) VALUES
  ('T001', 'Infra Runbook / Deploy Script',    'core', 'document', 'TEMPLATE-001-INFRA-RUNBOOK.md',        '🚀', 'Deployment runbook template'),
  ('T002', 'Architecture / System Overview',   'core', 'document', 'TEMPLATE-002-ARCHITECTURE-OVERVIEW.md', '🏗', 'System architecture template'),
  ('T003', 'Domain / DNS / Routing Map',       'core', 'document', 'TEMPLATE-003-DOMAIN-DNS-ROUTING.md',    '🌐', 'DNS routing configuration'),
  ('T004', 'README',                            'core', 'document', 'TEMPLATE-004-README.md',                '📖', 'Perfect repository README'),
  ('T005', 'Changelog',                         'core', 'document', 'TEMPLATE-005-CHANGELOG.md',             '📝', 'Semantic versioning changelog');

-- Cloudflare templates
INSERT OR REPLACE INTO template_catalog (id, name, category, type, file_path, emoji, description) VALUES
  ('CF01', 'Worker API',                        'cloudflare', 'code',   'cloudflare/TEMPLATE-WORKER-API.js',      '⛅️', 'REST API Worker'),
  ('CF02', 'Worker Auth',                       'cloudflare', 'code',   'cloudflare/TEMPLATE-WORKER-AUTH.js',     '🔐', 'Authentication Worker'),
  ('CF03', 'Worker Router',                     'cloudflare', 'code',   'cloudflare/TEMPLATE-WORKER-ROUTER.js',   '🔀', 'Subdomain router'),
  ('CF04', 'Pages Landing',                     'cloudflare', 'code',   'cloudflare/TEMPLATE-PAGES-LANDING.html', '🌐', 'Landing page template'),
  ('CF05', 'Wrangler Config',                   'cloudflare', 'config', 'cloudflare/TEMPLATE-WRANGLER.toml',      '🔧', 'Worker deployment config');

-- Google Drive templates
INSERT OR REPLACE INTO template_catalog (id, name, category, type, file_path, emoji, description) VALUES
  ('GD01', 'Project Structure',                'google-drive', 'document', 'google-drive/PROJECT-STRUCTURE-TEMPLATE.json',      '📁', 'Complete project folder'),
  ('GD02', 'Technical Spec',                   'google-drive', 'document', 'google-drive/TEMPLATE-DOC-TECHNICAL-SPEC.json',    '📘', 'Technical specification'),
  ('GD03', 'User Guide',                       'google-drive', 'document', 'google-drive/TEMPLATE-DOC-USER-GUIDE.json',        '📙', 'User documentation'),
  ('GD04', 'Meeting Notes',                    'google-drive', 'document', 'google-drive/TEMPLATE-DOC-MEETING-NOTES.json',     '📝', 'Meeting notes template');

-- Notion templates
INSERT OR REPLACE INTO template_catalog (id, name, category, type, file_path, emoji, description) VALUES
  ('N001', 'Project Dashboard',                'notion', 'document', 'notion/TEMPLATE-DASHBOARD-PROJECT.json',     '📊', 'Project management dashboard'),
  ('N002', 'Tasks Database',                   'notion', 'document', 'notion/TEMPLATE-DATABASE-TASKS.json',        '📋', 'Task tracking database'),
  ('N003', 'Agent Profile',                    'notion', 'document', 'notion/TEMPLATE-PAGE-AGENT-PROFILE.json',    '🤖', 'Agent documentation page');

-- GitHub templates
INSERT OR REPLACE INTO template_catalog (id, name, category, type, file_path, emoji, description) VALUES
  ('GH01', 'Bug Report',                       'github', 'document', 'github/ISSUE_TEMPLATE/bug_report.md',        '🐛', 'Bug report issue template'),
  ('GH02', 'Feature Request',                  'github', 'document', 'github/ISSUE_TEMPLATE/feature_request.md',   '✨', 'Feature request template'),
  ('GH03', 'Pull Request',                     'github', 'document', 'github/PULL_REQUEST_TEMPLATE.md',            '📥', 'PR template with checklist');

-- Airtable templates
INSERT OR REPLACE INTO template_catalog (id, name, category, type, file_path, emoji, description) VALUES
  ('AT01', 'CRM Complete',                     'airtable', 'document', 'airtable/TEMPLATE-CRM-COMPLETE.json',      '🗂', 'Full CRM base with tables');

-- ============================================================================
-- EMOJI REFERENCE TABLE
-- All 127 canonical emojis from EMOJI-REFERENCE.md
-- ============================================================================

CREATE TABLE IF NOT EXISTS emoji_reference (
  emoji       TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  category    TEXT NOT NULL,      -- From 1-10 categories
  meaning     TEXT NOT NULL,
  usage       TEXT NOT NULL
);

-- Layout & Pointers (23)
INSERT OR REPLACE INTO emoji_reference (emoji, name, category, meaning, usage) VALUES
  ('👉', 'Main pointer',     'Layout & Pointers', 'Call out important line/choice', 'Highlight key information'),
  ('➡️', 'Next/forward',     'Layout & Pointers', 'Move to next step', 'Sequential flow'),
  ('⬅️', 'Back/previous',    'Layout & Pointers', 'Rollback step, go back', 'Reverse flow'),
  ('↗️', 'Escalate',         'Layout & Pointers', 'Scale up resources', 'Increase capacity'),
  ('↘️', 'De-escalate',      'Layout & Pointers', 'Scale down resources', 'Decrease capacity'),
  ('🔁', 'Loop/repeat',      'Layout & Pointers', 'Repeat step/cron-like', 'Cyclic operation'),
  ('➕', 'Add',              'Layout & Pointers', 'Create resource, add config', 'Addition'),
  ('➖', 'Remove',           'Layout & Pointers', 'Remove resource, subtract', 'Deletion');

-- Context / Platform (17)
INSERT OR REPLACE INTO emoji_reference (emoji, name, category, meaning, usage) VALUES
  ('⛅️', 'Cloudflare',       'Context / Platform', 'Workers, R2, D1, Wrangler', 'Cloudflare context'),
  ('☁️', 'Generic cloud',    'Context / Platform', 'AWS, GCP, etc.', 'Cloud platform'),
  ('💻', 'Dev machine/local','Context / Platform', 'Local dev, CLI tooling', 'Local environment'),
  ('🛣', 'BlackRoad OS',     'Context / Platform', 'Cross-system/orchestration', 'BlackRoad system'),
  ('📱', 'Mobile',           'Context / Platform', 'iOS/Android/TestFlight', 'Mobile app'),
  ('🖥', 'Web app',          'Context / Platform', 'Dashboards, web frontends', 'Web application'),
  ('🌐', 'DNS/domains',      'Context / Platform', 'Domains, subdomains, routing', 'DNS configuration'),
  ('💳', 'Payments',         'Context / Platform', 'Stripe, billing flows', 'Payment system'),
  ('🔐', 'Security/auth',    'Context / Platform', 'Secrets, auth, lock-down', 'Security');

-- Actions (17)
INSERT OR REPLACE INTO emoji_reference (emoji, name, category, meaning, usage) VALUES
  ('🚀', 'Deploy/launch',    'Actions', 'Ship to environment', 'Deployment'),
  ('▶️', 'Run',              'Actions', 'Run script/command/job', 'Execution'),
  ('⏹', 'Stop',             'Actions', 'Stop process/kill job', 'Termination'),
  ('🔄', 'Sync',             'Actions', 'Refresh state, pull latest', 'Synchronization'),
  ('♻️', 'Redeploy',         'Actions', 'Recreate with same config', 'Redeployment'),
  ('📥', 'Import',           'Actions', 'Ingest configs/data/DNS', 'Import operation'),
  ('📤', 'Export',           'Actions', 'Backup, snapshot, archive', 'Export operation'),
  ('🔧', 'Configure',        'Actions', 'Change config, settings', 'Configuration'),
  ('🪛', 'Fix',              'Actions', 'Small targeted fix, patch', 'Bug fix');

-- Status / Severity (13)
INSERT OR REPLACE INTO emoji_reference (emoji, name, category, meaning, usage) VALUES
  ('✅', 'OK/done',          'Status / Severity', 'Succeeded, safe, verified', 'Success state'),
  ('☐', 'Todo',             'Status / Severity', 'Manual step remaining', 'Pending task'),
  ('⏳', 'Pending',          'Status / Severity', 'Waiting, in progress', 'In progress'),
  ('⚠️', 'Warning',          'Status / Severity', 'Non-fatal, needs attention', 'Warning state'),
  ('❌', 'Error',            'Status / Severity', 'Failed, stop here', 'Error state'),
  ('🚨', 'Incident',         'Status / Severity', 'On-fire, high severity', 'Critical issue'),
  ('🔍', 'Investigate',      'Status / Severity', 'Look closer/drill in', 'Investigation');

-- Resources & Infra (17)
INSERT OR REPLACE INTO emoji_reference (emoji, name, category, meaning, usage) VALUES
  ('📦', 'Package/artifact', 'Resources & Infra', 'Worker script, bundle, container', 'Artifact'),
  ('📁', 'Folder/repo',      'Resources & Infra', 'GitHub repo, directory', 'Repository'),
  ('🧱', 'Database',         'Resources & Infra', 'D1 tables, infra blocks', 'Database'),
  ('🤖', 'AI service/model', 'Resources & Infra', 'LLMs, agents, AI API', 'AI system'),
  ('🛰', 'Service',          'Resources & Infra', 'Satellite services', 'Microservice'),
  ('🧩', 'Integration',      'Resources & Infra', 'Stripe, Clerk, 3rd-party', 'Integration'),
  ('📜', 'Schema/contract',  'Resources & Infra', 'API schema, DB schema', 'Schema'),
  ('🔑', 'Secrets store',    'Resources & Infra', 'Env vars, secret manager', 'Secrets');

-- Docs & Learning (10)
INSERT OR REPLACE INTO emoji_reference (emoji, name, category, meaning, usage) VALUES
  ('📚', 'Reference docs',   'Docs & Learning', 'Full guides, manuals', 'Documentation'),
  ('📖', 'Reading view',     'Docs & Learning', '"Start here" explanations', 'Overview'),
  ('📘', 'API docs',         'Docs & Learning', 'Technical reference', 'API reference'),
  ('📙', 'How-to guide',     'Docs & Learning', 'Step-by-step walkthroughs', 'Tutorial'),
  ('📝', 'Notes/summary',    'Docs & Learning', 'Short summaries, quick notes', 'Notes'),
  ('🗒', 'Checklist',        'Docs & Learning', 'Deployment/verification checklist', 'Checklist'),
  ('💡', 'Tip/insight',      'Docs & Learning', 'Pro tips, best practice', 'Tip');

-- Meta / Vibe (7)
INSERT OR REPLACE INTO emoji_reference (emoji, name, category, meaning, usage) VALUES
  ('✨', 'Magic/delightful', 'Meta / Vibe', '"This feels special"', 'Delight'),
  ('🔥', 'Epic done',        'Meta / Vibe', 'Whole system wired, big milestone', 'Achievement'),
  ('💎', 'Premium/value',    'Meta / Vibe', '"Worth $$"', 'Value'),
  ('🎉', 'Celebration',      'Meta / Vibe', 'Success, done, confetti', 'Celebration'),
  ('🧠', 'Learning',         'Meta / Vibe', 'Philosophy, patterns, mental models', 'Knowledge'),
  ('🔮', 'Vision/future',    'Meta / Vibe', 'Roadmap, speculative ideas', 'Vision');

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- All templates by category
CREATE VIEW IF NOT EXISTS templates_by_category AS
SELECT category, COUNT(*) as template_count, GROUP_CONCAT(emoji) as emojis
FROM template_catalog
GROUP BY category
ORDER BY template_count DESC;

-- Most used templates
CREATE VIEW IF NOT EXISTS most_used_templates AS
SELECT id, name, category, emoji, usage_count, last_used
FROM template_catalog
WHERE usage_count > 0
ORDER BY usage_count DESC
LIMIT 10;

-- Template dependency graph
CREATE VIEW IF NOT EXISTS template_dependency_graph AS
SELECT
  t1.name as template,
  t1.emoji as template_emoji,
  t2.name as depends_on,
  t2.emoji as depends_on_emoji,
  td.dependency_type
FROM template_dependencies td
JOIN template_catalog t1 ON td.template_id = t1.id
JOIN template_catalog t2 ON td.depends_on = t2.id;

-- Domain statistics
CREATE VIEW IF NOT EXISTS domain_stats AS
SELECT
  domain,
  emoji,
  purpose,
  status,
  subdomain_count,
  (SELECT COUNT(*) FROM template_003_subdomain_nodes WHERE domain_id = template_003_domain_nodes.id AND status = 'live') as live_subdomains,
  (SELECT COUNT(*) FROM template_003_subdomain_nodes WHERE domain_id = template_003_domain_nodes.id AND status = 'pending') as pending_subdomains
FROM template_003_domain_nodes
ORDER BY live_subdomains DESC;

-- ============================================================================
-- EXAMPLE QUERIES
-- ============================================================================

-- Get all templates for a specific category
-- SELECT * FROM template_catalog WHERE category = 'cloudflare';

-- Get the flow structure of Template 001
-- SELECT t1.label as from_section, t2.label as to_section, e.label as relationship
-- FROM template_001_edges e
-- JOIN template_001_nodes t1 ON e.from_id = t1.id
-- JOIN template_001_nodes t2 ON e.to_id = t2.id;

-- Get all subdomains for a domain
-- SELECT subdomain, full_url, emoji, category, status
-- FROM template_003_subdomain_nodes
-- WHERE domain_id = 'blackroad-io'
-- ORDER BY category, subdomain;

-- Get component connections in architecture
-- SELECT c1.label as from_component, c2.label as to_component, e.label as connection, e.protocol
-- FROM template_002_component_edges e
-- JOIN template_002_component_nodes c1 ON e.from_id = c1.id
-- JOIN template_002_component_nodes c2 ON e.to_id = c2.id;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

-- Summary statistics
SELECT '✅ GraphSQL Schema Complete!' as status;
SELECT COUNT(*) || ' templates cataloged' as template_count FROM template_catalog;
SELECT COUNT(*) || ' domains configured' as domain_count FROM template_003_domain_nodes;
SELECT COUNT(*) || ' emojis defined' as emoji_count FROM emoji_reference;
