# BlackRoad Tools

> ERP, CRM, manifest profiler, cluster builders, and DevOps utilities

## Quick Reference

| Property | Value |
|----------|-------|
| **Language** | Python 3.10+ |
| **CLI** | Click + Rich |
| **Build** | Hatch |
| **License** | MIT |

## Tech Stack

```
Python 3.10+
├── Click (CLI Framework)
├── Rich (Terminal UI)
├── httpx (HTTP Client)
├── PyYAML (Config Files)
├── SQLAlchemy (ERP/CRM Database)
└── kubernetes (K8s Integration)
```

## Installation

```bash
# Standard install
pip install blackroad-tools

# With ERP support
pip install blackroad-tools[erp]

# With Kubernetes support
pip install blackroad-tools[k8s]

# Full install
pip install blackroad-tools[erp,k8s,dev]
```

## Commands

```bash
# Main CLI
br-tools           # Main tools CLI

# Specialized tools
br-erp             # ERP system
br-crm             # CRM system
br-manifest        # Manifest profiler
br-pully           # Pull/sync utility

# Development
pytest             # Run tests
black .            # Format code
ruff check .       # Lint
```

## Tool Suite

### ERP (Enterprise Resource Planning)
- Inventory management
- Order processing
- Financial tracking

### CRM (Customer Relationship Management)
- Contact management
- Interaction tracking
- Pipeline management

### Manifest Profiler
- Kubernetes manifest analysis
- Resource optimization
- Configuration validation

### Pully
- Multi-repo synchronization
- Branch management
- Automated pulls

### Cluster Builders
- Kubernetes cluster setup
- Node configuration
- Service deployment

## Project Structure

```
tools_cli.py        # Main CLI entry
erp/
├── __init__.py
├── inventory.py
└── orders.py
crm/
├── __init__.py
├── contacts.py
└── pipeline.py
manifest_profile/
├── __init__.py
├── analyzer.py
└── optimizer.py
pully/
├── __init__.py
└── sync.py
```

## Environment Variables

```env
BR_TOOLS_CONFIG=~/.blackroad/tools.yaml
BR_ERP_DATABASE_URL=postgresql://...
BR_CRM_DATABASE_URL=postgresql://...
KUBECONFIG=~/.kube/config
```

## Related Repos

- `blackroad-agents` - Agent orchestration
- `blackroad-cli` - Main CLI
- `blackroad-pi-ops` - Edge devices
