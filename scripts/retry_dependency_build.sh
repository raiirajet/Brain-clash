#!/usr/bin/env bash
# Retry only external dependency throttling, never compilation or test failures.
set -euo pipefail
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
for attempt in 1 2 3; do
  if "$@" 2>&1 | tee "$log"; then exit 0; fi
  if ! grep -Eiq '429.*Too Many Requests|status code 429|HTTP 429|HTTP 503|status code 503' "$log"; then exit 1; fi
  if [ "$attempt" -eq 3 ]; then exit 1; fi
  echo "External dependency server throttled; retrying build after bounded backoff."
  sleep "$((attempt * 30))"
done
