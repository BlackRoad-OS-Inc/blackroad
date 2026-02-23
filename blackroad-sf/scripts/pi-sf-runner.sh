#!/bin/bash
# Run Salesforce operations from Pi
# Usage: ./pi-sf-runner.sh [validate|deploy|test|status]
set -e

SF_CMD="sf"
command -v sf &>/dev/null || SF_CMD="sfdx"
command -v $SF_CMD &>/dev/null || { echo "❌ sf CLI not installed. Run: sudo npm install -g @salesforce/cli"; exit 1; }

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
ORG_ALIAS="blackroad-${BRANCH//\//-}"

case "$1" in
  validate)
    $SF_CMD project deploy validate \
      --source-dir force-app \
      --target-org "$ORG_ALIAS" \
      --test-level RunLocalTests
    ;;
  deploy)
    $SF_CMD project deploy start \
      --source-dir force-app \
      --target-org "$ORG_ALIAS" \
      --test-level RunLocalTests
    ;;
  test)
    cd .. && npm test
    ;;
  status)
    $SF_CMD org list
    ;;
  *)
    echo "Usage: $0 [validate|deploy|test|status]"
    ;;
esac
