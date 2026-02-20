#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0

run_test() {
  NAME="$1"
  INPUT="$2"
  GOLDEN="$3"

  OUT="$(printf "%s\n" "$INPUT" | ./br agent blackroad-operator)"

  if diff -u "$GOLDEN" <(printf "%s\n" "$OUT") >/dev/null; then
    echo "✓ $NAME"
    PASS=$((PASS+1))
  else
    echo "✗ $NAME"
    echo "---- expected ----"
    cat "$GOLDEN"
    echo "---- got ----"
    printf "%s\n" "$OUT"
    FAIL=$((FAIL+1))
  fi
}

run_test \
  "operator: cloudflare tunnels" \
  "Set up Cloudflare tunnels" \
  tests/operator.golden

echo
echo "Passed: $PASS"
echo "Failed: $FAIL"

[ "$FAIL" -eq 0 ]
