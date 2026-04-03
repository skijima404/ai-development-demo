# OpenShift デモ基盤前提

- operation_id: ops-openshift-platform-prerequisites
- title: 素の OpenShift へデモ基盤 operator を導入する手順
- owner: shared
- status: draft
- created_at: 2026-04-03
- updated_at: 2026-04-03

## 目的
OpenShift を新規にプロビジョニングした直後の環境に対して、Tekton + Argo CD デモの前提となる operator を再現可能に導入する。

## 対象
- OpenShift GitOps
- OpenShift Pipelines

## 前提
- cluster-admin 相当で `oc login` 済み
- `openshift-marketplace` と `openshift-operators` が利用可能
- `redhat-operators` catalog source が利用可能

## repo 資産
- `deploy/openshift/operators/subscriptions.yaml`
- `deploy/openshift/operators/tekton-config.yaml`
- `scripts/openshift/install-demo-operators.sh`

## Codex に任せるときの基本フロー
1. `scripts/openshift/install-demo-operators.sh` を実行する。
2. `openshift-gitops` と `openshift-pipelines` の生成を待つ。
3. GitOps / Tekton API が見えることを確認する。
4. その後 `scripts/openshift/bootstrap-demo-env.sh` を実行する。

## 手動実行の要点
1. `openshift-operators` に subscription を apply する。
2. OpenShift GitOps operator の CSV が `Succeeded` になるまで待つ。
3. OpenShift Pipelines operator の CSV が `Succeeded` になるまで待つ。
4. `TektonConfig` を apply して `openshift-pipelines` を起動する。
5. `openshift-gitops` と `openshift-pipelines` の主要 deployment が `Available` になるまで待つ。

## 確認コマンド
```bash
oc get subscription -n openshift-operators
oc get csv -n openshift-operators
oc get ns openshift-gitops openshift-pipelines
oc api-resources | rg 'argoproj|tekton'
```

## 次の手順
operator 導入後は次へ進む。
- `docs/operations/openshift-demo-bootstrap-checklist.md`
- `scripts/openshift/bootstrap-demo-env.sh`

## 2026-04-03 実地確認メモ
- 素の OCP では OpenShift GitOps / OpenShift Pipelines は未導入だった。
- `scripts/openshift/install-demo-operators.sh` により、`openshift-gitops` と `openshift-pipelines` の作成まで確認できた。
- OpenShift GitOps の application controller は deployment ではなく statefulset として待つ必要があった。
