# BR CLI Implementation Plan
**Version:** 0.1.0
**Created:** 2025-12-27
**Stack:** Go + Cobra
**Target:** Single-binary CLI for 30,000+ node mesh operations

---

## Architecture Overview

```
br (binary)
├── cmd/                    # Cobra commands
│   ├── root.go            # Global flags, config loading
│   ├── init.go
│   ├── inventory/         # br inventory nodes|agents|services
│   ├── connectors/        # br connectors add|auth|test
│   ├── sync/              # br sync pull|push|drift
│   ├── deploy/            # br deploy plan|apply|rollback
│   ├── run/               # br run exec|ssh|job|fanout
│   ├── test/              # br test smoke|suite
│   ├── policy/            # br policy whoami|lint|apply
│   ├── secrets/           # br secrets set-ref|ref|rotate
│   └── doctor/            # br doctor [node]
├── pkg/
│   ├── selector/          # Target selector engine
│   ├── registry/          # Inventory store (nodes, agents, services)
│   ├── changeset/         # Changeset tracking + attestation
│   ├── policy/            # CECE policy engine
│   ├── connectors/        # Connector plugins
│   ├── runner/            # Execution engine (SSH, fanout, parallel)
│   ├── deployer/          # Deployment orchestration
│   ├── verifier/          # Preflight/postflight checks
│   └── observability/     # KPIs, logs, metrics
├── configs/
│   ├── profiles/
│   │   ├── dev.yaml
│   │   ├── stage.yaml
│   │   └── prod.yaml
│   ├── policy/
│   │   └── cece-rules.yaml
│   └── inventory/
│       └── nodes.yaml
├── scripts/
│   ├── install.sh         # One-line installer
│   ├── bootstrap-node.sh  # br init node output
│   └── cross-compile.sh   # Build for Mac/Linux/ARM
└── ops/
    └── ansible/           # Optional: Ansible playbooks driven by br

```

---

## Core Components

### 1. Selector Engine (`pkg/selector`)

The heart of "30,000 nodes possible" - parses and resolves target selectors:

```go
// selector/selector.go
type Selector struct {
    Filters []Filter
    Limit   int
    Percent int
}

type Filter struct {
    Field    string  // node, role, tag, env, service, agent-pack
    Operator string  // =, !=, in, not-in
    Value    string
}

func Parse(expr string) (*Selector, error)
func (s *Selector) Resolve(inventory *registry.Inventory) ([]registry.Node, error)
```

**Examples:**
- `role=pi,env=prod` → AND filter
- `role=pi|role=jetson` → OR filter
- `tag!=deprecated` → NOT filter
- `percent=5` → Random stable 5% slice (hash-based)

### 2. Inventory Registry (`pkg/registry`)

Schema-driven inventory with multi-backend support:

```go
// registry/registry.go
type Inventory struct {
    Nodes    []Node
    Agents   []Agent
    Services []Service
}

type Node struct {
    Name     string            `yaml:"name"`
    IP       string            `yaml:"ip"`
    Role     string            `yaml:"role"`
    Tags     []string          `yaml:"tags"`
    Env      string            `yaml:"env"`
    SSH      SSHConfig         `yaml:"ssh"`
    Meta     map[string]string `yaml:"meta"`
}

type Agent struct {
    ID       string   `yaml:"id"`
    Pack     string   `yaml:"pack"`
    Nodes    []string `yaml:"nodes"`
    Config   string   `yaml:"config"`
}

type Service struct {
    Name     string   `yaml:"name"`
    Endpoint string   `yaml:"endpoint"`
    Health   string   `yaml:"health"`
}
```

**Backends:**
- Local: `~/.local/share/blackroad/inventory.yaml`
- Git: `git@github.com:BlackRoad-OS/blackroad-os-inventory.git`
- Future: D1, KV, S3

### 3. Changeset Tracking (`pkg/changeset`)

Every mutation generates a signed, versioned changeset:

```go
// changeset/changeset.go
type Changeset struct {
    ID          string           `json:"changeset_id"`
    RunID       string           `json:"run_id"`
    Profile     string           `json:"profile"`
    Actor       Actor            `json:"actor"`
    Targets     TargetResolution `json:"targets"`
    Policy      PolicyDecision   `json:"policy"`
    Plan        Plan             `json:"plan"`
    Results     Results          `json:"results"`
    KPIs        KPIs             `json:"kpis"`
    Attestation Attestation      `json:"attestation"`
}

type Actor struct {
    Type       string `json:"type"` // human|agent
    ID         string `json:"id"`
    KeyFingerprint string `json:"key_fpr"`
}

type TargetResolution struct {
    Selector string `json:"selector"`
    Resolved int    `json:"resolved"`
}

type PolicyDecision struct {
    Decision string `json:"decision"` // allow|deny
    Reason   string `json:"reason"`
    RuleID   string `json:"rule_id"`
}
```

**Storage:**
- `~/.local/share/blackroad/changesets/<changeset_id>.json`
- Signed with PS-SHA-∞ hash cascade
- Indexed for `br deploy rollback --to <id>`

### 4. Runner Engine (`pkg/runner`)

Parallel execution engine with safety controls:

```go
// runner/runner.go
type Runner struct {
    Selector   *selector.Selector
    Inventory  *registry.Inventory
    MaxParallel int
    Timeout    time.Duration
}

func (r *Runner) Exec(cmd string) (*RunResult, error)
func (r *Runner) Upload(src, dst string) error
func (r *Runner) Download(src, dst string) error
func (r *Runner) SSH(interactive bool) error
```

**Features:**
- Parallel execution with configurable max-parallelism
- Progress bars (when not `--json`)
- Automatic retry with exponential backoff
- Circuit breaker (stop if >20% fail)
- Dry-run mode (SSH validation only)

### 5. Policy Engine (`pkg/policy`)

CECE (Cecilia + Policy) integration:

```go
// policy/policy.go
type Engine struct {
    Rules []Rule
}

type Rule struct {
    ID          string
    Command     string  // deploy.apply, run.exec, etc
    Profile     string  // dev|stage|prod|*
    Require     []string // mfa, approval, quorum, etc
    MaxTargets  int
    AllowAgent  bool
}

func (e *Engine) Evaluate(ctx Context) (*Decision, error)
func (e *Engine) Attest(changeset *changeset.Changeset) (string, error)
```

**Example policy:**
```yaml
# configs/policy/cece-rules.yaml
- id: cece:prod-deploy-strict
  command: deploy.apply
  profile: prod
  require:
    - mfa
    - approval
  max_targets: 100
  allow_agent: false

- id: cece:dev-permissive
  command: "*"
  profile: dev
  require: []
  allow_agent: true
```

### 6. Connectors (`pkg/connectors`)

Plugin system for external integrations:

```go
// connectors/connector.go
type Connector interface {
    Name() string
    Auth() error
    Test() error
    // Specific methods per connector
}

// connectors/github.go
type GitHubConnector struct {
    Token string
    Org   string
}

// connectors/cloudflare.go
type CloudflareConnector struct {
    APIToken   string
    AccountID  string
    Zones      []Zone
}
```

**Supported connectors:**
- GitHub (repos, PRs, actions)
- Cloudflare (Pages, KV, D1, tunnels)
- Railway (projects, deployments)
- Tailscale (mesh network)
- Slack (notifications)
- Linear (issue tracking)
- SMTP (email alerts)
- Google Calendar (deployment schedules)

---

## Command Specs

### `br init`

```bash
# Create config + directories
br init

# Scaffold mono/multi-repo layout
br init repo --layout mono|multi

# Generate bootstrap script for a Pi/Jetson
br init node --name octavia --role holo > bootstrap-octavia.sh
```

**Output:**
```
✅ Created ~/.config/blackroad/config.yaml
✅ Created ~/.local/share/blackroad/
✅ Created ~/.local/state/blackroad/logs/
```

---

### `br inventory`

```bash
# List all nodes
br inventory nodes list
br inventory nodes list --role pi
br inventory nodes list --json

# Add a node
br inventory nodes add \
  --name octavia \
  --ip 192.168.4.74 \
  --role pi \
  --tags holo,3dprint

# Remove a node
br inventory nodes rm octavia

# Tag management
br inventory nodes tags octavia add robotics
br inventory nodes tags octavia rm deprecated

# Export inventory
br inventory export --format yaml > inventory-backup.yaml
```

**Output:**
```
NAME        IP              ROLE    TAGS           ENV
lucidia     192.168.4.38    pi      ops,dev        dev
alice       192.168.4.49    pi      ops,k3s        prod
aria        192.168.4.64    pi      sim,backup     dev
octavia     192.168.4.74    pi      holo,3dprint   dev
shellfish   174.138.44.45   cloud   droplet        prod
```

---

### `br connectors`

```bash
# List configured connectors
br connectors list

# Add a connector
br connectors add github
# Prompts for: token, org

# Authenticate
br connectors auth github

# Test connection
br connectors test github

# Doctor (check all connectors)
br connectors doctor

# Rotate credentials
br connectors rotate github
```

---

### `br sync`

```bash
# Show sync status
br sync status

# Pull latest inventory/policy from GitHub
br sync pull

# Push local changes (creates PR)
br sync push --message "Add octavia node"

# Detect drift between desired state and reality
br sync drift

# Create signed snapshot
br sync snapshot > snapshot-2025-12-27.json

# Lock/unlock sync (prevent concurrent changes)
br sync lock
br sync unlock
```

---

### `br deploy`

```bash
# Generate deployment plan
br deploy plan --targets role=pi

# Apply deployment
br deploy apply --targets role=pi,env=prod

# Rollback to previous changeset
br deploy rollback --to cs_01JH...

# Promote dev → prod
br deploy promote --from dev --to prod

# Canary deployment
br deploy canary --percent 5 --targets role=pi

# Show deployment status
br deploy status

# Follow logs
br deploy logs --follow
```

**Output (human mode):**
```
━━━ Deployment Plan ━━━
Profile: prod
Targets: role=pi,env=prod (resolved: 12 nodes)
Policy: ✅ allow (cece:prod-deploy-strict)

Changes:
  • Update agent-pack: job-applier v2.1.0 → v2.2.0
  • Update config: /etc/blackroad/agents.yaml

Affected nodes:
  ✓ lucidia-pi
  ✓ alice-pi
  ✓ aria-pi
  [... 9 more]

KPIs:
  Estimated duration: 4m 32s
  Rollbackable: yes

Proceed? [y/N]:
```

---

### `br run`

```bash
# Execute command on all matching nodes
br run exec --targets role=pi -- "uptime"

# SSH to first matching node
br run ssh --targets node=octavia

# Run predefined job
br run job update-agents --param version=2.2.0

# Upload script and run (fanout)
br run fanout ./deploy-agent.sh --targets role=pi
```

**Output:**
```
━━━ Executing: uptime ━━━
Targets: role=pi (resolved: 4 nodes)
Max parallel: 10
Timeout: 30s

[1/4] lucidia-pi   ✓ 12:34:56 up 42 days, 3:21, 1 user
[2/4] alice-pi     ✓ 12:34:56 up 38 days, 12:05, 2 users
[3/4] aria-pi      ✓ 12:34:56 up 15 days, 8:43, 0 users
[4/4] octavia-pi   ✗ timeout (30s)

Results: 3 ok, 1 failed, 0 skipped
Error rate: 25%
Duration: 32.4s
```

---

### `br test`

```bash
# Quick smoke test
br test smoke

# Run test suite
br test suite mesh
br test suite infra
br test suite agents

# Show test report
br test report --last 10
```

---

### `br policy`

```bash
# Show current identity
br policy whoami

# Lint policy files
br policy lint

# Apply policy updates
br policy apply

# Explain what a command would do
br policy explain "deploy.apply" --profile prod --targets role=pi

# Sign and attest a changeset
br policy attest --changeset cs_01JH...
```

---

### `br secrets`

```bash
# Set secret reference (don't store value!)
br secrets set-ref github-token 1password:blackroad/github-token

# Get secret reference
br secrets ref github-token

# Rotate secret
br secrets rotate github-token

# Audit secret usage
br secrets audit
```

---

### `br doctor`

```bash
# Check entire mesh health
br doctor

# Check specific node
br doctor node octavia

# Fix issues (safe mode)
br doctor fix --safe

# Fix issues (aggressive mode)
br doctor fix --aggressive
```

**Output:**
```
━━━ BlackRoad Mesh Health Check ━━━

✓ Config valid
✓ Inventory schema valid
✓ SSH keys present
✗ Node unreachable: shellfish (174.138.44.45)
✓ Policy engine loaded
⚠ Connector github: token expires in 7 days

Nodes:
  ✓ lucidia-pi    (192.168.4.38)
  ✓ alice-pi      (192.168.4.49)
  ✓ aria-pi       (192.168.4.64)
  ✓ octavia-pi    (192.168.4.74)
  ✗ shellfish     (174.138.44.45) - unreachable

Overall: 4/5 nodes healthy (80%)
```

---

## Verification Protocol

Every `br deploy apply` automatically runs:

1. **Preflight** (`br test preflight`):
   - Disk space check (>10% free)
   - Network connectivity
   - SSH auth validation
   - Policy check

2. **Plan** (`br deploy plan`):
   - Show diff
   - Estimate duration
   - Calculate risk score

3. **Apply** (`br deploy apply`):
   - Execute changes
   - Stream logs
   - Track progress

4. **Postflight** (`br test smoke`):
   - Verify services running
   - Check health endpoints
   - Validate expected state

5. **Attest** (`br policy attest`):
   - Sign changeset
   - Write KPI report
   - Store in changeset log

**Override:** `br deploy apply --no-verify` (policy permitting)

---

## Installation

### One-line installer

```bash
curl -fsSL https://blackroad.sh | bash
```

**Script does:**
1. Detect OS/architecture (Mac, Linux x86, ARM)
2. Download appropriate binary from GitHub releases
3. Install to `/usr/local/bin/br`
4. Run `br init`
5. Verify with `br doctor`

### Manual install

```bash
# Download latest release
wget https://github.com/BlackRoad-OS/br-cli/releases/latest/download/br-darwin-arm64

# Install
chmod +x br-darwin-arm64
sudo mv br-darwin-arm64 /usr/local/bin/br

# Initialize
br init
```

### Build from source

```bash
git clone https://github.com/BlackRoad-OS/br-cli.git
cd br-cli
make build
sudo make install
```

---

## Cross-Compilation Targets

```makefile
# Makefile
.PHONY: build-all
build-all:
	GOOS=darwin GOARCH=amd64 go build -o bin/br-darwin-amd64 main.go
	GOOS=darwin GOARCH=arm64 go build -o bin/br-darwin-arm64 main.go
	GOOS=linux GOARCH=amd64 go build -o bin/br-linux-amd64 main.go
	GOOS=linux GOARCH=arm64 go build -o bin/br-linux-arm64 main.go
	GOOS=linux GOARCH=arm go build -o bin/br-linux-arm main.go
```

**Targets:**
- Mac Intel: `darwin/amd64`
- Mac Apple Silicon: `darwin/arm64`
- Linux x86: `linux/amd64` (DigitalOcean, most servers)
- Linux ARM64: `linux/arm64` (Raspberry Pi 4/5, Jetson)
- Linux ARM: `linux/arm` (Raspberry Pi 3 and older)

---

## Configuration Files

### `~/.config/blackroad/config.yaml`

```yaml
version: 1
default_profile: dev

profiles:
  dev:
    inventory: ~/.local/share/blackroad/inventory.yaml
    policy: ~/.config/blackroad/policy/dev.yaml
    max_parallel: 5
    timeout: 30s

  prod:
    inventory: git@github.com:BlackRoad-OS/blackroad-os-inventory.git
    policy: git@github.com:BlackRoad-OS/blackroad-os-policy.git
    max_parallel: 20
    timeout: 120s

connectors:
  github:
    org: BlackRoad-OS
    token_ref: 1password:blackroad/github-token

  cloudflare:
    account_id: 12345...
    token_ref: 1password:blackroad/cf-token

logging:
  level: info
  format: json
  file: ~/.local/state/blackroad/logs/br.log
```

### `~/.local/share/blackroad/inventory.yaml`

```yaml
nodes:
  - name: lucidia-pi
    ip: 192.168.4.38
    role: pi
    tags: [ops, dev]
    env: dev
    ssh:
      user: lucidia
      key: ~/.ssh/id_br_ed25519
      port: 22

  - name: alice-pi
    ip: 192.168.4.49
    role: pi
    tags: [ops, k3s]
    env: prod
    ssh:
      user: alice
      key: ~/.ssh/id_br_ed25519

  - name: aria-pi
    ip: 192.168.4.64
    role: pi
    tags: [sim, backup]
    env: dev
    ssh:
      user: pi
      key: ~/.ssh/id_br_ed25519

  - name: octavia-pi
    ip: 192.168.4.74
    role: pi
    tags: [holo, 3dprint, robotics]
    env: dev
    ssh:
      user: pi
      key: ~/.ssh/id_br_ed25519

  - name: shellfish
    ip: 174.138.44.45
    role: cloud
    tags: [droplet, codex]
    env: prod
    ssh:
      user: root
      key: ~/.ssh/id_do_ed25519

agents:
  - id: job-applier-001
    pack: job-applier
    nodes: [lucidia-pi, alice-pi]
    config: /etc/blackroad/agents/job-applier.yaml

services:
  - name: blackroad-api
    endpoint: https://api.blackroad.sh/health
    health: /health
```

---

## JSON Output Mode

Every command supports `--json` for machine-readable output:

```bash
br inventory nodes list --json
```

```json
{
  "nodes": [
    {
      "name": "lucidia-pi",
      "ip": "192.168.4.38",
      "role": "pi",
      "tags": ["ops", "dev"],
      "env": "dev",
      "ssh": {
        "user": "lucidia",
        "key": "~/.ssh/id_br_ed25519",
        "port": 22
      }
    }
  ]
}
```

---

## Exit Codes

- `0` - Success
- `2` - Policy denied
- `3` - Drift detected
- `4` - Partial failure (some nodes failed)
- `5` - Infrastructure failure (no nodes reachable)

---

## Next Steps

1. **Scaffold repo:** Create `blackroad-os-br-cli` with Go module structure
2. **Implement selector engine:** Core target resolution logic
3. **Build `br inventory` commands:** Get basic node management working
4. **Add `br run exec`:** Enable remote command execution
5. **Integrate CECE policy:** Connect to existing policy system
6. **Cross-compile:** Build for all platforms
7. **Write installer:** One-line install script
8. **Documentation:** CLI reference, examples, runbooks

---

## Questions for You

1. **Inventory backend:** Start with local YAML or immediately use GitHub repo?
2. **CECE integration:** Is there an existing policy engine to integrate with?
3. **Secrets:** Use 1Password CLI, ENV vars, or custom secret store?
4. **Logging:** Local files, centralized (e.g., Loki), or both?
5. **Distribution:** GitHub releases, Homebrew, or custom CDN?

---

**Ready to start coding when you are!** 🖤🛣️
