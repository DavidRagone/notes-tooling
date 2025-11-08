#!/usr/bin/env bash
# install.sh — bootstrap notes-tooling inside a private notes repo
# Usage:
#   ./install.sh [--repo URL] [--version TAG] [--tooling-dir PATH] [--no-justfile] [--no-envrc] [--force]
#
# Defaults:
#   --tooling-dir .tooling
#   --repo        (only used if cloning) e.g., https://github.com/you/notes-tooling
#   --version     (if omitted) read from .tooling-version or keep current checkout
#
# Idempotent: safe to re-run. Will not overwrite an existing Justfile unless --force is set.

set -euo pipefail

### ----- Arg parsing -----
TOOLING_DIR=".tooling"
REPO_URL="${REPO_URL:-}"     # optional env override
PINNED_VERSION="${PINNED_VERSION:-}"  # optional env override
WRITE_JUSTFILE=1
WRITE_ENVRC=1
FORCE=0

usage() {
  sed -n '1,40p' "$0" | sed -n '2,40p'
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tooling-dir) TOOLING_DIR="$2"; shift 2 ;;
    --repo) REPO_URL="$2"; shift 2 ;;
    --version) PINNED_VERSION="$2"; shift 2 ;;
    --no-justfile) WRITE_JUSTFILE=0; shift ;;
    --no-envrc) WRITE_ENVRC=0; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

ROOT="$(pwd)"
NOTES_DIR="$ROOT"

log()  { printf "\033[1;34m[install]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || warn "Missing recommended tool: $1"
}

### ----- Step 1: ensure .tooling exists or clone -----
if [[ ! -d "$TOOLING_DIR" ]]; then
  if [[ -z "${REPO_URL}" ]]; then
    err "No $TOOLING_DIR found and --repo URL not provided. Either clone your public repo into '$TOOLING_DIR' or re-run with --repo URL."
  fi
  log "Cloning tooling from $REPO_URL into $TOOLING_DIR (shallow)…"
  git clone --depth 1 "${PINNED_VERSION:+--branch $PINNED_VERSION}" "$REPO_URL" "$TOOLING_DIR"
else
  log "Found existing $TOOLING_DIR"
fi

### ----- Step 2: honor pinned version -----
VERSION_FILE="$ROOT/.tooling-version"
if [[ -z "$PINNED_VERSION" ]]; then
  if [[ -f "$VERSION_FILE" ]]; then
    PINNED_VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"
  elif [[ -f "$TOOLING_DIR/VERSION" ]]; then
    PINNED_VERSION="$(cat "$TOOLING_DIR/VERSION" | tr -d '[:space:]')"
  else
    PINNED_VERSION=""
  fi
fi

if [[ -n "$PINNED_VERSION" ]]; then
  log "Pinning $TOOLING_DIR to version/tag: $PINNED_VERSION"
  (
    cd "$TOOLING_DIR"
    git fetch --tags --quiet || true
    git checkout -q "$PINNED_VERSION" || err "Failed to checkout $PINNED_VERSION in $TOOLING_DIR"
  )
  echo "$PINNED_VERSION" > "$VERSION_FILE"
else
  log "No version pin provided; leaving $TOOLING_DIR at current revision"
fi

### ----- Step 3: symlink .scripts -> .tooling/bin -----
SCRIPTS_LINK="$ROOT/.scripts"
if [[ -L "$SCRIPTS_LINK" || -d "$SCRIPTS_LINK" || -f "$SCRIPTS_LINK" ]]; then
  if [[ $FORCE -eq 1 ]]; then
    rm -rf "$SCRIPTS_LINK"
  fi
fi
if [[ ! -e "$SCRIPTS_LINK" ]]; then
  ln -s "$TOOLING_DIR/bin" "$SCRIPTS_LINK"
  log "Symlinked .scripts -> $TOOLING_DIR/bin"
else
  log "Existing .scripts present; leaving as-is"
fi

### ----- Step 4: ensure executables -----
if [[ -d "$TOOLING_DIR/bin" ]]; then
  chmod +x "$TOOLING_DIR"/bin/* 2>/dev/null || true
  log "Ensured scripts in $TOOLING_DIR/bin are executable"
else
  err "Missing $TOOLING_DIR/bin; your public repo should include a bin/ directory"
fi

### ----- Step 5: create core directories -----
mkdir -p "$ROOT/journal" "$ROOT/meetings" "$ROOT/todo" "$ROOT/ideas" "$ROOT/reviews" "$ROOT/people" "$ROOT/.index"
log "Ensured core directories exist (journal, meetings, todo, ideas, reviews, people, .index)"

### ----- Step 6: write Justfile (if absent or forced) -----
JUSTFILE_PATH="$ROOT/Justfile"
if [[ $WRITE_JUSTFILE -eq 1 ]]; then
  if [[ -f "$JUSTFILE_PATH" && $FORCE -ne 1 ]]; then
    log "Justfile already exists; skipping (use --force to overwrite)"
  else
    cat > "$JUSTFILE_PATH" <<'JUST'
# Justfile for private notes repo — uses .scripts/ from .tooling/
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

bin := ".scripts"

new:
	@{{bin}}/new-journal

open:
	@{{bin}}/open-journal

meet NAME?:
	@{{bin}}/new-meeting {{NAME | default("")}} --link

idea TITLE?:
	@{{bin}}/new-idea {{TITLE | default("")}}

promote SRC_RANGE TITLE:
	@{{bin}}/promote {{SRC_RANGE}} --title "{{TITLE}}"

agenda:
	@{{bin}}/agenda-to-md

weekly:
	@{{bin}}/weekly-review

weekly-week WEEK:
	@{{bin}}/weekly-review --week {{WEEK}}

weekly-range START END:
	@{{bin}}/weekly-review --start {{START}} --end {{END}}

search QUERY +ARGS='':
	@{{bin}}/search {{QUERY}} {{ARGS}}

todo:
	@{{bin}}/todo-refresh

index:
	@{{bin}}/index

daily:
	@{{bin}}/new-journal --no-open
	@{{bin}}/agenda-to-md
	@{{bin}}/open-journal
JUST
    log "Wrote Justfile"
  fi
else
  log "Skipping Justfile creation (--no-justfile)"
fi

### ----- Step 7: PATH integration -----
if [[ $WRITE_ENVRC -eq 1 ]]; then
  if command -v direnv >/dev/null 2>&1; then
    ENVRC="$ROOT/.envrc"
    if [[ -f "$ENVRC" && $FORCE -ne 1 ]]; then
      log ".envrc exists; leaving as-is (use --force to overwrite)"
    else
      cat > "$ENVRC" <<'ENV'
# direnv: load notes environment
export NOTES_DIR="$PWD"
export PATH="$PWD/.scripts:$PATH"
ENV
      log "Wrote .envrc (run 'direnv allow' once)"
    fi
  else
    warn "direnv not found; add this to your shell rc manually:"
    echo '  export PATH="$PWD/.scripts:$PATH"'
    echo '  export NOTES_DIR="$PWD"'
  fi
else
  log "Skipping PATH setup (--no-envrc)"
fi

### ----- Step 8: dependency hints -----
require_cmd rg
require_cmd awk
require_cmd sed
require_cmd python3
require_cmd gcalcli
require_cmd llm
require_cmd just
require_cmd glow

log "Done. Try: 'just new' or 'just daily'."

