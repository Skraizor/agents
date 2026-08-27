#!/usr/bin/env bash
# Symlinks every OpenCode agent in ./opencode-agents into
# ~/.config/opencode/agents (or $XDG_CONFIG_HOME/opencode/agents).
# OpenCode auto-discovers Markdown agent files there.
# Idempotent — edits to files in this repo apply immediately through symlinks.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/opencode-agents"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DEST_DIR="$CONFIG_HOME/opencode/agents"

mkdir -p "$DEST_DIR"
shopt -s nullglob

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

# Clean only dangling links that used to point into this repository.
for link in "$DEST_DIR"/*.md; do
  if [[ -L "$link" && ! -e "$link" ]]; then
    target="$(readlink "$link")"
    if [[ "$target" == "$SRC_DIR/"* ]]; then
      rm "$link"
      echo "CLEAN removed dangling $(basename "$link")"
    fi
  fi
done

echo
echo "$installed OpenCode agent(s) installed. Start a new OpenCode session to refresh the agent list."
