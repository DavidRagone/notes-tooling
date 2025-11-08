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

  # Local clone of the public repo into .tooling so we avoid network
  git clone --local "$REPO_ROOT" "$PRIVATE/.tooling" >/dev/null 2>&1

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
  ( cd "$PRIVATE" && "$@" )
}

