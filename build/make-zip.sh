#!/usr/bin/env bash
#
# build/make-zip.sh — produce dist/p3-fenix-<ver>.zip
#
# Reads FENIX_VERSION from scripts/setup.sh as the single source of truth.
# Stages the kit into dist/p3-fenix-<ver>/ and zips it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

FENIX_VERSION="$(grep -E '^FENIX_VERSION=' scripts/setup.sh | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
[[ -n "$FENIX_VERSION" ]] || { echo "✗ FENIX_VERSION not found in scripts/setup.sh" >&2; exit 1; }

KIT_NAME="p3-fenix-${FENIX_VERSION}"
DIST_DIR="$REPO_ROOT/dist"
STAGE_DIR="$DIST_DIR/$KIT_NAME"
ZIP_PATH="$DIST_DIR/${KIT_NAME}.zip"

echo "→ Building $KIT_NAME"

rm -rf "$STAGE_DIR" "$ZIP_PATH"
mkdir -p "$STAGE_DIR"

# Stage payload. Excludes anything that isn't shipped.
rsync -a \
  --exclude='dist/' \
  --exclude='build/' \
  --exclude='_claude_backup/' \
  --exclude='next_version/' \
  --exclude='.claude/' \
  --exclude='.idea/' \
  --exclude='.DS_Store' \
  --exclude='.git/' \
  --exclude='1125/' \
  --exclude='node_modules/' \
  ./ "$STAGE_DIR/"

# Sanity: scripts/setup.sh must be present and executable inside the staged tree.
[[ -f "$STAGE_DIR/scripts/setup.sh" ]] || { echo "✗ scripts/setup.sh missing in stage" >&2; exit 1; }
chmod +x "$STAGE_DIR/scripts/setup.sh"

# Legacy-name guard. The new naming is scripts/setup.sh + p3-fenix-<ver>.zip.
# References to the old fenix-setup.sh / fenix-v3.0.0.zip names should not ship.
if grep -rIn -E "fenix-setup\.sh|fenix-v3\.0\.0\.zip" \
     --include='*.md' --include='*.sh' "$STAGE_DIR" >/dev/null 2>&1; then
  echo "⚠ Legacy-name tokens found in staged tree:" >&2
  grep -rIn -E "fenix-setup\.sh|fenix-v3\.0\.0\.zip" \
       --include='*.md' --include='*.sh' "$STAGE_DIR" >&2 || true
  echo "✗ Build aborted. Clean these references and re-run." >&2
  exit 1
fi

# Zip it.
( cd "$DIST_DIR" && zip -qr "${KIT_NAME}.zip" "$KIT_NAME" )

# Verify.
LISTING="$(unzip -l "$ZIP_PATH")"
echo "$LISTING" | grep -qF "${KIT_NAME}/scripts/setup.sh" \
  || { echo "✗ scripts/setup.sh not found in zip" >&2; exit 1; }

echo "✓ $ZIP_PATH"
echo "  Top-level dir: $KIT_NAME/"
echo "  Install: unzip ${KIT_NAME}.zip && ./${KIT_NAME}/scripts/setup.sh"
