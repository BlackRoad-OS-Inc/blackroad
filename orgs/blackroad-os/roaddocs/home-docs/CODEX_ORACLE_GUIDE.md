# Agent Integration Guide - BlackRoad Code Library

## 🎯 The Prime Directive for All Agents

> **"Before building anything, ALWAYS check the library first."**

This guide shows AI agents how to integrate the BlackRoad Code Library into their workflow.

---

## 🤖 Agent Workflow

### Step 1: Understand the Task
When given a task, identify what components you might need:
- Authentication? Check library.
- UI component? Check library.
- API endpoint? Check library.
- Database code? Check library.

### Step 2: Search the Library
Use the library search tools to find existing implementations.

### Step 3: Evaluate Results
- Review quality scores (prefer 7.0+)
- Check recency (prefer recently used)
- Verify dependencies are acceptable

### Step 4: Extract or Build
- **If found:** Extract and integrate existing component
- **If not found:** Build new component and it will be added on next scan

---

## 🔧 Tools Available

### 1. Library Search (Command Line)
```bash
# Basic search
python3 ~/blackroad-library-search.py "authentication"

# With filters
python3 ~/blackroad-library-search.py "sidebar" --language typescript --min-quality 8.0

# Get statistics
python3 ~/blackroad-library-search.py --stats
```

### 2. Agent API (Natural Language)
```bash
# Ask questions
python3 ~/blackroad-library-agent-api.py "Show me authentication implementations"
python3 ~/blackroad-library-agent-api.py "I need a React sidebar component"

# Interactive mode
python3 ~/blackroad-library-agent-api.py
```

### 3. Component Extractor
```bash
# Get component ID from search, then:
python3 ~/blackroad-library-extract.py <component_id> --print

# Save to file
python3 ~/blackroad-library-extract.py <component_id> --output ~/my-component.py

# Create full package
python3 ~/blackroad-library-extract.py <component_id> --package ~/my-package/
```

### 4. Statistics Dashboard
```bash
# View dashboard
python3 ~/blackroad-library-stats.py

# Export as JSON
python3 ~/blackroad-library-stats.py --json ~/library-stats.json
```

---

## 📚 Python API Integration

Agents can directly use Python APIs:

```python
#!/usr/bin/env python3
"""
Example: Agent using the code library
"""

import sqlite3
from pathlib import Path

class AgentWithLibrary:
    """AI Agent with library integration."""

    def __init__(self):
        self.library_db = Path("~/blackroad-code-library/index/components.db").expanduser()

    def check_library(self, query: str, language: str = None) -> list:
        """Search library before building."""
        conn = sqlite3.connect(self.library_db)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        sql = """
            SELECT * FROM components
            WHERE (name LIKE ? OR tags LIKE ? OR description LIKE ?)
        """
        params = [f"%{query}%", f"%{query}%", f"%{query}%"]

        if language:
            sql += " AND language = ?"
            params.append(language)

        sql += " ORDER BY quality_score DESC LIMIT 5"

        cursor.execute(sql, params)
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()

        return results

    def build_feature(self, feature_name: str):
        """Build a feature - library-first approach."""

        # Step 1: Check library
        print(f"🔍 Checking library for: {feature_name}")
        results = self.check_library(feature_name)

        if results:
            print(f"✅ Found {len(results)} existing implementations!")
            for i, comp in enumerate(results, 1):
                print(f"  {i}. {comp['name']} ({comp['type']}) - Quality: {comp['quality_score']}/10")
                print(f"     Location: {comp['file_path']}:{comp['start_line']}")

            # Use existing component
            return self.use_existing_component(results[0])

        else:
            print(f"❌ No existing implementation found")
            print(f"📝 Building from scratch...")
            return self.build_from_scratch(feature_name)

    def use_existing_component(self, component: dict):
        """Use an existing component from library."""
        print(f"\n✅ Using existing component: {component['name']}")

        # Extract the code
        file_path = Path(component['file_path'])
        if file_path.exists():
            with open(file_path) as f:
                lines = f.readlines()

            start = component['start_line'] - 1
            end = component['end_line']
            code = ''.join(lines[start:end])

            print(f"📦 Extracted {end - start} lines of code")
            return code
        else:
            print(f"⚠️  Source file not found: {file_path}")
            return None

    def build_from_scratch(self, feature_name: str):
        """Build new component."""
        print(f"Building {feature_name}...")
        # Agent's normal build process
        # ... implementation ...
        return "new code"


# Example usage
if __name__ == "__main__":
    agent = AgentWithLibrary()

    # Agent needs authentication
    agent.build_feature("authentication")

    # Agent needs sidebar
    agent.build_feature("sidebar component")
```

---

## 🎯 Decision Tree for Agents

```
┌─────────────────────────────┐
│   New Task Assigned         │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Identify Required Components│
│ (auth, UI, API, DB, etc.)   │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Search Library for Each     │
│ Component                   │
└──────────┬──────────────────┘
           │
           ▼
      ┌────┴────┐
      │ Found?  │
      └────┬────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
  YES            NO
    │             │
    ▼             ▼
┌─────────┐  ┌─────────┐
│ Extract │  │ Build   │
│ & Use   │  │ New     │
└────┬────┘  └────┬────┘
     │            │
     ▼            ▼
┌──────────────────────────┐
│ Integrate into Project   │
└──────────────────────────┘
```

---

## 💡 Best Practices for Agents

### 1. Always Search First
```python
# BAD ❌
def build_auth():
    # Just start building...
    pass

# GOOD ✅
def build_auth():
    # Check library first
    results = check_library("authentication")
    if results:
        return use_existing(results[0])
    else:
        return build_new()
```

### 2. Use Quality Filters
```python
# Prefer high-quality components
results = search_library(
    "authentication",
    filters={
        'min_quality': 8.0,  # Only high quality
        'max_age_days': 90,  # Recently used
    }
)
```

### 3. Check Multiple Keywords
```python
# Try different search terms
keywords = ["auth", "authentication", "jwt", "login"]
for keyword in keywords:
    results = search_library(keyword)
    if results:
        break
```

### 4. Verify Dependencies
```python
# Check if dependencies are acceptable
import json

for comp in results:
    deps = json.loads(comp['dependencies'])
    if all(is_acceptable_dep(d) for d in deps):
        return comp  # Use this one
```

### 5. Log Usage
When you use a component, it should be tracked (future enhancement).

---

## 📊 Current Library Stats

**As of:** 2025-12-23

- **Total Components:** 8,789
- **Repositories Indexed:** 35
- **Languages:** Python (98.1%), TypeScript (1.9%)
- **Top Categories:**
  - Classes: 6,798 (77.3%)
  - Functions: 1,991 (22.7%)
- **Top Tags:** authentication, api, jwt, ui, utility, postgresql, redis

---

## 🔍 Common Queries for Agents

### Authentication
```bash
python3 ~/blackroad-library-agent-api.py "authentication implementations"
python3 ~/blackroad-library-search.py "jwt" --min-quality 8
python3 ~/blackroad-library-search.py "api_key" --language python
```

### UI Components
```bash
python3 ~/blackroad-library-agent-api.py "React sidebar"
python3 ~/blackroad-library-search.py "modal" --framework react
python3 ~/blackroad-library-search.py "form" --language typescript
```

### API & Backend
```bash
python3 ~/blackroad-library-agent-api.py "API endpoints"
python3 ~/blackroad-library-search.py "fastapi" --framework fastapi
python3 ~/blackroad-library-search.py "express routes" --language typescript
```

### Database
```bash
python3 ~/blackroad-library-agent-api.py "database connections"
python3 ~/blackroad-library-search.py "postgresql"
python3 ~/blackroad-library-search.py "redis cache"
```

---

## 🚀 Quick Start for New Agents

**1. Set up library access:**
```python
import os
os.environ['LIBRARY_PATH'] = os.path.expanduser('~/blackroad-code-library')
```

**2. Add to agent prompt:**
```
Before building any feature, you MUST:
1. Search the code library for existing implementations
2. Use the library search tools at ~/blackroad-library-*.py
3. Only build from scratch if nothing suitable exists
4. Prefer components with quality scores >= 8.0
```

**3. Add to agent workflow:**
```python
class Agent:
    def execute_task(self, task):
        # 1. Search library (NEW)
        existing = self.search_library(task)

        if existing:
            # 2. Use existing component
            return self.integrate_existing(existing)
        else:
            # 3. Build new (only if necessary)
            return self.build_new(task)
```

---

## 📈 Measuring Success

Agents should track:
- **Library Check Rate:** % of tasks where library was checked
- **Reuse Rate:** % of tasks using existing components
- **Time Saved:** Time saved by using library vs building
- **Quality:** Average quality score of reused components

**Target Metrics:**
- Library check rate: 100%
- Reuse rate: 60%+
- Time saved: 4-6 hours per feature
- Quality: 8.0+ average

---

## 🔄 Keeping Library Updated

The library auto-updates when you re-scan:

```bash
# Re-scan all repos (monthly recommended)
python3 ~/blackroad-library-scanner.py

# Re-scan specific repo (after major changes)
python3 ~/blackroad-library-scanner.py --repo ~/projects/my-repo
```

New components are automatically:
- Extracted and classified
- Tagged and scored
- Made searchable immediately

---

## 🆘 Troubleshooting for Agents

### "No results found"
- Try broader search terms
- Remove filters (language, framework)
- Check library stats to see what's available

### "Source file not found"
- File may have moved
- Re-scan repository
- Check file path in component metadata

### "Low quality scores"
- Quality scoring is basic right now (default 5.0)
- Future: will incorporate usage, tests, documentation
- Don't rely solely on quality score yet

---

## 🎓 Examples

### Example 1: Building Authentication
```python
# Agent task: Add authentication to new app

# Step 1: Check library
results = search("authentication jwt")

# Results:
# 1. api_key_auth (5.0/10) - blackroad-os-api
# 2. MultiDomainBasicAuth (5.0/10) - blackroad-simple-launch

# Step 2: Extract component
code = extract_component("fc305d899409e4d8")

# Step 3: Integrate
# Copy code to new project
# Install dependencies
# Update imports
# Done in 15 minutes vs 2 hours from scratch!
```

### Example 2: React Component
```python
# Agent task: Create sidebar navigation

# Step 1: Check library
results = search("sidebar", language="typescript")

# Step 2: If found, extract and customize
# Step 3: If not found, build new and it will be added next scan
```

---

## 🎯 Summary

**For every task:**
1. ✅ Check library FIRST
2. ✅ Use existing if quality >= 8.0
3. ✅ Extract and integrate (15 min)
4. ✅ Build new only if necessary (2 hours)

**The question:**
> "Did you check the library, or are you raw-dogging it?"

**The answer should always be:**
> "I checked the library first."

---

## 📁 Quick Reference

**Search Tools:**
- `~/blackroad-library-search.py` - CLI search
- `~/blackroad-library-agent-api.py` - Natural language API
- `~/blackroad-library-extract.py` - Extract components
- `~/blackroad-library-stats.py` - View statistics

**Database:**
- Location: `~/blackroad-code-library/index/components.db`
- Size: 6.9 MB
- Components: 8,789

**Documentation:**
- This guide: `~/AGENT_LIBRARY_INTEGRATION_GUIDE.md`
- System architecture: `~/blackroad-code-library-system.md`
- Quick start: `~/LIBRARY_QUICKSTART.md`

---

**Remember: The library is your first resource. Use it. Every. Single. Time.**
