#!/usr/bin/env bash
set -euo pipefail

FOCUS_TIME_TIMER_KUSTOMIZATION_PATH="deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml"
FOCUS_TIME_TIMER_DEFAULT_BRANCH="main"
FOCUS_TIME_TIMER_ARGOCD_APP="focus-time-timer-demo"
FOCUS_TIME_TIMER_ARGOCD_NAMESPACE="openshift-gitops"
FOCUS_TIME_TIMER_DEPLOY_NAMESPACE="demo-apps"

focus_time_timer_require_repo_root() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "${repo_root}" ]]; then
    echo "git repository root could not be determined" >&2
    exit 1
  fi
  cd "${repo_root}"
}

focus_time_timer_require_clean_worktree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "working tree must be clean before running this script" >&2
    exit 1
  fi
}

focus_time_timer_require_branch() {
  local expected_branch="$1"
  local current_branch
  current_branch="$(git branch --show-current)"
  if [[ "${current_branch}" != "${expected_branch}" ]]; then
    echo "current branch is '${current_branch}', expected '${expected_branch}'" >&2
    exit 1
  fi
}

focus_time_timer_sync_branch() {
  local branch="$1"
  git fetch origin "${branch}"
  git rebase "origin/${branch}"
}

focus_time_timer_update_tag() {
  local tag="$1"
  python - "${FOCUS_TIME_TIMER_KUSTOMIZATION_PATH}" "${tag}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
tag = sys.argv[2]
lines = path.read_text().splitlines()
updated = []
replaced = False
for line in lines:
    if line.strip().startswith("newTag:"):
        updated.append("    newTag: " + tag)
        replaced = True
    else:
        updated.append(line)
if not replaced:
    raise SystemExit("newTag entry not found")
path.write_text("\n".join(updated) + "\n")
PY
}

focus_time_timer_commit_and_push() {
  local branch="$1"
  local commit_message="$2"
  git add "${FOCUS_TIME_TIMER_KUSTOMIZATION_PATH}"
  git commit -m "${commit_message}"
  git push origin "${branch}"
}

focus_time_timer_refresh_argocd() {
  if ! command -v oc >/dev/null 2>&1; then
    echo "oc not found; skipping Argo CD refresh" >&2
    return 0
  fi

  oc -n "${FOCUS_TIME_TIMER_ARGOCD_NAMESPACE}" patch application "${FOCUS_TIME_TIMER_ARGOCD_APP}" \
    --type merge \
    -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
}

focus_time_timer_print_followup() {
  cat <<EOF
Next checks:
  oc -n ${FOCUS_TIME_TIMER_DEPLOY_NAMESPACE} rollout status deploy/focus-time-timer
  oc -n ${FOCUS_TIME_TIMER_DEPLOY_NAMESPACE} get deploy focus-time-timer -o jsonpath='{.spec.template.spec.containers[0].image}{"\\n"}'
  oc -n ${FOCUS_TIME_TIMER_ARGOCD_NAMESPACE} get application ${FOCUS_TIME_TIMER_ARGOCD_APP} -o jsonpath='{.status.sync.status}{"\\n"}{.status.sync.revision}{"\\n"}'
EOF
}
