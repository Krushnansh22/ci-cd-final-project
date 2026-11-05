#!/usr/bin/env bash
#
# Smoke-test a deployed Hit Counter Service.
#
# Usage:
#   ./scripts/smoke-test.sh https://counter-service-route-url
#
set -euo pipefail

BASE_URL="${1:-${BASE_URL:-}}"
if [ -z "$BASE_URL" ]; then
    echo "Usage: $0 https://your-route-url"
    exit 1
fi
BASE_URL="${BASE_URL%/}"

echo "==> Health"
curl -fsS "$BASE_URL/health"
echo

echo "==> Index"
curl -fsS "$BASE_URL/"
echo

echo "==> Create counter"
curl -fsS -X POST "$BASE_URL/counters/demo"
echo

echo "==> Increment counter"
curl -fsS -X PUT "$BASE_URL/counters/demo"
echo

echo "==> Read counter"
curl -fsS "$BASE_URL/counters/demo"
echo

echo "==> List counters"
curl -fsS "$BASE_URL/counters"
echo

echo "Smoke test passed."
