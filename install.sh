#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/xiaotongsu53-a11y/claude-hud-kawaii.git"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Detect whether we're running from a local checkout. When piped via
# `curl ... | bash`, BASH_SOURCE points to /dev/stdin (or is empty), so
# the patches/ directory isn't reachable — clone the repo to a temp dir.
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  CANDIDATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$CANDIDATE/config.json" ] && [ -d "$CANDIDATE/patches" ]; then
    SCRIPT_DIR="$CANDIDATE"
  fi
fi

if [ -z "$SCRIPT_DIR" ]; then
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  echo "fetching claude-hud-kawaii..."
  git clone --depth 1 --quiet "$REPO_URL" "$TMPDIR/repo"
  SCRIPT_DIR="$TMPDIR/repo"
fi

PLUGIN_DIR=$(ls -d "$CLAUDE_DIR"/plugins/cache/*/claude-hud/*/ 2>/dev/null \
  | awk -F/ '{ print $(NF-1) "\t" $0 }' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+[[:space:]]' \
  | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
  | tail -1 | cut -f2-)

if [ -z "$PLUGIN_DIR" ]; then
  echo "claude-hud plugin not found. Run /plugin install claude-hud first." >&2
  exit 1
fi

echo "plugin: $PLUGIN_DIR"

for patch in "$SCRIPT_DIR"/patches/*.patch; do
  name=$(basename "$patch")
  # -N (--forward) refuses to apply a patch that's already applied (which
  # default `patch` would silently reverse). -s silences output.
  if (cd "$PLUGIN_DIR" && patch -p1 -N --dry-run < "$patch" >/dev/null 2>&1); then
    (cd "$PLUGIN_DIR" && patch -p1 -N -s < "$patch")
    echo "applied: $name"
  elif (cd "$PLUGIN_DIR" && patch -p1 -R --dry-run < "$patch" >/dev/null 2>&1); then
    echo "skipped: $name (already applied)"
  else
    echo "FAILED: $name (upstream changed?)" >&2
    exit 1
  fi
done

mkdir -p "$CLAUDE_DIR/plugins/claude-hud"
cp "$SCRIPT_DIR/config.json" "$CLAUDE_DIR/plugins/claude-hud/config.json"
echo "config: $CLAUDE_DIR/plugins/claude-hud/config.json"

echo "done. HUD will reflect changes immediately."
