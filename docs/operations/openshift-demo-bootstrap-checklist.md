# OpenShift デモ初期化チェックリスト

- operation_id: ops-openshift-demo-bootstrap-checklist
- title: 新しい OpenShift デモ環境を初期化するチェックリスト
- owner: shared
- status: draft
- created_at: 2026-04-02
- updated_at: 2026-04-02

## 目的
都度新しく払い出される OpenShift 環境に対して、Codex または人が、Tekton + Argo CD デモを再現可能な状態へ短時間で初期化できるようにする。

## 環境依存で毎回確認する値
- OpenShift cluster login 状態
- GitHub webhook に登録する EventListener URL
- `git-auth` 用の GitHub push 認証
- `github-webhook-secret` 用の shared secret
- `dockerhub-auth` 用の Docker Hub 認証
- internal registry push に使う `image-registry-auth`
- デモ基準タグ `v2` の有無

## Codex に任せるときの基本フロー
1. 必要な認証値を環境変数でセットする。
2. `scripts/openshift/bootstrap-demo-env.sh` を実行する。
3. `scripts/openshift/check-demo-env.sh` を実行する。
4. EventListener Route を取得し、GitHub webhook を設定する。
5. 必要なら `scripts/openshift/tag-focus-time-timer-image.sh` で `v2` を作る。
6. `docs/operations/openshift-demo-rollout-rollback-runbook.md` に沿って手動確認を行う。

## 推奨環境変数
- `GIT_USERNAME`
- `GIT_TOKEN`
- `GITHUB_WEBHOOK_SECRET`
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- 任意:
  - `IMAGE_REGISTRY_USERNAME`
  - `IMAGE_REGISTRY_TOKEN`
  - `DEMO_CICD_NAMESPACE`
  - `DEMO_APPS_NAMESPACE`

## 初期化手順
1. OpenShift に login する。
2. 次を実行する。

```bash
scripts/openshift/bootstrap-demo-env.sh
```

3. 作成・適用される対象:
   - namespace
   - RBAC
   - ImageStream
   - Tekton / EventListener / Route
   - Argo CD Application
   - `git-auth`
   - `github-webhook-secret`
   - `dockerhub-auth`
   - `image-registry-auth`
   - `pipeline-bot` への secret link

## 初期化後の確認
```bash
scripts/openshift/check-demo-env.sh
```

## `v2` 基準版の作り方
1. 手動 `PipelineRun` を 1 回実行する。
2. 生成された `demo-<short-sha>` を確認する。
3. 次を実行する。

```bash
scripts/openshift/tag-focus-time-timer-image.sh demo-<short-sha> v2
```

4. 必要なら `stable` も同様に作る。
5. GitOps の `newTag` を `v2` に合わせる。

## GitHub webhook 設定
Route URL は毎回変わり得るので固定値を使わない。

```bash
oc -n demo-cicd get route focus-time-timer-listener -o jsonpath='https://{.spec.host}{"\n"}'
```

設定値:
- Payload URL: 上記 URL
- Content type: `application/json`
- Secret: `GITHUB_WEBHOOK_SECRET`
- Event: `Just the push event`

## 関連資産
- `scripts/openshift/bootstrap-demo-env.sh`
- `scripts/openshift/check-demo-env.sh`
- `scripts/openshift/tag-focus-time-timer-image.sh`
- `docs/operations/openshift-demo-rollout-rollback-runbook.md`
- `docs/operations/openshift-demo-troubleshooting.md`
