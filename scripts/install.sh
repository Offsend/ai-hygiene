#!/usr/bin/env bash
set -euo pipefail

VERSION="${OFFSEND_VERSION:?OFFSEND_VERSION is required}"
ACTION_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="${ACTION_ROOT}/scripts/versions.json"
TMP_ROOT="${RUNNER_TEMP:-/tmp}"

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin)
      case "$arch" in
        arm64 | x86_64)
          PLATFORM="darwin"
          ARCHIVE_NAME="offsend-cli-${VERSION}.zip"
          CHECKSUM_KEY="darwin"
          ;;
        *)
          echo "Unsupported macOS architecture: $arch" >&2
          exit 1
          ;;
      esac
      ;;
    Linux)
      case "$arch" in
        x86_64 | amd64)
          PLATFORM="linux"
          LINUX_ARCH="x86_64"
          ;;
        aarch64 | arm64)
          PLATFORM="linux"
          LINUX_ARCH="aarch64"
          ;;
        *)
          echo "Unsupported Linux architecture: $arch" >&2
          exit 1
          ;;
      esac
      ARCHIVE_NAME="offsend-cli-${VERSION}-linux-${LINUX_ARCH}.tar.gz"
      CHECKSUM_KEY="linux-${LINUX_ARCH}"
      ;;
    *)
      echo "Unsupported operating system: $os" >&2
      echo "Offsend CLI supports macOS and Linux runners." >&2
      exit 1
      ;;
  esac
}

lookup_checksum() {
  if [[ ! -f "$VERSIONS_FILE" ]]; then
    return 0
  fi

  VERSION="$VERSION" CHECKSUM_KEY="$CHECKSUM_KEY" VERSIONS_FILE="$VERSIONS_FILE" python3 - <<'PY'
import json
import os
import sys

version = os.environ["VERSION"]
key = os.environ["CHECKSUM_KEY"]
with open(os.environ["VERSIONS_FILE"], encoding="utf-8") as handle:
    versions = json.load(handle)

entry = versions.get(version)
if not entry:
    sys.exit(0)

# New multi-platform shape: { "darwin": {"sha256": "..."}, "linux-x86_64": {...} }
if isinstance(entry, dict) and key in entry and isinstance(entry[key], dict):
    digest = entry[key].get("sha256")
    if digest:
        print(digest)
    sys.exit(0)

# Legacy macOS-only shape: { "sha256": "..." }
if key == "darwin" and isinstance(entry, dict) and "sha256" in entry:
    print(entry["sha256"])
PY
}

verify_checksum() {
  local archive_path="$1"
  local expected
  expected="$(lookup_checksum || true)"

  if [[ -z "${expected:-}" ]]; then
    echo "No pinned checksum for v${VERSION} (${CHECKSUM_KEY}); skipping verification."
    return 0
  fi

  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$archive_path" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
  fi

  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch for ${ARCHIVE_NAME}." >&2
    echo "Expected: ${expected}" >&2
    echo "Actual:   ${actual}" >&2
    exit 1
  fi
  echo "Verified SHA256 for offsend-cli v${VERSION} (${CHECKSUM_KEY})"
}

extract_archive() {
  local archive_path="$1"
  local dest="$2"

  rm -rf "$dest"
  mkdir -p "$dest"

  case "$PLATFORM" in
    darwin)
      unzip -q "$archive_path" -d "$dest"
      ;;
    linux)
      tar -xzf "$archive_path" -C "$dest"
      ;;
  esac

  if [[ ! -x "${dest}/offsend" ]]; then
    echo "Extracted archive is missing an executable offsend binary." >&2
    exit 1
  fi
  chmod +x "${dest}/offsend"
}

detect_platform

INSTALL_DIR="${TMP_ROOT}/offsend-cli-${VERSION}-${CHECKSUM_KEY}"
DOWNLOAD_URL="https://github.com/Offsend/Offsend/releases/download/v${VERSION}/${ARCHIVE_NAME}"
ARCHIVE_PATH="${TMP_ROOT}/${ARCHIVE_NAME}"

if [[ -x "${INSTALL_DIR}/offsend" ]]; then
  echo "Using cached offsend CLI at ${INSTALL_DIR}/offsend"
else
  echo "Downloading offsend-cli v${VERSION} (${CHECKSUM_KEY}) from ${DOWNLOAD_URL}"
  curl -fsSL --retry 3 --retry-delay 2 -o "$ARCHIVE_PATH" "$DOWNLOAD_URL"
  verify_checksum "$ARCHIVE_PATH"
  extract_archive "$ARCHIVE_PATH" "$INSTALL_DIR"
fi

"${INSTALL_DIR}/offsend" --version

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$INSTALL_DIR" >> "$GITHUB_PATH"
else
  export PATH="${INSTALL_DIR}:${PATH}"
fi
