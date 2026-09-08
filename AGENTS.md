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
  print `SKIP`). Symlink installers prune only dangling links that point back into this repo;
  the Codex installer prunes only copies recorded in its management manifest.
- When adding an agent, add all four native formats together and re-run all four installers
  (see `README.md` "Adding a new agent").
- OpenCode `chief` is a **primary** agent (`mode: primary`); the other OpenCode roles are
  subagents. Frontier roles use `openai/gpt-5.6-sol`; local roles use `ollama/devstral:24b`.
