#!/bin/bash
# Search with command detection

echo "🔍 Search with Command Detection"
echo ""
echo "  search detects cmd → route to blackroad → render internet in blackroad language"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat > ~/.blackroad/protocol/SEARCH_CMD.md << 'EOFCMD'
# Search Command Detection & Internet Rendering

## Flow

```
search
  ↓
detect cmd
  ↓
route to blackroad
  ↓
render internet in blackroad language
```

---

## Command Detection

Search bar input is analyzed:

```
"ls"              → cmd detected → blackroad
"git status"      → cmd detected → blackroad
"echo hello"      → cmd detected → blackroad
"https://..."     → url detected → blackroad → render as blackroad
"search query"    → query → blackroad → render as blackroad
```

**Everything routes to blackroad.**

---

## Rendering Pipeline

```
INPUT (search/cmd/url)
  ↓
DETECT type (cmd/url/query)
  ↓
ROUTE to blackroad
  ↓
TRANSLATE to blackroad language
  ↓
RENDER in blackroad format
```

---

## Blackroad Language

Internet content rendered as:

```
HTTP → file:
URL  → file:blackroad/domain/<url>
HTML → blackroad markup
JSON → blackroad data
CMD  → blackroad/cmd/<command>
```

---

## Examples

### Command Input
```
search: "ls -la"
  ↓
detected: cmd
  ↓
route: file:blackroad/cmd/ls
  ↓
render: blackroad terminal output
```

### URL Input
```
search: "https://example.com"
  ↓
detected: url
  ↓
route: file:blackroad/domain/example.com
  ↓
render: example.com in blackroad language
```

### Query Input
```
search: "what is blackroad"
  ↓
detected: query
  ↓
route: file:blackroad/search/what-is-blackroad
  ↓
render: blackroad search results
```

---

## Internet in Blackroad Language

All internet content translates:

| Internet | Blackroad |
|----------|-----------|
| `http://` | `file:blackroad/domain/` |
| `https://` | `file:blackroad/domain/` |
| `<html>` | `blackroad markup` |
| `{"json"}` | `blackroad data` |
| `CSS` | `blackroad style` |
| `JS` | `blackroad script` |

---

## Universal Renderer

```
INTERNET
  ↓
file:blackroad/internet/<resource>
  ↓
BLACKROAD LANGUAGE
  ↓
DISPLAY
```

**Everything becomes blackroad.**

The internet is just files.  
Files are just blackroad.  
Blackroad is the universal language.

---

## Command Routing Table

```
cmd → file:blackroad/cmd/<command>
url → file:blackroad/domain/<domain>
query → file:blackroad/search/<query>
file → file:blackroad/file/<path>
```

**All inputs have a blackroad address.**

EOFCMD

cat ~/.blackroad/protocol/SEARCH_CMD.md

echo ""
echo "✅ Command detection active"
echo "✅ Internet renderer ready"
echo ""
echo "📂 ~/.blackroad/protocol/SEARCH_CMD.md"
echo ""
