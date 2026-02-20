#!/bin/bash
# Retry script for remaining forks that hit GitHub's secondary rate limit
# Run this after ~30-60 minutes from the initial fork wave
# Usage: ./scripts/retry-forks.sh

set -e
DELAY=5  # seconds between forks

echo "=== Retrying rate-limited forks with ${DELAY}s delays ==="

fork_repo() {
  local source="$1" org="$2" forkname="$3"
  echo "--- Forking $source → $org/$forkname"
  result=$(gh repo fork "$source" --org "$org" --fork-name "$forkname" --clone=false 2>&1)
  if echo "$result" | grep -q "already exists"; then
    echo "  SKIP: Already exists"
  elif echo "$result" | grep -q "github.com/$org"; then
    echo "  OK: $result"
  else
    echo "  FAIL: $result"
  fi
  sleep "$DELAY"
}

echo ""
echo "--- BlackRoad-Labs (need ~10 more) ---"
fork_repo "pola-rs/polars" "BlackRoad-Labs" "blackroad-polars"
fork_repo "duckdb/duckdb" "BlackRoad-Labs" "blackroad-duckdb"
fork_repo "Netflix/metaflow" "BlackRoad-Labs" "blackroad-metaflow"
fork_repo "kubeflow/kubeflow" "BlackRoad-Labs" "blackroad-kubeflow"
fork_repo "nteract/papermill" "BlackRoad-Labs" "blackroad-papermill"
fork_repo "voila-dashboards/voila" "BlackRoad-Labs" "blackroad-voila"
fork_repo "plotly/dash" "BlackRoad-Labs" "blackroad-dash"
fork_repo "marimo-team/marimo" "BlackRoad-Labs" "blackroad-marimo"
fork_repo "rapidsai/cudf" "BlackRoad-Labs" "blackroad-cudf"
fork_repo "wandb/wandb" "BlackRoad-Labs" "blackroad-wandb"

echo ""
echo "--- BlackRoad-Studio (need ~11 more) ---"
fork_repo "Ardour/ardour" "BlackRoad-Studio" "blackroad-ardour"
fork_repo "musescore/MuseScore" "BlackRoad-Studio" "blackroad-musescore"
fork_repo "fontforge/fontforge" "BlackRoad-Studio" "blackroad-fontforge"
fork_repo "pencil2d/pencil" "BlackRoad-Studio" "blackroad-pencil"
fork_repo "opentoonz/opentoonz" "BlackRoad-Studio" "blackroad-opentoonz"
fork_repo "KDE/kdenlive" "BlackRoad-Studio" "blackroad-kdenlive"
fork_repo "pitivi/pitivi" "BlackRoad-Studio" "blackroad-pitivi"
fork_repo "scribusproject/scribus" "BlackRoad-Studio" "blackroad-scribus"
fork_repo "wonderunit/storyboarder" "BlackRoad-Studio" "blackroad-storyboarder"
fork_repo "GNOME/gimp" "BlackRoad-Studio" "blackroad-gimp"
fork_repo "mltframework/shotcut" "BlackRoad-Studio" "blackroad-shotcut"

echo ""
echo "--- BlackRoad-Ventures (need ~13 more) ---"
fork_repo "bagisto/bagisto" "BlackRoad-Ventures" "blackroad-bagisto"
fork_repo "lnbits/lnbits" "BlackRoad-Ventures" "blackroad-lnbits"
fork_repo "OpenBB-finance/OpenBBTerminal" "BlackRoad-Ventures" "blackroad-openbbterminal"
fork_repo "QuantConnect/Lean" "BlackRoad-Ventures" "blackroad-lean"
fork_repo "freqtrade/freqtrade" "BlackRoad-Ventures" "blackroad-freqtrade"
fork_repo "ghostfolio/ghostfolio" "BlackRoad-Ventures" "blackroad-ghostfolio"
fork_repo "simonmichael/hledger" "BlackRoad-Ventures" "blackroad-hledger"
fork_repo "frappe/books" "BlackRoad-Ventures" "blackroad-books"
fork_repo "inventree/InvenTree" "BlackRoad-Ventures" "blackroad-inventree"
fork_repo "rotki/rotki" "BlackRoad-Ventures" "blackroad-rotki"
fork_repo "beancount/beancount" "BlackRoad-Ventures" "blackroad-beancount"
fork_repo "Uniswap/v3-core" "BlackRoad-Ventures" "blackroad-v3-core"
fork_repo "sushiswap/sushiswap" "BlackRoad-Ventures" "blackroad-sushiswap"

echo ""
echo "--- BlackRoad-Education (need ~6 more) ---"
fork_repo "TheOdinProject/curriculum" "BlackRoad-Education" "blackroad-curriculum"
fork_repo "codecombat/codecombat" "BlackRoad-Education" "blackroad-codecombat"
fork_repo "jupyterhub/jupyterhub" "BlackRoad-Education" "blackroad-jupyterhub"
fork_repo "GibbonEdu/core" "BlackRoad-Education" "blackroad-gibbon"
fork_repo "exercism/website" "BlackRoad-Education" "blackroad-exercism"
fork_repo "ilios/ilios" "BlackRoad-Education" "blackroad-ilios"

echo ""
echo "--- BlackRoad-Gov (need ~7 more) ---"
fork_repo "mysociety/alaveteli" "BlackRoad-Gov" "blackroad-alaveteli"
fork_repo "element-hq/element-web" "BlackRoad-Gov" "blackroad-element-web"
fork_repo "umami-software/umami" "BlackRoad-Gov" "blackroad-umami"
fork_repo "ory/hydra" "BlackRoad-Gov" "blackroad-hydra"
fork_repo "kanboard/kanboard" "BlackRoad-Gov" "blackroad-kanboard"
fork_repo "agorakit/agorakit" "BlackRoad-Gov" "blackroad-agorakit"
fork_repo "anytype/anytype-ts" "BlackRoad-Gov" "blackroad-anytype"

echo ""
echo "--- BlackRoad-Archive (need ~9 more) ---"
fork_repo "yt-dlp/yt-dlp" "BlackRoad-Archive" "blackroad-yt-dlp"
fork_repo "mikf/gallery-dl" "BlackRoad-Archive" "blackroad-gallery-dl"
fork_repo "storj/storj" "BlackRoad-Archive" "blackroad-storj"
fork_repo "obsidianmd/obsidian-releases" "BlackRoad-Archive" "blackroad-obsidian-releases"
fork_repo "kovidgoyal/calibre" "BlackRoad-Archive" "blackroad-calibre"
fork_repo "kiwix/kiwix-js" "BlackRoad-Archive" "blackroad-kiwix-js"
fork_repo "miniflux/v2" "BlackRoad-Archive" "blackroad-miniflux"
fork_repo "FreshRSS/FreshRSS" "BlackRoad-Archive" "blackroad-freshrss"
fork_repo "fox-it/dissect" "BlackRoad-Archive" "blackroad-dissect"

echo ""
echo "--- Blackbox-Enterprises (need ~9 more) ---"
fork_repo "strapi/strapi" "Blackbox-Enterprises" "blackbox-strapi"
fork_repo "chatwoot/chatwoot" "Blackbox-Enterprises" "blackbox-chatwoot"
fork_repo "calcom/cal.com" "Blackbox-Enterprises" "blackbox-cal.com"
fork_repo "makeplane/plane" "Blackbox-Enterprises" "blackbox-plane"
fork_repo "42wim/matterbridge" "Blackbox-Enterprises" "blackbox-matterbridge"
fork_repo "caprover/caprover" "Blackbox-Enterprises" "blackbox-caprover"
fork_repo "coollabsio/coolify" "Blackbox-Enterprises" "blackbox-coolify"
fork_repo "dokploy/dokploy" "Blackbox-Enterprises" "blackbox-dokploy"
fork_repo "supabase/supabase" "Blackbox-Enterprises" "blackbox-supabase"

echo ""
echo "=== DONE - Check counts ==="
for org in BlackRoad-Labs BlackRoad-Studio BlackRoad-Ventures BlackRoad-Education BlackRoad-Gov BlackRoad-Archive Blackbox-Enterprises; do
  count=$(gh repo list "$org" --limit 200 --json name -q 'length' 2>/dev/null)
  echo "$org: $count repos"
done
