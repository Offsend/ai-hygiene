#!/usr/bin/env bash
set -euo pipefail

VERSION="${OFFSEND_VERSION:?OFFSEND_VERSION is required}"
ACTION_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${ACTION_ROOT}/scripts/versions.json"

case "$(uname -s)" in
  Darwin) ;;
  *)
    echo "offsend-cli currently supports macOS runners only." >&2
    echo "Use runs-on: macos-latest (or another macOS runner)." >&2
    exit 1
    ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  arm64 | x86_64) ;;
  *)
    echo "Unsupported macOS architecture: $ARCH" >&2
    exit 1
    ;;
esac

INSTALL_DIR="${RUNNER_TEMP:-/tmp}/offsend-cli-${VERSION}"
ZIP_NAME="offsend-cli-${VERSION}.zip"
DOWNLOAD_URL="https://github.com/Offsend/Offsend/releases/download/v${VERSION}/${ZIP_NAME}"
ZIP_PATH="${RUNNER_TEMP:-/tmp}/${ZIP_NAME}"

if [[ -x "${INSTALL_DIR}/offsend" ]]; then
  echo "Using cached offsend CLI at ${INSTALL_DIR}/offsend"
else
  echo "Downloading offsend-cli v${VERSION} from ${DOWNLOAD_URL}"
  curl -fsSL --retry 3 --retry-delay 2 -o "$ZIP_PATH" "$DOWNLOAD_URL"

  if [[ -f "$VERSIONS_FILE" ]]; then
    EXPECTED_SHA256="$(
      VERSION="$VERSION" VERSIONS_FILE="$VERSIONS_FILE" python3 - <<'PY'
import json
import os
import sys

version = os.environ["VERSION"]
with open(os.environ["VERSIONS_FILE"], encoding="utf-8") as handle:
    versions = json.load(handle)

entry = versions.get(version)
if not entry:
    sys.exit(0)

print(entry["sha256"])
PY
    )"
    if [[ -n "${EXPECTED_SHA256:-}" ]]; then
      ACTUAL_SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
      if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
        echo "Checksum mismatch for ${ZIP_NAME}." >&2
        echo "Expected: ${EXPECTED_SHA256}" >&2
        echo "Actual:   ${ACTUAL_SHA256}" >&2
        exit 1
      fi
      echo "Verified SHA256 for offsend-cli v${VERSION}"
    else
      echo "No pinned checksum for v${VERSION}; skipping verification."
    fi
  fi

  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  unzip -q "$ZIP_PATH" -d "$INSTALL_DIR"
  chmod +x "${INSTALL_DIR}/offsend"
fi

"${INSTALL_DIR}/offsend" --version

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$INSTALL_DIR" >> "$GITHUB_PATH"
else
  export PATH="${INSTALL_DIR}:${PATH}"
fi
