# BlackRoad Codex - Search Workflow Guide

**Purpose:** Methodical discovery of forgotten/unknown code in your 8,789 component library

---

## 🎯 The Workflow

When you want to know "have I built X before?", follow this process:

### Step 1: Quick Search (The Oracle)
```bash
python3 ~/blackroad-codex-search.py "your query" --library ~/blackroad-codex --limit 10
```

**Example:**
```bash
python3 ~/blackroad-codex-search.py "quantum" --library ~/blackroad-codex --limit 10
```

**What you get:**
- Component names
- File locations
- Quality scores
- Tags

---

### Step 2: Natural Language Query (Optional)
```bash
python3 ~/blackroad-codex-oracle.py "Show me all X-related code" --library ~/blackroad-codex
```

**Example:**
```bash
python3 ~/blackroad-codex-oracle.py "Show me all math equation code" --library ~/blackroad-codex
```

**What you get:**
- Natural language interpretation
- Context-aware results
- Code previews

---

### Step 3: Database Deep Dive
```bash
sqlite3 ~/blackroad-codex/index/components.db "SELECT name, file_path FROM components WHERE name LIKE '%keyword%' OR file_path LIKE '%keyword%'"
```

**Example:**
```bash
sqlite3 ~/blackroad-codex/index/components.db "SELECT name, file_path FROM components WHERE name LIKE '%equation%' OR file_path LIKE '%math%'"
```

**What you get:**
- Raw database results
- All matching components
- File paths for exploration

---

### Step 4: Extract the Code
```bash
# Get component ID from search results, then:
python3 ~/blackroad-codex-extract.py <component_id> --library ~/blackroad-codex --print
```

**Example:**
```bash
python3 ~/blackroad-codex-extract.py bd1a64466d166910 --library ~/blackroad-codex --print
```

**What you get:**
- Full source code
- Line numbers
- File location

---

### Step 5: Filesystem Exploration (When needed)
```bash
# Find all files with keyword in path
find ~/projects -name "*keyword*" -type f

# Grep for keyword in code
grep -r "keyword" ~/projects/BlackRoad-Operating-System --include="*.py" | head -20
```

**Example:**
```bash
find ~/projects -name "*math*" -type f
grep -r "equation" ~/projects/BlackRoad-Operating-System --include="*.py" | head -20
```

**What you get:**
- File discovery
- Context lines
- Usage patterns

---

## 📊 Real Example: Quantum Discovery

**Question:** "Have I built quantum stuff before?"

**Step 1 - Quick Search:**
```bash
python3 ~/blackroad-codex-search.py "quantum" --library ~/blackroad-codex --limit 10
```

**Result:**
```
Found 2 component(s):

1. ⭐ QuantumFinanceSimulator (python/class) - 5.0/10
   📍 BlackRoad-Operating-System/quantum_finance.py:13

2. ⭐ QuantumBackend (python/class) - 5.0/10
   📍 BlackRoad-Operating-System/backends.py:16
```

**Step 2 - Database Deep Dive:**
```bash
sqlite3 ~/blackroad-codex/index/components.db "SELECT name, file_path FROM components WHERE file_path LIKE '%quantum%' LIMIT 20"
```

**Result:** 20 components in quantum_engine/ and lucidia_quantum/

**Step 3 - Filesystem Grep:**
```bash
grep -r "quantum" ~/projects/BlackRoad-Operating-System --include="*.py" | head -10
```

**Result:** Found VQE, QAOA, QFT, PQC, QNN implementations

**Step 4 - Extract Code:**
```bash
python3 ~/blackroad-codex-extract.py bd1a64466d166910 --library ~/blackroad-codex --print
```

**Result:** Full QuantumFinanceSimulator class with quantum-inspired financial modeling

**Discovery:** Full quantum computing research lab with 20+ components!

---

## 🎯 Query Templates

### By Technology
```bash
python3 ~/blackroad-codex-search.py "react" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "fastapi" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "postgres" --library ~/blackroad-codex
```

### By Domain
```bash
python3 ~/blackroad-codex-search.py "authentication" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "blockchain" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "machine learning" --library ~/blackroad-codex
```

### By Pattern
```bash
python3 ~/blackroad-codex-search.py "singleton" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "factory" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "observer" --library ~/blackroad-codex
```

### By Functionality
```bash
python3 ~/blackroad-codex-search.py "API endpoint" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "database query" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "websocket" --library ~/blackroad-codex
```

### By Math/Science
```bash
python3 ~/blackroad-codex-search.py "equation" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "algorithm" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "optimization" --library ~/blackroad-codex
```

---

## 💡 Pro Tips

### 1. Start Broad, Then Narrow
```bash
# Broad search
python3 ~/blackroad-codex-search.py "math" --library ~/blackroad-codex

# Narrow down
python3 ~/blackroad-codex-search.py "differential equation" --library ~/blackroad-codex --limit 5
```

### 2. Use Multiple Keywords
```bash
sqlite3 ~/blackroad-codex/index/components.db "SELECT name FROM components WHERE name LIKE '%equation%' OR name LIKE '%formula%' OR name LIKE '%calculation%'"
```

### 3. Explore File Paths
```bash
# See what's in a specific directory
sqlite3 ~/blackroad-codex/index/components.db "SELECT DISTINCT file_path FROM components WHERE file_path LIKE '%research-lab%'"
```

### 4. Check Tags
```bash
sqlite3 ~/blackroad-codex/index/components.db "SELECT name, tags FROM components WHERE tags LIKE '%math%'"
```

### 5. Combine Tools
```bash
# 1. Find with Codex
python3 ~/blackroad-codex-search.py "optimization" --library ~/blackroad-codex

# 2. Explore directory
ls -la ~/projects/BlackRoad-Operating-System/packs/research-lab/

# 3. Grep for details
grep -r "optimize" ~/projects/BlackRoad-Operating-System/packs/research-lab/ | head -10
```

---

## 📈 The Process

```
Question: "Have I built X?"
    ↓
Quick Search (Codex)
    ↓
Found something? → Extract & Review
    ↓
Want more detail? → Database Query
    ↓
Want to explore? → Filesystem Grep
    ↓
Want full context? → Read source files
    ↓
Log to Memory → Done!
```

---

## 🎭 Example Questions & Queries

### "Have I built math equations before?"
```bash
python3 ~/blackroad-codex-search.py "equation" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "formula" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "math" --library ~/blackroad-codex
grep -r "equation" ~/projects/BlackRoad-Operating-System --include="*.py"
```

### "Do I have blockchain code?"
```bash
python3 ~/blackroad-codex-search.py "blockchain" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "wallet" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "transaction" --library ~/blackroad-codex
```

### "What about machine learning?"
```bash
python3 ~/blackroad-codex-search.py "neural network" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "model" --library ~/blackroad-codex
python3 ~/blackroad-codex-search.py "training" --library ~/blackroad-codex
```

### "Any API integrations?"
```bash
python3 ~/blackroad-codex-search.py "api" --library ~/blackroad-codex --limit 20
sqlite3 ~/blackroad-codex/index/components.db "SELECT name FROM components WHERE name LIKE '%API%' OR name LIKE '%api%'"
```

---

## 🔄 After Discovery

Once you find something interesting:

1. **Log it to memory:**
```bash
~/memory-system.sh log discovered "Description of what you found"
```

2. **Extract for reuse:**
```bash
python3 ~/blackroad-codex-extract.py <component_id> --output ~/my-component.py
```

3. **Deep scrape for more info:**
```bash
python3 ~/blackroad-codex-advanced-scraper.py --deep-scrape <component_id>
```

4. **Document it:**
Add to your project notes or README

---

## 📜 The Codex Philosophy

> "Did you consult the Codex, or are you raw-dogging it?"

Before building anything:
1. Search the Codex
2. If found → Extract & reuse (15 min)
3. If not found → Build new (2 hours)
4. Re-scan → Add to Codex

**The Codex remembers. The Codex preserves. The Codex reveals.**

---

**Next Query:** "math equations"

Ready to discover your mathematical wisdom! 🧮📜
