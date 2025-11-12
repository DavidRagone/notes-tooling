#!/usr/bin/env bats
load test_helper.bash

@test "todo-refresh creates TODO.md with header if it doesn't exist" {
  # Ensure todo dir doesn't exist yet
  [ ! -f "$PRIVATE/todo/TODO.md" ]
  
  # Create a note with a task
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
- [ ] First task
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  
  todo="$PRIVATE/todo/TODO.md"
  [ -f "$todo" ]
  grep -q "# Open Tasks" "$todo"
  grep -q "First task" "$todo"
}

@test "todo-refresh appends new todos instead of overwriting" {
  # Create TODO.md with existing content
  todo="$PRIVATE/todo/TODO.md"
  mkdir -p "$(dirname "$todo")"
  cat > "$todo" <<'MD'
# Open Tasks

- [ ] Existing task 1
- [x] Completed task
- [ ] Existing task 2

Some notes here
MD

  # Add a new task in a journal entry
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
- [ ] New task from journal
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  
  # Verify existing content is preserved
  grep -q "Existing task 1" "$todo"
  grep -q "Completed task" "$todo"
  grep -q "Existing task 2" "$todo"
  grep -q "Some notes here" "$todo"
  
  # Verify new task was appended
  grep -q "New task from journal" "$todo"
}

@test "todo-refresh is idempotent - doesn't create duplicates" {
  # Create a note with a task
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
- [ ] Task to be found
MD

  # Run todo-refresh first time
  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Added 1 new todo"
  
  todo="$PRIVATE/todo/TODO.md"
  first_count=$(grep -c "Task to be found" "$todo")
  [ "$first_count" -eq 1 ]
  
  # Run todo-refresh second time
  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No new todos found"
  
  # Verify no duplicate was created
  second_count=$(grep -c "Task to be found" "$todo")
  [ "$second_count" -eq 1 ]
  
  # Run a third time for good measure
  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  
  third_count=$(grep -c "Task to be found" "$todo")
  [ "$third_count" -eq 1 ]
}

@test "todo-refresh finds multiple new todos and appends them all" {
  todo="$PRIVATE/todo/TODO.md"
  mkdir -p "$(dirname "$todo")"
  cat > "$todo" <<'MD'
# Open Tasks

- [ ] Pre-existing task
MD

  # Create multiple notes with tasks
  jf1="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf1")"
  cat >> "$jf1" <<'MD'
- [ ] Journal task 1
- [ ] Journal task 2
- [x] Completed task (should not appear)
MD

  idea="$PRIVATE/ideas/my-idea.md"
  mkdir -p "$(dirname "$idea")"
  cat >> "$idea" <<'MD'
- [ ] Idea task
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Added 3 new todo"
  
  # Verify all tasks are present
  grep -q "Pre-existing task" "$todo"
  grep -q "Journal task 1" "$todo"
  grep -q "Journal task 2" "$todo"
  grep -q "Idea task" "$todo"
  
  # Verify completed task is not included
  ! grep -q "Completed task (should not appear)" "$todo"
}

@test "todo-refresh preserves manual edits and notes in TODO.md" {
  todo="$PRIVATE/todo/TODO.md"
  mkdir -p "$(dirname "$todo")"
  cat > "$todo" <<'MD'
# Open Tasks

## High Priority
- [ ] Critical bug fix

## Notes
This is my custom section with important information.

- [ ] Another manually added task
MD

  # Add a new task in a note
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
- [ ] Found task
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  
  # Verify all manual content is preserved
  grep -q "## High Priority" "$todo"
  grep -q "Critical bug fix" "$todo"
  grep -q "## Notes" "$todo"
  grep -q "This is my custom section with important information." "$todo"
  grep -q "Another manually added task" "$todo"
  
  # Verify new task was appended
  grep -q "Found task" "$todo"
}

@test "todo-refresh reports correct count of new todos" {
  # First run with no existing file
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
- [ ] Task 1
- [ ] Task 2
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Added 2 new todo"
  
  # Add more tasks
  idea="$PRIVATE/ideas/my-idea.md"
  mkdir -p "$(dirname "$idea")"
  cat >> "$idea" <<'MD'
- [ ] Task 3
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Added 1 new todo"
  
  # Run again with no new tasks
  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No new todos found"
}

@test "todo-refresh handles todos with special characters and formatting" {
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
- [ ] Task with "quotes" and 'apostrophes'
- [ ] Task with $dollar and &ampersand
- [ ] Task with [markdown](link) syntax
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  
  todo="$PRIVATE/todo/TODO.md"
  grep -q 'Task with "quotes" and '"'"'apostrophes'"'"'' "$todo"
  grep -q 'Task with $dollar and &ampersand' "$todo"
  grep -q 'Task with \[markdown\](link) syntax' "$todo"
  
  # Run again to ensure idempotency with special chars
  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No new todos found"
}

@test "todo-refresh excludes empty todos (template placeholders)" {
  # Create a note with both an empty todo template and a real todo
  # This simulates the meeting template which has "- [ ] " as a placeholder
  jf="$PRIVATE/journal/2025/2025-11/2025-11-08.md"
  mkdir -p "$(dirname "$jf")"
  cat >> "$jf" <<'MD'
## Actions

- [ ] 

- [ ] Real task with actual text

Some other content here
MD

  run_private .scripts/todo-refresh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Added 1 new todo"
  
  todo="$PRIVATE/todo/TODO.md"
  # Verify the real task is included
  grep -q "Real task with actual text" "$todo"
  
  # Verify empty todos are NOT included
  # We check that there's no todo line that would result from an empty todo
  # An empty todo would create a line like "- [ ]   _(in [filename](path#Lline))_"
  # But since we're excluding them, we should not see a todo entry without actual task text
  # Let's verify by checking the count - there should be exactly 1 todo
  todo_count=$(grep -c "Real task with actual text" "$todo")
  [ "$todo_count" -eq 1 ]
  
  # Also verify that if we search for todos from this file, we only find the real one
  # The empty todo should not have created an entry
  file_todos=$(grep -c "2025-11-08.md" "$todo" || true)
  [ "$file_todos" -eq 1 ]
}

