#!/usr/bin/env bats
load test_helper.bash

@test "new-journal creates the dated journal file idempotently" {
  run_private .scripts/new-journal --date 2025-11-08 --no-open
  [ "$status" -eq 0 ]
  f="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  [ -f "$f" ]

  before="$(wc -c < "$f")"
  run_private .scripts/new-journal --date 2025-11-08 --no-open
  after="$(wc -c < "$f")"
  # no duplicate writes
  [ "$before" -eq "$after" ]
}

@test "new-meeting creates note and --link adds backlink to journal" {
  run_private .scripts/new-meeting "Payroll API Sync" --date 2025-11-08 --link --no-open
  meet="$PRIVATE/meetings/2025/2025-11/2025-11-08-payroll-api-sync.md"
  [ -f "$meet" ]
  jrnl="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  grep -q "Payroll API Sync" "$jrnl"
  grep -q "(../meetings/2025/2025-11/2025-11-08-payroll-api-sync.md)" "$jrnl"
}

