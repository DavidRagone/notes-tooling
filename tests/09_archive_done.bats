#!/usr/bin/env bats
load test_helper.bash

@test "archive-done moves completed todos to done.md with date header" {
  # Create todo files with completed and incomplete todos
  todo1="$PRIVATE/todo/task1.md"
  mkdir -p "$(dirname "$todo1")"
  cat > "$todo1" <<'MD'
# Task List 1
- [ ] Incomplete task 1
- [x] Completed task 1
- [ ] Incomplete task 2
- [x] Completed task 2
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  
  # Check done.md was created with correct content
  done_file="$PRIVATE/todo/done.md"
  [ -f "$done_file" ]
  grep -q "# Completed Tasks" "$done_file"
  grep -q "^### $(date +%Y-%m-%d)$" "$done_file"
  grep -q "Completed task 1" "$done_file"
  grep -q "Completed task 2" "$done_file"
  
  # Check completed todos were removed from original file
  ! grep -q "Completed task 1" "$todo1"
  ! grep -q "Completed task 2" "$todo1"
  
  # Check incomplete todos remain
  grep -q "Incomplete task 1" "$todo1"
  grep -q "Incomplete task 2" "$todo1"
}

@test "archive-done processes multiple files in todo directory" {
  todo1="$PRIVATE/todo/task1.md"
  todo2="$PRIVATE/todo/task2.md"
  mkdir -p "$(dirname "$todo1")"
  
  cat > "$todo1" <<'MD'
- [x] Task from file 1
- [ ] Incomplete from file 1
MD

  cat > "$todo2" <<'MD'
- [x] Task from file 2
- [ ] Incomplete from file 2
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  
  done_file="$PRIVATE/todo/done.md"
  grep -q "Task from file 1" "$done_file"
  grep -q "Task from file 2" "$done_file"
  
  # Check original files were updated
  ! grep -q "Task from file 1" "$todo1"
  ! grep -q "Task from file 2" "$todo2"
  grep -q "Incomplete from file 1" "$todo1"
  grep -q "Incomplete from file 2" "$todo2"
}

@test "archive-done excludes done.md from processing" {
  # Create done.md with some content
  done_file="$PRIVATE/todo/done.md"
  mkdir -p "$(dirname "$done_file")"
  cat > "$done_file" <<'MD'
# Completed Tasks

### 2025-01-01
- [x] Old completed task
MD

  # Create another file with completed todos
  todo1="$PRIVATE/todo/task1.md"
  cat > "$todo1" <<'MD'
- [x] New completed task
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  
  # Check old content in done.md is preserved
  grep -q "Old completed task" "$done_file"
  
  # Check new task was added
  grep -q "New completed task" "$done_file"
  
  # Check done.md itself wasn't processed (old completed task should still be there)
  grep -q "Old completed task" "$done_file"
}

@test "archive-done handles files that become empty after removing todos" {
  todo1="$PRIVATE/todo/task1.md"
  mkdir -p "$(dirname "$todo1")"
  cat > "$todo1" <<'MD'
- [x] Only completed task
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  
  # File should still exist but be empty or have minimal content
  [ -f "$todo1" ]
  
  # Check completed task was moved
  done_file="$PRIVATE/todo/done.md"
  grep -q "Only completed task" "$done_file"
  ! grep -q "Only completed task" "$todo1"
}

@test "archive-done reports no completed todos when none exist" {
  todo1="$PRIVATE/todo/task1.md"
  mkdir -p "$(dirname "$todo1")"
  cat > "$todo1" <<'MD'
- [ ] Only incomplete tasks
- [ ] Another incomplete task
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No completed todos found"
  
  # done.md should not be created
  [ ! -f "$PRIVATE/todo/done.md" ]
  
  # Original file should be unchanged
  grep -q "Only incomplete tasks" "$todo1"
  grep -q "Another incomplete task" "$todo1"
}

@test "archive-done appends to existing done.md with new date header" {
  # Create existing done.md
  done_file="$PRIVATE/todo/done.md"
  mkdir -p "$(dirname "$done_file")"
  cat > "$done_file" <<'MD'
# Completed Tasks

### 2025-01-01
- [x] Old task
MD

  # Create new completed todos
  todo1="$PRIVATE/todo/task1.md"
  cat > "$todo1" <<'MD'
- [x] New task
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  
  # Check old content is preserved
  grep -q "Old task" "$done_file"
  
  # Check new date header and task were added
  grep -q "^### $(date +%Y-%m-%d)$" "$done_file"
  grep -q "New task" "$done_file"
  
  # Verify the structure: old date header should come before new one
  old_line=$(grep -n "### 2025-01-01" "$done_file" | cut -d: -f1)
  new_line=$(grep -n "^### $(date +%Y-%m-%d)$" "$done_file" | cut -d: -f1)
  [ "$old_line" -lt "$new_line" ]
}

@test "archive-done handles multiple runs correctly" {
  todo1="$PRIVATE/todo/task1.md"
  mkdir -p "$(dirname "$todo1")"
  cat > "$todo1" <<'MD'
- [x] First completed task
MD

  # First run
  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Archived 1 completed todo"
  
  # Add more completed tasks
  cat > "$todo1" <<'MD'
- [x] Second completed task
- [ ] Incomplete task
MD

  # Second run
  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Archived 1 completed todo"
  
  done_file="$PRIVATE/todo/done.md"
  # Both tasks should be in done.md
  grep -q "First completed task" "$done_file"
  grep -q "Second completed task" "$done_file"
  
  # Incomplete task should remain
  grep -q "Incomplete task" "$todo1"
}

@test "archive-done preserves file structure and other content" {
  todo1="$PRIVATE/todo/task1.md"
  mkdir -p "$(dirname "$todo1")"
  cat > "$todo1" <<'MD'
# My Task List

## Section 1
- [ ] Incomplete 1
- [x] Completed 1
- [ ] Incomplete 2

## Section 2
- [x] Completed 2
- [ ] Incomplete 3

Some notes here
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  
  # Check structure is preserved
  grep -q "# My Task List" "$todo1"
  grep -q "## Section 1" "$todo1"
  grep -q "## Section 2" "$todo1"
  grep -q "Some notes here" "$todo1"
  
  # Check incomplete tasks remain
  grep -q "Incomplete 1" "$todo1"
  grep -q "Incomplete 2" "$todo1"
  grep -q "Incomplete 3" "$todo1"
  
  # Check completed tasks were removed
  ! grep -q "Completed 1" "$todo1"
  ! grep -q "Completed 2" "$todo1"
  
  # Check completed tasks are in done.md
  done_file="$PRIVATE/todo/done.md"
  grep -q "Completed 1" "$done_file"
  grep -q "Completed 2" "$done_file"
}

@test "archive-done reports correct count and files modified" {
  todo1="$PRIVATE/todo/task1.md"
  todo2="$PRIVATE/todo/task2.md"
  mkdir -p "$(dirname "$todo1")"
  
  cat > "$todo1" <<'MD'
- [x] Task 1
- [x] Task 2
MD

  cat > "$todo2" <<'MD'
- [x] Task 3
MD

  run_private .scripts/archive-done
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Archived 3 completed todos"
  echo "$output" | grep -q "Updated files:"
}

