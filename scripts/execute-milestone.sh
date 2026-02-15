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
#   ./scripts/execute-milestone.sh plan/v1/tasks

PLAN_DIR="${1:?Usage: $0 <plan-tasks-dir>}"

if [ ! -d "$PLAN_DIR" ]; then
  echo "Error: Tasks directory not found: $PLAN_DIR" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for TASK_FILE in "${PLAN_DIR}"/*.tasks.md; do
  echo "=== Starting issue: ${TASK_FILE} ==="
  "${SCRIPT_DIR}/execute-issue.sh" "$TASK_FILE"
  echo "=== Completed issue: ${TASK_FILE} ==="
  echo
done

echo "All issues complete."
