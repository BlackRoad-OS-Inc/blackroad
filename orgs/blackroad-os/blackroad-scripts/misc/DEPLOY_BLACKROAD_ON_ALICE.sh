#!/bin/bash
# Run these commands ON ALICE (you're already there!)

echo "🌌 DEPLOYING BLACKROAD LANGUAGE TO ALICE! 🌌"
echo ""

# Check current space
echo "=== Current disk space ==="
df -h / | tail -1
echo ""

# Find what's taking space in /usr/local
echo "=== Checking /usr/local ==="
du -sh /usr/local/* 2>/dev/null | sort -h | tail -5
echo ""

# Create minimal working directory in /tmp (should have space)
echo "=== Creating BlackRoad workspace in /tmp ==="
mkdir -p /tmp/blackroad
cd /tmp/blackroad

# We'll transfer the C source code directly
# For now, let's create a minimal test

cat > test.road << 'EOF'
# BlackRoad Minimal Test
let x: int = 42
let name = "BlackRoad"
let color = #FF1D6C

fun main():
    print("Hello from BlackRoad on Alice! 🖤🛣️")
EOF

echo "✅ Test file created"
echo ""

# Show what we need to do next
echo "═══════════════════════════════════════"
echo "NEXT STEPS (run from your Mac):"
echo "═══════════════════════════════════════"
echo ""
echo "1. Transfer the C compiler source:"
echo "   cat ~/roadc/roadc.c | ssh alice 'cat > /tmp/blackroad/roadc.c'"
echo ""
echo "2. Compile on Alice:"
echo "   ssh alice 'cd /tmp/blackroad && gcc -std=c99 -O2 -o roadc roadc.c'"
echo ""
echo "3. Test it:"
echo "   ssh alice '/tmp/blackroad/roadc /tmp/blackroad/test.road'"
echo ""
echo "4. Celebrate! 🎉"
echo ""

# Or if you want to free space first:
echo "═══════════════════════════════════════"
echo "TO FREE SPACE (optional):"
echo "═══════════════════════════════════════"
echo ""
echo "# Check what's in /usr/local"
echo "du -sh /usr/local/* | sort -h | tail -10"
echo ""
echo "# If there are old Python versions or node_modules:"
echo "sudo rm -rf /usr/local/lib/python2.7"  # if exists
echo "sudo rm -rf /usr/local/lib/node_modules"  # if exists
echo ""

echo "Current location: $(pwd)"
ls -la
