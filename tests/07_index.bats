#!/usr/bin/env bats
load test_helper.bash

@test "index calls llm embed-multi and creates embeddings DB" {
  run_private .scripts/index
  [ "$status" -eq 0 ]
  [ -f "$PRIVATE/.index/embeddings.db" ]
}

