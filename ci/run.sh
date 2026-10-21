#!/usr/bin/env bash
# ci/run.sh — run neuronal suites and write one log per suite.
#
#   ci/run.sh                 # all default suites
#   ci/run.sh matlab rust     # only these
#
# Output: $CI_LOG_DIR/<UTCstamp>-<sha>/{<suite>.log, status.tsv, summary.md}
# Default CI_LOG_DIR: <repo>/.ci-logs   (keep it in .gitignore on main)
#
# Logs are meant to be published to a PUBLIC branch: paths under $HOME,
# $NEURONAL_DATA_ROOT and $NEURONAL_CATALOG_PATH are redacted.

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

DEFAULT_SUITES=(registry rust python matlab lean)
KNOWN_SUITES=(registry rust python matlab realdata lean)

SUITES=("$@")
[ ${#SUITES[@]} -eq 0 ] && SUITES=("${DEFAULT_SUITES[@]}")
for s in "${SUITES[@]}"; do
  [[ " ${KNOWN_SUITES[*]} " == *" $s "* ]] || { echo "unknown suite: $s (known: ${KNOWN_SUITES[*]})" >&2; exit 2; }
done

SHA="$(git rev-parse --short=12 HEAD)"
BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${STAMP}-${SHA}"
OUT="${CI_LOG_DIR:-$ROOT/.ci-logs}/$RUN_ID"
mkdir -p "$OUT"

if [ -n "${GITHUB_RUN_ID:-}" ]; then
  ORIGIN="actions ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
else
  ORIGIN="local"
fi
DIRTY=""; git diff --quiet HEAD -- 2>/dev/null || DIRTY=" (uncommitted changes)"

MATLAB_BIN="${MATLAB_BIN:-$(command -v matlab-r2019a || command -v matlab || true)}"
export CARGO_TERM_COLOR=never
[ -d "$HOME/.elan/bin" ] && export PATH="$HOME/.elan/bin:$PATH"

redact() {
  # Literal replacements: paths may contain sed delimiters or regex syntax.
  python3 -u -c '
import os, re, sys
pairs = [(os.environ.get(key, ""), replacement) for key, replacement in (
    ("NEURONAL_DATA_ROOT", "<data-root>"),
    ("NEURONAL_CATALOG_PATH", "<catalog>"), ("HOME", "~"))]
pairs = sorted((pair for pair in pairs if pair[0]), key=lambda pair: -len(pair[0]))
for line in sys.stdin:
    for source, replacement in pairs:
        line = line.replace(source, replacement)
    sys.stdout.write(re.sub(r"\x1b\[[0-9;]*[mK]", "", line))
'
}

step() { echo "\$ $*"; "$@"; }

# ---- suites -----------------------------------------------------------------

suite_registry() {
  step make -C books check
  local base="${CI_BASE_SHA:-HEAD^}"
  git rev-parse -q --verify "$base" >/dev/null || base="$(git hash-object -t tree /dev/null)"
  step git diff --check "$base" HEAD
  echo "\$ check: no submodules or .lake/ tracked"
  ! git ls-files --stage | grep -Eq '^160000 |/\.lake/'
}

suite_rust() {
  step cargo --version
  step cargo fmt --all -- --check
  step cargo build --workspace --locked
  step cargo clippy --workspace --all-targets --locked -- -D warnings
  step cargo test --workspace --locked
}

suite_python() {
  step python3 --version
  [ -d .ci-venv ] || step python3 -m venv .ci-venv
  step .ci-venv/bin/python -m pip install --quiet '.[dev]'
  step .ci-venv/bin/python -m pytest -q
}

suite_matlab() {
  [ -n "$MATLAB_BIN" ] || { echo "MATLAB not found (set MATLAB_BIN or put matlab-r2019a on PATH)"; return 1; }
  echo "MATLAB_BIN=$MATLAB_BIN"
  step test -f matlab/tests/run_scientific_suite.m
  rm -f matlab/build/scientific-tests.log
  local rc=0
  step "$MATLAB_BIN" -batch "assert(license('test','Signal_Toolbox')==1); ver; run('$ROOT/matlab/tests/run_scientific_suite.m')" || rc=$?
  [ -f matlab/build/scientific-tests.log ] && redact < matlab/build/scientific-tests.log > "$OUT/matlab-scientific-tests.log"
  return $rc
}

# Opt-in only (not in defaults): touches private recordings.
suite_realdata() {
  [ -n "${NEURONAL_CATALOG_PATH:-}" ] || { echo "NEURONAL_CATALOG_PATH unset; skipping"; return 0; }
  [ -n "$MATLAB_BIN" ] || { echo "MATLAB not found"; return 1; }
  step "$MATLAB_BIN" -batch "run('$ROOT/analysis/con2phys_real_data_check.m')"
}

suite_lean() {
  cd books/formal_foundations/lean || return 1
  step lake --version
  step lake exe cache get
  step lake build
}

# ---- runner -----------------------------------------------------------------

printf 'suite\tstatus\tseconds\n' > "$OUT/status.tsv"
OVERALL=0
for s in "${SUITES[@]}"; do
  echo "==> $s"
  t0=$SECONDS
  ( set -e; "suite_$s" ) 2>&1 | redact > "$OUT/$s.log"
  pipeline_status=("${PIPESTATUS[@]}")
  rc=${pipeline_status[0]}
  [ "${pipeline_status[1]}" -eq 0 ] || rc=${pipeline_status[1]}
  dt=$((SECONDS - t0))
  if [ "$rc" -eq 0 ]; then st=pass; else st="FAIL($rc)"; OVERALL=1; fi
  printf '%s\t%s\t%s\n' "$s" "$st" "$dt" >> "$OUT/status.tsv"
  echo "    $st in ${dt}s"
done

{
  echo "# neuronal run $RUN_ID"
  echo
  echo "- overall: $([ $OVERALL -eq 0 ] && echo pass || echo FAIL)"
  echo "- commit: \`$SHA\`$DIRTY on \`$BRANCH\`"
  echo "- origin: $ORIGIN"
  echo "- host: $(uname -srm)"
  echo "- matlab: ${MATLAB_BIN:-none}" | redact
  echo
  echo "| suite | status | seconds |"
  echo "|---|---|---|"
  tail -n +2 "$OUT/status.tsv" | awk -F'\t' '{printf "| %s | %s | %s |\n",$1,$2,$3}'
  while IFS=$'\t' read -r s st _; do
    [[ "$st" == FAIL* ]] || continue
    echo; echo "## $s — last 40 lines"; echo; echo '```'
    tail -n 40 "$OUT/$s.log"
    echo '```'
  done < <(tail -n +2 "$OUT/status.tsv")
} > "$OUT/summary.md"

echo "$OUT"
exit $OVERALL
