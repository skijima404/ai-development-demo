# OpenShift デモ切り分けメモ

- operation_id: ops-openshift-demo-troubleshooting
- title: OpenShift デモ初期化と運用の代表的な切り分け
- owner: shared
- status: draft
- created_at: 2026-04-02
- updated_at: 2026-04-03

## 目的
新しい OpenShift 環境でデモ準備を行う際に、発生しやすい失敗を Codex または人が短く切り分けられるようにする。

## ケース 1: Docker Hub rate limit
- 症状:
  - `node:22-alpine` pull 付近で失敗する
- 主な確認:
  - `oc -n demo-cicd get secret dockerhub-auth`
  - `oc -n demo-cicd get sa pipeline-bot -o yaml | rg dockerhub-auth`
- 主な対処:
  - `DOCKERHUB_USERNAME` と `DOCKERHUB_TOKEN` を設定して `scripts/openshift/bootstrap-demo-env.sh` を再実行する
  - 必要なら次を個別実行する

```bash
oc -n demo-cicd secrets link pipeline-bot dockerhub-auth --for=pull
```

## ケース 2: `secret "git-auth" not found`
- 症状:
  - `update-gitops-manifest` が失敗する
- 主な確認:
  - `oc -n demo-cicd get secret git-auth`
- 主な対処:
  - `GIT_USERNAME` と `GIT_TOKEN` を設定して `scripts/openshift/bootstrap-demo-env.sh` を再実行する

## ケース 3: EventListener が古い filter のまま
- 症状:
  - `main` の push だけでなく意図しない変更でも起動する
  - `deploy/gitops/**` だけの変更で再起動する
  - `chore(gitops):` commit で再起動する
- 主な確認:
  - `oc -n demo-cicd get eventlistener focus-time-timer-listener -o yaml`
  - `deploy/openshift/tekton/focus-time-timer-pipeline.yaml`
- 主な対処:

```bash
oc apply -k deploy/openshift
```

## ケース 4: `v2` に戻したいが tag が存在しない
- 症状:
  - rollback シナリオに入れない
  - `focus-time-timer:v2` を pull しようとして `ImagePullBackOff` になる
- 主な確認:
  - `oc -n demo-apps get istag focus-time-timer:v2`
  - `oc -n demo-apps get istag`
  - `oc -n demo-apps describe pod <pod-name>`
- 主な対処:
  - 既存の `demo-<short-sha>` を確認し、次を実行する

```bash
scripts/openshift/tag-focus-time-timer-image.sh demo-<short-sha> v2
```

## ケース 5: Argo CD 反映が遅い / 手動 refresh を打ちたい
- 症状:
  - GitOps 更新後すぐに反映されない
- 主な確認:
  - `oc -n openshift-gitops get application focus-time-timer-demo -o jsonpath='{.status.sync.status}{"\n"}{.status.health.status}{"\n"}'`
- 主な対処:

```bash
oc -n openshift-gitops patch application focus-time-timer-demo \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

## ケース 6: rollout 状態を見たい
- 主な確認:

```bash
oc -n demo-apps rollout status deploy/focus-time-timer
oc -n demo-apps get deploy focus-time-timer -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
oc -n demo-apps get route focus-time-timer
```

## ケース 7: 環境全体が揃っているか確認したい
- 主な対処:

```bash
scripts/openshift/check-demo-env.sh
```

## ケース 8: `openshift-gitops` や `openshift-pipelines` が存在しない
- 症状:
  - まっさらな OCP に対して bootstrap が進まない
- 主な確認:
  - `oc get ns openshift-gitops openshift-pipelines`
  - `oc get subscription -n openshift-operators`
- 主な対処:

```bash
scripts/openshift/install-demo-operators.sh
```

## ケース 9: webhook 疎通確認は成功したが PipelineRun が作られない
- 症状:
  - GitHub webhook delivery は `202`
  - `demo-cicd` に `PipelineRun` が作られない
- 主な確認:
  - delivery が `ping` ではなく `push` か
  - push 先が `main` か
  - 変更に `src/focus-time-timer/` が含まれているか
  - commit message が `chore(gitops):` で始まっていないか
- 主な対処:
  - 初回は手動 `PipelineRun` で `demo-<short-sha>` を作る
  - その後 webhook の自動起動確認へ進む

```bash
oc create -f deploy/openshift/tekton/focus-time-timer-manual-run.yaml
```

## 関連資産
- `scripts/openshift/install-demo-operators.sh`
- `scripts/openshift/bootstrap-demo-env.sh`
- `scripts/openshift/check-demo-env.sh`
- `scripts/openshift/tag-focus-time-timer-image.sh`
- `deploy/openshift/kustomization.yaml`
- `docs/operations/openshift-platform-prerequisites.md`
- `docs/operations/openshift-demo-bootstrap-checklist.md`
