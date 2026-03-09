-- BlackRoad Verification API - D1 Schema
-- Source reputation + verification cache + community reports

CREATE TABLE IF NOT EXISTS source_reputation (
  domain TEXT PRIMARY KEY,
  score REAL NOT NULL DEFAULT 0.5,
  category TEXT NOT NULL DEFAULT 'unknown',
  bias TEXT NOT NULL DEFAULT 'unknown',
  factual TEXT NOT NULL DEFAULT 'unknown',
  description TEXT,
  updated_at TEXT DEFAULT (datetime('now')),
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS verification_cache (
  url TEXT PRIMARY KEY,
  result_json TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS community_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  url TEXT NOT NULL,
  domain TEXT NOT NULL,
  claim_text TEXT,
  report_type TEXT NOT NULL,
  details TEXT,
  reporter_id TEXT DEFAULT 'anonymous',
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reports_domain ON community_reports(domain);
CREATE INDEX IF NOT EXISTS idx_reports_url ON community_reports(url);
CREATE INDEX IF NOT EXISTS idx_cache_created ON verification_cache(created_at);

-- Seed the source reputation database (same domains as Rust backend)

-- Academic & Research
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('arxiv.org', 0.95, 'academic', 'none', 'very-high'),
  ('scholar.google.com', 0.95, 'academic', 'none', 'very-high'),
  ('pubmed.ncbi.nlm.nih.gov', 0.95, 'academic', 'none', 'very-high'),
  ('jstor.org', 0.95, 'academic', 'none', 'very-high'),
  ('sciencedirect.com', 0.95, 'academic', 'none', 'very-high'),
  ('ieee.org', 0.95, 'academic', 'none', 'very-high'),
  ('acm.org', 0.95, 'academic', 'none', 'very-high'),
  ('researchgate.net', 0.95, 'academic', 'none', 'very-high');

-- Scientific Journals
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('nature.com', 0.96, 'journal', 'none', 'very-high'),
  ('science.org', 0.96, 'journal', 'none', 'very-high'),
  ('cell.com', 0.96, 'journal', 'none', 'very-high'),
  ('thelancet.com', 0.96, 'journal', 'none', 'very-high'),
  ('nejm.org', 0.96, 'journal', 'none', 'very-high'),
  ('bmj.com', 0.96, 'journal', 'none', 'very-high'),
  ('pnas.org', 0.96, 'journal', 'none', 'very-high'),
  ('plos.org', 0.96, 'journal', 'none', 'very-high');

-- Government
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('nasa.gov', 0.92, 'government', 'none', 'very-high'),
  ('nih.gov', 0.92, 'government', 'none', 'very-high'),
  ('cdc.gov', 0.92, 'government', 'none', 'very-high'),
  ('fda.gov', 0.92, 'government', 'none', 'very-high'),
  ('noaa.gov', 0.92, 'government', 'none', 'very-high'),
  ('census.gov', 0.92, 'government', 'none', 'very-high'),
  ('sec.gov', 0.92, 'government', 'none', 'very-high'),
  ('data.gov', 0.92, 'government', 'none', 'very-high');

-- Wire Services
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('apnews.com', 0.93, 'wire-service', 'center', 'very-high'),
  ('reuters.com', 0.93, 'wire-service', 'center', 'very-high'),
  ('afp.com', 0.91, 'wire-service', 'center', 'very-high');

-- Reference
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('wikipedia.org', 0.88, 'reference', 'none', 'high'),
  ('britannica.com', 0.88, 'reference', 'none', 'high'),
  ('who.int', 0.88, 'reference', 'none', 'high'),
  ('worldbank.org', 0.88, 'reference', 'none', 'high');

-- Fact-checking
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('snopes.com', 0.90, 'fact-check', 'center', 'very-high'),
  ('factcheck.org', 0.90, 'fact-check', 'center', 'very-high'),
  ('politifact.com', 0.90, 'fact-check', 'center', 'very-high'),
  ('fullfact.org', 0.90, 'fact-check', 'center', 'very-high');

-- Quality News
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('bbc.com', 0.85, 'news', 'center', 'high'),
  ('bbc.co.uk', 0.85, 'news', 'center', 'high'),
  ('npr.org', 0.84, 'news', 'center', 'high'),
  ('pbs.org', 0.84, 'news', 'center', 'high'),
  ('economist.com', 0.83, 'news', 'center', 'high'),
  ('bloomberg.com', 0.83, 'news', 'center', 'high'),
  ('ft.com', 0.83, 'news', 'center', 'high'),
  ('wsj.com', 0.82, 'news', 'center-right', 'high'),
  ('nytimes.com', 0.82, 'news', 'center-left', 'high'),
  ('washingtonpost.com', 0.81, 'news', 'center-left', 'high'),
  ('theguardian.com', 0.80, 'news', 'center-left', 'high'),
  ('propublica.org', 0.86, 'news', 'center-left', 'high');

-- Tech Docs
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('developer.mozilla.org', 0.85, 'tech-docs', 'none', 'high'),
  ('docs.python.org', 0.85, 'tech-docs', 'none', 'high'),
  ('docs.rust-lang.org', 0.85, 'tech-docs', 'none', 'high'),
  ('stackoverflow.com', 0.85, 'tech-docs', 'none', 'high');

-- Social Media (low trust)
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('twitter.com', 0.30, 'social', 'mixed', 'low'),
  ('x.com', 0.30, 'social', 'mixed', 'low'),
  ('facebook.com', 0.30, 'social', 'mixed', 'low'),
  ('instagram.com', 0.30, 'social', 'mixed', 'low'),
  ('tiktok.com', 0.30, 'social', 'mixed', 'low'),
  ('reddit.com', 0.30, 'social', 'mixed', 'low');

-- Known low credibility
INSERT OR IGNORE INTO source_reputation (domain, score, category, bias, factual) VALUES
  ('infowars.com', 0.15, 'low-credibility', 'extreme', 'very-low'),
  ('naturalnews.com', 0.15, 'low-credibility', 'extreme', 'very-low'),
  ('breitbart.com', 0.15, 'low-credibility', 'extreme', 'very-low'),
  ('dailymail.co.uk', 0.15, 'low-credibility', 'extreme', 'very-low');
