#!/usr/bin/env bash
# ci/local.sh — run suites on this machine, then publish logs even if they failed.
#
#   ci/local.sh               # all default suites
#   ci/local.sh matlab        # just MATLAB
#   NO_PUBLISH=1 ci/local.sh  # run only, keep logs in .ci-logs/

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

out="$(bash "$HERE/run.sh" "$@" | tee /dev/stderr | tail -n1)"
rc=${PIPESTATUS[0]}

if [ -z "${NO_PUBLISH:-}" ] && [ -d "$out" ]; then
  bash "$HERE/publish.sh" "$out" || echo "publish failed; logs remain in $out" >&2
fi
exit "$rc"
