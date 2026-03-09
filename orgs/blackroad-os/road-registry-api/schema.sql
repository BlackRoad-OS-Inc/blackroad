-- BlackRoad Domain Registry Database Schema

CREATE DATABASE IF NOT EXISTS road_registry;

\c road_registry;

-- Domains table
CREATE TABLE IF NOT EXISTS domains (
  id UUID PRIMARY KEY,
  domain VARCHAR(255) UNIQUE NOT NULL,
  registrar VARCHAR(100),
  registered_at TIMESTAMP,
  expires_at TIMESTAMP,
  nameservers TEXT[],
  status VARCHAR(50) DEFAULT 'active',
  owner_email VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_domains_domain ON domains(domain);
CREATE INDEX idx_domains_status ON domains(status);

-- DNS Records table
CREATE TABLE IF NOT EXISTS dns_records (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  record_type VARCHAR(10) NOT NULL,  -- A, AAAA, CNAME, MX, TXT, NS, SOA, etc.
  name VARCHAR(255) NOT NULL,
  value TEXT NOT NULL,
  ttl INTEGER DEFAULT 3600,
  priority INTEGER,  -- For MX records
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_dns_records_domain_id ON dns_records(domain_id);
CREATE INDEX idx_dns_records_type ON dns_records(record_type);
CREATE INDEX idx_dns_records_name ON dns_records(name);

-- Deployments table
CREATE TABLE IF NOT EXISTS deployments (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  repo_url VARCHAR(500) NOT NULL,
  branch VARCHAR(100) DEFAULT 'main',
  build_command TEXT,
  deploy_path VARCHAR(500),
  status VARCHAR(50) DEFAULT 'pending',  -- pending, building, deployed, failed
  build_log TEXT,
  deployed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_deployments_domain_id ON deployments(domain_id);
CREATE INDEX idx_deployments_status ON deployments(status);
CREATE INDEX idx_deployments_deployed_at ON deployments(deployed_at DESC);

-- SSL Certificates table
CREATE TABLE IF NOT EXISTS ssl_certificates (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  certificate_path VARCHAR(500),
  private_key_path VARCHAR(500),
  chain_path VARCHAR(500),
  issuer VARCHAR(255) DEFAULT 'Let''s Encrypt',
  issued_at TIMESTAMP,
  expires_at TIMESTAMP,
  auto_renew BOOLEAN DEFAULT true,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ssl_domain_id ON ssl_certificates(domain_id);
CREATE INDEX idx_ssl_expires ON ssl_certificates(expires_at);

-- Domain Analytics table
CREATE TABLE IF NOT EXISTS domain_analytics (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  requests INTEGER DEFAULT 0,
  bytes_sent BIGINT DEFAULT 0,
  unique_visitors INTEGER DEFAULT 0,
  status_2xx INTEGER DEFAULT 0,
  status_3xx INTEGER DEFAULT 0,
  status_4xx INTEGER DEFAULT 0,
  status_5xx INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_domain_date ON domain_analytics(domain_id, date DESC);

-- API Keys table (for road-registry-api authentication)
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY,
  key_name VARCHAR(255) NOT NULL,
  key_hash VARCHAR(255) UNIQUE NOT NULL,
  permissions TEXT[],
  created_by VARCHAR(255),
  last_used_at TIMESTAMP,
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);

-- Insert default data
INSERT INTO domains (id, domain, registrar, nameservers, status, owner_email)
VALUES (
  gen_random_uuid(),
  'blackroad.io',
  'GoDaddy',
  ARRAY['ns1.blackroad.io', 'ns2.blackroad.io'],
  'active',
  'admin@blackroad.io'
) ON CONFLICT (domain) DO NOTHING;

-- Grant permissions
-- CREATE USER IF NOT EXISTS roaduser WITH PASSWORD 'blackroad2026';
-- GRANT ALL PRIVILEGES ON DATABASE road_registry TO roaduser;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO roaduser;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO roaduser;
