#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

PLUGIN_DIR=$(ls -d "$CLAUDE_DIR"/plugins/cache/*/claude-hud/*/ 2>/dev/null \
  | awk -F/ '{ print $(NF-1) "\t" $0 }' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+[[:space:]]' \
  | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
  | tail -1 | cut -f2-)

if [ -z "$PLUGIN_DIR" ]; then
  echo "claude-hud plugin not found. Run /plugin install claude-hud first." >&2
  exit 1
fi

echo "Plugin: $PLUGIN_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for patch in "$SCRIPT_DIR"/patches/*.patch; do
  name=$(basename "$patch")
  if (cd "$PLUGIN_DIR" && patch -p1 --dry-run --silent < "$patch") 2>/dev/null; then
    (cd "$PLUGIN_DIR" && patch -p1 < "$patch")
    echo "applied: $name"
  elif (cd "$PLUGIN_DIR" && patch -p1 --dry-run --silent --reverse < "$patch") 2>/dev/null; then
    echo "skipped: $name (already applied)"
  else
    echo "FAILED: $name (upstream changed?)" >&2
    exit 1
  fi
done

mkdir -p "$CLAUDE_DIR/plugins/claude-hud"
cp "$SCRIPT_DIR/config.json" "$CLAUDE_DIR/plugins/claude-hud/config.json"
echo "config: $CLAUDE_DIR/plugins/claude-hud/config.json"

echo "Done. The HUD will reflect changes immediately."
