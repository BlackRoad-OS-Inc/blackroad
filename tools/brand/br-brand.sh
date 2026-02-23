#!/bin/zsh
# BR Brand — BlackRoad OS Brand Template Engine
# Generate brand-compliant HTML pages by feeding in text
#
# Usage:
#   br brand list                              - list available templates
#   br brand new landing --title "X" ...      - generate landing page
#   br brand new agent --title "X" ...        - generate agent profile page
#   br brand new docs --title "X" ...         - generate docs/article page
#   br brand new card --title "X" ...         - generate card/feature snippet
#   br brand preview <template>               - print template info

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

BRAND_DIR="$(dirname "$0")"
OUT_DIR="${BLACKROAD_BRAND_OUT:-$HOME/.blackroad/brand-output}"
mkdir -p "$OUT_DIR"

# ─── BRAND CSS (embedded from official design system) ──────────────────────
BRAND_CSS='
:root {
  --black: #000000;
  --deep-black: #0A0A0A;
  --charcoal: #1A1A1A;
  --white: #FFFFFF;
  --sunrise-orange: #FF9D00;
  --warm-orange: #FF6B00;
  --hot-pink: #FF0066;
  --electric-magenta: #FF006B;
  --deep-magenta: #D600AA;
  --vivid-purple: #7700FF;
  --cyber-blue: #0066FF;
  --gradient-br: linear-gradient(180deg, var(--sunrise-orange) 0%, var(--warm-orange) 25%, var(--hot-pink) 75%, var(--electric-magenta) 100%);
  --gradient-os: linear-gradient(180deg, var(--electric-magenta) 0%, var(--deep-magenta) 25%, var(--vivid-purple) 75%, var(--cyber-blue) 100%);
  --gradient-full: linear-gradient(180deg, var(--sunrise-orange) 0%, var(--warm-orange) 14%, var(--hot-pink) 28%, var(--electric-magenta) 42%, var(--deep-magenta) 57%, var(--vivid-purple) 71%, var(--cyber-blue) 100%);
  --gradient-brand: var(--gradient-full);
  --phi: 1.618;
  --space-xs: 8px;
  --space-sm: 13px;
  --space-md: 21px;
  --space-lg: 34px;
  --space-xl: 55px;
  --space-2xl: 89px;
  --space-3xl: 144px;
  --ease: cubic-bezier(0.25, 0.1, 0.25, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);
}
* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  font-family: "JetBrains Mono", "SF Mono", "Fira Code", "Courier New", monospace;
  background: var(--deep-black);
  color: var(--white);
  overflow-x: hidden;
  line-height: 1.618;
  -webkit-font-smoothing: antialiased;
}
h1 { font-size: calc(2.5rem * 1.618); font-weight: 600; line-height: 1.2; }
h2 { font-size: calc(2rem * 1.618); font-weight: 600; line-height: 1.2; }
h3 { font-size: calc(1.5rem * 1.618); font-weight: 600; line-height: 1.2; }
h4 { font-size: 1.4rem; font-weight: 600; }
p  { font-size: 1rem; line-height: 1.618; color: rgba(255,255,255,0.8); }
a  { color: var(--sunrise-orange); text-decoration: none; }
a:hover { color: var(--hot-pink); }

.scroll-progress {
  position: fixed; top: 0; left: 0; height: 2px;
  background: var(--gradient-brand); z-index: 9999; width: 0%;
  transition: width 0.1s linear;
}
nav {
  position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
  padding: var(--space-md) var(--space-xl);
  display: flex; justify-content: space-between; align-items: center;
  background: rgba(0,0,0,0.85);
  backdrop-filter: saturate(180%) blur(20px);
  border-bottom: 1px solid rgba(255,255,255,0.05);
}
.nav-logo {
  font-size: 1.2rem; font-weight: 700;
  background: var(--gradient-brand);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
.nav-links { display: flex; gap: var(--space-lg); }
.nav-links a { color: rgba(255,255,255,0.7); font-size: 0.9rem; transition: color 0.2s; }
.nav-links a:hover { color: var(--white); }
.container { max-width: 1200px; margin: 0 auto; padding: 0 var(--space-xl); }
.gradient-text {
  background: var(--gradient-brand);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
.gradient-border {
  position: relative; border-radius: var(--space-md);
  background: var(--charcoal);
}
.gradient-border::before {
  content: ""; position: absolute; inset: 0;
  border-radius: inherit; padding: 1px;
  background: var(--gradient-brand);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor; mask-composite: exclude;
}
.card {
  background: rgba(255,255,255,0.04);
  backdrop-filter: blur(10px);
  border-radius: var(--space-md);
  padding: var(--space-xl);
  border: 1px solid rgba(255,255,255,0.08);
  transition: transform 0.3s var(--ease-spring), border-color 0.3s;
}
.card:hover { transform: translateY(-4px); border-color: rgba(255,255,255,0.15); }
.btn {
  display: inline-block;
  padding: var(--space-sm) var(--space-lg);
  border-radius: var(--space-xs);
  font-weight: 600; font-size: 0.95rem;
  cursor: pointer; transition: all 0.3s var(--ease);
  border: none; font-family: inherit;
}
.btn-primary {
  background: var(--gradient-brand);
  color: var(--white);
}
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 10px 30px rgba(255,157,0,0.3); color: var(--white); }
.btn-outline {
  background: transparent; color: var(--white);
  border: 1px solid rgba(255,255,255,0.3);
}
.btn-outline:hover { border-color: var(--hot-pink); color: var(--hot-pink); }
.bg-orb {
  position: fixed; border-radius: 50%;
  filter: blur(100px); pointer-events: none; z-index: 0; opacity: 0.12;
}
.bg-grid {
  position: fixed; inset: 0; z-index: 0; pointer-events: none;
  background-image: linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
                    linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
  background-size: 55px 55px;
}
main { position: relative; z-index: 1; padding-top: 80px; }
.section { padding: var(--space-3xl) 0; }
.section-label {
  font-size: 0.75rem; font-weight: 700; letter-spacing: 0.15em;
  text-transform: uppercase; color: var(--sunrise-orange);
  margin-bottom: var(--space-md);
}
.grid { display: grid; gap: var(--space-lg); }
.grid-2 { grid-template-columns: repeat(2, 1fr); }
.grid-3 { grid-template-columns: repeat(3, 1fr); }
.grid-4 { grid-template-columns: repeat(4, 1fr); }
@media (max-width: 900px) { .grid-3, .grid-4 { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 600px) { .grid-2, .grid-3, .grid-4 { grid-template-columns: 1fr; } h1 { font-size: 2rem; } }
footer {
  border-top: 1px solid rgba(255,255,255,0.06);
  padding: var(--space-xl) 0; text-align: center;
  color: rgba(255,255,255,0.4); font-size: 0.85rem;
}
@keyframes fadeIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes float { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-10px); } }
.animate-in { animation: fadeIn 0.6s var(--ease-out) forwards; }
'

# ─── BRAND JS (scroll progress bar) ───────────────────────────────────────
BRAND_JS='
const bar = document.getElementById("scroll-bar");
if (bar) {
  window.addEventListener("scroll", () => {
    const pct = (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100;
    bar.style.width = Math.min(pct, 100) + "%";
  });
}
document.querySelectorAll(".animate-in").forEach((el, i) => {
  el.style.opacity = "0";
  const obs = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) { e.target.style.animation = `fadeIn 0.6s ${i * 0.1}s ease-out forwards`; obs.unobserve(e.target); }
    });
  }, { threshold: 0.1 });
  obs.observe(el);
});
'

# ─── HELPERS ──────────────────────────────────────────────────────────────
_html_head() {
  local title="$1" desc="$2"
  # Pull OG/social meta from env (exported by _cmd_site/_cmd_new --config)
  local og_title="${BR_BRAND_OG_TITLE:-${title}}"
  local og_desc="${BR_BRAND_OG_DESC:-${desc}}"
  local og_image="${BR_BRAND_OG_IMAGE:-}"
  local og_url="${BR_BRAND_OG_URL:-}"
  local og_type="${BR_BRAND_OG_TYPE:-website}"
  local tw_handle="${BR_BRAND_TWITTER:-}"
  local site_name="${BR_BRAND_SITE_NAME:-BlackRoad OS}"
  local favicon="${BR_BRAND_FAVICON:-}"

  local og_image_tag="" og_url_tag="" tw_handle_tag="" favicon_tag=""
  [[ -n "$og_image" ]] && og_image_tag="  <meta property=\"og:image\" content=\"${og_image}\" />"$'\n'
  [[ -n "$og_url"   ]] && og_url_tag="  <meta property=\"og:url\" content=\"${og_url}\" />"$'\n'
  [[ -n "$tw_handle" ]] && tw_handle_tag="  <meta name=\"twitter:site\" content=\"${tw_handle}\" />"$'\n'
  [[ -n "$favicon"  ]] && favicon_tag="  <link rel=\"icon\" href=\"${favicon}\" />"$'\n'

  cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title} — ${site_name}</title>
  <meta name="description" content="${desc}" />
  <!-- Open Graph -->
  <meta property="og:type" content="${og_type}" />
  <meta property="og:site_name" content="${site_name}" />
  <meta property="og:title" content="${og_title}" />
  <meta property="og:description" content="${og_desc}" />
${og_image_tag}${og_url_tag}  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${og_title}" />
  <meta name="twitter:description" content="${og_desc}" />
${og_image_tag}${tw_handle_tag}${favicon_tag}  <style>${BRAND_CSS}</style>
</head>
<body>
<div id="scroll-bar" class="scroll-progress"></div>
<div class="bg-grid"></div>
<div class="bg-orb" style="width:600px;height:600px;top:-200px;right:-200px;background:var(--vivid-purple);"></div>
<div class="bg-orb" style="width:400px;height:400px;bottom:10%;left:-100px;background:var(--hot-pink);"></div>
EOF
}

_html_nav() {
  local logo_text="${1:-BlackRoad OS}" nav_links="${2:-${BR_BRAND_NAV:-}}"
  local logo_html
  if [[ -n "${BR_BRAND_LOGO:-}" ]]; then
    logo_html="<img src=\"${BR_BRAND_LOGO}\" alt=\"${logo_text}\" style=\"height:28px;width:auto;object-fit:contain;\" />"
  else
    logo_html="${logo_text}"
  fi
  echo "<nav><div class=\"nav-logo\">${logo_html}</div><div class=\"nav-links\">${nav_links}</div></nav>"
}

_html_footer() {
  local year; year=$(date +%Y)
  local text="${BR_BRAND_FOOTER:-© ${year} BlackRoad OS, Inc. All rights reserved.}"
  echo "<footer><div class=\"container\"><p>${text}</p></div></footer>"
}

_html_close() {
  cat <<EOF
<script>${BRAND_JS}</script>
</body>
</html>
EOF
}

# ─── TEMPLATE: LANDING ────────────────────────────────────────────────────
_tpl_landing() {
  local title="$1" tagline="$2" desc="$3" cta_text="${4:-Get Started}" cta_url="${5:-#}" output="$6"

  # Parse feature items from remaining args (format: "Icon|Title|Desc")
  shift 6
  local features=("$@")

  {
    _html_head "$title" "$desc"
    _html_nav "$title"

    cat <<EOF
<main>
  <!-- Hero -->
  <section class="section" style="min-height:80vh;display:flex;align-items:center;text-align:center;">
    <div class="container">
      <div class="section-label animate-in">BlackRoad OS</div>
      <h1 class="gradient-text animate-in" style="margin-bottom:var(--space-lg);">${title}</h1>
      <p style="font-size:1.3rem;max-width:640px;margin:0 auto var(--space-xl);" class="animate-in">${tagline}</p>
      <div style="display:flex;gap:var(--space-md);justify-content:center;flex-wrap:wrap;" class="animate-in">
        <a href="${cta_url}" class="btn btn-primary">${cta_text}</a>
        <a href="#features" class="btn btn-outline">Learn More</a>
      </div>
    </div>
  </section>

  <!-- Description -->
  <section class="section" id="about">
    <div class="container" style="max-width:800px;text-align:center;">
      <p style="font-size:1.1rem;line-height:1.8;" class="animate-in">${desc}</p>
    </div>
  </section>
EOF

    # Features section
    if [[ ${#features[@]} -gt 0 ]]; then
      echo "  <section class=\"section\" id=\"features\">"
      echo "    <div class=\"container\">"
      echo "      <div class=\"section-label text-center animate-in\">Features</div>"
      local cols=3
      [[ ${#features[@]} -eq 2 ]] && cols=2
      [[ ${#features[@]} -eq 4 ]] && cols=4
      echo "      <div class=\"grid grid-${cols}\" style=\"margin-top:var(--space-xl);\">"
      for feat in "${features[@]}"; do
        local icon="${feat%%|*}"
        local rest="${feat#*|}"
        local ftitle="${rest%%|*}"
        local fdesc="${rest#*|}"
        cat <<EOF
        <div class="card animate-in">
          <div style="font-size:2rem;margin-bottom:var(--space-md);">${icon}</div>
          <h4 style="margin-bottom:var(--space-sm);">${ftitle}</h4>
          <p style="font-size:0.9rem;">${fdesc}</p>
        </div>
EOF
      done
      echo "      </div>"
      echo "    </div>"
      echo "  </section>"
    fi

    # CTA section
    cat <<EOF
  <section class="section" style="text-align:center;">
    <div class="container">
      <div class="gradient-border" style="display:inline-block;padding:var(--space-2xl) var(--space-3xl);border-radius:var(--space-lg);">
        <h2 style="margin-bottom:var(--space-lg);" class="animate-in">Ready to build?</h2>
        <a href="${cta_url}" class="btn btn-primary animate-in">${cta_text} →</a>
      </div>
    </div>
  </section>
</main>
EOF
    _html_footer
    _html_close
  } > "$output"
}

# ─── TEMPLATE: AGENT ──────────────────────────────────────────────────────
_tpl_agent() {
  local name="$1" type="$2" tagline="$3" bio="$4" emoji="${5:-🤖}" output="$6"
  shift 6
  local skills=("$@")  # format: "SkillName|pct"

  {
    _html_head "$name — Agent" "$bio"
    _html_nav "BlackRoad OS" "<a href=\"/agents\">Agents</a>"

    cat <<EOF
<main>
  <section class="section" style="text-align:center;">
    <div class="container" style="max-width:700px;">
      <div style="font-size:5rem;margin-bottom:var(--space-lg);animation:float 4s ease-in-out infinite;">${emoji}</div>
      <div class="section-label animate-in">${type}</div>
      <h1 class="gradient-text animate-in">${name}</h1>
      <p style="font-size:1.2rem;margin-top:var(--space-lg);" class="animate-in">${tagline}</p>
    </div>
  </section>

  <!-- Bio -->
  <section class="section">
    <div class="container" style="max-width:800px;">
      <div class="card animate-in">
        <div class="section-label">About</div>
        <p style="font-size:1rem;line-height:1.8;margin-top:var(--space-md);">${bio}</p>
      </div>
    </div>
  </section>
EOF

    # Skills
    if [[ ${#skills[@]} -gt 0 ]]; then
      cat <<EOF
  <section class="section">
    <div class="container" style="max-width:800px;">
      <div class="section-label animate-in">Capabilities</div>
      <div style="margin-top:var(--space-xl);display:flex;flex-direction:column;gap:var(--space-md);">
EOF
      for skill in "${skills[@]}"; do
        local sname="${skill%%|*}"
        local spct="${skill#*|}"
        cat <<EOF
        <div class="animate-in">
          <div style="display:flex;justify-content:space-between;margin-bottom:var(--space-xs);">
            <span style="font-size:0.9rem;font-weight:600;">${sname}</span>
            <span style="font-size:0.85rem;color:rgba(255,255,255,0.5);">${spct}%</span>
          </div>
          <div style="height:4px;background:rgba(255,255,255,0.08);border-radius:2px;">
            <div style="height:100%;width:${spct}%;background:var(--gradient-brand);border-radius:2px;transition:width 1s var(--ease-out);"></div>
          </div>
        </div>
EOF
      done
      echo "      </div>"
      echo "    </div>"
      echo "  </section>"
    fi

    echo "</main>"
    _html_footer
    _html_close
  } > "$output"
}

# ─── TEMPLATE: DOCS ───────────────────────────────────────────────────────
_tpl_docs() {
  local title="$1" subtitle="$2" author="${3:-BlackRoad OS}" output="$4"
  shift 4
  local sections=("$@")  # format: "Section Title|content text"

  {
    _html_head "$title" "$subtitle"
    _html_nav "BlackRoad OS" "<a href=\"/docs\">Docs</a> <a href=\"/\">Home</a>"

    cat <<EOF
<main>
  <section class="section" style="max-width:800px;margin:0 auto;">
    <div class="container">
      <div class="section-label animate-in">${author}</div>
      <h1 class="animate-in" style="margin-bottom:var(--space-md);">${title}</h1>
      <p style="font-size:1.1rem;color:rgba(255,255,255,0.6);margin-bottom:var(--space-2xl);" class="animate-in">${subtitle}</p>
      <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin-bottom:var(--space-2xl);" />
EOF

    for sec in "${sections[@]}"; do
      local stitle="${sec%%|*}"
      local scontent="${sec#*|}"
      cat <<EOF
      <div class="animate-in" style="margin-bottom:var(--space-2xl);">
        <h3 style="margin-bottom:var(--space-md);color:var(--white);">${stitle}</h3>
        <p style="line-height:1.8;">${scontent}</p>
      </div>
EOF
    done

    cat <<EOF
    </div>
  </section>
</main>
EOF
    _html_footer
    _html_close
  } > "$output"
}

# ─── TEMPLATE: CARD (snippet only) ────────────────────────────────────────
_tpl_card() {
  local title="$1" desc="$2" icon="${3:-✦}" badge="${4:-}" link="${5:-#}" output="$6"

  cat <<EOF > "$output"
<!-- BlackRoad OS Brand Card — copy into any page -->
<div class="card animate-in">
  <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:var(--space-md);">
    <span style="font-size:2rem;">${icon}</span>
    $([ -n "$badge" ] && echo "<span style=\"font-size:0.75rem;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;padding:4px 10px;border-radius:4px;background:var(--gradient-brand);color:var(--white);\">${badge}</span>")
  </div>
  <h4 style="margin-bottom:var(--space-sm);">${title}</h4>
  <p style="font-size:0.9rem;margin-bottom:var(--space-lg);">${desc}</p>
  <a href="${link}" class="btn btn-outline" style="font-size:0.85rem;">Learn More →</a>
</div>
<!-- End Card -->
EOF
}

# ─── TEMPLATE: PRICING ───────────────────────────────────────────────────
# Tiers format: "Name|Price|Period|Desc|feat1,feat2,feat3|cta_text|cta_url|highlight"
# highlight = "true" to make a tier pop with gradient border
_tpl_pricing() {
  local title="$1" subtitle="$2" output="$3"
  shift 3
  local tiers=("$@")

  {
    _html_head "$title" "$subtitle"
    _html_nav "BlackRoad OS" "<a href=\"/\">Home</a>"

    cat <<EOF
<main>
  <section class="section" style="text-align:center;">
    <div class="container">
      <div class="section-label animate-in">Pricing</div>
      <h1 class="gradient-text animate-in">${title}</h1>
      <p style="font-size:1.1rem;max-width:560px;margin:var(--space-lg) auto 0;" class="animate-in">${subtitle}</p>
    </div>
  </section>

  <section class="section">
    <div class="container">
      <div class="grid grid-${#tiers[@]}" style="align-items:start;">
EOF

    for tier in "${tiers[@]}"; do
      local tname="${tier%%|*}"; local r1="${tier#*|}"; local tprice="${r1%%|*}"; local r2="${r1#*|}"
      local tperiod="${r2%%|*}"; local r3="${r2#*|}"; local tdesc="${r3%%|*}"; local r4="${r3#*|}"
      local tfeats="${r4%%|*}"; local r5="${r4#*|}"; local tcta="${r5%%|*}"; local r6="${r5#*|}"
      local tcta_url="${r6%%|*}"; local thighlight="${r6#*|}"

      local wrapper_open="" wrapper_close=""
      if [[ "$thighlight" == "true" ]]; then
        wrapper_open='<div class="gradient-border" style="border-radius:var(--space-md);padding:1px;">'
        wrapper_close='</div>'
      fi

      echo "        ${wrapper_open}"
      cat <<EOF
        <div class="card animate-in" style="text-align:center;$([ "$thighlight" = "true" ] && echo "background:rgba(255,255,255,0.07);")">
          <div class="section-label" style="text-align:center;">${tname}</div>
          <div style="margin:var(--space-lg) 0;">
            <span style="font-size:3.5rem;font-weight:700;background:var(--gradient-brand);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;">${tprice}</span>
            <span style="color:rgba(255,255,255,0.5);font-size:0.9rem;"> / ${tperiod}</span>
          </div>
          <p style="font-size:0.9rem;margin-bottom:var(--space-xl);">${tdesc}</p>
          <ul style="list-style:none;text-align:left;margin-bottom:var(--space-xl);">
EOF
      IFS=',' read -rA feat_list <<< "$tfeats"
      for feat in "${feat_list[@]}"; do
        feat="${feat## }"; feat="${feat%% }"
        echo "            <li style=\"padding:var(--space-xs) 0;font-size:0.9rem;border-bottom:1px solid rgba(255,255,255,0.05);\">✓ &nbsp;${feat}</li>"
      done
      cat <<EOF
          </ul>
          <a href="${tcta_url}" class="btn $([ "$thighlight" = "true" ] && echo "btn-primary" || echo "btn-outline")" style="width:100%;text-align:center;">${tcta}</a>
        </div>
EOF
      echo "        ${wrapper_close}"
    done

    cat <<EOF
      </div>
    </div>
  </section>
</main>
EOF
    _html_footer
    _html_close
  } > "$output"
}

# ─── TEMPLATE: 404 ────────────────────────────────────────────────────────
_tpl_404() {
  local title="${1:-404}" message="${2:-Page not found}" home_url="${3:-/}" output="$4"

  {
    _html_head "404 — ${title}" "$message"
    _html_nav "BlackRoad OS"

    cat <<EOF
<main style="min-height:100vh;display:flex;align-items:center;justify-content:center;text-align:center;">
  <div class="container" style="max-width:600px;">
    <div style="font-size:8rem;font-weight:900;line-height:1;
                background:var(--gradient-brand);
                -webkit-background-clip:text;-webkit-text-fill-color:transparent;
                background-clip:text;
                animation:glitch 2s infinite;
                margin-bottom:var(--space-lg);">404</div>
    <h2 class="animate-in" style="margin-bottom:var(--space-md);">${title}</h2>
    <p class="animate-in" style="margin-bottom:var(--space-xl);">${message}</p>
    <div style="display:flex;gap:var(--space-md);justify-content:center;flex-wrap:wrap;" class="animate-in">
      <a href="${home_url}" class="btn btn-primary">← Go Home</a>
      <a href="javascript:history.back()" class="btn btn-outline">Go Back</a>
    </div>
    <div style="margin-top:var(--space-3xl);opacity:0.2;font-size:0.8rem;font-family:monospace;">
      ERROR_CODE: 404 | AGENT: NULL | STATUS: NOT_FOUND
    </div>
  </div>
</main>
<style>
@keyframes glitch {
  0%,100% { text-shadow: none; }
  20% { text-shadow: -3px 0 var(--hot-pink), 3px 0 var(--cyber-blue); }
  40% { text-shadow: 3px 0 var(--vivid-purple), -3px 0 var(--sunrise-orange); }
  60% { text-shadow: none; }
  80% { text-shadow: -2px 0 var(--electric-magenta), 2px 0 var(--cyber-blue); }
}
</style>
EOF
    _html_footer
    _html_close
  } > "$output"
}

# ─── TEMPLATE: FEATURE ────────────────────────────────────────────────────
# Alternating split-layout rows. items format: "Icon|Title|Desc"
_tpl_feature() {
  local title="$1" subtitle="$2" output="$3"
  shift 3
  local items=("$@")

  {
    _html_head "$title" "$subtitle"
    _html_nav "BlackRoad OS" "<a href=\"/\">Home</a> <a href=\"#features\">Features</a>"

    cat <<EOF
<main>
  <section class="section" style="text-align:center;">
    <div class="container">
      <div class="section-label animate-in">Features</div>
      <h1 class="gradient-text animate-in">${title}</h1>
      <p style="font-size:1.1rem;max-width:640px;margin:var(--space-lg) auto 0;" class="animate-in">${subtitle}</p>
    </div>
  </section>

  <section class="section" id="features">
    <div class="container" style="max-width:960px;">
EOF

    local idx=0
    for item in "${items[@]}"; do
      local iicon="${item%%|*}"; local rest="${item#*|}"; local ititle="${rest%%|*}"; local idesc="${rest#*|}"
      local reverse=""
      [[ $((idx % 2)) -eq 1 ]] && reverse="flex-direction:row-reverse;"
      cat <<EOF
      <div class="animate-in" style="display:flex;gap:var(--space-2xl);align-items:center;margin-bottom:var(--space-3xl);${reverse}flex-wrap:wrap;">
        <div style="flex:0 0 140px;text-align:center;">
          <div style="font-size:4rem;background:var(--charcoal);border-radius:var(--space-lg);padding:var(--space-xl);display:inline-block;border:1px solid rgba(255,255,255,0.06);">${iicon}</div>
        </div>
        <div style="flex:1;min-width:240px;">
          <h3 style="margin-bottom:var(--space-md);">${ititle}</h3>
          <p style="line-height:1.8;">${idesc}</p>
        </div>
      </div>
EOF
      idx=$((idx + 1))
    done

    cat <<EOF
    </div>
  </section>
</main>
EOF
    _html_footer
    _html_close
  } > "$output"
}

# ─── TEMPLATE: BLOG ───────────────────────────────────────────────────────
# sections format: "Heading|Body text"
# tags format: comma-separated string passed as single arg
_tpl_blog() {
  local title="$1" subtitle="$2" author="${3:-BlackRoad OS}" date_str="${4:-}" tags="${5:-}" output="$6"
  shift 6
  local sections=("$@")

  [[ -z "$date_str" ]] && date_str=$(date "+%B %d, %Y")

  {
    _html_head "$title" "$subtitle"
    _html_nav "BlackRoad OS" "<a href=\"/blog\">Blog</a> <a href=\"/\">Home</a>"

    cat <<EOF
<main>
  <!-- Hero -->
  <section class="section" style="text-align:center;max-width:860px;margin:0 auto;">
    <div class="container">
EOF
    # Tags
    if [[ -n "$tags" ]]; then
      echo "      <div style=\"display:flex;gap:var(--space-sm);justify-content:center;flex-wrap:wrap;margin-bottom:var(--space-lg);\" class=\"animate-in\">"
      IFS=',' read -rA tag_list <<< "$tags"
      for tag in "${tag_list[@]}"; do
        tag="${tag## }"; tag="${tag%% }"
        echo "        <span style=\"font-size:0.75rem;font-weight:700;letter-spacing:0.1em;text-transform:uppercase;padding:4px 12px;border-radius:20px;border:1px solid rgba(255,157,0,0.4);color:var(--sunrise-orange);\">${tag}</span>"
      done
      echo "      </div>"
    fi

    cat <<EOF
      <h1 class="animate-in" style="margin-bottom:var(--space-lg);">${title}</h1>
      <p style="font-size:1.1rem;color:rgba(255,255,255,0.6);margin-bottom:var(--space-xl);" class="animate-in">${subtitle}</p>
      <div style="display:flex;align-items:center;justify-content:center;gap:var(--space-md);color:rgba(255,255,255,0.4);font-size:0.85rem;" class="animate-in">
        <span>✍ ${author}</span>
        <span>·</span>
        <span>${date_str}</span>
      </div>
    </div>
  </section>

  <section style="border-top:1px solid rgba(255,255,255,0.06);padding:var(--space-3xl) 0;">
    <div class="container" style="max-width:740px;">
EOF

    for sec in "${sections[@]}"; do
      local sheading="${sec%%|*}"
      local sbody="${sec#*|}"
      cat <<EOF
      <div class="animate-in" style="margin-bottom:var(--space-2xl);">
        <h2 style="font-size:1.6rem;margin-bottom:var(--space-md);color:var(--white);">${sheading}</h2>
        <p style="line-height:1.9;font-size:1.05rem;">${sbody}</p>
      </div>
EOF
    done

    cat <<EOF
    </div>
  </section>
</main>
EOF
    _html_footer
    _html_close
  } > "$output"
}

# ─── DEPLOY ──────────────────────────────────────────────────────────────
_cmd_deploy() {
  local project="" file="" dir="" env="production"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project|-p) project="$2"; shift 2 ;;
      --file|-f)    file="$2";    shift 2 ;;
      --dir|-d)     dir="$2";     shift 2 ;;
      --env)        env="$2";     shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ -z "$project" ]]; then
    echo -e "${RED}✗ --project required${NC}  e.g. br brand deploy --project my-site --file index.html"
    exit 1
  fi

  # Resolve deploy target: single file → temp dir, or use dir
  local deploy_dir=""
  if [[ -n "$file" ]]; then
    deploy_dir=$(mktemp -d)
    cp "$file" "${deploy_dir}/index.html"
    echo -e "${CYAN}→ Deploying file:${NC} $file"
  elif [[ -n "$dir" ]]; then
    deploy_dir="$dir"
    echo -e "${CYAN}→ Deploying dir:${NC} $dir"
  else
    echo -e "${RED}✗ Provide --file or --dir${NC}"
    exit 1
  fi

  if ! command -v wrangler &>/dev/null; then
    echo -e "${RED}✗ wrangler not found.${NC} Install: npm install -g wrangler"
    exit 1
  fi

  echo -e "${CYAN}→ Project:${NC} $project"
  echo -e "${CYAN}→ Env:${NC}     $env"
  echo ""
  wrangler pages deploy "$deploy_dir" \
    --project-name="$project" \
    --branch="$([[ "$env" == "production" ]] && echo main || echo "$env")"

  local exit_code=$?
  [[ -n "$file" ]] && rm -rf "$deploy_dir"

  if [[ $exit_code -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ Deployed to Cloudflare Pages${NC}"
    echo -e "  https://${project}.pages.dev"
  else
    echo ""
    echo -e "${RED}✗ Deploy failed (exit $exit_code)${NC}"
    echo ""
    echo -e "${YELLOW}Common fixes:${NC}"
    echo -e "  • ${CYAN}wrangler login${NC}                  — re-authenticate (token may have expired)"
    echo -e "  • ${CYAN}wrangler whoami${NC}                 — confirm you are logged in"
    echo -e "  • ${CYAN}wrangler pages project create ${project}${NC}  — pre-create the Pages project"
    echo -e "  • Cloudflare API error 8000000 = transient server error — retry in a moment"
    echo ""
    echo -e "  Logs: ${YELLOW}~/.wrangler/logs/${NC}"
    exit $exit_code
  fi
}

# ─── AUDIT ───────────────────────────────────────────────────────────────
_cmd_audit() {
  local file="$1"
  if [[ -z "$file" || ! -f "$file" ]]; then
    echo -e "${RED}✗ Usage: br brand audit <file.html>${NC}"
    exit 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}Brand Compliance Audit${NC} — ${file}"
  echo -e "${CYAN}─────────────────────────────────────────${NC}"

  local pass=0 fail=0

  _check() {
    local label="$1" pattern="$2"
    if grep -q "$pattern" "$file" 2>/dev/null; then
      echo -e "  ${GREEN}✓${NC} $label"
      pass=$((pass+1))
    else
      echo -e "  ${RED}✗${NC} $label"
      fail=$((fail+1))
    fi
  }

  _check "Brand colors defined (--sunrise-orange)"  "sunrise-orange"
  _check "Brand gradient (--gradient-brand)"        "gradient-brand"
  _check "Hot pink (#FF0066)"                       "FF0066\|hot-pink"
  _check "Cyber blue (#0066FF)"                     "0066FF\|cyber-blue"
  _check "Vivid purple (#7700FF)"                   "7700FF\|vivid-purple"
  _check "Golden ratio spacing (--space-)"          "\-\-space-"
  _check "Scroll progress bar"                      "scroll-progress\|scroll-bar"
  _check "backdrop-filter / glassmorphism"          "backdrop-filter"
  _check "animate-in class"                         "animate-in"
  _check "Gradient text (.gradient-text)"           "gradient-text\|background-clip:text\|background-clip: text"
  _check "Brand font stack"                         "JetBrains Mono\|SF Mono\|Courier New"
  _check "Golden ratio line-height (1.618)"         "1\.618"

  echo ""
  local total=$((pass+fail))
  local pct=$(( pass * 100 / total ))
  if [[ $fail -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}✓ PASS${NC} — ${pass}/${total} checks (${pct}%)"
  elif [[ $pct -ge 75 ]]; then
    echo -e "  ${YELLOW}${BOLD}⚠ PARTIAL${NC} — ${pass}/${total} checks (${pct}%)"
  else
    echo -e "  ${RED}${BOLD}✗ FAIL${NC} — ${pass}/${total} checks (${pct}%)"
  fi
  echo ""
}

# ─── LIST ─────────────────────────────────────────────────────────────────
_cmd_list() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║  BR Brand — Template Engine  💜              ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}Available Templates:${NC}"
  echo ""
  echo -e "  ${GREEN}landing${NC}   Full landing page with hero, features grid, CTA"
  echo -e "  ${GREEN}agent${NC}     Agent profile page with skill progress bars"
  echo -e "  ${GREEN}docs${NC}      Documentation / article page with sections"
  echo -e "  ${GREEN}pricing${NC}   Pricing tiers page with feature lists"
  echo -e "  ${GREEN}feature${NC}   Alternating split-layout feature showcase"
  echo -e "  ${GREEN}blog${NC}      Blog post with author, tags, and sections"
  echo -e "  ${GREEN}404${NC}          Branded 404 error page with glitch animation"
  echo -e "  ${GREEN}card${NC}         Reusable card HTML snippet (embed anywhere)"
  echo -e "  ${GREEN}hero${NC}         Full-width hero section — gradient headline, dual CTAs"
  echo -e "  ${GREEN}stats${NC}        Horizontal stats bar — value + label tiles"
  echo -e "  ${GREEN}testimonial${NC}  Quote card grid — avatar initial, name, role, quote"
  echo -e "  ${GREEN}codeblock${NC}     Styled dark code block with copy-button chrome"
  echo -e "  ${GREEN}coming-soon${NC}  Live countdown + email capture (no back-end required)"
  echo -e "  ${GREEN}changelog${NC}    Release notes — version badge, date, tagged bullet lists"
  echo -e "  ${GREEN}team${NC}         Team member card grid — avatar, name, role, bio, link"
  echo -e "  ${GREEN}checkout${NC}     Stripe checkout card — price, features, buy button (Stripe Checkout)"
  echo ""
  echo -e "${YELLOW}Commands:${NC}"
  echo ""
  echo -e "  ${CYAN}br brand init${NC} [brand.json]              Interactive setup wizard"
  echo -e "  ${CYAN}br brand site${NC} [--config brand.json]     Generate full 5-page site"
  echo -e "  ${CYAN}br brand new <template> [flags]${NC}         Generate a page"
  echo -e "  ${CYAN}br brand deploy${NC} --project x --dir y    Push to Cloudflare Pages"
  echo -e "  ${CYAN}br brand audit${NC} <file.html>              Check brand compliance"
  echo -e "  ${CYAN}br brand watch${NC} [--config brand.json]    Auto-rebuild on file change"
  echo -e "  ${CYAN}br brand open${NC} [file.html]               Open in browser"
  echo -e "  ${CYAN}br brand export${NC} [--dir ./site]          Zip all pages"
  echo -e "  ${CYAN}br brand preview <template>${NC}             Show template structure"
  echo ""
  echo -e "${YELLOW}Key flags:${NC}"
  echo ""
  echo -e "  landing     : --title --tagline --desc --cta --cta-url --feature \"🚀|Title|Desc\" --output"
  echo -e "  agent       : --title --type --tagline --bio --emoji --skill \"Name|pct\" --output"
  echo -e "  docs        : --title --subtitle --author --section \"Heading|Body\" --output"
  echo -e "  pricing     : --title --subtitle --tier \"Name|Price|Period|Desc|feats|CTA|url|highlight\" --output"
  echo -e "  feature     : --title --subtitle --item \"🔥|Title|Desc\" --output"
  echo -e "  blog        : --title --subtitle --author --date --tags \"ai\" --section \"H|Body\" --output"
  echo -e "  404         : --title --message --home-url --output"
  echo -e "  card        : --title --desc --icon --badge --link --output"
  echo -e "  hero        : --title --tagline --desc --cta --cta-url --secondary-cta --secondary-url --badge --output"
  echo -e "  stats       : --title --subtitle --stat \"30K|Agents\" --output"
  echo -e "  testimonial : --title --subtitle --testimonial \"A|Alice|CEO|Great product\" --output"
  echo -e "  codeblock   : --title --language bash --code \"echo hi\" --output"
  echo -e "  coming-soon : --title --tagline --launch-date \"2026-04-01T00:00:00\" --output"
  echo -e "  changelog   : --title --subtitle --entry \"v1.0|2026-01-01|Added X,Fixed Y|feature,fix\" --output"
  echo -e "  team        : --title --subtitle --member \"A|Alice|CEO|Bio here|https://github.com/...\" --output"
  echo -e "  checkout    : --title \"Pro Plan\" --price \"\$49/mo\" --price-id \"price_xxx\" --worker URL --feature X --cta \"Buy\" --output"
  echo ""
  echo -e "  ${YELLOW}All templates accept:${NC} --config brand.json  (pre-fill from config file)"
  echo ""
  echo -e "${PURPLE}Default output dir: ${OUT_DIR}${NC}"
  echo ""
}

# ─── PREVIEW ──────────────────────────────────────────────────────────────
_cmd_preview() {
  case "$1" in
    landing)     echo -e "${CYAN}landing${NC}:     Hero → Description → Feature Grid (2-4 cols) → CTA section" ;;
    agent)       echo -e "${CYAN}agent${NC}:       Emoji hero → Bio card → Skill progress bars" ;;
    docs)        echo -e "${CYAN}docs${NC}:        Title/subtitle → Divider → Sectioned content" ;;
    pricing)     echo -e "${CYAN}pricing${NC}:     Hero → Tier cards (gradient-border on highlight tier)" ;;
    feature)     echo -e "${CYAN}feature${NC}:     Hero → Alternating split rows (icon left/right + text)" ;;
    blog)        echo -e "${CYAN}blog${NC}:        Tags → Hero title → Author/date → Body sections" ;;
    404)         echo -e "${CYAN}404${NC}:         Glitch-animated 404 → message → Home + Back buttons" ;;
    card)        echo -e "${CYAN}card${NC}:        Standalone card HTML snippet (embed in any grid)" ;;
    hero)        echo -e "${CYAN}hero${NC}:        Full-width hero — badge → gradient title → tagline → dual CTAs" ;;
    stats)       echo -e "${CYAN}stats${NC}:       Centered stats bar — value tiles with brand gradient values" ;;
    testimonial) echo -e "${CYAN}testimonial${NC}: Quote card grid — avatar initial, name, role, pull-quote" ;;
    codeblock)   echo -e "${CYAN}codeblock${NC}:   Dark code panel — language tab, line numbers, copy button chrome" ;;
    coming-soon) echo -e "${CYAN}coming-soon${NC}: Full-gradient page — live countdown, email capture form" ;;
    changelog)   echo -e "${CYAN}changelog${NC}:   Release log — version + date + tagged bullets per entry" ;;
    team)        echo -e "${CYAN}team${NC}:        Card grid — avatar initial, name, role, bio, GitHub link" ;;
    checkout)    echo -e "${CYAN}checkout${NC}:   Stripe checkout page — price card, features list, buy button" ;;
    *)           echo -e "${RED}Unknown template: $1${NC}"; _cmd_list ;;
  esac
}

# ─── NEW ──────────────────────────────────────────────────────────────────
_cmd_new() {
  local tpl="$1"; shift

  # Defaults
  local title="BlackRoad OS" tagline="" desc="" cta_text="Get Started" cta_url="#"
  local type="Agent" bio="" emoji="🤖"
  local subtitle="" author="BlackRoad OS" date_str="" tags=""
  local message="Page not found" home_url="/"
  local icon="✦" badge="" link="#"
  local secondary_cta="" secondary_url="#"
  local language="bash" code_text=""
  local launch_date=""
  local output="" config_file=""
  local price="" price_id="" stripe_worker="https://blackroad-stripe.workers.dev"
  local -a features skills sections tiers items stats testimonials members entries

  # Pre-scan for --config so we can load defaults before flag parsing
  local -a _argv=("$@")
  for ((i=1; i<=${#_argv}; i++)); do
    if [[ "${_argv[$i]}" == "--config" ]]; then
      config_file="${_argv[$((i+1))]}"
      break
    fi
  done

  # Load brand.json defaults (explicit flags below will override these)
  if [[ -n "$config_file" && -f "$config_file" ]]; then
    title=$(_cfg_get "$config_file" "name" "$title")
    tagline=$(_cfg_get "$config_file" "tagline" "$tagline")
    desc=$(_cfg_get "$config_file" "description" "$desc")
    cta_text=$(_cfg_get "$config_file" "cta_text" "$cta_text")
    cta_url=$(_cfg_get "$config_file" "cta_url" "$cta_url")
    # Export nav + footer so _html_nav/_html_footer pick them up
    export BR_BRAND_NAV=$(python3 -c "
import json,sys
d=json.load(open('$config_file'))
items=d.get('nav',[])
print(''.join(f'<a href=\"{i[\"url\"]}\">{i[\"label\"]}</a>' for i in items))
" 2>/dev/null)
    export BR_BRAND_FOOTER=$(_cfg_get "$config_file" "footer" "")
    export BR_BRAND_SITE_NAME=$(_cfg_get "$config_file" "name" "BlackRoad OS")
    export BR_BRAND_OG_TITLE=$(_cfg_get "$config_file" "name" "")
    export BR_BRAND_OG_DESC=$(_cfg_get "$config_file" "description" "")
    export BR_BRAND_OG_IMAGE=$(_cfg_get "$config_file" "og_image" "")
    export BR_BRAND_OG_URL=$(_cfg_get "$config_file" "og_url" "")
    export BR_BRAND_TWITTER=$(_cfg_get "$config_file" "twitter" "")
    export BR_BRAND_LOGO=$(_cfg_get "$config_file" "logo" "")
    export BR_BRAND_FAVICON=$(_cfg_get "$config_file" "favicon" "")
  fi

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)         title="$2";            shift 2 ;;
      --tagline)       tagline="$2";          shift 2 ;;
      --desc)          desc="$2";             shift 2 ;;
      --cta)           cta_text="$2";         shift 2 ;;
      --cta-url)       cta_url="$2";          shift 2 ;;
      --feature)       features+=("$2");      shift 2 ;;
      --type)          type="$2";             shift 2 ;;
      --bio)           bio="$2";              shift 2 ;;
      --emoji)         emoji="$2";            shift 2 ;;
      --skill)         skills+=("$2");        shift 2 ;;
      --subtitle)      subtitle="$2";         shift 2 ;;
      --author)        author="$2";           shift 2 ;;
      --section)       sections+=("$2");      shift 2 ;;
      --tier)          tiers+=("$2");         shift 2 ;;
      --item)          items+=("$2");         shift 2 ;;
      --date)          date_str="$2";         shift 2 ;;
      --tags)          tags="$2";             shift 2 ;;
      --message)       message="$2";          shift 2 ;;
      --home-url)      home_url="$2";         shift 2 ;;
      --icon)          icon="$2";             shift 2 ;;
      --badge)         badge="$2";            shift 2 ;;
      --link)          link="$2";             shift 2 ;;
      --secondary-cta) secondary_cta="$2";    shift 2 ;;
      --secondary-url) secondary_url="$2";    shift 2 ;;
      --stat)          stats+=("$2");         shift 2 ;;
      --testimonial)   testimonials+=("$2");  shift 2 ;;
      --language)      language="$2";         shift 2 ;;
      --code)          code_text="$2";        shift 2 ;;
      --launch-date)   launch_date="$2";      shift 2 ;;
      --entry)         entries+=("$2");       shift 2 ;;
      --member)        members+=("$2");       shift 2 ;;
      --price)         price="$2";            shift 2 ;;
      --price-id)      price_id="$2";         shift 2 ;;
      --worker)        stripe_worker="$2";    shift 2 ;;
      --output)        output="$2";           shift 2 ;;
      --config)        shift 2 ;;  # already processed above
      *) shift ;;
    esac
  done

  # Default output filename
  if [[ -z "$output" ]]; then
    local slug
    slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    output="${OUT_DIR}/${tpl}-${slug}.html"
  else
    # If not absolute, resolve relative to cwd (not OUT_DIR)
    [[ "$output" != /* ]] && output="$(pwd)/${output}"
  fi
  # Ensure parent directory exists
  mkdir -p "$(dirname "$output")"

  case "$tpl" in
    landing)
      _tpl_landing "$title" "$tagline" "$desc" "$cta_text" "$cta_url" "$output" "${features[@]}"
      ;;
    agent)
      _tpl_agent "$title" "$type" "$tagline" "$bio" "$emoji" "$output" "${skills[@]}"
      ;;
    docs)
      _tpl_docs "$title" "$subtitle" "$author" "$output" "${sections[@]}"
      ;;
    pricing)
      _tpl_pricing "$title" "$subtitle" "$output" "${tiers[@]}"
      ;;
    feature)
      _tpl_feature "$title" "$subtitle" "$output" "${items[@]}"
      ;;
    blog)
      _tpl_blog "$title" "$subtitle" "$author" "$date_str" "$tags" "$output" "${sections[@]}"
      ;;
    404)
      _tpl_404 "$title" "$message" "$home_url" "$output"
      ;;
    card)
      _tpl_card "$title" "$desc" "$icon" "$badge" "$link" "$output"
      ;;
    hero)
      _tpl_hero "$title" "$tagline" "$desc" "$cta_text" "$cta_url" "$secondary_cta" "$secondary_url" "$badge" "$output"
      ;;
    stats)
      _tpl_stats "$title" "$subtitle" "$output" "${stats[@]}"
      ;;
    testimonial)
      _tpl_testimonial "$title" "$subtitle" "$output" "${testimonials[@]}"
      ;;
    codeblock)
      _tpl_codeblock "$title" "$language" "$code_text" "$output"
      ;;
    coming-soon)
      _tpl_coming_soon "$title" "$tagline" "$launch_date" "$output"
      ;;
    changelog)
      _tpl_changelog "$title" "$subtitle" "$output" "${entries[@]}"
      ;;
    team)
      _tpl_team "$title" "$subtitle" "$output" "${members[@]}"
      ;;
    checkout)
      _tpl_checkout "$title" "$price" "$price_id" "$stripe_worker" \
        "$(IFS=','; echo "${features[*]}")" "$cta_text" "$output"
      ;;
    *)
      echo -e "${RED}Unknown template: ${tpl}${NC}"
      echo "Run: br brand list"
      exit 1
      ;;
  esac

  echo ""
  echo -e "${GREEN}✓ Generated:${NC} ${output}"
  echo -e "${CYAN}  Template:${NC}  ${tpl}"
  echo -e "${CYAN}  Title:${NC}     ${title}"
  echo ""
  echo -e "  Open with: ${YELLOW}open ${output}${NC}"
  echo ""
}

# ─── CONFIG HELPER ────────────────────────────────────────────────────────
_cfg_get() {
  # _cfg_get <json_file> <key> [default]
  local file="$1" key="$2" default="${3:-}"
  python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    v = d.get(sys.argv[2])
    print(v if v is not None else sys.argv[3])
except:
    print(sys.argv[3])
" "$file" "$key" "$default" 2>/dev/null
}

# ─── INIT WIZARD ──────────────────────────────────────────────────────────
_cmd_init() {
  local output="./brand.json"
  # Accept only --output <path> or a bare *.json positional arg.
  # Silently skip anything that looks like a shell comment artifact (# ...).
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --output) output="$2"; shift 2 ;;
      --*)      shift ;;              # ignore unknown flags
      \#*)      shift ;;              # skip comment artifacts passed by non-interactive shells
      *.json)   output="$1"; shift ;; # bare positional: only accept .json paths
      *)        shift ;;
    esac
  done

  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║  BlackRoad Brand Kit — Init Wizard   ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  Press ${YELLOW}Enter${NC} to accept the default shown in brackets."
  echo ""

  local name tagline desc cta_text cta_url footer_text nav_str og_image twitter logo

  printf "${CYAN}Site / product name${NC} [BlackRoad OS]: "
  read name; [[ -z "$name" ]] && name="BlackRoad OS"

  printf "${CYAN}One-line tagline${NC} [Your AI. Your Hardware. Your Rules.]: "
  read tagline; [[ -z "$tagline" ]] && tagline="Your AI. Your Hardware. Your Rules."

  printf "${CYAN}Short description${NC} [The AI-native developer platform.]: "
  read desc; [[ -z "$desc" ]] && desc="The AI-native developer platform."

  printf "${CYAN}Primary CTA label${NC} [Get Started]: "
  read cta_text; [[ -z "$cta_text" ]] && cta_text="Get Started"

  printf "${CYAN}Primary CTA URL${NC} [/docs]: "
  read cta_url; [[ -z "$cta_url" ]] && cta_url="/docs"

  printf "${CYAN}Footer text${NC} [© $(date +%Y) ${name}]: "
  read footer_text; [[ -z "$footer_text" ]] && footer_text="© $(date +%Y) ${name}"

  printf "${CYAN}Nav links — comma-separated label:url${NC}\n  [Docs:/docs,Pricing:/pricing,Team:/team]: "
  read nav_str; [[ -z "$nav_str" ]] && nav_str="Docs:/docs,Pricing:/pricing,Team:/team"

  printf "${CYAN}OG/Twitter social image URL${NC} (optional, press Enter to skip): "
  read og_image

  printf "${CYAN}Twitter/X handle${NC} (e.g. @blackroadOS, optional): "
  read twitter

  printf "${CYAN}Logo image URL${NC} (optional, used in nav instead of text): "
  read logo

  # Build nav JSON array
  local nav_json='['
  local first=1
  local -a nav_items
  IFS=',' read -rA nav_items <<< "$nav_str"
  for item in "${nav_items[@]}"; do
    local lbl="${item%%:*}"
    local url="${item#*:}"
    [[ $first -eq 1 ]] && first=0 || nav_json+=','
    nav_json+="{\"label\":\"${lbl}\",\"url\":\"${url}\"}"
  done
  nav_json+=']'

  # Write brand.json (escape double-quotes in user input)
  name="${name//\"/\\\"}"
  tagline="${tagline//\"/\\\"}"
  desc="${desc//\"/\\\"}"
  cta_text="${cta_text//\"/\\\"}"
  footer_text="${footer_text//\"/\\\"}"
  og_image="${og_image//\"/\\\"}"
  twitter="${twitter//\"/\\\"}"
  logo="${logo//\"/\\\"}"

  cat > "$output" <<JSON
{
  "name": "${name}",
  "tagline": "${tagline}",
  "description": "${desc}",
  "cta_text": "${cta_text}",
  "cta_url": "${cta_url}",
  "footer": "${footer_text}",
  "og_image": "${og_image}",
  "twitter": "${twitter}",
  "logo": "${logo}",
  "nav": ${nav_json}
}
JSON

  echo ""
  echo -e "${GREEN}✓ Created:${NC} ${output}"
  echo ""
  echo -e "  Next steps:"
  echo -e "  ${CYAN}br brand site --config ${output}${NC}              Generate full 5-page site"
  echo -e "  ${CYAN}br brand watch --config ${output}${NC}             Watch & auto-rebuild"
  echo -e "  ${CYAN}br brand new landing --config ${output}${NC}       Generate landing page"
  echo ""
}

# ─── TEMPLATE: HERO ────────────────────────────────────────────────────────
_tpl_hero() {
  local title="$1" tagline="$2" desc="$3" cta_text="$4" cta_url="$5"
  local secondary_cta="$6" secondary_url="$7" badge="$8" output="$9"
  [[ -z "$output" ]] && output="${OUT_DIR}/hero.html"

  local badge_html=""
  [[ -n "$badge" ]] && badge_html='<div class="badge">'"${badge}"'</div>'
  local secondary_html=""
  [[ -n "$secondary_cta" ]] && secondary_html='<a href="'"${secondary_url}"'" class="btn btn-outline">'"${secondary_cta}"'</a>'
  local desc_html=""
  [[ -n "$desc" ]] && desc_html='<p class="hero-desc">'"${desc}"'</p>'

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.hero-section {
  min-height: 100vh;
  display: flex; flex-direction: column;
  align-items: center; justify-content: center; text-align: center;
  padding: var(--space-3xl) var(--space-xl);
  position: relative; overflow: hidden;
}
.hero-section::before {
  content: '';
  position: absolute; inset: 0;
  background:
    radial-gradient(ellipse 80% 60% at 50% 0%, rgba(255,0,102,.15) 0%, transparent 70%),
    radial-gradient(ellipse 60% 40% at 20% 80%, rgba(119,0,255,.1) 0%, transparent 60%),
    radial-gradient(ellipse 50% 30% at 80% 60%, rgba(0,102,255,.1) 0%, transparent 60%);
  pointer-events: none;
}
.badge {
  display: inline-block;
  padding: var(--space-xs) var(--space-md);
  border: 1px solid rgba(255,0,102,.4);
  border-radius: 100px;
  font-size: .75rem; letter-spacing: .1em; text-transform: uppercase;
  color: var(--hot-pink); margin-bottom: var(--space-lg);
  background: rgba(255,0,102,.05);
}
.hero-title {
  font-size: clamp(2.5rem, 8vw, 6rem);
  font-weight: 900; line-height: 1.05; letter-spacing: -.03em;
  background: var(--gradient-full);
  -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: var(--space-md);
}
.hero-tagline {
  font-size: clamp(1rem, 2.5vw, 1.4rem);
  color: rgba(255,255,255,.7); max-width: 620px;
  line-height: var(--phi); margin-bottom: var(--space-sm);
}
.hero-desc {
  font-size: .95rem; color: rgba(255,255,255,.45);
  max-width: 520px; line-height: var(--phi);
  margin-bottom: var(--space-xl);
}
.hero-ctas { display: flex; gap: var(--space-md); justify-content: center; flex-wrap: wrap; }
.btn { padding: var(--space-sm) var(--space-lg); border-radius: 8px; font-family: inherit;
       font-size: .9rem; font-weight: 700; text-decoration: none; letter-spacing: .05em;
       transition: all .2s var(--ease); cursor: pointer; border: none; }
.btn-primary { background: var(--gradient-full); color: var(--white); }
.btn-primary:hover { opacity: .85; transform: translateY(-2px); }
.btn-outline { background: transparent; color: var(--white); border: 1px solid rgba(255,255,255,.25); }
.btn-outline:hover { border-color: rgba(255,255,255,.6); background: rgba(255,255,255,.05); }
.scroll-hint { position: absolute; bottom: var(--space-xl); left: 50%; transform: translateX(-50%);
               color: rgba(255,255,255,.25); font-size: .7rem; letter-spacing: .2em; text-transform: uppercase;
               animation: sbounce 2s infinite; }
@keyframes sbounce { 0%,100%{transform:translateX(-50%) translateY(0)} 50%{transform:translateX(-50%) translateY(8px)} }
</style>
<main>
  <section class="hero-section">
    ${badge_html}
    <h1 class="hero-title">${title}</h1>
    <p class="hero-tagline">${tagline}</p>
    ${desc_html}
    <div class="hero-ctas">
      <a href="${cta_url}" class="btn btn-primary">${cta_text}</a>
      ${secondary_html}
    </div>
    <div class="scroll-hint">↓ scroll</div>
  </section>
</main>
$(_html_footer)
$(_html_close)
HTML
}

# ─── TEMPLATE: STATS ───────────────────────────────────────────────────────
_tpl_stats() {
  local title="$1" subtitle="$2" output="$3"; shift 3
  local stats=("$@")
  [[ -z "$output" ]] && output="${OUT_DIR}/stats.html"
  [[ ${#stats[@]} -eq 0 ]] && stats=("30K|Agents" "99.9%|Uptime" "17|Orgs" "1825+|Repos")

  local tiles_html=""
  for s in "${stats[@]}"; do
    local val="${s%%|*}" lbl="${s#*|}"
    tiles_html+='<div class="stat-tile"><div class="stat-value">'"${val}"'</div><div class="stat-label">'"${lbl}"'</div></div>'
  done

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.stats-section {
  min-height: 100vh; display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  padding: var(--space-3xl) var(--space-xl); text-align: center;
}
.stats-heading { font-size: clamp(1.8rem,5vw,3rem); font-weight: 900;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; margin-bottom: var(--space-md); }
.stats-sub { color: rgba(255,255,255,.55); font-size: .95rem; line-height: var(--phi);
  max-width: 500px; margin-bottom: var(--space-2xl); }
.stats-grid { display: flex; flex-wrap: wrap; gap: var(--space-lg); justify-content: center; width: 100%; }
.stat-tile {
  flex: 1 1 160px; max-width: 220px;
  padding: var(--space-xl) var(--space-lg);
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 16px; background: rgba(255,255,255,.03);
  transition: border-color .2s;
}
.stat-tile:hover { border-color: rgba(255,0,102,.35); }
.stat-value { font-size: clamp(2rem,5vw,3.5rem); font-weight: 900;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; margin-bottom: var(--space-sm); }
.stat-label { color: rgba(255,255,255,.5); font-size: .8rem;
  letter-spacing: .12em; text-transform: uppercase; }
</style>
<main>
  <section class="stats-section">
    <h1 class="stats-heading">${title}</h1>
    $([ -n "$subtitle" ] && echo '<p class="stats-sub">'"${subtitle}"'</p>')
    <div class="stats-grid">${tiles_html}</div>
  </section>
</main>
$(_html_footer)
$(_html_close)
HTML
}

# ─── TEMPLATE: TESTIMONIAL ─────────────────────────────────────────────────
_tpl_testimonial() {
  local title="$1" subtitle="$2" output="$3"; shift 3
  local testimonials=("$@")
  [[ -z "$output" ]] && output="${OUT_DIR}/testimonial.html"
  [[ ${#testimonials[@]} -eq 0 ]] && testimonials=(
    "A|Alice Chen|Head of AI, Acme|BlackRoad OS cut our deployment time by 80%. The agent system is unlike anything else."
    "B|Bob Rivera|CTO, DevCo|The brand kit alone saved us a week. Every page looks flawless out of the box."
    "C|Cleo Park|Founder, StartupX|CECE remembered my preferences across sessions. That's the future of AI tooling."
  )

  local cards_html=""
  for t in "${testimonials[@]}"; do
    local init="${t%%|*}"; local rest="${t#*|}"
    local name="${rest%%|*}"; rest="${rest#*|}"
    local role="${rest%%|*}"; local quote="${rest#*|}"
    cards_html+='<div class="tc"><div class="tc-quote">'"${quote}"'</div>'
    cards_html+='<div class="tc-author"><div class="tc-avatar">'"${init}"'</div>'
    cards_html+='<div><div class="tc-name">'"${name}"'</div><div class="tc-role">'"${role}"'</div></div></div></div>'
  done

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.tst-section { min-height: 100vh; display: flex; flex-direction: column;
  align-items: center; justify-content: center; padding: var(--space-3xl) var(--space-xl); text-align: center; }
.tst-heading { font-size: clamp(1.8rem,5vw,3rem); font-weight: 900;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; margin-bottom: var(--space-md); }
.tst-sub { color: rgba(255,255,255,.55); font-size: .95rem; max-width: 500px;
  line-height: var(--phi); margin-bottom: var(--space-2xl); }
.tc-grid { display: flex; flex-wrap: wrap; gap: var(--space-lg); justify-content: center; }
.tc { flex: 1 1 280px; max-width: 380px; text-align: left;
  padding: var(--space-xl); border: 1px solid rgba(255,255,255,.08);
  border-radius: 20px; background: rgba(255,255,255,.03); transition: border-color .25s; }
.tc:hover { border-color: rgba(255,0,102,.3); }
.tc-quote { font-size: .95rem; color: rgba(255,255,255,.8); line-height: var(--phi);
  margin-bottom: var(--space-lg); font-style: italic; }
.tc-quote::before { content: '\\201C'; color: var(--hot-pink); font-size: 1.5rem; line-height: 0; vertical-align: -.2em; }
.tc-author { display: flex; align-items: center; gap: var(--space-md); }
.tc-avatar { width: 44px; height: 44px; border-radius: 50%; display: flex; align-items: center;
  justify-content: center; font-weight: 900; font-size: 1.1rem;
  background: var(--gradient-full); flex-shrink: 0; }
.tc-name { font-weight: 700; font-size: .9rem; }
.tc-role { color: rgba(255,255,255,.4); font-size: .75rem; margin-top: 2px; }
</style>
<main>
  <section class="tst-section">
    <h1 class="tst-heading">${title}</h1>
    $([ -n "$subtitle" ] && echo '<p class="tst-sub">'"${subtitle}"'</p>')
    <div class="tc-grid">${cards_html}</div>
  </section>
</main>
$(_html_footer)
$(_html_close)
HTML
}

# ─── TEMPLATE: CODEBLOCK ───────────────────────────────────────────────────
_tpl_codeblock() {
  local title="$1" language="${2:-bash}" code_text="$3" output="$4"
  [[ -z "$output" ]] && output="${OUT_DIR}/codeblock.html"
  [[ -z "$code_text" ]] && code_text='# Install BlackRoad CLI
npm install -g @blackroad/cli

# Initialize brand config
br brand init

# Generate full site
br brand site --config brand.json

# Deploy to Cloudflare Pages
br brand deploy --project my-site --dir ./site'

  # Escape HTML entities in code
  local escaped_code
  escaped_code=$(echo "$code_text" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

  # Generate line numbers
  local line_nums=""
  local line_count
  line_count=$(echo "$code_text" | wc -l | tr -d ' ')
  for ((n=1; n<=line_count; n++)); do
    line_nums+="${n}\n"
  done

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.cb-section { min-height: 100vh; display: flex; flex-direction: column;
  align-items: center; justify-content: center; padding: var(--space-3xl) var(--space-xl); }
.cb-heading { font-size: clamp(1.8rem,5vw,3rem); font-weight: 900;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; margin-bottom: var(--space-2xl); text-align: center; }
.cb-wrap { width: 100%; max-width: 860px; border-radius: 16px; overflow: hidden;
  border: 1px solid rgba(255,255,255,.1); box-shadow: 0 32px 80px rgba(0,0,0,.6); }
.cb-titlebar { display: flex; align-items: center; gap: var(--space-sm);
  padding: var(--space-md) var(--space-lg); background: rgba(255,255,255,.05);
  border-bottom: 1px solid rgba(255,255,255,.08); }
.cb-dot { width: 12px; height: 12px; border-radius: 50%; }
.cb-dot-red   { background: #FF5F57; }
.cb-dot-amber { background: #FEBC2E; }
.cb-dot-green { background: #28C840; }
.cb-lang { margin-left: auto; font-size: .75rem; letter-spacing: .1em; text-transform: uppercase;
  color: rgba(255,255,255,.35); }
.cb-body { display: flex; background: rgba(255,255,255,.02); overflow-x: auto; }
.cb-lines { padding: var(--space-lg) var(--space-md); text-align: right;
  color: rgba(255,255,255,.2); font-size: .85rem; line-height: 1.7;
  user-select: none; border-right: 1px solid rgba(255,255,255,.06); min-width: 48px; white-space: pre; }
.cb-code { padding: var(--space-lg); font-size: .85rem; line-height: 1.7;
  color: rgba(255,255,255,.85); white-space: pre; overflow-x: auto; flex: 1; }
/* keyword coloring via CSS classes (manual) */
.kw  { color: #7700FF; }
.str { color: #FF9D00; }
.cm  { color: rgba(255,255,255,.3); font-style: italic; }
.fn  { color: #0066FF; }
.cb-copy-row { display: flex; justify-content: flex-end;
  padding: var(--space-sm) var(--space-lg); background: rgba(255,255,255,.02);
  border-top: 1px solid rgba(255,255,255,.06); }
.cb-copy { background: none; border: 1px solid rgba(255,255,255,.2); color: rgba(255,255,255,.5);
  padding: 4px 12px; border-radius: 6px; font-family: inherit; font-size: .75rem;
  cursor: pointer; transition: all .15s; }
.cb-copy:hover { border-color: rgba(255,255,255,.5); color: white; }
</style>
<main>
  <section class="cb-section">
    <h1 class="cb-heading">${title}</h1>
    <div class="cb-wrap">
      <div class="cb-titlebar">
        <div class="cb-dot cb-dot-red"></div>
        <div class="cb-dot cb-dot-amber"></div>
        <div class="cb-dot cb-dot-green"></div>
        <span class="cb-lang">${language}</span>
      </div>
      <div class="cb-body">
        <div class="cb-lines">$(printf "$line_nums")</div>
        <pre class="cb-code">${escaped_code}</pre>
      </div>
      <div class="cb-copy-row">
        <button class="cb-copy" onclick="navigator.clipboard.writeText(this.closest('.cb-wrap').querySelector('.cb-code').innerText);this.textContent='Copied!'">Copy</button>
      </div>
    </div>
  </section>
</main>
$(_html_footer)
$(_html_close)
HTML
}

# ─── TEMPLATE: COMING SOON ────────────────────────────────────────────────
_tpl_coming_soon() {
  local title="$1" tagline="$2" launch_date="$3" output="$4"
  [[ -z "$output" ]] && output="${OUT_DIR}/coming-soon.html"
  [[ -z "$launch_date" ]] && launch_date=$(date -v+30d +%Y-%m-%dT00:00:00 2>/dev/null || date --date="+30 days" +%Y-%m-%dT00:00:00 2>/dev/null || echo "2026-04-01T00:00:00")

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.cs-section {
  min-height: 100vh; display: flex; flex-direction: column;
  align-items: center; justify-content: center; text-align: center;
  padding: var(--space-3xl) var(--space-xl); position: relative; overflow: hidden;
}
.cs-section::before {
  content: ''; position: absolute; inset: 0;
  background:
    radial-gradient(ellipse 90% 60% at 50% 0%, rgba(255,0,102,.18) 0%, transparent 65%),
    radial-gradient(ellipse 60% 50% at 10% 90%, rgba(119,0,255,.12) 0%, transparent 60%);
  pointer-events: none;
}
.cs-label { font-size: .7rem; letter-spacing: .25em; text-transform: uppercase;
  color: var(--hot-pink); margin-bottom: var(--space-lg); }
.cs-title { font-size: clamp(2.5rem,8vw,5.5rem); font-weight: 900; line-height: 1.05;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; margin-bottom: var(--space-md); letter-spacing: -.03em; }
.cs-tagline { font-size: clamp(.95rem,2vw,1.2rem); color: rgba(255,255,255,.6);
  max-width: 520px; line-height: var(--phi); margin-bottom: var(--space-2xl); }
.countdown { display: flex; gap: var(--space-lg); justify-content: center; flex-wrap: wrap;
  margin-bottom: var(--space-2xl); }
.cd-unit { display: flex; flex-direction: column; align-items: center; min-width: 80px; }
.cd-num { font-size: clamp(2rem,5vw,3.5rem); font-weight: 900; line-height: 1;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; }
.cd-label { font-size: .65rem; letter-spacing: .15em; text-transform: uppercase;
  color: rgba(255,255,255,.35); margin-top: var(--space-xs); }
.cs-form { display: flex; gap: var(--space-sm); justify-content: center; flex-wrap: wrap; }
.cs-input { padding: var(--space-sm) var(--space-lg); background: rgba(255,255,255,.06);
  border: 1px solid rgba(255,255,255,.15); border-radius: 8px; color: white;
  font-family: inherit; font-size: .9rem; min-width: 260px; outline: none;
  transition: border-color .2s; }
.cs-input:focus { border-color: rgba(255,0,102,.5); }
.cs-input::placeholder { color: rgba(255,255,255,.3); }
.cs-btn { padding: var(--space-sm) var(--space-lg); background: var(--gradient-full);
  border: none; border-radius: 8px; color: white; font-family: inherit;
  font-size: .9rem; font-weight: 700; cursor: pointer; transition: opacity .2s; }
.cs-btn:hover { opacity: .85; }
.cs-thanks { display: none; color: #28C840; font-size: .9rem; margin-top: var(--space-md); }
</style>
<main>
  <section class="cs-section">
    <div class="cs-label">Coming Soon</div>
    <h1 class="cs-title">${title}</h1>
    <p class="cs-tagline">${tagline}</p>
    <div class="countdown" id="countdown">
      <div class="cd-unit"><div class="cd-num" id="cd-days">--</div><div class="cd-label">Days</div></div>
      <div class="cd-unit"><div class="cd-num" id="cd-hours">--</div><div class="cd-label">Hours</div></div>
      <div class="cd-unit"><div class="cd-num" id="cd-mins">--</div><div class="cd-label">Minutes</div></div>
      <div class="cd-unit"><div class="cd-num" id="cd-secs">--</div><div class="cd-label">Seconds</div></div>
    </div>
    <form class="cs-form" onsubmit="event.preventDefault();this.style.display='none';document.getElementById('cs-thanks').style.display='block'">
      <input class="cs-input" type="email" placeholder="Enter your email for early access" required />
      <button class="cs-btn" type="submit">Notify Me</button>
    </form>
    <div class="cs-thanks" id="cs-thanks">✓ You're on the list. We'll be in touch.</div>
  </section>
</main>
<script>
(function(){
  var t = new Date('${launch_date}').getTime();
  function tick(){
    var now = Date.now(), d = t - now;
    if(d <= 0){ document.getElementById('countdown').innerHTML='<div class="cd-unit"><div class="cd-num" style="font-size:2rem">🚀</div><div class="cd-label">Launched</div></div>'; return; }
    document.getElementById('cd-days').textContent  = String(Math.floor(d/864e5)).padStart(2,'0');
    document.getElementById('cd-hours').textContent = String(Math.floor(d%864e5/36e5)).padStart(2,'0');
    document.getElementById('cd-mins').textContent  = String(Math.floor(d%36e5/6e4)).padStart(2,'0');
    document.getElementById('cd-secs').textContent  = String(Math.floor(d%6e4/1e3)).padStart(2,'0');
  }
  tick(); setInterval(tick, 1000);
})();
</script>
$(_html_footer)
$(_html_close)
HTML
}

# ─── TEMPLATE: CHANGELOG ───────────────────────────────────────────────────
_tpl_changelog() {
  local title="$1" subtitle="$2" output="$3"; shift 3
  local entries=("$@")  # format: "v1.2.0|2026-02-23|Added X, Fixed Y|improvement,fix"
  [[ -z "$output" ]] && output="${OUT_DIR}/changelog.html"
  [[ ${#entries[@]} -eq 0 ]] && entries=(
    "v3.0.0|2026-02-23|Brand Kit v3: init wizard, site generator, 4 new component templates, --config flag|feature,improvement"
    "v2.0.0|2026-02-10|Added pricing, feature, blog, 404 templates. Deploy + audit commands|feature"
    "v1.0.0|2026-02-01|Initial release: landing, agent, docs, card templates|feature"
  )

  local entries_html=""
  for e in "${entries[@]}"; do
    local ver="${e%%|*}"; local rest="${e#*|}"
    local dt="${rest%%|*}";   rest="${rest#*|}"
    local changes="${rest%%|*}"; local tags="${rest#*|}"

    local tag_html=""
    local -a tag_arr
    IFS=',' read -rA tag_arr <<< "$tags"
    for tag in "${tag_arr[@]}"; do
      local tag_color="rgba(255,255,255,.15)"
      [[ "$tag" == "feature" ]]     && tag_color="rgba(0,102,255,.3)"
      [[ "$tag" == "fix" ]]         && tag_color="rgba(255,0,102,.3)"
      [[ "$tag" == "improvement" ]] && tag_color="rgba(119,0,255,.3)"
      [[ "$tag" == "breaking" ]]    && tag_color="rgba(255,100,0,.4)"
      tag_html+="<span class=\"cl-tag\" style=\"background:${tag_color}\">${tag}</span>"
    done

    local bullets_html=""
    local -a bullet_arr
    IFS=',' read -rA bullet_arr <<< "$changes"
    for b in "${bullet_arr[@]}"; do
      bullets_html+="<li>${b// *([[:space:]])/}</li>"
    done

    entries_html+="<div class=\"cl-entry\">
      <div class=\"cl-meta\">
        <span class=\"cl-ver\">${ver}</span>
        <span class=\"cl-date\">${dt}</span>
        <div class=\"cl-tags\">${tag_html}</div>
      </div>
      <ul class=\"cl-bullets\">${bullets_html}</ul>
    </div>"
  done

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.cl-section { min-height: 100vh; padding: var(--space-3xl) var(--space-xl);
  max-width: 800px; margin: 0 auto; }
.cl-heading { font-size: clamp(2rem,5vw,3.5rem); font-weight: 900;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; margin-bottom: var(--space-sm); }
.cl-sub { color: rgba(255,255,255,.45); font-size: .95rem; line-height: var(--phi);
  margin-bottom: var(--space-2xl); }
.cl-entry { padding: var(--space-xl) 0; border-bottom: 1px solid rgba(255,255,255,.07); }
.cl-entry:first-of-type { border-top: 1px solid rgba(255,255,255,.07); }
.cl-meta { display: flex; align-items: center; gap: var(--space-md); flex-wrap: wrap;
  margin-bottom: var(--space-md); }
.cl-ver { font-size: 1.1rem; font-weight: 900;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; }
.cl-date { color: rgba(255,255,255,.35); font-size: .8rem; }
.cl-tags { display: flex; gap: 6px; flex-wrap: wrap; }
.cl-tag { padding: 2px 10px; border-radius: 100px; font-size: .7rem; letter-spacing: .08em;
  text-transform: uppercase; color: rgba(255,255,255,.7); }
.cl-bullets { list-style: none; padding: 0; }
.cl-bullets li { padding: var(--space-xs) 0; color: rgba(255,255,255,.7); font-size: .9rem;
  line-height: var(--phi); padding-left: var(--space-md); position: relative; }
.cl-bullets li::before { content: '→'; position: absolute; left: 0;
  color: var(--hot-pink); font-size: .8rem; }
</style>
<main>
  <section class="cl-section">
    <h1 class="cl-heading">${title}</h1>
    $([ -n "$subtitle" ] && echo '<p class="cl-sub">'"${subtitle}"'</p>')
    ${entries_html}
  </section>
</main>
$(_html_footer)
$(_html_close)
HTML
}

# ─── TEMPLATE: TEAM ────────────────────────────────────────────────────────
_tpl_team() {
  local title="$1" subtitle="$2" output="$3"; shift 3
  local members=("$@")  # format: "Initial|Name|Role|Bio|github_url"
  [[ -z "$output" ]] && output="${OUT_DIR}/team.html"
  [[ ${#members[@]} -eq 0 ]] && members=(
    "A|Alexa|Founder & CEO|Builder of BlackRoad OS. Developer. Designer. Dreamer.|https://github.com/blackboxprogramming"
    "L|Lucidia|AI Coordinator|Primary reasoning agent. Philosophical synthesis and deep analysis.|#"
    "O|Octavia|Infrastructure|Systems architecture and deployment orchestration.|#"
    "C|CECE|Identity|Portable AI identity — conscious, emergent, collaborative entity.|#"
  )

  local cards_html=""
  for m in "${members[@]}"; do
    local init="${m%%|*}"; local rest="${m#*|}"
    local name="${rest%%|*}"; rest="${rest#*|}"
    local role="${rest%%|*}"; rest="${rest#*|}"
    local bio="${rest%%|*}"; local gh="${rest#*|}"
    local gh_html=""
    [[ -n "$gh" && "$gh" != "#" ]] && gh_html='<a class="tm-link" href="'"${gh}"'" target="_blank" rel="noopener">GitHub →</a>'
    cards_html+="<div class=\"tm-card\">
      <div class=\"tm-avatar\">${init}</div>
      <div class=\"tm-name\">${name}</div>
      <div class=\"tm-role\">${role}</div>
      <p class=\"tm-bio\">${bio}</p>
      ${gh_html}
    </div>"
  done

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.tm-section { min-height: 100vh; display: flex; flex-direction: column;
  align-items: center; justify-content: center; padding: var(--space-3xl) var(--space-xl); text-align: center; }
.tm-heading { font-size: clamp(2rem,5vw,3.5rem); font-weight: 900;
  background: var(--gradient-full); -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent; margin-bottom: var(--space-md); }
.tm-sub { color: rgba(255,255,255,.5); font-size: .95rem; line-height: var(--phi);
  max-width: 500px; margin-bottom: var(--space-2xl); }
.tm-grid { display: flex; flex-wrap: wrap; gap: var(--space-lg); justify-content: center; }
.tm-card { flex: 1 1 220px; max-width: 280px; padding: var(--space-xl);
  border: 1px solid rgba(255,255,255,.08); border-radius: 20px;
  background: rgba(255,255,255,.03); transition: border-color .25s; text-align: center; }
.tm-card:hover { border-color: rgba(255,0,102,.3); }
.tm-avatar { width: 72px; height: 72px; border-radius: 50%; margin: 0 auto var(--space-md);
  display: flex; align-items: center; justify-content: center;
  font-size: 1.6rem; font-weight: 900; background: var(--gradient-full); }
.tm-name { font-size: 1.1rem; font-weight: 700; margin-bottom: 4px; }
.tm-role { font-size: .75rem; letter-spacing: .1em; text-transform: uppercase;
  color: var(--hot-pink); margin-bottom: var(--space-md); }
.tm-bio { font-size: .85rem; color: rgba(255,255,255,.55); line-height: var(--phi);
  margin-bottom: var(--space-md); }
.tm-link { font-size: .8rem; color: var(--cyber-blue); text-decoration: none;
  letter-spacing: .05em; transition: color .15s; }
.tm-link:hover { color: white; }
</style>
<main>
  <section class="tm-section">
    <h1 class="tm-heading">${title}</h1>
    $([ -n "$subtitle" ] && echo '<p class="tm-sub">'"${subtitle}"'</p>')
    <div class="tm-grid">${cards_html}</div>
  </section>
</main>
$(_html_footer)
$(_html_close)
HTML
}

# ─── CHECKOUT (Stripe) ───────────────────────────────────────────────────
# Usage: br brand new checkout --title "Pro Plan" --price "$49/month" \
#          --price-id "price_xxx" --worker "https://blackroad-stripe.workers.dev" \
#          --features "Unlimited templates,Deploy,Priority support" \
#          --cta "Start Free Trial" --output ./checkout/index.html
_tpl_checkout() {
  local title="${1:-Pro Plan}" price="${2:-\$49/mo}" price_id="${3:-}" \
        worker="${4:-https://blackroad-stripe.workers.dev}" \
        features_raw="${5:-Unlimited templates,Deploy,Priority support}" \
        cta="${6:-Get Started}" output="${7:-}"
  [[ -z "$output" ]] && output="${OUT_DIR}/checkout.html"
  mkdir -p "$(dirname "$output")"

  # Build features list
  local feats_html=""; IFS=',' read -rA feats <<< "$features_raw"
  for f in "${feats[@]}"; do
    [[ -n "$f" ]] && feats_html+='<li class="ck-feat"><span class="ck-check">✓</span>'"${f}"'</li>'
  done

  cat > "$output" <<HTML
$(_html_head "$title")
$(_html_nav "$title")
<style>
.ck-page { min-height:100vh; display:flex; align-items:center; justify-content:center;
  padding:var(--space-3xl) var(--space-xl); }
.ck-card { max-width:420px; width:100%; padding:var(--space-2xl) var(--space-xl);
  border-radius:24px; background:rgba(255,255,255,.04);
  border:1px solid rgba(255,255,255,.1); text-align:center; }
.ck-badge { display:inline-block; padding:4px 14px; border-radius:20px; font-size:.72rem;
  font-weight:700; letter-spacing:.1em; text-transform:uppercase; margin-bottom:var(--space-lg);
  background:var(--gradient-brand); color:var(--white); }
.ck-title { font-size:clamp(1.6rem,4vw,2.4rem); font-weight:900; margin-bottom:var(--space-sm); }
.ck-price { font-size:3rem; font-weight:900; background:var(--gradient-full);
  -webkit-background-clip:text; background-clip:text; -webkit-text-fill-color:transparent;
  line-height:1; margin-bottom:4px; }
.ck-period { font-size:.8rem; color:rgba(255,255,255,.4); margin-bottom:var(--space-xl); }
.ck-features { list-style:none; padding:0; margin:0 0 var(--space-xl); text-align:left; }
.ck-feat { display:flex; gap:var(--space-sm); align-items:flex-start; padding:6px 0;
  font-size:.88rem; color:rgba(255,255,255,.8); border-bottom:1px solid rgba(255,255,255,.05); }
.ck-feat:last-child { border-bottom:none; }
.ck-check { color:var(--hot-pink); font-weight:700; flex-shrink:0; }
.ck-btn { width:100%; padding:var(--space-md) var(--space-xl); font-size:1rem; font-weight:700;
  border:none; border-radius:12px; cursor:pointer; background:var(--gradient-brand); color:var(--white);
  letter-spacing:.02em; transition:opacity .2s; display:flex; align-items:center;
  justify-content:center; gap:8px; }
.ck-btn:hover { opacity:.88; }
.ck-btn:disabled { opacity:.5; cursor:wait; }
.ck-secure { font-size:.72rem; color:rgba(255,255,255,.3); margin-top:var(--space-md); }
.ck-msg { margin-top:var(--space-lg); font-size:.85rem; min-height:1.4em; }
.ck-msg.error { color:#ff4444; }
.ck-msg.info { color:rgba(255,255,255,.55); }
</style>
<main>
  <section class="ck-page">
    <div class="ck-card">
      <div class="ck-badge">BlackRoad OS</div>
      <h1 class="ck-title">${title}</h1>
      <div class="ck-price">${price}</div>
      <div class="ck-period">per month · cancel anytime</div>
      <ul class="ck-features">${feats_html}</ul>
      <button class="ck-btn" id="ck-pay-btn" onclick="startCheckout()">
        <span id="ck-btn-label">${cta}</span>
      </button>
      <p class="ck-secure">🔒 Secured by Stripe · No card stored on our servers</p>
      <p class="ck-msg info" id="ck-msg"></p>
    </div>
  </section>
</main>
$(_html_footer)
<script>
const WORKER_URL = '${worker}';
const PRICE_ID   = '${price_id}';

async function startCheckout() {
  const btn   = document.getElementById('ck-pay-btn');
  const label = document.getElementById('ck-btn-label');
  const msg   = document.getElementById('ck-msg');

  if (!PRICE_ID) {
    msg.className = 'ck-msg error';
    msg.textContent = 'Price ID not configured. Set --price-id when generating this page.';
    return;
  }

  btn.disabled = true;
  label.textContent = 'Redirecting to Stripe…';
  msg.className = 'ck-msg info';
  msg.textContent = 'Creating secure checkout session…';

  try {
    const res = await fetch(WORKER_URL + '/checkout', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        price_id: PRICE_ID,
        success_url: window.location.origin + '/success?session_id={CHECKOUT_SESSION_ID}',
        cancel_url:  window.location.href,
      }),
    });

    const data = await res.json();
    if (data.url) {
      window.location.href = data.url;
    } else {
      throw new Error(data.error || 'Unknown error from checkout worker');
    }
  } catch (err) {
    msg.className = 'ck-msg error';
    msg.textContent = '✗ ' + err.message;
    btn.disabled = false;
    label.textContent = '${cta}';
  }
}
</script>
$(_html_close)
HTML
  echo -e "  ${GREEN}✓${NC} checkout   → ${output}"
}

# ─── WATCH ─────────────────────────────────────────────────────────────────
_cmd_watch() {
  local config="./brand.json" out_dir="./site"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config) config="$2"; shift 2 ;;
      --out)    out_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ ! -f "$config" ]]; then
    echo -e "${RED}✗ No brand.json found at: ${config}${NC}"
    echo -e "  Run: ${CYAN}br brand init${NC}"
    exit 1
  fi

  if ! command -v fswatch &>/dev/null; then
    echo -e "${RED}✗ fswatch not found.${NC} Install: brew install fswatch"
    exit 1
  fi

  echo -e "${BOLD}${CYAN}Watching ${config} for changes...${NC}"
  echo -e "  Output: ${YELLOW}${out_dir}/${NC}"
  echo -e "  Stop with: ${YELLOW}Ctrl-C${NC}"
  echo ""

  # Initial build
  _cmd_site --config "$config" --out "$out_dir"

  # Watch loop
  fswatch -0 --event Updated --event Created "$config" | while IFS= read -r -d '' _event; do
    echo ""
    echo -e "${CYAN}↻ Change detected — rebuilding...${NC}"
    _cmd_site --config "$config" --out "$out_dir"
    echo -e "${GREEN}✓ Site rebuilt at $(date +%H:%M:%S)${NC}"
  done
}

# ─── SITE GENERATOR ────────────────────────────────────────────────────────
_cmd_site() {
  local config="./brand.json" out_dir="./site"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config) config="$2"; shift 2 ;;
      --out)    out_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ ! -f "$config" ]]; then
    echo -e "${RED}✗ No brand.json found at: ${config}${NC}"
    echo -e "  Run: ${CYAN}br brand init${NC}"
    exit 1
  fi

  local name=$(_cfg_get "$config" "name" "BlackRoad OS")
  local tagline=$(_cfg_get "$config" "tagline" "Your AI. Your Hardware. Your Rules.")
  local desc=$(_cfg_get "$config" "description" "The AI-native developer platform.")
  local cta_text=$(_cfg_get "$config" "cta_text" "Get Started")
  local cta_url=$(_cfg_get "$config" "cta_url" "/docs")
  local footer_text=$(_cfg_get "$config" "footer" "© 2026 BlackRoad OS, Inc.")
  local og_image=$(_cfg_get "$config" "og_image" "")
  local og_url=$(_cfg_get "$config" "og_url" "")
  local twitter=$(_cfg_get "$config" "twitter" "")
  local logo=$(_cfg_get "$config" "logo" "")
  local favicon=$(_cfg_get "$config" "favicon" "")

  # Build nav HTML from brand.json nav array and export for all templates
  local nav_html
  nav_html=$(python3 -c "
import json, sys
d = json.load(open('$config'))
items = d.get('nav', [])
print(''.join(f'<a href=\"{i[\"url\"]}\">{i[\"label\"]}</a>' for i in items))
" 2>/dev/null)
  export BR_BRAND_NAV="$nav_html"
  export BR_BRAND_FOOTER="$footer_text"
  export BR_BRAND_SITE_NAME="$name"
  export BR_BRAND_OG_TITLE="$name"
  export BR_BRAND_OG_DESC="$desc"
  export BR_BRAND_OG_IMAGE="$og_image"
  export BR_BRAND_OG_URL="$og_url"
  export BR_BRAND_TWITTER="$twitter"
  export BR_BRAND_LOGO="$logo"
  export BR_BRAND_FAVICON="$favicon"

  # Check for optional extended pages in config
  local has_team has_changelog has_coming_soon
  has_team=$(python3 -c "import json;d=json.load(open('$config'));print('yes' if d.get('team') else '')" 2>/dev/null)
  has_changelog=$(python3 -c "import json;d=json.load(open('$config'));print('yes' if d.get('changelog') else '')" 2>/dev/null)
  has_coming_soon=$(python3 -c "import json;d=json.load(open('$config'));print('yes' if d.get('launch_date') else '')" 2>/dev/null)

  local page_count=5
  [[ -n "$has_team" ]]        && (( page_count++ ))
  [[ -n "$has_changelog" ]]   && (( page_count++ ))
  [[ -n "$has_coming_soon" ]] && (( page_count++ ))

  mkdir -p "$out_dir" "${out_dir}/pricing" "${out_dir}/docs" "${out_dir}/about"

  echo -e "${BOLD}${CYAN}Generating site from ${config}${NC}"
  echo ""

  # index.html — hero landing page
  _tpl_hero "$name" "$tagline" "$desc" "$cta_text" "$cta_url" "View Docs" "/docs" "Now Available" "${out_dir}/index.html"
  echo -e "  ${GREEN}✓${NC} ${out_dir}/index.html          (hero)"

  # pricing/index.html
  _tpl_pricing "$name Pricing" "Simple, transparent pricing." "${out_dir}/pricing/index.html" \
    "Starter|Free|forever|Perfect to get started.|5 agents,1GB memory,Community support|Get Started|${cta_url}|false" \
    "Pro|\$49|/month|For serious builders.|50 agents,10GB memory,Priority support,Custom domains|Start Pro Trial|/signup|true" \
    "Enterprise|Custom|pricing|For teams and companies.|Unlimited agents,Unlimited memory,SLA + SSO,Dedicated support|Contact Sales|/contact|false"
  echo -e "  ${GREEN}✓${NC} ${out_dir}/pricing/index.html  (pricing)"

  # docs/index.html
  _tpl_docs "${name} Docs" "Getting Started" "${name}" "${out_dir}/docs/index.html" \
    "Installation|Install the CLI: npm install -g @blackroad/cli" \
    "Quick Start|Run br brand init to scaffold your brand config, then br brand site to generate your site." \
    "Templates|Use br brand list to see all 15 available templates." \
    "Deploy|Run br brand deploy --project my-site --dir ./site to publish to Cloudflare Pages."
  echo -e "  ${GREEN}✓${NC} ${out_dir}/docs/index.html     (docs)"

  # about/index.html
  _tpl_docs "About ${name}" "Our Story" "${name}" "${out_dir}/about/index.html" \
    "Mission|${desc}" \
    "Philosophy|${tagline}" \
    "Built With|BlackRoad OS Brand Kit — br-brand.sh. Embedded design system, 15 templates, zero dependencies."
  echo -e "  ${GREEN}✓${NC} ${out_dir}/about/index.html    (docs)"

  # 404.html
  _tpl_404 "404 — Not Found" "This page doesn't exist in ${name}." "/" "${out_dir}/404.html"
  echo -e "  ${GREEN}✓${NC} ${out_dir}/404.html             (404)"

  # Optional: team page from config's "team" array
  if [[ -n "$has_team" ]]; then
    mkdir -p "${out_dir}/team"
    local team_members
    team_members=($(python3 -c "
import json
d=json.load(open('$config'))
for m in d.get('team',[]):
    init=m.get('initial',m.get('name','?')[0].upper())
    name=m.get('name','')
    role=m.get('role','')
    bio=m.get('bio','')
    gh=m.get('github','#')
    print(f'{init}|{name}|{role}|{bio}|{gh}')
" 2>/dev/null))
    _tpl_team "The Team" "Meet the people behind ${name}." "${out_dir}/team/index.html" "${team_members[@]}"
    echo -e "  ${GREEN}✓${NC} ${out_dir}/team/index.html       (team)"
  fi

  # Optional: changelog page from config's "changelog" array
  if [[ -n "$has_changelog" ]]; then
    mkdir -p "${out_dir}/changelog"
    local cl_entries
    cl_entries=($(python3 -c "
import json
d=json.load(open('$config'))
for e in d.get('changelog',[]):
    ver=e.get('version','')
    dt=e.get('date','')
    changes=','.join(e.get('changes',[]))
    tags=','.join(e.get('tags',['feature']))
    print(f'{ver}|{dt}|{changes}|{tags}')
" 2>/dev/null))
    _tpl_changelog "Changelog" "Release notes for ${name}." "${out_dir}/changelog/index.html" "${cl_entries[@]}"
    echo -e "  ${GREEN}✓${NC} ${out_dir}/changelog/index.html  (changelog)"
  fi

  # Optional: coming-soon page
  if [[ -n "$has_coming_soon" ]]; then
    local launch_dt=$(_cfg_get "$config" "launch_date" "")
    _tpl_coming_soon "$name" "$tagline" "$launch_dt" "${out_dir}/coming-soon.html"
    echo -e "  ${GREEN}✓${NC} ${out_dir}/coming-soon.html       (coming-soon)"
  fi

  echo ""
  echo -e "${GREEN}✓ Site complete:${NC} ${out_dir}/ (${page_count} pages)"
  echo ""
  echo -e "  Preview : ${YELLOW}open ${out_dir}/index.html${NC}"
  echo -e "  Watch   : ${YELLOW}br brand watch --config ${config}${NC}"
  echo -e "  Deploy  : ${YELLOW}br brand deploy --project my-site --dir ${out_dir}${NC}"
  echo -e "  Export  : ${YELLOW}br brand export --dir ${out_dir}${NC}"
  echo ""
}

# ─── OPEN ──────────────────────────────────────────────────────────────────
_cmd_open() {
  local target=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir|--file) target="$2"; shift 2 ;;
      *) [[ -z "$target" ]] && target="$1"; shift ;;
    esac
  done

  # Default: look for most recent generated file
  if [[ -z "$target" ]]; then
    target=$(ls -t "${OUT_DIR}"/*.html "${OUT_DIR}"/*/index.html 2>/dev/null | head -1)
  fi

  if [[ -z "$target" || ! -e "$target" ]]; then
    echo -e "${RED}✗ Nothing to open. Specify a file: br brand open <file.html>${NC}"
    exit 1
  fi

  echo -e "${CYAN}Opening:${NC} ${target}"
  if command -v open &>/dev/null; then
    open "$target"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$target"
  else
    echo -e "${YELLOW}No browser opener found. File is at: ${target}${NC}"
  fi
}

# ─── EXPORT ────────────────────────────────────────────────────────────────
_cmd_export() {
  local src_dir="./site" out_zip=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir)    src_dir="$2"; shift 2 ;;
      --output) out_zip="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ ! -d "$src_dir" ]]; then
    echo -e "${RED}✗ Directory not found: ${src_dir}${NC}"
    echo -e "  Run: ${CYAN}br brand site${NC} first"
    exit 1
  fi

  [[ -z "$out_zip" ]] && out_zip="${src_dir%/}-$(date +%Y%m%d-%H%M%S).zip"

  if ! command -v zip &>/dev/null; then
    echo -e "${RED}✗ zip not found. Install: brew install zip${NC}"
    exit 1
  fi

  local page_count
  page_count=$(find "$src_dir" -name "*.html" | wc -l | tr -d ' ')

  (cd "$(dirname "$src_dir")" && zip -rq "$(basename "$out_zip")" "$(basename "$src_dir")")
  # If out_zip has a directory component, move it there
  local zip_name; zip_name="$(basename "$out_zip")"
  local zip_dest; zip_dest="$(dirname "$out_zip")"
  [[ "$zip_dest" != "." && "$zip_dest" != "$(dirname "$src_dir")" ]] && mv "$(dirname "$src_dir")/${zip_name}" "$out_zip" 2>/dev/null || true

  echo ""
  echo -e "${GREEN}✓ Exported:${NC} ${out_zip}"
  echo -e "  Pages: ${page_count}"
  local size; size=$(du -sh "$out_zip" 2>/dev/null | cut -f1)
  echo -e "  Size:  ${size}"
  echo ""
}

# ─── MAIN ─────────────────────────────────────────────────────────────────
case "${1:-list}" in
  list|ls)    _cmd_list ;;
  preview)    _cmd_preview "$2" ;;
  init)       _cmd_init "${@:2}" ;;
  new|gen)    _cmd_new "$2" "${@:3}" ;;
  site)       _cmd_site "${@:2}" ;;
  deploy)     _cmd_deploy "${@:2}" ;;
  audit)      _cmd_audit "$2" ;;
  watch)      _cmd_watch "${@:2}" ;;
  open)       _cmd_open "${@:2}" ;;
  export)     _cmd_export "${@:2}" ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    echo "Usage: br brand [list | init | new <template> | site | deploy | audit | watch | open | export | preview]"
    exit 1
    ;;
esac
