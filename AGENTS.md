# AGENTS.md

## Cursor Cloud specific instructions

This repository is a library of AI subagent definitions, not a runnable service. There is no
package manager, build system, test suite, or linter — do not look for `npm`/`pip`/`make`
targets or CI. The only "application" is four idempotent installer scripts that install the
agent definitions into host config directories.

Layout:
- `agents/*.md` — Claude Code agents (Markdown + YAML frontmatter), linked into `~/.claude/agents`.
- `codex-agents/*.toml` — Codex agents (TOML), copied into `$CODEX_HOME/agents` (default `~/.codex/agents`).
- `cursor-agents/*.md` — Cursor agents (Markdown + YAML frontmatter), linked into `~/.cursor/agents`.
- `opencode-agents/*.md` — OpenCode agents (Markdown + YAML frontmatter), linked into
  `~/.config/opencode/agents` (or `$XDG_CONFIG_HOME/opencode/agents`).

Running / "building" the project = running the installers (see `README.md` for the canonical
commands): `./install.sh`, `./install-codex.sh`, `./install-cursor.sh`, `./install-opencode.sh`.
The update script already runs these on startup, so the agents are installed before you begin.

Non-obvious caveats:
- The Claude Code, Cursor, and OpenCode installers create **symlinks** back into this repo, so
  editing an existing source file takes effect immediately for new host sessions. Re-run the
  relevant installer after **adding, renaming, or deleting** an agent file.
- The Codex installer creates managed **copies**, because Codex 0.149.0 does not discover
  symlinked agent files. Re-run `./install-codex.sh` after every Codex agent edit as well as
  after adding, renaming, or deleting one. It migrates this repository's old Codex symlinks.
- Installers are idempotent and refuse to overwrite unrelated files at the destination (they
  print `SKIP`) by default. Codex supports `--overwrite` to replace conflicting agent files
  or symlinks and adopt the copies into its manifest; directories are always skipped.
  Symlink installers prune only dangling links that point back into this repo;
  the Codex installer prunes only copies recorded in its management manifest.
- When adding an agent, add all four native formats together and re-run all four installers
  (see `README.md` "Adding a new agent").
- OpenCode `chief` is a **primary** agent (`mode: primary`); the other OpenCode roles are
  subagents. Its chief and routine reviewer use `openai/gpt-5.6-sol`, its escalation reviewer
  uses `openai/gpt-6-astra`, and local workers use `ollama/qwen3-coder:30b`.
- OpenCode 1.18.23 ignores the V2 `permissions` array. Keep its V1 `permission` mirror in sync
  with V2 rules until the installed host is upgraded; validate effective rules with `opencode agent list`.
- Preserve existing uncommitted changes when editing definitions, especially changes made in
  another session. Keep review routing and review-packet instructions consistent across hosts.

Host-specific routing:
- Claude Code uses Sonnet for chief/routine review and Opus for escalation. Start the chief
  with `claude --agent chief` for main-session orchestration; nested dispatch needs host support.
- Cursor inherits its session model; escalation is an independent review, not a promised model upgrade.
- Keep shared review gates consistent, but use only each host's available role names and model syntax.
