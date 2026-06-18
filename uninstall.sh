#!/bin/bash
# obsidian-claude uninstaller.
# Usage: ./uninstall.sh                # interactive
#        LABEL_NS=… ./uninstall.sh     # non-interactive

set -uo pipefail

DEFAULT_LABEL_NS="com.localuser"
LABEL_NS="${LABEL_NS:-}"

if [[ -t 0 && -z "$LABEL_NS" ]]; then
    read -rp "LaunchAgent label namespace to uninstall [$DEFAULT_LABEL_NS]: " LABEL_NS
    LABEL_NS="${LABEL_NS:-$DEFAULT_LABEL_NS}"
else
    LABEL_NS="${LABEL_NS:-$DEFAULT_LABEL_NS}"
fi

echo
echo "Uninstalling obsidian-claude with namespace: $LABEL_NS"
echo

# ── Unload + remove LaunchAgents ──────────────────────────────────────────
for label in obsidian-vault-autocommit obsidian-nightly-knowledge-review; do
    plist="$HOME/Library/LaunchAgents/${LABEL_NS}.${label}.plist"
    if [[ -f "$plist" ]]; then
        launchctl unload "$plist" 2>/dev/null || true
        rm -f "$plist"
        echo "✓ removed $plist"
    fi
done

# ── Remove bin scripts ────────────────────────────────────────────────────
rm -f "$HOME/.local/bin/obsidian-vault-autocommit.sh"
rm -f "$HOME/.local/bin/obsidian-nightly-knowledge-review.sh"
echo "✓ removed ~/.local/bin/obsidian-*.sh"

# ── Remove skills ─────────────────────────────────────────────────────────
rm -rf "$HOME/.claude/skills/obsidian-journal"
rm -rf "$HOME/.claude/skills/obsidian-knowledge-review"
echo "✓ removed ~/.claude/skills/obsidian-*"

echo
echo "✅ obsidian-claude removed."
echo "   Logs preserved at ~/Library/Logs/obsidian-*.log (delete manually if desired)."
echo "   Your vault and its git history are untouched."
