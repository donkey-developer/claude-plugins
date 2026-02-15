#!/usr/bin/env bash
set -euo pipefail

# Run all tasks for a single issue (one task file) using the Ralph Wiggum loop.
# Each iteration invokes a stateless agent that completes one task and stops.
# The loop exits when the agent signals NO_MORE_TASKS_TO_PROCESS (all tasks done).
#
# Usage:
#   ./scripts/execute-issue.sh plan/v1/tasks/01-scaffolding.tasks.md

TASK_FILE="${1:?Usage: $0 <task-file>}"

if [ ! -f "$TASK_FILE" ]; then
  echo "Error: Task file not found: $TASK_FILE" >&2
  exit 1
fi

echo "Starting issue: ${TASK_FILE}"

while :; do
  echo "Follow EXECUTE.prompt.md for ${TASK_FILE}" \
    | claude --print 2>&1 | tee agent_output.log

  if grep -q "NO_MORE_TASKS_TO_PROCESS" agent_output.log; then
    echo "Issue complete: ${TASK_FILE}"
    rm -f agent_output.log
    break
  fi
done
