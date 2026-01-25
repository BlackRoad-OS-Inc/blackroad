#!/bin/bash
# Check Trinity compliance for an entity

ENTITY_NAME="$1"
ENTITY_TYPE="${2:-template}"

if [ -z "$ENTITY_NAME" ]; then
    echo "Usage: $0 <entity_name> [entity_type]"
    exit 1
fi

CODEX_DB="$HOME/.blackroad/codex/codex.db"

echo "🚦 Checking Trinity compliance for: $ENTITY_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check each Light
for light in greenlight yellowlight redlight; do
    echo ""
    case "$light" in
        greenlight) emoji="🟢" ;;
        yellowlight) emoji="🟡" ;;
        redlight) emoji="🔴" ;;
    esac
    
    echo "$emoji ${light^^} Standards:"
    
    sqlite3 "$CODEX_DB" <<SQL
SELECT 
    '  ' || CASE WHEN passed THEN '✅' ELSE '❌' END || ' ' || 
    test_name || ': ' || 
    COALESCE(details, 'No details')
FROM trinity_test_results
WHERE entity_name = '$ENTITY_NAME' 
  AND light_type = '$light'
ORDER BY tested_at DESC;
SQL
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Overall compliance
sqlite3 "$CODEX_DB" <<SQL
SELECT 
    CASE 
        WHEN greenlight_pass AND yellowlight_pass AND redlight_pass THEN '✅ FULL COMPLIANCE'
        WHEN greenlight_pass OR yellowlight_pass OR redlight_pass THEN '⚠️ PARTIAL COMPLIANCE'
        ELSE '❌ NON-COMPLIANT'
    END || 
    ' (🟢: ' || CASE WHEN greenlight_pass THEN 'PASS' ELSE 'FAIL' END || 
    ', 🟡: ' || CASE WHEN yellowlight_pass THEN 'PASS' ELSE 'FAIL' END ||
    ', 🔴: ' || CASE WHEN redlight_pass THEN 'PASS' ELSE 'FAIL' END || ')'
FROM trinity_compliance
WHERE entity_name = '$ENTITY_NAME'
ORDER BY last_checked DESC
LIMIT 1;
SQL

