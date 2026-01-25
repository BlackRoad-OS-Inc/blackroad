# BlackRoad OS - CLI Tools Master Fork List
**Permissive Licenses Only (MIT/BSD/Apache)**
**Last Updated:** December 10, 2025

---

## 🎯 TIER 1: PRIORITY FORKS (Already Planned)

| # | Tool | License | Status | BlackRoad Name | Priority |
|---|------|---------|--------|----------------|----------|
| 1 | fzf | MIT | 🔨 In Progress | br-fuzzy | P0 |
| 2 | jq | MIT | 🔨 In Progress | br-jq | P0 |
| 3 | HTTPie | BSD 3-Clause | 📋 Planned | br-http / br-fetch | P0 |
| 4 | kubectl | Apache 2.0 | 📋 Planned | br-node | P0 |
| 5 | gh (GitHub CLI) | MIT | 📋 Planned | br-repo | P1 |

**Status:**
- ✅ Strategy documented
- ✅ Repos scaffolded
- ⏳ Upstream forks needed

---

## 🔥 TIER 2: CRITICAL UTILITIES (Build Next)

### Data & Processing
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 6 | gojq | MIT | Go implementation of jq | br-jq-go |
| 7 | oq | MIT | jq wrapper/extension | br-oq |
| 8 | ripgrep | MIT | Fast code search | br-grep |
| 9 | fd | MIT | Better `find` | br-find |

### Terminal UI & Display
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 10 | bat | MIT | Better `cat` with syntax | br-cat |
| 11 | htop | GPL → Skip | Process viewer | ❌ GPL |
| 12 | neofetch | MIT | System info display | br-info |
| 13 | screenfetch | MIT | System info fetcher | br-sysinfo |

### File & Navigation
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 14 | autojump | GPL → Skip | Smart `cd` | ❌ GPL |
| 15 | z.lua | MIT | Directory tracker | br-jump |
| 16 | view | MIT | File viewer | br-view |

### Development Tools
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 17 | gitui | MIT | Terminal Git UI | br-git-ui |
| 18 | micro | MIT | Terminal text editor | br-edit |
| 19 | lazydocker | MIT | Docker TUI | br-docker-ui |
| 20 | k9s | Apache 2.0 | Kubernetes TUI | br-k9s |

### Build & Task Management
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 21 | just | MIT | Task runner | br-task |
| 22 | taskwarrior | MIT | Task manager | br-tasks |

### Utilities
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 23 | mklicense | MIT | Generate licenses | br-license |
| 24 | diff2html-cli | MIT | Diff visualization | br-diff |
| 25 | add-gitignore | MIT | .gitignore generator | br-gitignore |
| 26 | is-up-cli | MIT | Domain checker | br-is-up |
| 27 | tldr | MIT | Simplified man pages | br-help |
| 28 | cheat | MIT | Cheat sheets | br-cheat |

---

## ✨ TIER 3: NEW DISCOVERIES (From Latest List)

### Code Analysis & Building
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 29 | ast-grep | MIT | Code structural search | br-ast |
| 30 | BuildCLI | MIT | Java build automation | br-build-java |
| 31 | urfave/cli | MIT | Go CLI framework | (library - use internally) |
| 32 | tiny-cli | MIT | Frontend CLI tool | br-frontend |

### Framework Tools
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 33 | Thor | MIT | Ruby CLI toolkit | (library - Ruby components) |

---

## 🚫 EXCLUDED (GPL or Copyleft Licenses)

| Tool | License | Reason |
|------|---------|--------|
| htop | GPL | Copyleft - can't fork proprietary |
| autojump | GPL | Copyleft - can't fork proprietary |
| kubebox | (Check) | Need to verify license |

---

## 📦 IMPLEMENTATION ROADMAP

### Phase 1: Core 5 (Weeks 1-4) ✅
- [x] fzf → br-fuzzy (P0)
- [x] jq → br-jq (P0)
- [x] HTTPie → br-http (P0)
- [ ] kubectl → br-node (P0)
- [ ] gh → br-repo (P1)

### Phase 2: Data & Search (Weeks 5-6)
- [ ] ripgrep → br-grep
- [ ] fd → br-find
- [ ] gojq → br-jq-go
- [ ] ast-grep → br-ast

### Phase 3: UI & Display (Weeks 7-8)
- [ ] bat → br-cat
- [ ] neofetch → br-info
- [ ] gitui → br-git-ui
- [ ] diff2html-cli → br-diff

### Phase 4: Task & Build (Weeks 9-10)
- [ ] just → br-task
- [ ] taskwarrior → br-tasks
- [ ] BuildCLI → br-build-java
- [ ] lazydocker → br-docker-ui

### Phase 5: Utilities (Weeks 11-12)
- [ ] tldr → br-help
- [ ] cheat → br-cheat
- [ ] mklicense → br-license
- [ ] z.lua → br-jump

---

## 🎯 FORK STRATEGY FOR EACH TOOL

### Step 1: Legal Review
```bash
# For each tool:
cd upstream-repo
cat LICENSE
# Verify: MIT / BSD / Apache 2.0
# Check dependencies (no GPL in chain)
```

### Step 2: Fork & Brand
```bash
# Create BlackRoad fork
git clone https://github.com/upstream/tool.git
cd tool
git remote add blackroad git@github.com:BlackRoad-OS/br-TOOL.git

# Rebrand
find . -type f -exec sed -i 's/TOOL/br-TOOL/g' {} +
# Update README with BlackRoad branding
# Add PS-SHA∞ signing capability
# Add agent-awareness
```

### Step 3: Enhance
```bash
# Add BlackRoad features:
# - PS-SHA∞ identity integration
# - Agent DNA awareness
# - Ledger event logging
# - Quantum state compatibility
# - Multi-cloud mesh integration
```

### Step 4: Package & Distribute
```bash
# Create Homebrew tap
brew tap blackroad-os/tools
brew install br-TOOL

# Create Docker image
docker build -t blackroad/br-TOOL .

# Publish to npm (if applicable)
npm publish @blackroad/br-TOOL
```

---

## 📊 LICENSE COMPLIANCE CHECKLIST

### For Each Fork
- [ ] Verify upstream license is MIT/BSD/Apache
- [ ] Check all dependencies (no GPL)
- [ ] Keep original LICENSE file
- [ ] Add BlackRoad copyright notice
- [ ] Document modifications
- [ ] Attribute original authors

### Example Copyright Notice
```
# BlackRoad OS - br-fuzzy
# Based on fzf by Junegunn Choi (MIT License)
# Copyright (c) 2025 BlackRoad OS, Inc.
#
# Original fzf license:
# Copyright (c) 2013-2025 Junegunn Choi
#
# Permission is hereby granted, free of charge...
```

---

## 🔧 DEVELOPMENT ENVIRONMENT

### Required Tools
```bash
# Core languages
brew install go rust python3 ruby node

# Build tools
brew install make cmake gcc

# Version control
brew install git gh

# Testing
brew install bats shellcheck
```

### Repo Structure (Per Tool)
```
br-TOOL/
├── upstream/          # Git submodule to original
├── src/
│   └── blackroad/     # BR-specific additions
├── tests/
├── docs/
├── scripts/
│   └── build.sh
├── LICENSE            # Original + BR copyright
├── README.md          # BR-branded
└── br-TOOL.rb         # Homebrew formula
```

---

## 📈 SUCCESS METRICS

### Technical Goals
- [ ] 33 tools forked and enhanced
- [ ] 100% test coverage on BR additions
- [ ] Cross-platform (macOS, Linux, Pi)
- [ ] <100ms startup latency
- [ ] PS-SHA∞ signing on all tools

### Adoption Goals
- [ ] 1,000+ GitHub stars across all tools
- [ ] 100+ community contributors
- [ ] Featured on Hacker News
- [ ] 10,000+ Homebrew installs

### Integration Goals
- [ ] All tools work with `br` master CLI
- [ ] Unified identity system (PS-SHA∞)
- [ ] Agent-aware execution
- [ ] Ledger event logging
- [ ] Mesh-native operation

---

## 🚀 QUICK START COMMANDS

### Fork First Tool
```bash
# 1. Choose tool (example: fzf)
cd ~/blackroad-sandbox/blackroad-cli-tools
mkdir br-fuzzy && cd br-fuzzy

# 2. Add upstream as submodule
git submodule add https://github.com/junegunn/fzf.git upstream

# 3. Create BlackRoad wrapper
mkdir -p src/blackroad
cat > src/blackroad/main.go << 'EOF'
package main

import (
    "github.com/junegunn/fzf/src"
    "github.com/blackroad-os/identity"
)

func main() {
    // Add PS-SHA∞ identity
    identity.Init()

    // Run original fzf with BR enhancements
    fzf.Run()
}
EOF

# 4. Build
go build -o br-fuzzy src/blackroad/main.go

# 5. Test
./br-fuzzy --version  # Should show "br-fuzzy (BlackRoad fork of fzf)"
```

### Create Homebrew Formula
```bash
cat > br-fuzzy.rb << 'EOF'
class BrFuzzy < Formula
  desc "BlackRoad's agent-aware fuzzy finder"
  homepage "https://blackroad.io/cli/fuzzy"
  url "https://github.com/BlackRoad-OS/br-fuzzy/archive/v0.1.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", "-o", "br-fuzzy"
    bin.install "br-fuzzy"
  end

  test do
    assert_match "br-fuzzy", shell_output("#{bin}/br-fuzzy --version")
  end
end
EOF
```

---

## 📚 RESOURCES

### Upstream Repositories
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [jq](https://github.com/jqlang/jq) - JSON processor
- [HTTPie](https://github.com/httpie/cli) - HTTP client
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast search
- [bat](https://github.com/sharkdp/bat) - Better cat
- [fd](https://github.com/sharkdp/fd) - Better find
- [ast-grep](https://github.com/ast-grep/ast-grep) - Code search
- [Full list of 33 tools](./CLI-TOOLS-MASTER-LIST.md)

### License References
- [MIT License](https://opensource.org/licenses/MIT)
- [BSD Licenses](https://opensource.org/licenses/BSD-3-Clause)
- [Apache 2.0](https://opensource.org/licenses/Apache-2.0)
- [License Compatibility](https://www.gnu.org/licenses/license-compatibility.html)

### BlackRoad Docs
- [CLI Fork Strategy](./BLACKROAD-CLI-FORK-STRATEGY.md)
- [PS-SHA∞ Integration Guide](../docs/PS-SHA-INFINITY.md)
- [Agent DNA System](../docs/AGENT-DNA.md)

---

## 🎯 IMMEDIATE NEXT STEPS

### This Week
1. ✅ Complete master list of 33 tools
2. [ ] Legal review of top 10 tools
3. [ ] Fork fzf → br-fuzzy (basic)
4. [ ] Fork jq → br-jq (basic)
5. [ ] Create Homebrew tap structure

### Next Week
1. [ ] Add PS-SHA∞ to br-fuzzy
2. [ ] Add PS-SHA∞ to br-jq
3. [ ] Fork HTTPie → br-http
4. [ ] Create br CLI plugin system
5. [ ] Write integration tests

### Week 3
1. [ ] Fork ripgrep → br-grep
2. [ ] Fork fd → br-find
3. [ ] Fork bat → br-cat
4. [ ] Create unified documentation
5. [ ] Alpha release internally

---

**Total Tools Identified:** 33
**Permissive Licenses:** 31 (2 excluded for GPL)
**Priority Tools:** 10
**Timeline:** 12 weeks to public launch

---

*"We're not just forking tools. We're building the command language of a new operating system."*

— BlackRoad OS CLI Team, December 10, 2025

---

## 📝 ADDITIONAL DISCOVERIES (Latest Batch)

### License & Code Tools
| # | Tool | License | Use Case | BlackRoad Name |
|---|------|---------|----------|----------------|
| 34 | license-cli | MIT | Generate LICENSE files | br-license-gen |
| 35 | ii | MIT | Minimalist IRC client | br-irc |

**Updated Total: 35 CLI tools identified (33 previously + 2 new)**

---

## 📊 FINAL TOOL COUNT

- **Priority Forks (P0):** 5 tools
- **Critical Utilities (P1):** 15 tools
- **New Discoveries (P2):** 15 tools
- **TOTAL IDENTIFIED:** 35 tools
- **Excluded (GPL):** 2 tools (htop, autojump)

**Net Total for BlackRoad:** 35 permissively-licensed CLI tools ready to fork!

