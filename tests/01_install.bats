#!/usr/bin/env bats
load test_helper.bash

@test "install.sh creates core folders and .scripts symlink" {
  [ -d "$PRIVATE/journal" ]
  [ -d "$PRIVATE/meetings" ]
  [ -d "$PRIVATE/todo" ]
  [ -d "$PRIVATE/ideas" ]
  [ -L "$PRIVATE/.scripts" ]
  [ -x "$PRIVATE/.scripts/new-journal" ]
}

