#!/bin/bash

# Automatically stages, commits, and pushes the current branch.
# Usage: ./scripts/auto_push.sh "commit message"

set -euo pipefail

commit_message=${1:-"chore: automatic update"}

# Ensure we are inside a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: This script must be run inside a Git repository." >&2
  exit 1
fi

# Determine the current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

if [ -z "$current_branch" ] || [ "$current_branch" = "HEAD" ]; then
  echo "Error: Unable to determine the current branch. Are you in a detached HEAD state?" >&2
  exit 1
fi

echo "Auto-pushing changes on branch '$current_branch'..."

git status --short

git add -A

if git diff --cached --quiet; then
  echo "No staged changes to commit. Exiting."
  exit 0
fi

git commit -m "$commit_message"
git push origin "$current_branch"

echo "Changes pushed to origin/$current_branch."
