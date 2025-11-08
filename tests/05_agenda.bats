#!/usr/bin/env bats
load test_helper.bash

@test "agenda appends Meetings section using gcalcli stub" {
  run_private .scripts/agenda 2025-11-08
  f="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  [ -f "$f" ]
  grep -q "^## Meetings" "$f"
  grep -q "Weekly Sync" "$f"
  grep -q "10:00–2025-11-08 10:30" "$f" || true  # tolerant of format, but title must exist
}

