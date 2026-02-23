#!/bin/bash
# Phase 1: Install PostgreSQL 16 + Redis 7 on Cecilia (192.168.4.89)
# Run ON Cecilia: bash /tmp/setup-cecilia.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1" >&2; }
info()  { echo -e "${CYAN}[i]${NC} $1"; }

PG_PASSWORD="${PG_PASSWORD:-CHANGE_ME_BEFORE_RUNNING}"
REDIS_PASSWORD="${REDIS_PASSWORD:-CHANGE_ME_BEFORE_RUNNING}"

if [ "$PG_PASSWORD" = "CHANGE_ME_BEFORE_RUNNING" ] || [ "$REDIS_PASSWORD" = "CHANGE_ME_BEFORE_RUNNING" ]; then
  error "Set passwords first:"
  error "  export PG_PASSWORD='your_strong_password'"
  error "  export REDIS_PASSWORD='your_strong_password'"
  exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Phase 1: PostgreSQL + Redis on Cecilia"
echo "  Host: $(hostname) ($(hostname -I | awk '{print $1}'))"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── POSTGRESQL 16 ───
install_postgresql() {
  log "Installing PostgreSQL 16..."

  sudo apt update
  sudo apt install -y postgresql postgresql-contrib

  # Get installed version
  local pg_ver
  pg_ver=$(pg_config --version 2>/dev/null | grep -oP '\d+' | head -1)
  log "PostgreSQL $pg_ver installed"

  local pg_conf="/etc/postgresql/${pg_ver}/main/postgresql.conf"
  local pg_hba="/etc/postgresql/${pg_ver}/main/pg_hba.conf"

  # Configure: listen on all interfaces
  sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$pg_conf"

  # NVMe-optimized tuning for Pi 5 (8GB RAM)
  sudo tee -a "$pg_conf" > /dev/null << 'PGCONF'

# === BlackRoad NVMe-optimized settings ===
shared_buffers = 2GB
effective_cache_size = 4GB
work_mem = 64MB
maintenance_work_mem = 512MB
wal_buffers = 64MB
max_connections = 100
random_page_cost = 1.1
effective_io_concurrency = 200
max_wal_size = 2GB
min_wal_size = 512MB
checkpoint_completion_target = 0.9
PGCONF

  # Allow connections from Pi subnet + WireGuard + Tailscale
  sudo tee -a "$pg_hba" > /dev/null << 'HBA'

# BlackRoad Pi subnet
host all all 192.168.4.0/24 scram-sha-256
# WireGuard tunnel
host all all 10.10.0.0/24 scram-sha-256
# Tailscale
host all all 100.64.0.0/10 scram-sha-256
HBA

  sudo systemctl restart postgresql
  sudo systemctl enable postgresql
  log "PostgreSQL configured and running"
}

create_databases() {
  log "Creating databases..."

  sudo -u postgres psql << SQL
-- Create application user
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'blackroad') THEN
    CREATE ROLE blackroad WITH LOGIN PASSWORD '${PG_PASSWORD}';
  END IF;
END
\$\$;

-- Create databases matching D1 names
CREATE DATABASE blackroad_os_main OWNER blackroad;
CREATE DATABASE blackroad_continuity OWNER blackroad;
CREATE DATABASE blackroad_saas OWNER blackroad;
CREATE DATABASE apollo_agent_registry OWNER blackroad;
CREATE DATABASE blackroad_revenue OWNER blackroad;

-- Grant privileges
ALTER USER blackroad CREATEDB;
SQL

  log "Created 5 databases"
}

setup_revenue_schema() {
  log "Setting up blackroad_revenue schema..."

  PGPASSWORD="$PG_PASSWORD" psql -U blackroad -d blackroad_revenue << 'SQL'
-- Revenue tracking (from payment-gateway/schema.sql, converted to PostgreSQL)
CREATE TABLE IF NOT EXISTS revenue (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  tier_id TEXT,
  amount DOUBLE PRECISION NOT NULL,
  currency TEXT DEFAULT 'usd',
  created_at TEXT NOT NULL,
  metadata TEXT
);
CREATE INDEX IF NOT EXISTS idx_revenue_user ON revenue(user_id);
CREATE INDEX IF NOT EXISTS idx_revenue_created ON revenue(created_at);

-- Subscription tracking
CREATE TABLE IF NOT EXISTS subscriptions (
  id SERIAL PRIMARY KEY,
  stripe_subscription_id TEXT UNIQUE NOT NULL,
  stripe_customer_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  tier_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  current_period_end TEXT,
  cancel_at_period_end INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sub_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_sub_customer ON subscriptions(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_sub_status ON subscriptions(status);

-- Webhook event idempotency
CREATE TABLE IF NOT EXISTS webhook_events (
  stripe_event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  processed_at TEXT NOT NULL,
  success INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_webhook_type ON webhook_events(event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_processed ON webhook_events(processed_at);
SQL

  log "blackroad_revenue schema ready"
}

# ─── REDIS 7 ───
install_redis() {
  log "Installing Redis..."

  sudo apt install -y redis-server

  # Configure Redis
  sudo tee /etc/redis/redis.conf > /dev/null << REDISCONF
# BlackRoad Redis Configuration
bind 0.0.0.0
protected-mode yes
port 6379
daemonize yes
supervised systemd
pidfile /run/redis/redis-server.pid
dir /var/lib/redis
dbfilename dump.rdb

# Authentication
requirepass ${REDIS_PASSWORD}

# Memory management (2GB max for Pi)
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence: RDB snapshots
save 900 1
save 300 10
save 60 10000

# Persistence: AOF (append-only file)
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log
REDISCONF

  sudo systemctl restart redis-server
  sudo systemctl enable redis-server
  log "Redis configured and running"
}

# ─── BACKUP CRON ───
setup_backups() {
  log "Setting up automated backups..."

  mkdir -p /home/pi/backups

  # PostgreSQL daily backup at 3 AM
  (crontab -l 2>/dev/null || true; echo "0 3 * * * pg_dumpall -U blackroad | gzip > /home/pi/backups/pg-\$(date +\%Y\%m\%d).sql.gz 2>/dev/null") | sort -u | crontab -

  # Redis snapshot every 6 hours
  (crontab -l 2>/dev/null || true; echo "0 */6 * * * redis-cli -a '${REDIS_PASSWORD}' BGSAVE 2>/dev/null") | sort -u | crontab -

  # Sync backups to Lucidia NVMe (redundancy) at 3:30 AM
  (crontab -l 2>/dev/null || true; echo "30 3 * * * rsync -avz /home/pi/backups/ pi@192.168.4.81:/mnt/nvme/backups/cecilia/ 2>/dev/null") | sort -u | crontab -

  # Clean backups older than 30 days
  (crontab -l 2>/dev/null || true; echo "0 4 * * 0 find /home/pi/backups -name 'pg-*.sql.gz' -mtime +30 -delete 2>/dev/null") | sort -u | crontab -

  log "Backup cron jobs installed"
}

# ─── VERIFICATION ───
verify() {
  echo ""
  log "Verifying installation..."

  # PostgreSQL
  if PGPASSWORD="$PG_PASSWORD" psql -U blackroad -d blackroad_revenue -c "SELECT 1" &>/dev/null; then
    log "  PostgreSQL: OK"
  else
    error "  PostgreSQL: FAILED"
  fi

  # Redis
  if redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q PONG; then
    log "  Redis: OK"
  else
    error "  Redis: FAILED"
  fi

  # Database list
  info "  Databases:"
  PGPASSWORD="$PG_PASSWORD" psql -U blackroad -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname" 2>/dev/null | while read -r db; do
    [ -n "$db" ] && info "    - $(echo "$db" | xargs)"
  done

  # Redis memory
  local redis_mem
  redis_mem=$(redis-cli -a "$REDIS_PASSWORD" INFO memory 2>/dev/null | grep used_memory_human | cut -d: -f2 | tr -d '[:space:]')
  info "  Redis memory: ${redis_mem:-unknown}"
}

# ─── MAIN ───
install_postgresql
create_databases
setup_revenue_schema
install_redis
setup_backups
verify

echo ""
echo "═══════════════════════════════════════════════════"
log "Phase 1 complete!"
info "PostgreSQL: localhost:5432 (user: blackroad)"
info "Redis: localhost:6379 (password protected)"
info ""
info "Next steps:"
info "  1. Import D1 data: bash /tmp/import-d1-to-postgres.sh"
info "  2. Import KV data: bash /tmp/import-kv-to-redis.sh"
echo "═══════════════════════════════════════════════════"
