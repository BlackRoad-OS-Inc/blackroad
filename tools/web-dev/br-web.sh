#!/usr/bin/env zsh

# Colors
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
NC='\033[0m'

DB_FILE="$HOME/.blackroad/web-dev.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    path TEXT,
    framework TEXT,
    port INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS builds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT,
    build_time REAL,
    bundle_size INTEGER,
    success INTEGER,
    built_at INTEGER
);

CREATE TABLE IF NOT EXISTS performance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT,
    load_time REAL,
    ttfb REAL,
    size_kb INTEGER,
    checked_at INTEGER
);
EOF
}

cmd_serve() {
    local dir="${1:-.}"
    local port="${2:-8080}"
    
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}❌ Directory not found: $dir${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🌐 Starting dev server...${NC}"
    echo -e "  ${BLUE}Directory:${NC} $dir"
    echo -e "  ${BLUE}Port:${NC} $port"
    echo -e "  ${BLUE}URL:${NC} http://localhost:$port"
    echo ""
    echo -e "${GREEN}✓ Server running${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
    
    cd "$dir"
    
    # Use Python's built-in HTTP server
    if command -v python3 &> /dev/null; then
        python3 -m http.server "$port"
    elif command -v python &> /dev/null; then
        python -m SimpleHTTPServer "$port"
    else
        echo -e "${RED}❌ Python not found${NC}"
        exit 1
    fi
}

cmd_scaffold() {
    local framework="$1"
    local name="$2"
    
    if [[ -z "$framework" || -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br web scaffold <framework> <name>${NC}"
        echo ""
        echo "Available frameworks:"
        echo "  react       - React with Vite"
        echo "  vue         - Vue 3 with Vite"
        echo "  next        - Next.js"
        echo "  svelte      - Svelte with Vite"
        echo "  static      - Static HTML/CSS/JS"
        echo "  express     - Express.js API"
        exit 1
    fi
    
    echo -e "${CYAN}🎨 Creating $framework project: $name${NC}\n"
    
    case "$framework" in
        react)
            if command -v npm &> /dev/null; then
                npm create vite@latest "$name" -- --template react
                echo -e "\n${GREEN}✓ React project created${NC}"
                echo "  cd $name && npm install && npm run dev"
            else
                echo -e "${RED}❌ npm not found${NC}"
            fi
            ;;
        vue)
            if command -v npm &> /dev/null; then
                npm create vite@latest "$name" -- --template vue
                echo -e "\n${GREEN}✓ Vue project created${NC}"
                echo "  cd $name && npm install && npm run dev"
            else
                echo -e "${RED}❌ npm not found${NC}"
            fi
            ;;
        next)
            if command -v npx &> /dev/null; then
                npx create-next-app@latest "$name"
                echo -e "\n${GREEN}✓ Next.js project created${NC}"
            else
                echo -e "${RED}❌ npx not found${NC}"
            fi
            ;;
        svelte)
            if command -v npm &> /dev/null; then
                npm create vite@latest "$name" -- --template svelte
                echo -e "\n${GREEN}✓ Svelte project created${NC}"
                echo "  cd $name && npm install && npm run dev"
            else
                echo -e "${RED}❌ npm not found${NC}"
            fi
            ;;
        static)
            mkdir -p "$name"/{css,js,images}
            cat > "$name/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Website</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <h1>Welcome to My Website</h1>
    </header>
    <main>
        <p>Built with BlackRoad CLI</p>
    </main>
    <script src="js/main.js"></script>
</body>
</html>
HTMLEOF
            cat > "$name/css/style.css" << 'CSSEOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    line-height: 1.6;
    padding: 2rem;
}

header {
    text-align: center;
    margin-bottom: 2rem;
}

h1 {
    color: #333;
}
CSSEOF
            cat > "$name/js/main.js" << 'JSEOF'
console.log('Website loaded!');
JSEOF
            echo -e "${GREEN}✓ Static site created${NC}"
            echo "  cd $name && br web serve"
            ;;
        express)
            mkdir -p "$name"
            cd "$name"
            if command -v npm &> /dev/null; then
                npm init -y
                npm install express
                cat > "server.js" << 'SERVEREOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'Welcome to the API' });
});

app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy' });
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
SERVEREOF
                echo -e "\n${GREEN}✓ Express.js API created${NC}"
                echo "  cd $name && node server.js"
            else
                echo -e "${RED}❌ npm not found${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Unknown framework: $framework${NC}"
            exit 1
            ;;
    esac
    
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO projects (name, path, framework, created_at) VALUES ('$name', '$(pwd)/$name', '$framework', $(date +%s));"
}

cmd_build() {
    local dir="${1:-.}"
    
    echo -e "${CYAN}🔨 Building project...${NC}\n"
    
    cd "$dir"
    local start_time=$(date +%s)
    
    if [[ -f "package.json" ]]; then
        # Detect build command
        if grep -q '"build"' package.json; then
            npm run build
        elif grep -q '"next"' package.json; then
            npx next build
        else
            echo -e "${YELLOW}⚠️  No build script found${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  No package.json found${NC}"
        echo "This appears to be a static site"
        exit 0
    fi
    
    local end_time=$(date +%s)
    local build_time=$((end_time - start_time))
    
    # Calculate bundle size
    local bundle_size=0
    if [[ -d "dist" ]]; then
        bundle_size=$(du -sk dist | cut -f1)
    elif [[ -d "build" ]]; then
        bundle_size=$(du -sk build | cut -f1)
    elif [[ -d ".next" ]]; then
        bundle_size=$(du -sk .next | cut -f1)
    fi
    
    echo -e "\n${GREEN}✓ Build complete${NC}"
    echo -e "  ${BLUE}Time:${NC} ${build_time}s"
    echo -e "  ${BLUE}Size:${NC} ${bundle_size}KB"
    
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO builds (project_name, build_time, bundle_size, success, built_at) VALUES ('$(basename $(pwd))', $build_time, $bundle_size, 1, $(date +%s));"
}

cmd_analyze() {
    local dir="${1:-.}"
    
    echo -e "${CYAN}📊 Analyzing bundle...${NC}\n"
    
    cd "$dir"
    
    # Find build output
    local build_dir=""
    if [[ -d "dist" ]]; then
        build_dir="dist"
    elif [[ -d "build" ]]; then
        build_dir="build"
    elif [[ -d ".next" ]]; then
        build_dir=".next"
    else
        echo -e "${RED}❌ No build output found${NC}"
        echo "Run: br web build"
        exit 1
    fi
    
    echo -e "${BLUE}Build Directory:${NC} $build_dir\n"
    
    # Analyze files
    echo -e "${CYAN}Largest Files:${NC}"
    find "$build_dir" -type f -exec du -h {} + | sort -rh | head -10
    
    echo -e "\n${CYAN}File Types:${NC}"
    find "$build_dir" -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
    
    echo -e "\n${CYAN}Total Size:${NC}"
    du -sh "$build_dir"
}

cmd_perf() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}❌ Usage: br web perf <url>${NC}"
        echo "Example: br web perf https://example.com"
        exit 1
    fi
    
    echo -e "${CYAN}⚡ Testing performance...${NC}\n"
    
    # Measure load time
    local start=$(date +%s.%N)
    local response=$(curl -sS -w "\n%{time_total}|%{size_download}|%{time_starttransfer}" -o /dev/null "$url")
    local end=$(date +%s.%N)
    
    local load_time=$(echo "$response" | tail -1 | cut -d'|' -f1)
    local size=$(echo "$response" | tail -1 | cut -d'|' -f2)
    local ttfb=$(echo "$response" | tail -1 | cut -d'|' -f3)
    
    local size_kb=$(echo "scale=2; $size / 1024" | bc)
    
    echo -e "${BLUE}URL:${NC} $url"
    echo -e "${BLUE}Load Time:${NC} ${load_time}s"
    echo -e "${BLUE}TTFB:${NC} ${ttfb}s"
    echo -e "${BLUE}Size:${NC} ${size_kb}KB"
    
    # Performance rating
    local rating=""
    if (( $(echo "$load_time < 1.0" | bc -l) )); then
        rating="${GREEN}Excellent ⚡${NC}"
    elif (( $(echo "$load_time < 2.5" | bc -l) )); then
        rating="${YELLOW}Good ✓${NC}"
    else
        rating="${RED}Needs Improvement ⚠️${NC}"
    fi
    
    echo -e "${BLUE}Rating:${NC} $rating"
    
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO performance (url, load_time, ttfb, size_kb, checked_at) VALUES ('$url', $load_time, $ttfb, $size_kb, $(date +%s));"
}

cmd_seo() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}❌ Usage: br web seo <url>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🔍 Checking SEO...${NC}\n"
    
    local html=$(curl -sS "$url")
    
    # Check title
    local title=$(echo "$html" | grep -o '<title[^>]*>[^<]*</title>' | sed 's/<[^>]*>//g')
    if [[ -n "$title" ]]; then
        echo -e "${GREEN}✓${NC} Title: $title"
    else
        echo -e "${RED}✗${NC} Missing title tag"
    fi
    
    # Check meta description
    if echo "$html" | grep -q '<meta name="description"'; then
        local desc=$(echo "$html" | grep -o '<meta name="description" content="[^"]*"' | sed 's/.*content="//;s/"$//')
        echo -e "${GREEN}✓${NC} Meta description: ${desc:0:60}..."
    else
        echo -e "${RED}✗${NC} Missing meta description"
    fi
    
    # Check Open Graph
    if echo "$html" | grep -q '<meta property="og:'; then
        echo -e "${GREEN}✓${NC} Open Graph tags found"
    else
        echo -e "${YELLOW}⚠${NC} Missing Open Graph tags"
    fi
    
    # Check heading structure
    local h1_count=$(echo "$html" | grep -o '<h1[^>]*>' | wc -l | tr -d ' ')
    if [[ "$h1_count" -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} One H1 tag"
    elif [[ "$h1_count" -gt 1 ]]; then
        echo -e "${YELLOW}⚠${NC} Multiple H1 tags ($h1_count)"
    else
        echo -e "${RED}✗${NC} No H1 tag"
    fi
    
    # Check mobile viewport
    if echo "$html" | grep -q '<meta name="viewport"'; then
        echo -e "${GREEN}✓${NC} Mobile viewport meta tag"
    else
        echo -e "${RED}✗${NC} Missing viewport meta tag"
    fi
    
    # Check HTTPS
    if [[ "$url" =~ ^https:// ]]; then
        echo -e "${GREEN}✓${NC} Using HTTPS"
    else
        echo -e "${YELLOW}⚠${NC} Not using HTTPS"
    fi
}

cmd_screenshot() {
    local url="$1"
    local output="${2:-screenshot.png}"
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}❌ Usage: br web screenshot <url> [output.png]${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📸 Taking screenshot...${NC}"
    
    # Check for screenshot tool
    if command -v screencapture &> /dev/null; then
        # macOS - open in browser and use screencapture
        open "$url"
        sleep 2
        screencapture "$output"
        echo -e "${GREEN}✓ Screenshot saved: $output${NC}"
    elif command -v webkit2png &> /dev/null; then
        webkit2png -F "$url"
        echo -e "${GREEN}✓ Screenshot saved${NC}"
    else
        echo -e "${YELLOW}⚠️  Install webkit2png or use browser dev tools${NC}"
        echo "macOS: brew install webkit2png"
    fi
}

cmd_sitemap() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}❌ Usage: br web sitemap <url>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🗺️  Generating sitemap...${NC}\n"
    
    local sitemap_url="${url}/sitemap.xml"
    
    if curl -sS --head "$sitemap_url" | grep -q "200 OK"; then
        echo -e "${GREEN}✓ Sitemap found: $sitemap_url${NC}"
        curl -sS "$sitemap_url" | grep -o '<loc>[^<]*</loc>' | sed 's/<[^>]*>//g'
    else
        echo -e "${YELLOW}⚠️  No sitemap found at $sitemap_url${NC}"
    fi
}

cmd_optimize() {
    local dir="${1:-.}"
    
    echo -e "${CYAN}⚡ Optimizing assets...${NC}\n"
    
    cd "$dir"
    
    # Optimize images if imagemagick is available
    if command -v convert &> /dev/null; then
        echo "Optimizing images..."
        find . -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -exec convert {} -quality 85 {} \;
        echo -e "${GREEN}✓ Images optimized${NC}"
    else
        echo -e "${YELLOW}⚠️  ImageMagick not found, skipping image optimization${NC}"
    fi
    
    # Minify HTML/CSS/JS
    echo -e "\n${BLUE}Tip:${NC} For production builds, use your framework's built-in optimizer"
    echo "  npm run build -- --optimize"
}

cmd_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR WEB${NC}  ${DIM}Spin up dev servers fast.${NC}"
  echo -e "  ${DIM}Local dev, professional grade.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  serve [port]                    ${NC} Start a static file server"
  echo -e "  ${AMBER}  proxy <port> <target>           ${NC} Reverse proxy to another port"
  echo -e "  ${AMBER}  tunnel                          ${NC} Expose local server via tunnel"
  echo -e "  ${AMBER}  status                          ${NC} Running servers overview"
  echo -e "  ${AMBER}  stop [port]                     ${NC} Stop server on port"
  echo -e "  ${AMBER}  logs [port]                     ${NC} Tail server logs"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br web serve 3000${NC}"
  echo -e "  ${DIM}  br web proxy 8080 http://localhost:3000${NC}"
  echo -e "  ${DIM}  br web tunnel${NC}"
  echo -e "  ${DIM}  br web status${NC}"
  echo -e ""
}
# Main dispatch
init_db

case "${1:-help}" in
    serve|server|dev) cmd_serve "${@:2}" ;;
    scaffold|create|new) cmd_scaffold "${@:2}" ;;
    build) cmd_build "${@:2}" ;;
    analyze|bundle) cmd_analyze "${@:2}" ;;
    perf|performance|speed) cmd_perf "${@:2}" ;;
    seo) cmd_seo "${@:2}" ;;
    screenshot|snap) cmd_screenshot "${@:2}" ;;
    sitemap) cmd_sitemap "${@:2}" ;;
    optimize|opt) cmd_optimize "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
