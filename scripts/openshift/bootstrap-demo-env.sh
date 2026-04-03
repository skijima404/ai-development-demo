#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DEMO_CICD_NAMESPACE="${DEMO_CICD_NAMESPACE:-demo-cicd}"
DEMO_APPS_NAMESPACE="${DEMO_APPS_NAMESPACE:-demo-apps}"
PIPELINE_SERVICE_ACCOUNT="${PIPELINE_SERVICE_ACCOUNT:-pipeline-bot}"
DOCKERHUB_SECRET_NAME="${DOCKERHUB_SECRET_NAME:-dockerhub-auth}"
GIT_SECRET_NAME="${GIT_SECRET_NAME:-git-auth}"
WEBHOOK_SECRET_NAME="${WEBHOOK_SECRET_NAME:-github-webhook-secret}"
IMAGE_REGISTRY_SECRET_NAME="${IMAGE_REGISTRY_SECRET_NAME:-image-registry-auth}"
REGISTRY_SERVER="${REGISTRY_SERVER:-image-registry.openshift-image-registry.svc:5000}"
DOCKERHUB_EMAIL="${DOCKERHUB_EMAIL:-unused@example.local}"
SKIP_APPLY="${SKIP_APPLY:-false}"
AUTO_INSTALL_PREREQUISITES="${AUTO_INSTALL_PREREQUISITES:-false}"

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

ensure_platform_prerequisites() {
  if oc get ns openshift-gitops >/dev/null 2>&1 && oc get crd tektonconfigs.operator.tekton.dev >/dev/null 2>&1; then
    return
  fi

  if [[ "${AUTO_INSTALL_PREREQUISITES}" == "true" ]]; then
    "${SCRIPT_DIR}/install-demo-operators.sh"
    return
  fi

  cat >&2 <<EOF
OpenShift GitOps or OpenShift Pipelines prerequisites are missing.
Run scripts/openshift/install-demo-operators.sh first,
or rerun this script with AUTO_INSTALL_PREREQUISITES=true.
EOF
  exit 1
}

apply_manifests() {
  if [[ "${SKIP_APPLY}" == "true" ]]; then
    echo "SKIP_APPLY=true; skipping oc apply -k deploy/openshift"
    return
  fi

  oc apply -k "${REPO_ROOT}/deploy/openshift"
}

replace_secret_from_stdin() {
  local namespace="$1"
  local secret_name="$2"

  oc -n "${namespace}" delete secret "${secret_name}" --ignore-not-found >/dev/null
  oc -n "${namespace}" apply -f -
}

create_git_auth_secret() {
  if [[ -z "${GIT_USERNAME:-}" || -z "${GIT_TOKEN:-}" ]]; then
    echo "skipping ${GIT_SECRET_NAME}; set GIT_USERNAME and GIT_TOKEN to create it"
    return
  fi

  oc -n "${DEMO_CICD_NAMESPACE}" create secret generic "${GIT_SECRET_NAME}" \
    --from-literal=username="${GIT_USERNAME}" \
    --from-literal=password="${GIT_TOKEN}" \
    --dry-run=client -o yaml | replace_secret_from_stdin "${DEMO_CICD_NAMESPACE}" "${GIT_SECRET_NAME}"
}

create_webhook_secret() {
  if [[ -z "${GITHUB_WEBHOOK_SECRET:-}" ]]; then
    echo "skipping ${WEBHOOK_SECRET_NAME}; set GITHUB_WEBHOOK_SECRET to create it"
    return
  fi

  oc -n "${DEMO_CICD_NAMESPACE}" create secret generic "${WEBHOOK_SECRET_NAME}" \
    --from-literal=secretToken="${GITHUB_WEBHOOK_SECRET}" \
    --dry-run=client -o yaml | replace_secret_from_stdin "${DEMO_CICD_NAMESPACE}" "${WEBHOOK_SECRET_NAME}"
}

create_dockerhub_secret() {
  if [[ -z "${DOCKERHUB_USERNAME:-}" || -z "${DOCKERHUB_TOKEN:-}" ]]; then
    echo "skipping ${DOCKERHUB_SECRET_NAME}; set DOCKERHUB_USERNAME and DOCKERHUB_TOKEN to create it"
    return
  fi

  oc -n "${DEMO_CICD_NAMESPACE}" create secret docker-registry "${DOCKERHUB_SECRET_NAME}" \
    --docker-server="https://index.docker.io/v1/" \
    --docker-username="${DOCKERHUB_USERNAME}" \
    --docker-password="${DOCKERHUB_TOKEN}" \
    --docker-email="${DOCKERHUB_EMAIL}" \
    --dry-run=client -o yaml | replace_secret_from_stdin "${DEMO_CICD_NAMESPACE}" "${DOCKERHUB_SECRET_NAME}"
}

create_image_registry_secret() {
  local username token

  username="${IMAGE_REGISTRY_USERNAME:-}"
  token="${IMAGE_REGISTRY_TOKEN:-}"

  if [[ -z "${username}" || -z "${token}" ]]; then
    username="$(oc whoami)"
    token="$(oc whoami -t)"
  fi

  oc -n "${DEMO_CICD_NAMESPACE}" create secret docker-registry "${IMAGE_REGISTRY_SECRET_NAME}" \
    --docker-server="${REGISTRY_SERVER}" \
    --docker-username="${username}" \
    --docker-password="${token}" \
    --docker-email="${DOCKERHUB_EMAIL}" \
    --dry-run=client -o yaml | replace_secret_from_stdin "${DEMO_CICD_NAMESPACE}" "${IMAGE_REGISTRY_SECRET_NAME}"
}

link_secret_if_present() {
  local secret_name="$1"
  local link_mode="$2"

  if ! oc -n "${DEMO_CICD_NAMESPACE}" get secret "${secret_name}" >/dev/null 2>&1; then
    echo "secret not found; skipping link: ${secret_name}" >&2
    return
  fi

  if [[ -n "${link_mode}" ]]; then
    oc -n "${DEMO_CICD_NAMESPACE}" secrets link "${PIPELINE_SERVICE_ACCOUNT}" "${secret_name}" "${link_mode}"
  else
    oc -n "${DEMO_CICD_NAMESPACE}" secrets link "${PIPELINE_SERVICE_ACCOUNT}" "${secret_name}"
  fi
}

print_followup() {
  cat <<EOF
Bootstrap completed. Suggested follow-up:
  oc -n ${DEMO_CICD_NAMESPACE} get sa ${PIPELINE_SERVICE_ACCOUNT} -o yaml
  oc -n ${DEMO_CICD_NAMESPACE} get secret ${GIT_SECRET_NAME} ${WEBHOOK_SECRET_NAME} ${DOCKERHUB_SECRET_NAME} ${IMAGE_REGISTRY_SECRET_NAME}
  oc -n ${DEMO_CICD_NAMESPACE} get route focus-time-timer-listener -o jsonpath='https://{.spec.host}{"\\n"}'
  oc -n openshift-gitops get application focus-time-timer-demo
EOF
}

main() {
  require_command oc
  require_oc_login
  ensure_platform_prerequisites

  apply_manifests
  create_git_auth_secret
  create_webhook_secret
  create_dockerhub_secret
  create_image_registry_secret
  link_secret_if_present "${DOCKERHUB_SECRET_NAME}" "--for=pull"
  link_secret_if_present "${IMAGE_REGISTRY_SECRET_NAME}" ""
  print_followup
}

main "$@"
