#!/usr/bin/env bash
# ci/publish.sh — commit a run directory to the `ci-logs` branch and push it.
#
#   ci/publish.sh                         # newest run in .ci-logs/
#   ci/publish.sh .ci-logs/<run-id>       # a specific run
#
# Branch layout:
#   latest/            copy of the most recent run (summary.md is the entry point)
#   runs/<run-id>/     every run, newest $CI_LOG_KEEP kept (default 50)
#   INDEX.md           one line per run, newest first
#
# Env: CI_LOG_BRANCH (ci-logs), CI_LOG_REMOTE (origin), CI_LOG_KEEP (50)

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BR="${CI_LOG_BRANCH:-ci-logs}"
REMOTE="${CI_LOG_REMOTE:-origin}"
KEEP="${CI_LOG_KEEP:-50}"

RUN_DIR="${1:-$(ls -1d "${CI_LOG_DIR:-$ROOT/.ci-logs}"/*/ 2>/dev/null | sort | tail -n1)}"
RUN_DIR="${RUN_DIR%/}"
[ -f "$RUN_DIR/status.tsv" ] || { echo "no run found at '$RUN_DIR'" >&2; exit 1; }
RUN_ID="$(basename "$RUN_DIR")"

overall=pass; grep -q 'FAIL' "$RUN_DIR/status.tsv" && overall=FAIL
commit_line="$(sed -n 's/^- commit: //p' "$RUN_DIR/summary.md")"

WT=""
cleanup() { [ -n "$WT" ] && { git -C "$ROOT" worktree remove --force "$WT" 2>/dev/null || true; rm -rf "$WT"; }; }
trap cleanup EXIT

attempt_publish() {
  cleanup
  WT="$(mktemp -d)"
  if git -C "$ROOT" fetch -q "$REMOTE" "+refs/heads/$BR:refs/remotes/$REMOTE/$BR" 2>/dev/null; then
    git -C "$ROOT" worktree add -q --detach "$WT" "$REMOTE/$BR"
  else
    git -C "$ROOT" worktree add -q --detach "$WT" HEAD
    git -C "$WT" checkout -q --orphan "ci-logs-init-$$"
    git -C "$WT" rm -rfq . >/dev/null
    printf '# ci-logs\n\nLogs from the Dell runner and local runs. Start at `latest/summary.md`.\n\n' > "$WT/README.md"
  fi

  mkdir -p "$WT/runs"
  rm -rf "$WT/runs/$RUN_ID" "$WT/latest"
  cp -r "$RUN_DIR" "$WT/runs/$RUN_ID"
  cp -r "$RUN_DIR" "$WT/latest"

  # retention
  ls -1 "$WT/runs" | sort -r | tail -n +"$((KEEP + 1))" | while read -r old; do rm -rf "$WT/runs/$old"; done

  { echo "- \`$RUN_ID\` **$overall** — $commit_line — [summary](runs/$RUN_ID/summary.md)"
    [ -f "$WT/INDEX.md" ] && grep -v "\`$RUN_ID\`" "$WT/INDEX.md" | grep '^- ' | head -n "$((KEEP - 1))"
  } > "$WT/INDEX.new"
  { echo "# runs (newest first)"; echo; cat "$WT/INDEX.new"; } > "$WT/INDEX.md"; rm "$WT/INDEX.new"

  git -C "$WT" add -A --force
  git -C "$WT" commit -q -m "logs: $RUN_ID $overall"
  git -C "$WT" push -q "$REMOTE" "HEAD:refs/heads/$BR"
}

for i in 1 2 3; do
  if attempt_publish; then
    git -C "$ROOT" branch -D "ci-logs-init-$$" >/dev/null 2>&1 || true
    echo "published $RUN_ID ($overall) -> $REMOTE/$BR"
    exit 0
  fi
  echo "push attempt $i failed; refetching" >&2
  sleep $((i * 3))
done
echo "could not publish $RUN_ID" >&2
exit 1
