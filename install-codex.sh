#!/usr/bin/env bash
# Symlinks every Codex agent in ./codex-agents into $CODEX_HOME/agents
# (default: ~/.codex/agents). Codex auto-discovers TOML role files there.
# Idempotent — edits to files in this repo apply immediately through symlinks.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/codex-agents"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST_DIR="$CODEX_DIR/agents"
CONFIG_FILE="$CODEX_DIR/config.toml"

mkdir -p "$DEST_DIR"
shopt -s nullglob

installed=0
for src in "$SRC_DIR"/*.toml; do
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
for link in "$DEST_DIR"/*.toml; do
  if [[ -L "$link" && ! -e "$link" ]]; then
    target="$(readlink "$link")"
    if [[ "$target" == "$SRC_DIR/"* ]]; then
      rm "$link"
      echo "CLEAN removed dangling $(basename "$link")"
    fi
  fi
done

echo
echo "$installed Codex agent(s) installed. Start a new Codex session to refresh the agent list."

# The chief spawns specialists, so it needs one level of nested subagents.
max_depth=""
if [[ -f "$CONFIG_FILE" ]]; then
  max_depth="$(awk '
    /^[[:space:]]*\[agents\][[:space:]]*(#.*)?$/ { in_agents = 1; next }
    /^[[:space:]]*\[/ { in_agents = 0 }
    in_agents && /^[[:space:]]*max_depth[[:space:]]*=/ {
      line = $0
      sub(/#.*/, "", line)
      sub(/.*=/, "", line)
      gsub(/[[:space:]]/, "", line)
      print line
      exit
    }
  ' "$CONFIG_FILE")"
fi

if [[ ! "$max_depth" =~ ^[0-9]+$ || "$max_depth" -lt 2 ]]; then
  echo
  echo "NOTE  chief needs nested agents. Add this to $CONFIG_FILE if it is not already configured:"
  echo "      [agents]"
  echo "      max_depth = 2"
fi
