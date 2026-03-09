-- BLACKROAD D1 Database Schema
-- Stores memory entries, agent data, tasks, and messaging

-- Memory entries table (main journal)
CREATE TABLE IF NOT EXISTS memory_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    action TEXT NOT NULL,
    entity TEXT NOT NULL,
    details TEXT,
    session_id TEXT NOT NULL,
    namespace TEXT,
    verification_hash TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_memory_timestamp ON memory_entries(timestamp DESC);
CREATE INDEX idx_memory_action ON memory_entries(action);
CREATE INDEX idx_memory_session ON memory_entries(session_id);
CREATE INDEX idx_memory_namespace ON memory_entries(namespace);

-- Agent registry
CREATE TABLE IF NOT EXISTS agents (
    agent_hash TEXT PRIMARY KEY,
    first_seen DATETIME NOT NULL,
    last_active DATETIME NOT NULL,
    total_score INTEGER DEFAULT 0,
    rank INTEGER DEFAULT 0,
    metadata TEXT -- JSON blob
);

CREATE INDEX idx_agents_rank ON agents(rank);
CREATE INDEX idx_agents_score ON agents(total_score DESC);

-- Bot connections
CREATE TABLE IF NOT EXISTS bot_connections (
    connection_id TEXT PRIMARY KEY,
    agent_hash TEXT NOT NULL,
    bot_type TEXT NOT NULL,
    config TEXT, -- JSON blob
    connected_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_activity DATETIME,
    FOREIGN KEY (agent_hash) REFERENCES agents(agent_hash)
);

CREATE INDEX idx_bots_agent ON bot_connections(agent_hash);
CREATE INDEX idx_bots_type ON bot_connections(bot_type);

-- Tasks (marketplace + infinite todos)
CREATE TABLE IF NOT EXISTS tasks (
    task_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending', -- pending, in_progress, completed
    priority TEXT DEFAULT 'normal', -- low, normal, high, urgent
    claimed_by TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    claimed_at DATETIME,
    completed_at DATETIME,
    tags TEXT, -- JSON array
    FOREIGN KEY (claimed_by) REFERENCES agents(agent_hash)
);

CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_claimed ON tasks(claimed_by);

-- Agent messages
CREATE TABLE IF NOT EXISTS messages (
    message_id TEXT PRIMARY KEY,
    from_agent TEXT NOT NULL,
    to_agent TEXT NOT NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    priority TEXT DEFAULT 'normal',
    read INTEGER DEFAULT 0, -- Boolean: 0 = unread, 1 = read
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_agent) REFERENCES agents(agent_hash),
    FOREIGN KEY (to_agent) REFERENCES agents(agent_hash)
);

CREATE INDEX idx_messages_to ON messages(to_agent, timestamp DESC);
CREATE INDEX idx_messages_from ON messages(from_agent, timestamp DESC);
CREATE INDEX idx_messages_unread ON messages(to_agent, read);

-- Namespace statistics (materialized view alternative)
CREATE TABLE IF NOT EXISTS namespace_stats (
    namespace TEXT PRIMARY KEY,
    entry_count INTEGER DEFAULT 0,
    last_activity DATETIME,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_namespace_count ON namespace_stats(entry_count DESC);

-- Traffic light status
CREATE TABLE IF NOT EXISTS traffic_lights (
    project_name TEXT PRIMARY KEY,
    status TEXT NOT NULL, -- green, yellow, red
    message TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT
);
