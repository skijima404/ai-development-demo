#!/usr/bin/env bash
set -euo pipefail

DEMO_APPS_NAMESPACE="${DEMO_APPS_NAMESPACE:-demo-apps}"
IMAGESTREAM_NAME="${IMAGESTREAM_NAME:-focus-time-timer}"

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 <source-tag> <target-tag> [namespace]" >&2
  exit 1
fi

SOURCE_TAG="$1"
TARGET_TAG="$2"
TARGET_NAMESPACE="${3:-${DEMO_APPS_NAMESPACE}}"

if ! command -v oc >/dev/null 2>&1; then
  echo "required command not found: oc" >&2
  exit 1
fi

if ! oc whoami >/dev/null 2>&1; then
  echo "oc login is required before running this script" >&2
  exit 1
fi

oc -n "${TARGET_NAMESPACE}" get istag "${IMAGESTREAM_NAME}:${SOURCE_TAG}" >/dev/null
oc -n "${TARGET_NAMESPACE}" tag "${IMAGESTREAM_NAME}:${SOURCE_TAG}" "${IMAGESTREAM_NAME}:${TARGET_TAG}"

cat <<EOF
Tagged ${IMAGESTREAM_NAME}:${SOURCE_TAG} -> ${IMAGESTREAM_NAME}:${TARGET_TAG}
Follow-up:
  oc -n ${TARGET_NAMESPACE} get istag ${IMAGESTREAM_NAME}:${TARGET_TAG}
  scripts/openshift/set-focus-time-timer-tag.sh ${TARGET_TAG}
EOF
