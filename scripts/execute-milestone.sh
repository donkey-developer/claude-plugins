#!/usr/bin/env bash
set -euo pipefail

# Run all issues for a milestone in sequence.
# Iterates over task files in numbered order (01-, 02-, etc.) and runs
# the Ralph Wiggum loop for each. The last task file (*-close.tasks.md)
# handles milestone completion — updating specs, cleanup, and closure.
#
# Assumes task files are numbered in dependency order. For parallel
# issues, run their execute-issue.sh loops concurrently instead.
#
# Usage:
#   ./scripts/execute-milestone.sh                 # auto-detects if only one milestone
#   ./scripts/execute-milestone.sh plan/v1/tasks

if [ -n "${1:-}" ]; then
  PLAN_DIR="$1"
else
  # Auto-detect: if exactly one milestone exists under plan/, use it
  MILESTONES=(plan/*/tasks)
  if [ ${#MILESTONES[@]} -eq 1 ] && [ -d "${MILESTONES[0]}" ]; then
    PLAN_DIR="${MILESTONES[0]}"
    echo "Auto-detected milestone: ${PLAN_DIR}"
  elif [ ${#MILESTONES[@]} -eq 0 ] || [ ! -d "${MILESTONES[0]}" ]; then
    echo "Error: No milestones found under plan/" >&2
    exit 1
  else
    echo "Error: Multiple milestones found. Specify one:" >&2
    printf "  %s\n" "${MILESTONES[@]}" >&2
    exit 1
  fi
fi

if [ ! -d "$PLAN_DIR" ]; then
  echo "Error: Tasks directory not found: $PLAN_DIR" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PREV_BRANCH="main"

for TASK_FILE in "${PLAN_DIR}"/*.tasks.md; do
  # Derive branch name from filename: 03-sre-domain.tasks.md → feat/03-sre-domain
  PREFIX=$(basename "$TASK_FILE" .tasks.md)
  BRANCH="feat/${PREFIX}"

  # Skip completed issues
  INCOMPLETE=$(grep -c '^\- \[ \]' "$TASK_FILE" || true)
  if [ "$INCOMPLETE" -eq 0 ]; then
    echo "=== Skipping (complete): ${TASK_FILE} ==="
    # Track branch for next issue's base (if branch exists, content is there;
    # if not, content was merged to main/upstream, PREV_BRANCH stays as-is)
    git rev-parse --verify "$BRANCH" >/dev/null 2>&1 && PREV_BRANCH="$BRANCH"
    continue
  fi

  # Create or checkout branch
  if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    git checkout "$BRANCH"
  else
    echo "Creating branch ${BRANCH} from ${PREV_BRANCH}..."
    git checkout -b "$BRANCH" "$PREV_BRANCH"
  fi

  echo "=== Starting issue: ${TASK_FILE} ==="
  "${SCRIPT_DIR}/execute-issue.sh" "$TASK_FILE" "$PREV_BRANCH"
  echo "=== Completed issue: ${TASK_FILE} ==="
  echo

  PREV_BRANCH="$BRANCH"
done

echo "All issues complete."
