#!/usr/bin/env bats
load test_helper.bash

@test "weekly-review without LLM produces links, decisions, actions" {
  # seed two files w/ a decision and an open task
  j="$PRIVATE/journal/2025/2025-11/2025-11-03.md"
  m="$PRIVATE/meetings/2025/2025-11/2025-11-04-sync.md"
  mkdir -p "$(dirname "$j")" "$(dirname "$m")"
  cat > "$j" <<'MD'
## Decisions
- Adopt API v2
- [ ] Open task from journal
MD
  cat > "$m" <<'MD'
## Notes
- Discussion
## Decisions
- Ship feature flag
MD
  run_private .scripts/weekly-review --start 2025-11-03 --end 2025-11-09 --no-llm
  out="$PRIVATE/reviews/2025/2025-45.md"
  [ -f "$out" ]
  grep -q "Adopt API v2" "$out"
  grep -q "Ship feature flag" "$out"
  grep -q "Open task from journal" "$out"
}

@test "weekly-review with LLM stub includes a Summary section" {
  run_private .scripts/weekly-review --start 2025-11-03 --end 2025-11-09
  out="$PRIVATE/reviews/2025/2025-45.md"
  grep -q "^## Summary" "$out"
  grep -q "Themes: stubbed" "$out"
}
