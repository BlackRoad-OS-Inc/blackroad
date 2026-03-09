# BlackRoad Code Library - Quick Start Guide

## "Did you check the library, or are you raw-dogging it?"

This is your 212,000-file code library made searchable and useful.

---

## 🚀 Quick Start (5 minutes)

### Step 1: Scan Your Repositories

```bash
# Scan all repos in ~/projects
python3 ~/blackroad-library-scanner.py

# Or scan a single repo
python3 ~/blackroad-library-scanner.py --repo ~/projects/blackroad-os-operator

# Or scan custom location
python3 ~/blackroad-library-scanner.py --repos ~/my-repos
```

This creates: `~/blackroad-code-library/index/components.db`

**Expected output:**
```
📂 Scanning blackroad-os-operator...
  ✅ Saved 247 components
📂 Scanning blackroad-os-web...
  ✅ Saved 183 components
...

✅ Scanned 66 repositories
📦 Found 8,429 components
💾 Library saved to: ~/blackroad-code-library
```

### Step 2: Search the Library

```bash
# Search for components
python3 ~/blackroad-library-search.py "authentication"

# Filter by language
python3 ~/blackroad-library-search.py "sidebar" --language typescript

# Filter by framework
python3 ~/blackroad-library-search.py "chat" --framework react

# Get library statistics
python3 ~/blackroad-library-search.py --stats
```

### Step 3: Use the Agent Interface

```bash
# Ask natural language questions
python3 ~/blackroad-library-agent-api.py "Show me authentication implementations"

# Interactive mode
python3 ~/blackroad-library-agent-api.py
❓ I need a React sidebar
❓ Find JWT components
❓ What database code do we have?
```

---

## 📖 Usage Examples

### Example 1: Building a New Feature

**Scenario:** You need to add JWT authentication to a new app.

**Before (raw-dogging):**
```
❌ 2 hours writing auth from scratch
❌ Debugging edge cases
❌ Missing refresh token logic
❌ Security vulnerabilities
```

**After (checking library):**
```bash
python3 ~/blackroad-library-agent-api.py "JWT authentication"

# Output:
✅ Found 3 component(s)

1. ⭐ JWT Auth with Refresh (typescript/class) - Quality: 9.2/10
   📍 Location: blackroad-os-operator/src/auth/jwt.ts:45
   🏷️  Tags: authentication, jwt, tokens, security
   🔧 Framework: express
   📦 Deps: jsonwebtoken, bcrypt, dotenv

# Copy the implementation
cat ~/projects/blackroad-os-operator/src/auth/jwt.ts

# ✅ 15 minutes to integrate vs 2 hours to build
```

### Example 2: Finding UI Components

```bash
python3 ~/blackroad-library-agent-api.py "React sidebar with navigation"

# Output:
✅ Found 2 component(s)

1. ⭐ Sidebar (react-component) - Quality: 9.0/10
   📍 Location: blackroad-os-web/components/Sidebar.tsx:1
   🏷️  Tags: react-component, navigation, ui
   🔧 Framework: react
   📦 Deps: lucide-react, next/link

   Preview:
   export function Sidebar() {
     return (
       <aside className="w-64 bg-gray-900">
         {/* Navigation items */}
       </aside>
   ...
```

### Example 3: Database Patterns

```bash
python3 ~/blackroad-library-search.py "postgres" --stats

# Shows all PostgreSQL-related components
# Ranked by quality and recency
```

---

## 🎯 Common Queries

### Authentication
```bash
python3 ~/blackroad-library-agent-api.py "authentication"
python3 ~/blackroad-library-agent-api.py "JWT"
python3 ~/blackroad-library-agent-api.py "OAuth"
python3 ~/blackroad-library-agent-api.py "session management"
```

### UI Components
```bash
python3 ~/blackroad-library-agent-api.py "React sidebar"
python3 ~/blackroad-library-agent-api.py "chat interface"
python3 ~/blackroad-library-agent-api.py "dashboard layout"
python3 ~/blackroad-library-agent-api.py "modal"
```

### State Management
```bash
python3 ~/blackroad-library-agent-api.py "Zustand store"
python3 ~/blackroad-library-agent-api.py "state management"
python3 ~/blackroad-library-agent-api.py "React context"
```

### API & Backend
```bash
python3 ~/blackroad-library-agent-api.py "API endpoint"
python3 ~/blackroad-library-agent-api.py "Express routes"
python3 ~/blackroad-library-agent-api.py "rate limiting"
python3 ~/blackroad-library-agent-api.py "WebSocket"
```

### Database
```bash
python3 ~/blackroad-library-agent-api.py "PostgreSQL"
python3 ~/blackroad-library-agent-api.py "Redis cache"
python3 ~/blackroad-library-agent-api.py "Supabase"
```

### Deployment
```bash
python3 ~/blackroad-library-agent-api.py "Docker config"
python3 ~/blackroad-library-agent-api.py "GitHub Actions"
python3 ~/blackroad-library-agent-api.py "Cloudflare Pages"
```

---

## 🔧 Advanced Usage

### Filter by Quality

```bash
# Only show high-quality components (8.0+)
python3 ~/blackroad-library-search.py "auth" --min-quality 8.0
```

### Filter by Recency

```bash
# Only show components used in last 30 days
python3 ~/blackroad-library-search.py "sidebar" --max-age 30
```

### Find Similar Components

```bash
# First, get a component ID
python3 ~/blackroad-library-search.py "JWT" --limit 1

# Then find similar ones
python3 ~/blackroad-library-search.py --similar <component_id>
```

### Get Specific Component Details

```bash
python3 ~/blackroad-library-search.py --id <component_id>
```

---

## 📊 Library Statistics

```bash
python3 ~/blackroad-library-search.py --stats

# Output:
📊 Library Statistics
======================================================================

Total Components: 8,429

By Language:
  typescript: 4,231
  javascript: 2,187
  python: 1,892
  go: 119

By Type:
  function: 3,492
  react-component: 2,871
  class: 1,823
  utility: 243

By Framework:
  react: 2,104
  nextjs: 1,583
  express: 421
  fastapi: 203

Repositories:
  blackroad-os-operator: 1,247 components
  blackroad-os-web: 983 components
  lucidia-earth: 542 components
  ...
```

---

## 🤖 For Agents

Agents should always check the library before building new code.

**Agent workflow:**

1. **Check Library First**
   ```python
   from blackroad_library_search import LibrarySearch

   search = LibrarySearch()
   components = search.search("authentication JWT")

   if components:
       print(f"Found {len(components)} existing implementations!")
       # Use existing code
   else:
       # Build from scratch
   ```

2. **Use Agent API**
   ```python
   from blackroad_library_agent_api import LibraryAgent

   agent = LibraryAgent()
   response = agent.ask("I need a React sidebar")
   print(response)
   ```

3. **Get Best Match**
   ```python
   best = agent.get_best_match("JWT authentication", {
       'language': 'typescript',
       'min_quality': 8.0
   })
   ```

---

## 🔄 Updating the Library

Re-scan repositories after making changes:

```bash
# Re-scan all repos
python3 ~/blackroad-library-scanner.py

# Re-scan specific repo
python3 ~/blackroad-library-scanner.py --repo ~/projects/blackroad-os-operator
```

The scanner automatically:
- Detects new components
- Updates existing components
- Maintains component IDs (won't duplicate)

---

## 📁 Library Structure

```
~/blackroad-code-library/
├── index/
│   └── components.db          # SQLite database (all components)
├── catalog/                   # (Future: organized by category)
└── README.md
```

### Database Schema

The library stores:
- Component name, type, language, framework
- Repository and file location
- Line numbers (start/end)
- Quality score (0-10)
- Tags and dependencies
- Code snippet (preview)
- Usage count and last used date

---

## 💡 Tips

1. **Always check library first** before building anything new
2. **Use natural language** with the agent API
3. **Filter by quality** to get best implementations
4. **Check similar components** for alternatives
5. **Re-scan regularly** to keep library up to date

---

## 🎯 The Question

Before starting any new code, ask yourself:

> **"Did you check the library, or are you raw-dogging it?"**

If it's in the library, use it. If it's not, build it once and it'll be there for next time.

**No more reinventing the wheel. Ever.**

---

## 🆘 Troubleshooting

### Library not found
```bash
# Check if database exists
ls -lh ~/blackroad-code-library/index/components.db

# If not, run scanner first
python3 ~/blackroad-library-scanner.py
```

### No results found
```bash
# Check library stats
python3 ~/blackroad-library-search.py --stats

# Try broader search terms
python3 ~/blackroad-library-search.py "auth"  # Instead of "JWT authentication with refresh tokens"
```

### Import errors
```bash
# Make sure you're in the right directory or add to path
export PYTHONPATH="$HOME:$PYTHONPATH"
```

---

## 📞 Support

Questions? Check:
- Full documentation: `~/blackroad-code-library-system.md`
- Memory system: `~/memory-system.sh summary`
- Email: blackroad.systems@gmail.com
