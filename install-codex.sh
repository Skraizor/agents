#!/usr/bin/env bash
# Copies every Codex agent in ./codex-agents into $CODEX_HOME/agents
# (default: ~/.codex/agents). Codex 0.149.0 does not discover symlinked agents.
# Idempotent — re-run after editing, adding, renaming, or deleting an agent.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/codex-agents"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST_DIR="$CODEX_DIR/agents"
MANIFEST="$DEST_DIR/.development-agents-managed"

mkdir -p "$DEST_DIR"
shopt -s nullglob

next_manifest="$(mktemp "$DEST_DIR/.development-agents-managed.XXXXXX")"
trap 'rm -f "$next_manifest"' EXIT

is_managed() {
  [[ -f "$MANIFEST" ]] && grep -Fqx -- "$1" "$MANIFEST"
}

installed=0
skipped=0
for src in "$SRC_DIR"/*.toml; do
  name="$(basename "$src")"
  dest="$DEST_DIR/$name"

  if [[ -L "$dest" ]]; then
    target="$(readlink "$dest")"
    if [[ "$target" != "$SRC_DIR/"* ]]; then
      echo "SKIP  $name — an unrelated symlink already exists at $dest"
      skipped=$((skipped + 1))
      continue
    fi
  elif [[ -e "$dest" ]] && ! is_managed "$name"; then
    echo "SKIP  $name — a real file already exists at $dest (won't overwrite)"
    skipped=$((skipped + 1))
    continue
  fi

  temp_copy="$(mktemp "$DEST_DIR/.$name.XXXXXX")"
  cp "$src" "$temp_copy"
  chmod 0644 "$temp_copy"
  mv -f "$temp_copy" "$dest"
  printf '%s\n' "$name" >> "$next_manifest"
  echo "OK    $name => $dest"
  installed=$((installed + 1))
done

# Clean up dangling symlinks left by the older symlink-based installer.
for link in "$DEST_DIR"/*.toml; do
  if [[ -L "$link" && ! -e "$link" ]]; then
    target="$(readlink "$link")"
    if [[ "$target" == "$SRC_DIR/"* ]]; then
      rm "$link"
      echo "CLEAN removed dangling $(basename "$link")"
    fi
  fi
done

# Remove copied agents that this installer previously managed but whose source
# file has since been renamed or deleted.
if [[ -f "$MANIFEST" ]]; then
  while IFS= read -r name; do
    [[ "$name" == *.toml && "$name" != */* ]] || continue
    if [[ ! -e "$SRC_DIR/$name" ]]; then
      dest="$DEST_DIR/$name"
      if [[ -f "$dest" && ! -L "$dest" ]]; then
        rm "$dest"
        echo "CLEAN removed $name"
      fi
    fi
  done < "$MANIFEST"
fi

mv -f "$next_manifest" "$MANIFEST"
trap - EXIT

echo
echo "$installed Codex agent(s) copied, $skipped skipped. Start a new Codex session to refresh the agent list."
