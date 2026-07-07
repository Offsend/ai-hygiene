#!/usr/bin/env bash
set -euo pipefail

PATH_TO_SCAN="${OFFSEND_PATH:-.}"
STAGED="${OFFSEND_STAGED:-false}"
POLICY="${OFFSEND_POLICY:-true}"
FAIL_ON="${OFFSEND_FAIL_ON:-block}"
FORMAT="${OFFSEND_FORMAT:-text}"
QUIET="${OFFSEND_QUIET:-false}"

if ! command -v offsend >/dev/null 2>&1; then
  echo "offsend CLI is not on PATH. Run scripts/install.sh first." >&2
  exit 1
fi

case "$FAIL_ON" in
  block | warn | none) ;;
  *)
    echo "Unsupported fail-on value: $FAIL_ON (expected block, warn, or none)" >&2
    exit 1
    ;;
esac

case "$FORMAT" in
  text | json) ;;
  *)
    echo "Unsupported format: $FORMAT (expected text or json)" >&2
    exit 1
    ;;
esac

WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
if [[ "$PATH_TO_SCAN" = /* ]]; then
  SCAN_ROOT="$PATH_TO_SCAN"
else
  SCAN_ROOT="${WORKSPACE%/}/${PATH_TO_SCAN}"
fi

if [[ ! -d "$SCAN_ROOT" ]]; then
  echo "Scan path not found: $SCAN_ROOT" >&2
  exit 1
fi

is_true() {
  case "$1" in
    [Tt][Rr][Uu][Ee] | 1 | [Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

args=(check)

if is_true "$STAGED"; then
  args+=(--staged --working-directory "$SCAN_ROOT")
else
  args+=(. --working-directory "$SCAN_ROOT")
fi

if is_true "$POLICY"; then
  args+=(--policy)
fi

args+=(--fail-on "$FAIL_ON" --format "$FORMAT")

if is_true "$QUIET"; then
  args+=(--quiet)
fi

offsend "${args[@]}"
