#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Detect notes root:
# - If this tooling repo lives at <notes>/.tooling, NOTES_DIR defaults to <notes>
# - Else fall back to repo parent, or $NOTES_DIR if provided.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLING_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ -z "${NOTES_DIR:-}" ]]; then
  parent="$(cd "$TOOLING_ROOT/.." && pwd)"
  if [[ -d "$parent/journal" || -d "$parent/meetings" || -d "$parent/todo" ]]; then
    NOTES_DIR="$parent"
  else
    NOTES_DIR="$TOOLING_ROOT"
  fi
fi

JOURNAL_DIR="${JOURNAL_DIR:-$NOTES_DIR/journal}"
MEETINGS_DIR="${MEETINGS_DIR:-$NOTES_DIR/meetings}"
TODO_DIR="${TODO_DIR:-$NOTES_DIR/todo}"
INDEX_DIR="${INDEX_DIR:-$NOTES_DIR/.index}"
TEMPLATES_DIR="${TEMPLATES_DIR:-$TOOLING_ROOT/templates}"
EDITOR_CMD="${EDITOR_CMD:-${EDITOR:-vim}}"
LLM_MODEL_EMBED="${LLM_MODEL_EMBED:-text-embedding-3-small}"

# Basic slugify: lowercase, spaces->-, strip non-alnum-dash.
slugify() {
  # Lowercase safely on Bash 3.2 (macOS) and normalize.
  local s="$*"
  if command -v iconv >/dev/null 2>&1; then
    s="$(printf '%s' "$s" | iconv -t ascii//TRANSLIT 2>/dev/null || printf '%s' "$s")"
  fi
  s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
  s="$(printf '%s' "$s" | tr ' ' '-')"
  s="$(printf '%s' "$s" | tr -cd '[:alnum:]-')"
  # collapse multiple dashes
  while [[ "$s" == *--* ]]; do s="$(printf '%s' "$s" | sed 's/--/-/g')"; done
  printf '%s' "$s"
}

ensure_dir() { mkdir -p "$1"; }

render_template() {
  # Usage: render_template <template-path> key=value key=value ...
  local tpl="$1"; shift
  local data sedargs=()
  data="$(cat "$tpl")"
  for kv in "$@"; do
    k="${kv%%=*}"; v="${kv#*=}"
    # escape sed specials in value
    v_esc="$(printf '%s' "$v" | sed -e 's/[&/\]/\\&/g')"
    sedargs+=("-e" "s/{{${k}}}/${v_esc}/g")
  done
  printf '%s' "$data" | sed "${sedargs[@]}"
}

relpath() {
  # relpath <target> <from>
  python3 - "$1" "$2" <<'PY'
import os, sys
print(os.path.relpath(sys.argv[1], sys.argv[2]))
PY
}

open_in_editor() { "$EDITOR_CMD" "$@"; }

# Date pieces from YYYY-MM-DD
y()  { printf '%s' "${1:0:4}"; }
ym() { printf '%s' "${1:0:7}"; }
today() { date +"%Y-%m-%d"; }

