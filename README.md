# obsidian-claude

> 🧠 **Turn your Claude Code sessions into a self-extending Obsidian knowledge base.**
> Auto-commit, daily journal, nightly concept extraction — all running on a launchd timer.

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](#requirements)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-blue.svg)](#requirements)
[![Status](https://img.shields.io/badge/status-alpha-orange.svg)](#)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-purple.svg)](https://docs.claude.com/en/docs/claude-code/skills)

**Tags:** `#obsidian` · `#claude-code` · `#productivity` · `#pkm` · `#knowledge-graph` · `#launchd` · `#macos` · `#second-brain` · `#para` · `#journaling`

---

## ✨ What it does

| Layer | Cadence | Purpose |
| --- | --- | --- |
| 🌀 **Auto-commit** | hourly | Local git history of every vault change. Roll back any note to any point. |
| 📓 **Journal skill** | on demand (in any Claude Code session) | Appends a structured `### Claude session HH:MM` block to today's daily note — Worked on / Bugs / Solutions / Open questions / Decisions. |
| 🌱 **Knowledge-review skill** | manual or nightly @ 22:00 | Reads today's journal, extracts technical concepts, expands or creates notes under `03 Resources/`, and writes a "what to read tonight" reading list. |

Wake up to a vault that has grown overnight with concept notes for everything you touched yesterday, plus a curated reading list.

---

## 📐 Architecture

```
~/vault/                                        ← your Obsidian vault (git repo)
  ├── 05 Daily/YYYY-MM-DD.md                    ← journal target
  └── 03 Resources/AI/<Concept>.md              ← knowledge graph

~/.local/bin/                                   ← installed by ./install.sh
  ├── obsidian-vault-autocommit.sh              ← hourly: git add . && commit
  └── obsidian-nightly-knowledge-review.sh      ← 22:00: claude -p → skill

~/.claude/skills/                               ← installed by ./install.sh
  ├── obsidian-journal/SKILL.md                 ← /obsidian-journal trigger
  └── obsidian-knowledge-review/SKILL.md        ← /obsidian-knowledge-review trigger

~/Library/LaunchAgents/                         ← installed by ./install.sh
  ├── <ns>.obsidian-vault-autocommit.plist
  └── <ns>.obsidian-nightly-knowledge-review.plist
```

---

## 🚀 Quick start

### Requirements
- 🍎 **macOS** (uses `launchd` for scheduling — Linux/Windows port welcome)
- 🤖 **[Claude Code](https://docs.claude.com/en/docs/claude-code/quickstart)** installed and authenticated
- 📓 **An Obsidian vault** initialized as a git repo (see [Setup vault](#-setup-vault) below)
- 🔧 **bash** + **git** + **sed** (all stock on macOS)

### Install

```bash
git clone https://example.invalid/obsidian-claude.git
cd obsidian-claude
./install.sh
```

The installer asks three questions:

| Prompt | Default | What it controls |
| --- | --- | --- |
| Vault path | `~/vault` | Where your Obsidian vault lives |
| LaunchAgent label namespace | `com.localuser` | Prefix for plist labels (e.g. `com.yourname.obsidian-*`) |
| Nightly review hour | `22` (10pm) | When the knowledge-review cron fires |

Or run it non-interactively:

```bash
OBSIDIAN_VAULT="$HOME/vault" \
LABEL_NS="com.yourname" \
NIGHTLY_HOUR=22 \
./install.sh
```

### Uninstall

```bash
LABEL_NS=com.yourname ./uninstall.sh
```

Vault and git history are left untouched.

---

## 🧪 Verify it works

```bash
# Trigger the hourly auto-commit immediately
launchctl kickstart -k gui/$(id -u)/com.yourname.obsidian-vault-autocommit

# Trigger the nightly knowledge review immediately
launchctl kickstart -k gui/$(id -u)/com.yourname.obsidian-nightly-knowledge-review

# Watch the logs
tail -f ~/Library/Logs/obsidian-vault-autocommit.log
tail -f ~/Library/Logs/obsidian-nightly-knowledge-review.log
```

In any Claude Code session, try:
- `/obsidian-journal` → logs the current session
- `/obsidian-knowledge-review` → extracts concepts from today's journal
- "log this session" / "review today" → trigger via natural language

---

## 📓 Setup vault *(if you don't already have one)*

The skills assume a [PARA-style](https://fortelabs.com/blog/para/) vault. Minimal version:

```bash
mkdir -p ~/vault/{00\ Inbox,01\ Projects,02\ Areas,03\ Resources/AI,04\ Archive,05\ Daily,06\ Templates,07\ Maps}
cd ~/vault
git init
echo ".obsidian/workspace*" > .gitignore
git add . && git commit -m "init vault"
```

Open `~/vault` in Obsidian (`Open folder as vault`).

The skills will:
- Auto-create today's daily note from `06 Templates/Daily Template.md` if missing
- Drop concept notes into `03 Resources/AI/`
- Update `07 Maps/AI MOC.md` as the knowledge graph grows

---

## ⚙️ Configuration

All knobs are env vars consumed by the bin scripts and plists. Override per-install via the install prompts, or post-install by editing the plists in `~/Library/LaunchAgents/`.

| Env var | Default | Used by |
| --- | --- | --- |
| `OBSIDIAN_VAULT` | `$HOME/vault` | Both scripts |
| `GIT_BIN` | `/usr/bin/git` | Auto-commit script |
| `CLAUDE_BIN` | auto-detected | Nightly review script |

To **change the nightly hour** after install, edit the `<Hour>` integer in `~/Library/LaunchAgents/*.obsidian-nightly-knowledge-review.plist` then reload:

```bash
launchctl unload ~/Library/LaunchAgents/com.yourname.obsidian-nightly-knowledge-review.plist
launchctl load -w ~/Library/LaunchAgents/com.yourname.obsidian-nightly-knowledge-review.plist
```

---

## 🎨 Customize the skills

The skills are plain markdown at `~/.claude/skills/obsidian-*/SKILL.md`. Edit them to change:
- 📝 Journal entry sections (Worked on / Bugs / etc.)
- 🏷️ How concepts are categorized
- 🔍 Whether to run web searches (`WebSearch`) for fresh research
- 📊 The phone-readable formatting bar
- 🌐 What gets surfaced as "tonight's reading"

Skills are read by Claude on every invocation — no restart needed.

---

## 🛡️ Privacy & security

- 🔒 **Nothing leaves your machine** by default. Auto-commit pushes nowhere; the nightly review runs locally via `claude -p`.
- 🔑 No API keys in this repo. Claude auth lives in `~/.claude/` (managed by Claude Code itself).
- 🧹 The installer parameterizes `__HOME__`, `__VAULT__`, `__LABEL_NS__` so nothing identifiable lands in the plists.
- ⚠️ The nightly script uses `--dangerously-skip-permissions` because launchd cron can't prompt for tool approvals. The skill's procedure is the scope guardrail — review it before installing.

---

## 🛠️ Troubleshooting

<details>
<summary><strong>📂 "vault not found" in the auto-commit log</strong></summary>

The `OBSIDIAN_VAULT` env var in the plist doesn't match where your vault is. Edit `~/Library/LaunchAgents/*.obsidian-vault-autocommit.plist`, fix the `<string>` under `OBSIDIAN_VAULT`, reload with `launchctl`.
</details>

<details>
<summary><strong>🔒 "Operation not permitted" from launchd</strong></summary>

macOS TCC blocks background processes from `~/Documents/`, `~/Desktop/`, `~/Downloads/`. Move the vault to `~/vault` or any other top-level home dir, update `OBSIDIAN_VAULT` accordingly.
</details>

<details>
<summary><strong>🤖 Nightly job runs but no concepts extracted</strong></summary>

The skill bails when today's daily note has no `### Claude session` blocks. Either:
- Run `/obsidian-journal` in a Claude Code session first, or
- Manually add a session block to the daily note
</details>

<details>
<summary><strong>🔄 Skill not showing up in Claude Code</strong></summary>

Claude Code loads skills at session start. Quit (`/exit`) and re-open Claude Code after install.
</details>

---

## 🗺️ Roadmap

- [ ] 🐧 Linux port (replace launchd with systemd-user / cron)
- [ ] 📅 Weekly rollup skill (`/obsidian-weekly-review`) — Sunday 23:00
- [ ] 🌐 Optional web-search integration for fresh research citations
- [ ] 📦 Logseq backend (currently Obsidian-only)
- [ ] 🪝 Optional `SessionEnd` hook for fully-automatic journaling (no manual trigger)
- [ ] 🧬 `--dry-run` mode for the installer

---

## 🤝 Contributing

PRs welcome. Keep these principles:
- 🪶 **Zero install deps** beyond what ships with macOS + Claude Code
- 🧱 **Source files stay parameterized** — no hardcoded `/Users/<name>/` or labels
- 🔒 **Never commit anything user-identifiable**
- ✅ **Test install + uninstall round-trip** before merging

---

## 📜 License

[MIT](LICENSE) © 2026 obsidian-claude contributors

---

<sub>Built with [Claude Code](https://docs.claude.com/en/docs/claude-code/) · Designed for [Obsidian](https://obsidian.md) · Powered by [launchd](https://www.launchd.info)</sub>
