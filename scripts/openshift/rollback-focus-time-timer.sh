#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/focus-time-timer-gitops-common.sh"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <tag> [branch]" >&2
  exit 1
fi

TAG="$1"
BRANCH="${2:-${FOCUS_TIME_TIMER_DEFAULT_BRANCH}}"
COMMIT_MESSAGE="chore(gitops): rollback focus-time-timer to ${TAG}"

focus_time_timer_require_repo_root
focus_time_timer_require_clean_worktree
focus_time_timer_require_branch "${BRANCH}"
focus_time_timer_sync_branch "${BRANCH}"
focus_time_timer_update_tag "${TAG}"
focus_time_timer_commit_and_push "${BRANCH}" "${COMMIT_MESSAGE}"
focus_time_timer_refresh_argocd
focus_time_timer_print_followup
