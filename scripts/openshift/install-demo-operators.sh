#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

OPERATORS_NAMESPACE="${OPERATORS_NAMESPACE:-openshift-operators}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-openshift-gitops}"
PIPELINES_NAMESPACE="${PIPELINES_NAMESPACE:-openshift-pipelines}"
WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-900}"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "required command not found: ${command_name}" >&2
    exit 1
  fi
}

require_oc_login() {
  if ! oc whoami >/dev/null 2>&1; then
    echo "oc login is required before running this script" >&2
    exit 1
  fi
}

wait_for_condition() {
  local description="$1"
  local command_text="$2"
  local elapsed=0

  until eval "${command_text}" >/dev/null 2>&1; do
    if (( elapsed >= WAIT_TIMEOUT_SECONDS )); then
      echo "timed out waiting for ${description}" >&2
      return 1
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
}

wait_for_csv() {
  local namespace="$1"
  local subscription_name="$2"

  wait_for_condition \
    "CSV for ${subscription_name}" \
    "test -n \"\$(oc -n ${namespace} get subscription ${subscription_name} -o jsonpath='{.status.currentCSV}' 2>/dev/null)\""

  local current_csv
  current_csv="$(oc -n "${namespace}" get subscription "${subscription_name}" -o jsonpath='{.status.currentCSV}')"

  wait_for_condition \
    "CSV ${current_csv} to succeed" \
    "test \"\$(oc -n ${namespace} get csv ${current_csv} -o jsonpath='{.status.phase}' 2>/dev/null)\" = Succeeded"
}

install_subscriptions() {
  oc apply -f "${REPO_ROOT}/deploy/openshift/operators/subscriptions.yaml"
}

wait_for_operator_apis() {
  wait_for_condition \
    "Argo CD CRD" \
    "oc get crd argocds.argoproj.io"

  wait_for_condition \
    "TektonConfig CRD" \
    "oc get crd tektonconfigs.operator.tekton.dev"
}

install_tekton_config() {
  oc apply -f "${REPO_ROOT}/deploy/openshift/operators/tekton-config.yaml"
}

wait_for_namespaces() {
  wait_for_condition "namespace ${ARGOCD_NAMESPACE}" "oc get ns ${ARGOCD_NAMESPACE}"
  wait_for_condition "namespace ${PIPELINES_NAMESPACE}" "oc get ns ${PIPELINES_NAMESPACE}"
}

wait_for_pods() {
  wait_for_condition \
    "GitOps application controller statefulset" \
    "oc -n ${ARGOCD_NAMESPACE} get statefulset openshift-gitops-application-controller"

  wait_for_condition \
    "GitOps server deployment" \
    "oc -n ${ARGOCD_NAMESPACE} get deploy openshift-gitops-server"

  wait_for_condition \
    "Pipelines webhook pod" \
    "oc -n ${PIPELINES_NAMESPACE} get deploy tekton-pipelines-webhook"

  oc -n "${ARGOCD_NAMESPACE}" rollout status statefulset/openshift-gitops-application-controller --timeout="${WAIT_TIMEOUT_SECONDS}s"
  oc -n "${ARGOCD_NAMESPACE}" wait --for=condition=Available deploy/openshift-gitops-server --timeout="${WAIT_TIMEOUT_SECONDS}s"
  oc -n "${PIPELINES_NAMESPACE}" wait --for=condition=Available deploy/tekton-pipelines-webhook --timeout="${WAIT_TIMEOUT_SECONDS}s"
}

print_followup() {
  cat <<EOF
Operator install completed. Suggested follow-up:
  oc get subscription -n ${OPERATORS_NAMESPACE}
  oc get csv -n ${OPERATORS_NAMESPACE}
  oc get ns ${ARGOCD_NAMESPACE} ${PIPELINES_NAMESPACE}
  oc api-resources | rg 'argoproj|tekton'
EOF
}

main() {
  require_command oc
  require_oc_login

  install_subscriptions
  wait_for_csv "${OPERATORS_NAMESPACE}" "openshift-gitops-operator"
  wait_for_csv "${OPERATORS_NAMESPACE}" "openshift-pipelines-operator-rh"
  wait_for_operator_apis
  install_tekton_config
  wait_for_namespaces
  wait_for_pods
  print_followup
}

main "$@"
