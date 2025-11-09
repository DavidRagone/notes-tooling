#!/usr/bin/env bats
load test_helper.bash

@test "promote extracts a range, creates new note, and inserts link-back" {
  src="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$src")"
  cat > "$src" <<'MD'
Intro
## Notes
Line A
Line B
Line C
Tail
MD
  run_private .scripts/promote "$src:3..5" --title "Extracted Block" --date 2025-11-08 --type note --no-open
  [ "$status" -eq 0 ]
  out="$PRIVATE/notes/2025/2025-11/2025-11-08-extracted-block.md"
  [ -f "$out" ]
  grep -q "Line A" "$out"
  grep -q "Line C" "$out"
  # link-back inserted after line 5
  grep -qF "Promoted to" "$src"
}

