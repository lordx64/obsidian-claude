#!/bin/bash
# Auto-commit the Obsidian vault if there are changes.
# Designed to run from a launchd LaunchAgent; safe to run manually.
#
# Configurable via env vars (set in the LaunchAgent plist or shell):
#   OBSIDIAN_VAULT  — path to the vault git repo (default: $HOME/vault)
#   GIT_BIN         — git binary (default: /usr/bin/git)

set -uo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/vault}"
GIT="${GIT_BIN:-/usr/bin/git}"

[[ -d "$VAULT/.git" ]] || { echo "[$(date '+%F %T')] vault not found or not a git repo: $VAULT"; exit 1; }

cd "$VAULT" || exit 1

# Bail silently if nothing changed
if [[ -z "$($GIT status --porcelain)" ]]; then
    exit 0
fi

$GIT add -A
$GIT commit -m "auto: $(date '+%Y-%m-%d %H:%M')" --quiet

echo "[$(date '+%F %T')] committed"
