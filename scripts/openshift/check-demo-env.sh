#!/usr/bin/env bash
set -euo pipefail

DEMO_CICD_NAMESPACE="${DEMO_CICD_NAMESPACE:-demo-cicd}"
DEMO_APPS_NAMESPACE="${DEMO_APPS_NAMESPACE:-demo-apps}"
PIPELINE_SERVICE_ACCOUNT="${PIPELINE_SERVICE_ACCOUNT:-pipeline-bot}"
BASELINE_TAG="${BASELINE_TAG:-v2}"

check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "required command not found: $1" >&2
    exit 1
  fi
}

print_section() {
  echo
  echo "## $1"
}

print_check() {
  local label="$1"
  local command_text="$2"

  if eval "${command_text}" >/dev/null 2>&1; then
    echo "[ok] ${label}"
  else
    echo "[warn] ${label}"
  fi
}

main() {
  check_command oc
  check_command rg

  print_section "Cluster Access"
  print_check "oc login" "oc whoami"

  print_section "Namespaces"
  print_check "namespace ${DEMO_CICD_NAMESPACE}" "oc get ns ${DEMO_CICD_NAMESPACE}"
  print_check "namespace ${DEMO_APPS_NAMESPACE}" "oc get ns ${DEMO_APPS_NAMESPACE}"

  print_section "Secrets"
  print_check "git-auth" "oc -n ${DEMO_CICD_NAMESPACE} get secret git-auth"
  print_check "github-webhook-secret" "oc -n ${DEMO_CICD_NAMESPACE} get secret github-webhook-secret"
  print_check "dockerhub-auth" "oc -n ${DEMO_CICD_NAMESPACE} get secret dockerhub-auth"
  print_check "image-registry-auth" "oc -n ${DEMO_CICD_NAMESPACE} get secret image-registry-auth"

  print_section "ServiceAccount Links"
  print_check "pipeline-bot references dockerhub-auth" "oc -n ${DEMO_CICD_NAMESPACE} get sa ${PIPELINE_SERVICE_ACCOUNT} -o yaml | rg -q 'dockerhub-auth'"
  print_check "pipeline-bot references image-registry-auth" "oc -n ${DEMO_CICD_NAMESPACE} get sa ${PIPELINE_SERVICE_ACCOUNT} -o yaml | rg -q 'image-registry-auth'"

  print_section "Tekton And Routing"
  print_check "pipeline installed" "oc -n ${DEMO_CICD_NAMESPACE} get pipeline focus-time-timer-build-and-promote"
  print_check "eventlistener installed" "oc -n ${DEMO_CICD_NAMESPACE} get eventlistener focus-time-timer-listener"
  print_check "listener route installed" "oc -n ${DEMO_CICD_NAMESPACE} get route focus-time-timer-listener"

  print_section "GitOps"
  print_check "argocd application" "oc -n openshift-gitops get application focus-time-timer-demo"
  print_check "demo deploy exists" "oc -n ${DEMO_APPS_NAMESPACE} get deploy focus-time-timer"

  print_section "Image Tags"
  print_check "baseline tag ${BASELINE_TAG}" "oc -n ${DEMO_APPS_NAMESPACE} get istag focus-time-timer:${BASELINE_TAG}"
  print_check "stable tag" "oc -n ${DEMO_APPS_NAMESPACE} get istag focus-time-timer:stable"

  echo
  echo "Current listener URL:"
  oc -n "${DEMO_CICD_NAMESPACE}" get route focus-time-timer-listener -o jsonpath='https://{.spec.host}{"\n"}' 2>/dev/null || true

  echo "Current deployed image:"
  oc -n "${DEMO_APPS_NAMESPACE}" get deploy focus-time-timer -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}' 2>/dev/null || true

  echo "Argo CD sync/health:"
  oc -n openshift-gitops get application focus-time-timer-demo -o jsonpath='{.status.sync.status}{" / "}{.status.health.status}{"\n"}' 2>/dev/null || true
}

main "$@"
