#!/usr/bin/env bash
# Symlinks every agent in ./agents into ~/.claude/agents so Claude Code
# can use them in any project. Idempotent — safe to re-run after adding
# or renaming agents. Edits to files in this repo apply immediately
# (symlinks point back here).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/agents"
DEST_DIR="$HOME/.claude/agents"

mkdir -p "$DEST_DIR"

installed=0
for src in "$SRC_DIR"/*.md; do
  name="$(basename "$src")"
  dest="$DEST_DIR/$name"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "SKIP  $name — a real file already exists at $dest (won't overwrite)"
    continue
  fi
  ln -sfn "$src" "$dest"
  echo "OK    $name -> $dest"
  installed=$((installed + 1))
done

# Remove dangling symlinks left behind by renamed/deleted agents
for link in "$DEST_DIR"/*.md; do
  [[ -L "$link" && ! -e "$link" ]] && { rm "$link"; echo "CLEAN removed dangling $(basename "$link")"; }
done

echo
echo "$installed agent(s) installed. Restart Claude Code sessions to pick up changes to agent lists."
