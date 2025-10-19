#!/bin/bash

# Integration test for scripts/auto_push.sh.
# Creates a temporary git repository with a local bare remote,
# makes a commit, invokes auto_push.sh, and verifies the remote received it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AUTO_PUSH_SCRIPT="$SCRIPT_DIR/auto_push.sh"

if [ ! -x "$AUTO_PUSH_SCRIPT" ]; then
  echo "Error: auto_push.sh is missing or not executable." >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REMOTE_DIR="$TMP_ROOT/remote.git"
REPO_DIR="$TMP_ROOT/repo"

git init --bare "$REMOTE_DIR" >/dev/null
git init "$REPO_DIR" >/dev/null

pushd "$REPO_DIR" >/dev/null

# Configure git identity for commits inside the temp repo
git config user.name "Auto Push Test"
git config user.email "auto-push-test@example.com"

# Initial commit so branch exists
echo "# Auto Push Test Repo" > README.md
git add README.md
git commit -m "Initial commit" >/dev/null

git remote add origin "$REMOTE_DIR"

# Make a change to be committed by auto_push.sh
echo "Change made at $(date)" >> README.md

# Run the auto push script (should commit & push)
COMMIT_MESSAGE="test: auto push script"
bash "$AUTO_PUSH_SCRIPT" "$COMMIT_MESSAGE"

# Verify the commit landed in the remote
REMOTE_LOG=$(git --git-dir="$REMOTE_DIR" log --pretty=format:%s -1)

if [[ "$REMOTE_LOG" != "$COMMIT_MESSAGE" ]]; then
  echo "Expected latest remote commit message to be '$COMMIT_MESSAGE' but got '$REMOTE_LOG'." >&2
  exit 1
fi

popd >/dev/null

echo "auto_push.sh test passed."
