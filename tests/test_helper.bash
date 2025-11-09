# tests/test_helper.bash
load() { :; }  # bats-compat no-op so "load test_helper" works even w/out bats-support libs

setup() {
  export REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-$0}")/.." && pwd)"
  export TEST_TMP="$BATS_TEST_TMPDIR"
  export STUB_BIN="$REPO_ROOT/tests/stubs"

  # Each test gets a fresh private workspace
  export PRIVATE="$TEST_TMP/private"
  mkdir -p "$PRIVATE"
  cp "$REPO_ROOT/install.sh" "$PRIVATE/"

  # Copy the tooling directory directly to include uncommitted changes
  # Use rsync to exclude .git if available, otherwise use cp and manually exclude
  mkdir -p "$PRIVATE/.tooling"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude='.git' --exclude='tests' "$REPO_ROOT/" "$PRIVATE/.tooling/"
  else
    cp -r "$REPO_ROOT/." "$PRIVATE/.tooling/"
    rm -rf "$PRIVATE/.tooling/.git" "$PRIVATE/.tooling/tests" 2>/dev/null || true
  fi
  
  # Create a minimal git repo in .tooling so install.sh doesn't fail
  (
    cd "$PRIVATE/.tooling"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git config commit.gpgsign false
    git add -A
    git commit -q -m "test snapshot" --no-verify --no-gpg-sign
  )

  # Run installer against this private repo (pin to HEAD to avoid tag assumptions)
  (
    cd "$PRIVATE"
    bash ./install.sh --version HEAD --no-envrc --no-justfile
  )

  # Prepend stubs; then add .scripts so tests can run installed commands
  export PATH="$STUB_BIN:$PRIVATE/.scripts:$PATH"

  # Ensure NOTES_DIR is the private root
  export NOTES_DIR="$PRIVATE"
}

teardown() {
  # Bats removes $BATS_TEST_TMPDIR recursively; nothing to do.
  true
}

run_private() {
  # Simulate bats' run command behavior by capturing status and output
  output="$( ( cd "$PRIVATE" && "$@" ) 2>&1 )"
  status=$?
  export output status
}

