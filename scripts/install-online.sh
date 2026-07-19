#!/usr/bin/env bash
#
# install-online.sh — one-command installer for P-3 (Fenix).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh | bash
#
# Optional:
#   FENIX_VERSION=4.0.0 ...    # pin a specific release (default: latest)
#
# What it does:
#   1. Resolves target version (latest GitHub release tag by default).
#   2. Downloads the release zip into a temp dir.
#   3. Extracts and runs scripts/setup.sh against the current directory.
#      - On fresh install: scaffolds everything.
#      - On existing install of an older version: runs the upgrade path
#        from scripts/upgrades/<from>-to-<to>.json.
#   4. Cleans up the temp dir on exit (success or failure).
#
# Review before running:
#   https://github.com/ablack13/p-3-fenix/blob/main/scripts/install-online.sh

set -euo pipefail

REPO="ablack13/p-3-fenix"
FENIX_VERSION="${FENIX_VERSION:-}"

# --- output helpers --------------------------------------------------------

if [[ -t 1 ]]; then
  GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'
  DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; DIM=''; BOLD=''; RESET=''
fi

ok()   { printf '%s✓%s %s\n'  "$GREEN" "$RESET" "$1"; }
warn() { printf '%s⚠%s %s\n'  "$YELLOW" "$RESET" "$1"; }
fail() { printf '%s✗%s %s\n'  "$RED"   "$RESET" "$1" >&2; exit 1; }
say()  { printf '%s\n' "$1"; }

# --- preflight -------------------------------------------------------------

command -v curl    >/dev/null 2>&1 || fail "curl is required"
command -v unzip   >/dev/null 2>&1 || fail "unzip is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required (used by setup.sh for manifest writes)"

REPO_ROOT="$(pwd)"

say ""
say "${BOLD}P-3 (Fenix) — online installer${RESET}"
say "${DIM}Target repo:${RESET} $REPO_ROOT"

# --- resolve version -------------------------------------------------------

if [[ -z "$FENIX_VERSION" ]]; then
  ok "Resolving latest release tag from GitHub..."
  TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('tag_name',''))" \
    2>/dev/null || true)"
  [[ -n "$TAG" ]] || fail "Could not resolve latest release. Pass FENIX_VERSION=<version> to pin a version."
  FENIX_VERSION="${TAG#v}"
fi

ok "Target version: $FENIX_VERSION"

KIT_NAME="p3-fenix-${FENIX_VERSION}"
ZIP_URL="https://github.com/${REPO}/releases/download/${FENIX_VERSION}/${KIT_NAME}.zip"

# --- temp workspace --------------------------------------------------------

TMP_DIR="$(mktemp -d -t fenix-install-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

ZIP_PATH="$TMP_DIR/${KIT_NAME}.zip"

ok "Downloading kit: $ZIP_URL"
curl -fsSL "$ZIP_URL" -o "$ZIP_PATH" || fail "Download failed. Check the version exists at: https://github.com/${REPO}/releases"

ok "Extracting..."
unzip -q "$ZIP_PATH" -d "$TMP_DIR" || fail "Extraction failed."

KIT_DIR="$TMP_DIR/$KIT_NAME"
[[ -f "$KIT_DIR/scripts/setup.sh" ]] || fail "setup.sh not found in extracted kit ($KIT_DIR/scripts/setup.sh)"

# --- hand off to setup.sh --------------------------------------------------

cd "$REPO_ROOT"
bash "$KIT_DIR/scripts/setup.sh"

# Cleanup runs via trap on exit.
