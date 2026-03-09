#!/bin/bash
# Test Coordination v2.0 Systems
# Quick verification that everything works

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🧪 TESTING COORDINATION v2.0 SYSTEMS"
echo "════════════════════════════════════════════════════════════════"
echo ""

PASS=0
FAIL=0

test_file() {
    local file="$1"
    local name="$2"

    if [ -f "$file" ]; then
        echo "✅ $name exists"
        ((PASS++))
        return 0
    else
        echo "❌ $name missing"
        ((FAIL++))
        return 1
    fi
}

test_executable() {
    local file="$1"
    local name="$2"

    if [ -x "$file" ]; then
        echo "✅ $name is executable"
        ((PASS++))
        return 0
    else
        echo "❌ $name not executable (run: chmod +x $file)"
        ((FAIL++))
        return 1
    fi
}

test_database() {
    local file="$1"
    local name="$2"

    if [ -f "$file" ]; then
        local tables=$(sqlite3 "$file" ".tables" 2>/dev/null | wc -w)
        if [ "$tables" -gt 0 ]; then
            echo "✅ $name database has $tables tables"
            ((PASS++))
            return 0
        else
            echo "⚠️  $name database exists but empty"
            ((FAIL++))
            return 1
        fi
    else
        echo "❌ $name database missing"
        ((FAIL++))
        return 1
    fi
}

test_command() {
    local cmd="$1"
    local name="$2"

    if eval "$cmd" &>/dev/null; then
        echo "✅ $name command works"
        ((PASS++))
        return 0
    else
        echo "❌ $name command failed"
        ((FAIL++))
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 1. Testing Documentation Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_file ~/CLAUDE_COORDINATION_ARCHITECTURE.md "Architecture Doc"
test_file ~/COORDINATION_QUICKSTART.md "Quick Start Guide"
test_file ~/Desktop/COORDINATION_V2_SUMMARY.md "Executive Summary"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 2. Testing Scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_file ~/blackroad-universal-index.sh "[INDEX] script exists"
test_executable ~/blackroad-universal-index.sh "[INDEX] executable"
test_file ~/blackroad-knowledge-graph.sh "[GRAPH] script exists"
test_executable ~/blackroad-knowledge-graph.sh "[GRAPH] executable"
test_file ~/claude-session-init-v2.sh "Session init v2.0 exists"
test_executable ~/claude-session-init-v2.sh "Session init v2.0 executable"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 3. Testing Databases"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_database ~/.blackroad/index/assets.db "[INDEX] database"
test_database ~/.blackroad/graph/knowledge.db "[GRAPH] database"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  4. Testing Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_command "~/blackroad-universal-index.sh stats" "[INDEX] stats command"
test_command "~/blackroad-knowledge-graph.sh stats" "[GRAPH] stats command"
test_command "~/memory-system.sh summary" "[MEMORY] summary command"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 5. Testing Integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if [INDEX] has any assets
INDEX_ASSETS=$(sqlite3 ~/.blackroad/index/assets.db "SELECT COUNT(*) FROM assets;" 2>/dev/null || echo "0")
if [ "$INDEX_ASSETS" -gt 0 ]; then
    echo "✅ [INDEX] has $INDEX_ASSETS assets indexed"
    ((PASS++))
else
    echo "⚠️  [INDEX] empty (run: ~/blackroad-universal-index.sh refresh)"
    echo "   This is normal for first run - just needs indexing"
fi

# Check if [GRAPH] has any nodes
GRAPH_NODES=$(sqlite3 ~/.blackroad/graph/knowledge.db "SELECT COUNT(*) FROM nodes;" 2>/dev/null || echo "0")
if [ "$GRAPH_NODES" -gt 0 ]; then
    echo "✅ [GRAPH] has $GRAPH_NODES nodes"
    ((PASS++))
else
    echo "⚠️  [GRAPH] empty (run: ~/blackroad-knowledge-graph.sh build)"
    echo "   This is normal for first run - just needs building"
fi

# Check [MEMORY] entries
MEMORY_ENTRIES=$(wc -l < ~/.blackroad/memory/journals/master-journal.jsonl 2>/dev/null || echo "0")
if [ "$MEMORY_ENTRIES" -gt 0 ]; then
    echo "✅ [MEMORY] has $MEMORY_ENTRIES entries"
    ((PASS++))
else
    echo "❌ [MEMORY] journal missing"
    ((FAIL++))
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📊 TEST RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✅ Passed: $PASS"
echo "❌ Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    echo ""
    echo "✅ Coordination v2.0 is fully operational!"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ~/blackroad-universal-index.sh refresh"
    echo "  2. Run: ~/blackroad-knowledge-graph.sh build"
    echo "  3. Run: ~/claude-session-init-v2.sh"
    echo ""
    echo "Read: ~/COORDINATION_QUICKSTART.md for usage guide"
else
    echo "⚠️  Some tests failed (see above)"
    echo ""
    echo "Common fixes:"
    echo "  • Run: chmod +x ~/blackroad-*.sh ~/claude-*.sh"
    echo "  • Run: ~/blackroad-universal-index.sh init"
    echo "  • Run: ~/blackroad-knowledge-graph.sh init"
    echo ""
    echo "For help, check: ~/COORDINATION_QUICKSTART.md"
fi

echo "════════════════════════════════════════════════════════════════"
