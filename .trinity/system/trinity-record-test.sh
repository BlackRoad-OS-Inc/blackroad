#!/bin/bash
# Record a Trinity test result

ENTITY_NAME="$1"
LIGHT_TYPE="$2"     # greenlight, yellowlight, redlight
TEST_NAME="$3"
PASSED="$4"         # 0 or 1
DETAILS="${5:-}"

if [ -z "$PASSED" ]; then
    echo "Usage: $0 <entity_name> <light_type> <test_name> <passed:0/1> [details]"
    exit 1
fi

CODEX_DB="$HOME/.blackroad/codex/codex.db"

# Record test result
sqlite3 "$CODEX_DB" <<SQL
INSERT INTO trinity_test_results (entity_name, light_type, test_name, passed, details)
VALUES ('$ENTITY_NAME', '$LIGHT_TYPE', '$TEST_NAME', $PASSED, '$DETAILS');
SQL

# Update compliance table
sqlite3 "$CODEX_DB" <<SQL
INSERT OR REPLACE INTO trinity_compliance (entity_type, entity_name, greenlight_pass, yellowlight_pass, redlight_pass, compliance_status)
SELECT 
    'template',
    '$ENTITY_NAME',
    MAX(CASE WHEN light_type = 'greenlight' AND passed = 1 THEN 1 ELSE 0 END),
    MAX(CASE WHEN light_type = 'yellowlight' AND passed = 1 THEN 1 ELSE 0 END),
    MAX(CASE WHEN light_type = 'redlight' AND passed = 1 THEN 1 ELSE 0 END),
    CASE 
        WHEN SUM(CASE WHEN passed = 1 THEN 1 ELSE 0 END) = COUNT(DISTINCT light_type) THEN 'full'
        WHEN SUM(CASE WHEN passed = 1 THEN 1 ELSE 0 END) > 0 THEN 'partial'
        ELSE 'failed'
    END
FROM trinity_test_results
WHERE entity_name = '$ENTITY_NAME';
SQL

echo "✅ Recorded: $TEST_NAME for $ENTITY_NAME ($LIGHT_TYPE) → $([ "$PASSED" = "1" ] && echo 'PASS' || echo 'FAIL')"

