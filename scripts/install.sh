#!/usr/bin/env bash
# Install the enhanced ndemo toolkit used by the narrated-web-app-demo skill.
# Clones splitbrain/ndemo, applies the enhancement patch, builds, and installs
# the Playwright browser. Idempotent-ish: refuses to overwrite a non-empty dest.
set -euo pipefail

DEST="${1:-$HOME/.claude/skills/ndemo}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH="$SCRIPT_DIR/../patches/ndemo-enhancements.patch"

if [ -d "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "Destination $DEST already exists and is not empty."
  echo "Remove it first, or pass a different path: scripts/install.sh /path/to/ndemo"
  exit 1
fi

echo "==> Cloning splitbrain/ndemo into $DEST"
git clone https://github.com/splitbrain/ndemo "$DEST"

echo "==> Applying enhancement patch"
git -C "$DEST" apply --3way "$PATCH" || {
  echo "Patch did not apply cleanly (upstream may have changed)."
  echo "Apply $PATCH manually, or open it to port the changes."
  exit 1
}

echo "==> Installing dependencies and building"
( cd "$DEST" && npm install && npm run build )

echo "==> Installing Playwright Chromium"
( cd "$DEST" && npx playwright install chromium )

echo "==> Done. Verify with: $DEST/ndemo doctor"
echo "    Set OPENAI_API_KEY and/or MINIMAX_API_KEY in your shell for TTS."
