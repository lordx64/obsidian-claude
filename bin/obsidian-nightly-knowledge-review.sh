#!/bin/bash
# Nightly knowledge-review: invoke Claude headless to run the
# obsidian-knowledge-review skill against today's daily journal.
# Designed to run from a launchd LaunchAgent; safe to run manually.
#
# Configurable via env vars (set in the LaunchAgent plist or shell):
#   OBSIDIAN_VAULT  — path to the vault (default: $HOME/vault)
#   CLAUDE_BIN      — claude CLI binary (default: auto-detect)

set -uo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/vault}"
CLAUDE="${CLAUDE_BIN:-$(command -v claude || echo /opt/homebrew/bin/claude)}"
LOG="$HOME/Library/Logs/obsidian-nightly-knowledge-review.log"
SKILL="$HOME/.claude/skills/obsidian-knowledge-review/SKILL.md"
TODAY=$(/bin/date +%F)
DAILY_FILE="$VAULT/05 Daily/$TODAY.md"

echo "[$(date +%FT%T)] starting nightly review for $TODAY" >> "$LOG"

# Sanity checks
[[ -x "$CLAUDE" ]] || { echo "[$(date +%FT%T)] claude binary not found at $CLAUDE" >> "$LOG"; exit 1; }
[[ -f "$SKILL" ]] || { echo "[$(date +%FT%T)] skill file not found at $SKILL" >> "$LOG"; exit 1; }

# Bail if there's no daily journal to review
if [[ ! -f "$DAILY_FILE" ]]; then
    echo "[$(date +%FT%T)] no daily file at $DAILY_FILE — skip" >> "$LOG"
    exit 0
fi

# Bail if the daily journal has no journal blocks
if ! /usr/bin/grep -q '^### Claude session' "$DAILY_FILE"; then
    echo "[$(date +%FT%T)] daily file has no journal sessions — skip" >> "$LOG"
    exit 0
fi

# Run claude headless against the skill. --dangerously-skip-permissions lets it
# Read/Edit/Write inside the vault without interactive prompts (which would
# deadlock a launchd job). The skill itself constrains scope to the vault.
PROMPT="Run the /obsidian-knowledge-review skill for today's date ($TODAY). Read $SKILL, then execute the procedure exactly as specified. Begin."

cd "$VAULT" || { echo "[$(date +%FT%T)] cd to vault failed" >> "$LOG"; exit 1; }

"$CLAUDE" -p "$PROMPT" \
    --dangerously-skip-permissions \
    --output-format text \
    >> "$LOG" 2>&1

EXIT=$?
echo "[$(date +%FT%T)] claude exited with $EXIT" >> "$LOG"
exit $EXIT
