-- PowerDNS PostgreSQL Schema
-- This initializes the database for PowerDNS Authoritative Server

CREATE TABLE domains (
  id                    SERIAL PRIMARY KEY,
  name                  VARCHAR(255) NOT NULL,
  master                VARCHAR(128) DEFAULT NULL,
  last_check            INT DEFAULT NULL,
  type                  VARCHAR(6) NOT NULL,
  notified_serial       BIGINT DEFAULT NULL,
  account               VARCHAR(40) DEFAULT NULL,
  CONSTRAINT c_lowercase_name CHECK (((name)::TEXT = LOWER((name)::TEXT)))
);

CREATE UNIQUE INDEX name_index ON domains(name);

CREATE TABLE records (
  id                    SERIAL PRIMARY KEY,
  domain_id             INT DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) DEFAULT NULL,
  content               VARCHAR(65535) DEFAULT NULL,
  ttl                   INT DEFAULT NULL,
  prio                  INT DEFAULT NULL,
  disabled              BOOL DEFAULT 'f',
  ordername             VARCHAR(255),
  auth                  BOOL DEFAULT 't',
  CONSTRAINT domain_exists FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE,
  CONSTRAINT c_lowercase_name CHECK (((name)::TEXT = LOWER((name)::TEXT)))
);

CREATE INDEX rec_name_index ON records(name);
CREATE INDEX nametype_index ON records(name,type);
CREATE INDEX domain_id ON records(domain_id);
CREATE INDEX orderindex ON records(ordername);

CREATE TABLE supermasters (
  ip                    INET NOT NULL,
  nameserver            VARCHAR(255) NOT NULL,
  account               VARCHAR(40) NOT NULL,
  PRIMARY KEY(ip, nameserver)
);

CREATE TABLE comments (
  id                    SERIAL PRIMARY KEY,
  domain_id             INT NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  type                  VARCHAR(10) NOT NULL,
  modified_at           INT NOT NULL,
  account               VARCHAR(40) DEFAULT NULL,
  comment               VARCHAR(65535) NOT NULL,
  CONSTRAINT domain_exists FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE,
  CONSTRAINT c_lowercase_name CHECK (((name)::TEXT = LOWER((name)::TEXT)))
);

CREATE INDEX comments_domain_id_idx ON comments(domain_id);
CREATE INDEX comments_name_type_idx ON comments(name, type);
CREATE INDEX comments_order_idx ON comments(domain_id, modified_at);

CREATE TABLE domainmetadata (
  id                    SERIAL PRIMARY KEY,
  domain_id             INT REFERENCES domains(id) ON DELETE CASCADE,
  kind                  VARCHAR(32),
  content               TEXT
);

CREATE INDEX domainmetadata_idx ON domainmetadata(domain_id, kind);

CREATE TABLE cryptokeys (
  id                    SERIAL PRIMARY KEY,
  domain_id             INT REFERENCES domains(id) ON DELETE CASCADE,
  flags                 INT NOT NULL,
  active                BOOL,
  published             BOOL,
  content               TEXT
);

CREATE INDEX domainidindex ON cryptokeys(domain_id);

CREATE TABLE tsigkeys (
  id                    SERIAL PRIMARY KEY,
  name                  VARCHAR(255),
  algorithm             VARCHAR(50),
  secret                VARCHAR(255),
  CONSTRAINT c_lowercase_name CHECK (((name)::TEXT = LOWER((name)::TEXT)))
);

CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm);

-- Insert initial blackroad.io zone
INSERT INTO domains (name, type) VALUES ('blackroad.io', 'NATIVE');

-- Get the domain ID (will be 1 for first insert)
DO $$
DECLARE
  domain_id INT;
BEGIN
  SELECT id INTO domain_id FROM domains WHERE name = 'blackroad.io';

  -- Insert SOA record
  INSERT INTO records (domain_id, name, type, content, ttl, prio) VALUES
    (domain_id, 'blackroad.io', 'SOA', 'ns1.blackroad.io admin.blackroad.io 2026010901 3600 1800 604800 3600', 3600, NULL);

  -- Insert NS records
  INSERT INTO records (domain_id, name, type, content, ttl, prio) VALUES
    (domain_id, 'blackroad.io', 'NS', 'ns1.blackroad.io', 3600, NULL),
    (domain_id, 'blackroad.io', 'NS', 'ns2.blackroad.io', 3600, NULL);

  -- Insert A records for nameservers (lucidia IP)
  INSERT INTO records (domain_id, name, type, content, ttl, prio) VALUES
    (domain_id, 'ns1.blackroad.io', 'A', '192.168.4.38', 3600, NULL),
    (domain_id, 'ns2.blackroad.io', 'A', '192.168.4.38', 3600, NULL);

  -- Insert A record for root domain (aria IP)
  INSERT INTO records (domain_id, name, type, content, ttl, prio) VALUES
    (domain_id, 'blackroad.io', 'A', '192.168.4.82', 3600, NULL);

  -- Insert A record for www (aria IP)
  INSERT INTO records (domain_id, name, type, content, ttl, prio) VALUES
    (domain_id, 'www.blackroad.io', 'A', '192.168.4.82', 3600, NULL);
END $$;

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO pdns;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO pdns;
