# 📜 BlackRoad Codex

**A Masterpiece of Alexandria & Amunra & Rohonc**

Universal code indexing, search, and verification system for the entire BlackRoad ecosystem.

---

## 🎯 What is the BlackRoad Codex?

The BlackRoad Codex is a comprehensive code intelligence system that:

- **Indexes** all code across 56 repositories (8,789 components)
- **Searches** with semantic understanding
- **Verifies** mathematical correctness with formal methods
- **Integrates** with [MEMORY] for perfect coordination

**Think of it as:** The Library of Alexandria for all BlackRoad code.

---

## 📊 Current Statistics

- **Repositories Indexed:** 56 (44 BlackRoad-OS + 12 blackboxprogramming)
- **Total Components:** 8,789
- **Languages:** Python (8,626), TypeScript (163)
- **Mathematical Identities:** 76 built-in
- **Verification Framework:** Full symbolic computation engine

**Top Repositories:**
1. blackroad-simple-launch: 7,044 components
2. BlackRoad-Operating-System: 1,379 components
3. earth-metaverse: 387 components
4. lucidia-core: 286 components
5. blackroad-io-app: 184 components

---

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/BlackRoad-OS/blackroad-os-codex.git
cd blackroad-os-codex

# Install dependencies
pip install -r requirements.txt

# Set up the Codex
./setup.sh
```

### Basic Usage

```bash
# Search for code
python3 blackroad-codex-search.py "authentication jwt login"

# Index a repository
python3 blackroad-codex-scanner.py --repo /path/to/repo

# Verify mathematical code
./blackroad-codex-verification-suite.sh verify <component_id> <file_path>

# View dashboard
python3 blackroad-codex-scraping-dashboard.py
```

---

## 🛠️ Tools

### Core Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| **blackroad-codex-scanner.py** | Extract components from code | `python3 blackroad-codex-scanner.py --repo <path>` |
| **blackroad-codex-search.py** | Semantic code search | `python3 blackroad-codex-search.py "query"` |
| **blackroad-codex-verification.py** | Mechanical calculation extraction | Internal use |
| **blackroad-codex-symbolic.py** | Symbolic computation engine | Internal use |
| **blackroad-codex-verification-suite.sh** | Unified verification CLI | `./blackroad-codex-verification-suite.sh <cmd>` |

### Advanced Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| **blackroad-codex-advanced-scraper.py** | Deep documentation scraper | `python3 blackroad-codex-advanced-scraper.py --deep-scrape <id>` |
| **blackroad-codex-scraping-dashboard.py** | Statistics dashboard | `python3 blackroad-codex-scraping-dashboard.py` |
| **blackroad-codex-prism-analysis.sh** | Prism Console analyzer | `./blackroad-codex-prism-analysis.sh dashboard` |
| **blackroad-codex-index-all.sh** | Universal ecosystem indexer | `./blackroad-codex-index-all.sh` |

---

## 📚 Documentation

### Getting Started
- [Installation Guide](docs/INSTALLATION.md)
- [Quick Start Tutorial](docs/QUICK_START.md)
- [Integration with Memory System](docs/MEMORY_CODEX_INTEGRATION.md)

### User Guides
- [Search Guide](docs/SEARCH_GUIDE.md)
- [Verification Guide](docs/CODEX_VERIFICATION_GUIDE.md)
- [Indexing Guide](docs/INDEXING_GUIDE.md)

### Reference
- [API Reference](docs/API_REFERENCE.md)
- [Database Schema](docs/DATABASE_SCHEMA.md)
- [CLI Commands](docs/CLI_REFERENCE.md)

---

## 🔍 Search Examples

### Find Authentication Code
```bash
python3 blackroad-codex-search.py "authentication login jwt oauth"
```

### Find API Endpoints
```bash
python3 blackroad-codex-search.py "fastapi router endpoint"
```

### Find React Components
```bash
python3 blackroad-codex-search.py "react component button modal"
```

### Find Mathematical Functions
```bash
python3 blackroad-codex-search.py "equation calculation matrix"
```

---

## 📐 Verification Framework

The Codex includes a complete formal verification framework:

### Features
- **Mechanical Calculation Extraction** - Automatically finds equations, formulas, algorithms
- **Symbolic Computation** - 76 mathematical identities, expression simplification
- **Type Checking** - Verify type consistency
- **Invariant Detection** - Loop invariants, assertions, pre/post conditions
- **LaTeX Generation** - Auto-generate documentation

### Usage

```bash
# Verify a component
./blackroad-codex-verification-suite.sh verify <component_id> <file_path>

# View mathematical identities
./blackroad-codex-verification-suite.sh identities

# Analyze all math components
./blackroad-codex-verification-suite.sh analyze-all-math

# Show dashboard
./blackroad-codex-verification-suite.sh dashboard
```

---

## 🗄️ Database Schema

The Codex uses SQLite with the following tables:

### Core Tables
- **components** - All indexed code components (functions, classes, modules)
- **dependencies** - Component dependencies
- **documentation** - Extracted docstrings and comments
- **patterns** - Code patterns detected

### Verification Tables
- **calculations** - Mechanical calculations (equations, formulas)
- **verifications** - Verification results
- **type_signatures** - Type information
- **invariants** - Loop/function invariants
- **symbolic_expressions** - Symbolic math expressions
- **equation_systems** - Systems of equations
- **math_identities** - Standard identities (76 total)
- **transformation_rules** - Rewrite rules
- **proofs** - Formal proofs

---

## 🔗 Integration with [MEMORY]

The Codex integrates with the BlackRoad Memory system for perfect coordination:

### The Two-Check System

**Before writing any code:**
1. **[MEMORY]** - Check what other Claudes are doing
2. **[CODEX]** - Search for existing code

**The Golden Rule:** If [CODEX] has it, USE IT. If [MEMORY] shows a conflict, COORDINATE.

### Quick Integration

```bash
# Register with memory
MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-task")

# Check both systems
~/memory-realtime-context.sh live $MY_CLAUDE compact  # [MEMORY]
python3 blackroad-codex-search.py "task keywords"    # [CODEX]

# Announce with both checks
~/memory-system.sh log announce "$MY_CLAUDE" "
[MEMORY] ✅ Checked for conflicts
[CODEX] ✅ Searched for existing code
Working on: [PROJECT]
"
```

See [MEMORY_CODEX_INTEGRATION.md](docs/MEMORY_CODEX_INTEGRATION.md) for complete guide.

---

## 🎯 Use Cases

### 1. Code Discovery
Find existing implementations before building new features:
```bash
python3 blackroad-codex-search.py "user authentication"
# → Found 23 auth components. Reuse instead of rebuild!
```

### 2. Code Review
Automatically verify mathematical correctness:
```bash
./blackroad-codex-verification-suite.sh verify bd1a64466d166910 /path/to/file.py
# → ✅ Type checking passed
# → ✅ Found 4 calculations
# → ✅ Symbolic computation verified
```

### 3. Refactoring
Ensure symbolic equivalence after changes:
```python
from blackroad_codex_symbolic import SymbolicComputationEngine

engine = SymbolicComputationEngine()
is_equiv = engine.verify_symbolic_equivalence("a * (b + c)", "a*b + a*c")
# True - distributive property verified
```

### 4. Documentation
Auto-generate LaTeX for documentation:
```bash
sqlite3 ~/blackroad-codex/index/components.db "
  SELECT original, latex FROM symbolic_expressions LIMIT 5
"
```

### 5. Team Coordination
Avoid duplicate work across Claude agents:
```bash
# Check if anyone else built this
python3 blackroad-codex-search.py "oauth token refresh"
# → Found in blackroad-os-api! Don't rebuild.
```

---

## 📈 Statistics & Dashboard

### View Stats
```bash
# Launch dashboard
python3 blackroad-codex-scraping-dashboard.py

# Query database directly
sqlite3 ~/blackroad-codex/index/components.db "
  SELECT language, COUNT(*) 
  FROM components 
  GROUP BY language
"
```

### Component Breakdown
- **By Language:** Python (98.1%), TypeScript (1.9%)
- **By Type:** Functions, Classes, Modules, API Endpoints, React Components
- **By Repository:** 56 repositories indexed
- **Verification:** 76 mathematical identities loaded

---

## 🏗️ Architecture

### Indexing Pipeline

```
Source Code → Scanner → AST Parser → Component Extractor → Database
                                   ↓
                            Verification Engine
                                   ↓
                            Symbolic Computation
```

### Search Pipeline

```
Query → Semantic Analysis → Vector Search → Ranking → Results
                                          ↓
                                   Component Details
```

### Verification Pipeline

```
Component → Calculation Extractor → Type Checker → Invariant Detector
                                                 ↓
                                          Symbolic Engine
                                                 ↓
                                         Verification Result
```

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone the repo
git clone https://github.com/BlackRoad-OS/blackroad-os-codex.git
cd blackroad-os-codex

# Install dev dependencies
pip install -r requirements-dev.txt

# Run tests
pytest tests/

# Run linter
flake8 *.py
```

---

## 📜 Philosophy

> **"A Masterpiece of Alexandria & Amunra & Rohonc"**

- **Alexandria:** The great library (alexa amundson)
- **Amunra:** Ancient knowledge
- **Rohonc:** Earliest robot (cipher reference)

**The Codex remembers everything. So should we.**

The BlackRoad Codex is:
- **Universal** - Indexes all code across the entire ecosystem
- **Intelligent** - Semantic search with understanding
- **Rigorous** - Formal verification of mathematical correctness
- **Coordinated** - Integrates with [MEMORY] for perfect team alignment

---

## 🎓 Learning Resources

### Tutorials
- [Indexing Your First Repository](docs/tutorials/first-index.md)
- [Advanced Search Techniques](docs/tutorials/advanced-search.md)
- [Mathematical Verification](docs/tutorials/verification.md)
- [Memory Integration](docs/tutorials/memory-integration.md)

### Videos (Coming Soon)
- Introduction to BlackRoad Codex
- Search Like a Pro
- Verification Framework Deep Dive
- Building with the Codex API

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🔗 Links

- **Organization:** [BlackRoad-OS](https://github.com/BlackRoad-OS)
- **Documentation:** [docs.blackroad.io](https://docs.blackroad.io)
- **Issues:** [GitHub Issues](https://github.com/BlackRoad-OS/blackroad-os-codex/issues)
- **Discussions:** [GitHub Discussions](https://github.com/BlackRoad-OS/blackroad-os-codex/discussions)

---

## 🙏 Acknowledgments

Built with:
- Python 3.11+
- SQLite
- AST parsing
- Symbolic computation
- Vector search
- Formal verification methods

Special thanks to all contributors and the BlackRoad OS community!

---

**The Codex remembers. The Codex verifies. The Codex knows all.** 📜

*Version 1.0.0 - December 23, 2025*

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson | **PROPRIETARY AND CONFIDENTIAL**

This software is NOT for commercial resale. Testing purposes only.

### 🏢 Enterprise Scale:
- 30,000 AI Agents
- 30,000 Human Employees
- CEO: Alexa Amundson

**Contact:** blackroad.systems@gmail.com

See [LICENSE](LICENSE) for complete terms.
