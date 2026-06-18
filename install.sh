#!/bin/bash
# obsidian-claude installer.
# Usage: ./install.sh           # interactive
#        OBSIDIAN_VAULT=… LABEL_NS=… NIGHTLY_HOUR=… ./install.sh  # non-interactive

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Config ────────────────────────────────────────────────────────────────
DEFAULT_VAULT="$HOME/vault"
DEFAULT_LABEL_NS="com.localuser"
DEFAULT_NIGHTLY_HOUR=22

VAULT_PATH="${OBSIDIAN_VAULT:-}"
LABEL_NS="${LABEL_NS:-}"
NIGHTLY_HOUR="${NIGHTLY_HOUR:-}"

if [[ -t 0 ]]; then
    [[ -z "$VAULT_PATH"    ]] && { read -rp "Vault path [$DEFAULT_VAULT]: " VAULT_PATH;       VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT}"; }
    [[ -z "$LABEL_NS"      ]] && { read -rp "LaunchAgent label namespace [$DEFAULT_LABEL_NS]: " LABEL_NS; LABEL_NS="${LABEL_NS:-$DEFAULT_LABEL_NS}"; }
    [[ -z "$NIGHTLY_HOUR"  ]] && { read -rp "Nightly review hour 0-23 [$DEFAULT_NIGHTLY_HOUR]: " NIGHTLY_HOUR; NIGHTLY_HOUR="${NIGHTLY_HOUR:-$DEFAULT_NIGHTLY_HOUR}"; }
else
    VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT}"
    LABEL_NS="${LABEL_NS:-$DEFAULT_LABEL_NS}"
    NIGHTLY_HOUR="${NIGHTLY_HOUR:-$DEFAULT_NIGHTLY_HOUR}"
fi

# ── Sanity ────────────────────────────────────────────────────────────────
if [[ ! -d "$VAULT_PATH" ]]; then
    echo "⚠️  Vault directory does not exist: $VAULT_PATH"
    echo "    Create it and re-run, or run: git init \"$VAULT_PATH\""
    [[ -t 0 ]] && { read -rp "Continue anyway? [y/N] " ok; [[ "$ok" =~ ^[Yy] ]] || exit 1; }
fi

if ! command -v claude >/dev/null 2>&1; then
    echo "⚠️  'claude' CLI not found on PATH. Install Claude Code first:"
    echo "    https://docs.claude.com/en/docs/claude-code/quickstart"
    [[ -t 0 ]] && { read -rp "Continue anyway? [y/N] " ok; [[ "$ok" =~ ^[Yy] ]] || exit 1; }
fi

echo
echo "Installing obsidian-claude:"
echo "  Vault:                 $VAULT_PATH"
echo "  LaunchAgent namespace: $LABEL_NS"
echo "  Nightly review hour:   ${NIGHTLY_HOUR}:00"
echo

# ── Targets ───────────────────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.claude/skills/obsidian-journal"
mkdir -p "$HOME/.claude/skills/obsidian-knowledge-review"
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$HOME/Library/Logs"

# ── Bin scripts (env-var driven; copy as-is) ──────────────────────────────
install -m 0755 "$SCRIPT_DIR/bin/obsidian-vault-autocommit.sh"           "$HOME/.local/bin/"
install -m 0755 "$SCRIPT_DIR/bin/obsidian-nightly-knowledge-review.sh"   "$HOME/.local/bin/"
echo "✓ scripts → ~/.local/bin/"

# ── Skills (substitute __VAULT__) ─────────────────────────────────────────
sed "s|__VAULT__|$VAULT_PATH|g" \
    "$SCRIPT_DIR/skills/obsidian-journal/SKILL.md.template" \
    > "$HOME/.claude/skills/obsidian-journal/SKILL.md"
sed "s|__VAULT__|$VAULT_PATH|g" \
    "$SCRIPT_DIR/skills/obsidian-knowledge-review/SKILL.md.template" \
    > "$HOME/.claude/skills/obsidian-knowledge-review/SKILL.md"
echo "✓ skills  → ~/.claude/skills/"

# ── LaunchAgents (substitute __HOME__, __VAULT__, __LABEL_NS__, __NIGHTLY_HOUR__) ──
for tpl in "$SCRIPT_DIR/launchagents"/*.plist.template; do
    base=$(basename "$tpl" .plist.template)
    target="$HOME/Library/LaunchAgents/${LABEL_NS}.${base}.plist"
    sed -e "s|__HOME__|$HOME|g" \
        -e "s|__LABEL_NS__|$LABEL_NS|g" \
        -e "s|__VAULT__|$VAULT_PATH|g" \
        -e "s|__NIGHTLY_HOUR__|$NIGHTLY_HOUR|g" \
        "$tpl" > "$target"
done
echo "✓ agents  → ~/Library/LaunchAgents/${LABEL_NS}.obsidian-*.plist"

# ── Load LaunchAgents (unload first in case of upgrade) ───────────────────
for plist in "$HOME/Library/LaunchAgents/${LABEL_NS}.obsidian-vault-autocommit.plist" \
             "$HOME/Library/LaunchAgents/${LABEL_NS}.obsidian-nightly-knowledge-review.plist"; do
    launchctl unload "$plist" 2>/dev/null || true
    launchctl load -w "$plist"
done
echo "✓ launchd loaded"

cat <<EOF

✅ obsidian-claude installed.

Running now:
  ⏰ Hourly        ${LABEL_NS}.obsidian-vault-autocommit
  🌙 ${NIGHTLY_HOUR}:00 daily  ${LABEL_NS}.obsidian-nightly-knowledge-review

In any Claude Code session you can now:
  • /obsidian-journal             — log the current session to today's daily
  • /obsidian-knowledge-review    — extract concepts from today's journal

Logs:
  tail -f ~/Library/Logs/obsidian-vault-autocommit.log
  tail -f ~/Library/Logs/obsidian-nightly-knowledge-review.log

Force-run the review now:
  launchctl kickstart -k gui/\$(id -u)/${LABEL_NS}.obsidian-nightly-knowledge-review

Uninstall:
  LABEL_NS=$LABEL_NS ./uninstall.sh
EOF
