#!/usr/bin/env bats
load test_helper.bash

@test "new-idea creates flat idea note with front matter" {
  run_private .scripts/new-idea "Faster onboarding checklist" --no-open --tags "onboarding,ops" --project "gep"
  [ "$status" -eq 0 ]
  f="$PRIVATE/ideas/faster-onboarding-checklist.md"
  [ -f "$f" ]
  grep -q "type: idea" "$f"
  grep -q "project: gep" "$f"
  grep -q "tags:" "$f"
}

@test "todo-refresh aggregates unchecked boxes" {
  # seed a task
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
- [ ] Draft onboarding rubric
- [x] Done item
MD
  run_private .scripts/todo-refresh
  todo="$PRIVATE/todo/TODO.md"
  [ -f "$todo" ]
  grep -q "Draft onboarding rubric" "$todo"
  ! grep -q "Done item" "$todo"
}

@test "search finds text across notes" {
  echo "needle-xyz" >> "$PRIVATE/ideas/faster-onboarding-checklist.md"
  run_private .scripts/search 'needle-xyz'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "faster-onboarding-checklist.md"
}

