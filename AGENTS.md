# AGENTS.md

## Cursor Cloud specific instructions

This repository is a library of AI subagent definitions, not a runnable service. There is no
package manager, build system, test suite, or linter — do not look for `npm`/`pip`/`make`
targets or CI. The only "application" is three idempotent installer scripts that symlink the
agent definitions into host config directories.

Layout:
- `agents/*.md` — Claude Code agents (Markdown + YAML frontmatter), linked into `~/.claude/agents`.
- `codex-agents/*.toml` — Codex agents (TOML), linked into `$CODEX_HOME/agents` (default `~/.codex/agents`).
- `cursor-agents/*.md` — Cursor agents (Markdown + YAML frontmatter), linked into `~/.cursor/agents`.

Running / "building" the project = running the installers (see `README.md` for the canonical
commands): `./install.sh`, `./install-codex.sh`, `./install-cursor.sh`. The update script
already runs these on startup, so the agents are installed before you begin.

Non-obvious caveats:
- Installers create **symlinks** back into this repo, so editing a source file under
  `agents/`, `codex-agents/`, or `cursor-agents/` takes effect immediately for new host
  sessions — no reinstall needed. Re-run the relevant installer only after **adding, renaming,
  or deleting** an agent file.
- Installers are idempotent and refuse to overwrite a real (non-symlink) file at the
  destination (they print `SKIP`). They also prune only dangling symlinks that point back into
  this repo.
- When adding an agent, add all three native formats together and re-run all three installers
  (see `README.md` "Adding a new agent").
