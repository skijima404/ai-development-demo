# OpenShift デモ運用手順

- operation_id: ops-openshift-demo-rollout-rollback
- title: Tekton + Argo CD デモのデプロイとロールバック手順
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-04-03

## 目的
`focus-time-timer` の新版デプロイと、前の安定版への巻き戻しを、同じ説明線上で実演できるようにする。

## 前提
- OpenShift Pipelines と OpenShift GitOps が導入済み
- `oc` で対象クラスタへログイン済み
- `openshift-gitops` namespace が存在する
- GitHub リポジトリへ webhook を登録できる
- GitHub リポジトリの既定ブランチは `main`
- デモ基準タグは `v2`
- 必要なら `stable` も補助用に持つ

## 初回セットアップ
### 1. ブートストラップ YAML を確認する
- 入口:
  - `deploy/openshift/kustomization.yaml`
- 含まれるもの:
  - `demo-cicd`, `demo-apps` namespace
  - `focus-time-timer` ImageStream
  - Argo CD が `demo-apps` に配備するための RoleBinding
  - `pipeline-bot` が EventListener を動かすための RoleBinding / ClusterRoleBinding
  - `pipeline-bot` に `privileged` SCC を付与する RoleBinding
  - Tekton Pipeline / Trigger / EventListener
  - EventListener 用 Route
  - Argo CD Application
- 併せて参照するもの:
  - `deploy/openshift/bootstrap/secret-templates.yaml`

### 2. secret template を環境値へ置換する
1. 手動で実施する場合は `deploy/openshift/bootstrap/secret-templates.yaml` を参照する。
2. Codex に任せる場合は `scripts/openshift/bootstrap-demo-env.sh` を使う。
3. 必要な値:
   - `git-auth.username`: Git push 用ユーザー名
   - `git-auth.password`: Git push 用 token
   - `github-webhook-secret.secretToken`: GitHub webhook shared secret
   - `dockerhub-auth`: Docker Hub pull 認証
   - `image-registry-auth..dockerconfigjson`: OpenShift internal registry push 用認証

### 3. 初回ブートストラップを適用する
1. `scripts/openshift/bootstrap-demo-env.sh` を実行する。
2. 適用後の確認:
   - `oc get ns demo-cicd demo-apps`
   - `oc -n demo-cicd get sa pipeline-bot`
   - `oc -n demo-cicd get rolebinding`
   - `oc get clusterrolebinding pipeline-bot-tekton-triggers-eventlistener-cluster`
   - `oc -n demo-cicd get sa pipeline-bot -o yaml | rg dockerhub-auth`
   - `oc -n demo-cicd get route focus-time-timer-listener`
   - `oc -n openshift-gitops get application focus-time-timer-demo`

### 4. GitHub webhook を作成する
1. EventListener Route URL を取得する。
   - `oc -n demo-cicd get route focus-time-timer-listener -o jsonpath='https://{.spec.host}{"\n"}'`
2. GitHub リポジトリの webhook を追加する。
3. 推奨設定:
   - Payload URL: 上記 Route URL
   - Content type: `application/json`
   - Secret: `github-webhook-secret.secretToken` と同じ値
   - Event: `Just the push event`
   - Active: `true`
4. 疎通確認で `202` が返る場合は EventListener 到達として正常とみなす。

### 5. デモ基準版 `v2` を作る
1. まず手動 `PipelineRun` で 1 回ビルドする。
   - `oc create -f deploy/openshift/tekton/focus-time-timer-manual-run.yaml`
2. 成功したタグを確認する。
   - `oc -n demo-apps get istag`
3. 初回成功タグを `v2` へ付け替える。
   - `scripts/openshift/tag-focus-time-timer-image.sh demo-<short-sha> v2`
4. 必要なら `stable` も控えとして作る。
   - `scripts/openshift/tag-focus-time-timer-image.sh demo-<short-sha> stable`
5. GitOps オーバーレイの初期タグも `v2` へそろえる。
   - `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml`
6. Argo CD が `deploy/gitops/focus-time-timer/overlays/demo` を同期し、初期版を配備する。

## 手動確認フロー
1. `oc create -f deploy/openshift/tekton/focus-time-timer-manual-run.yaml`
2. `oc -n demo-cicd get pipelinerun`
3. `oc -n demo-cicd logs -f pipelinerun/<generated-name>`
4. GitOps 更新確認:
   - `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml` の `newTag`
   - `git log --oneline --grep "chore(gitops): promote focus-time-timer"`
5. Argo CD 同期確認:
   - `oc -n openshift-gitops get application focus-time-timer-demo`
6. 配備確認:
   - `oc -n demo-apps rollout status deploy/focus-time-timer`
   - `oc -n demo-apps get route focus-time-timer`

## 通常のデプロイデモ
1. アプリ変更を Git に反映する。
2. Tekton Trigger または `PipelineRun` を起動する。
3. Tekton が image tag を生成し、GitOps オーバーレイの `newTag` を更新して push する。
4. Argo CD が同期し、OpenShift 上の `focus-time-timer` を更新する。
5. Route へアクセスして新版を確認する。

## 自動確認フロー
1. `src/focus-time-timer/` 配下に差分を含む commit を `main` へ push する。
2. GitHub webhook delivery が successful であることを確認する。
3. `oc -n demo-cicd get events --sort-by=.lastTimestamp`
4. `oc -n demo-cicd get pipelinerun`
5. `oc -n openshift-gitops get application focus-time-timer-demo -o jsonpath='{.status.sync.status}{"\n"}{.status.health.status}{"\n"}'`
6. `oc -n demo-apps get deploy focus-time-timer -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'`
7. アプリ Route で動作確認する。

## 補助スクリプト
- GitOps の image tag を任意のタグへ切り替える:
  - `scripts/openshift/set-focus-time-timer-tag.sh <tag>`
- GitOps の image tag を任意のタグへロールバックする:
  - `scripts/openshift/rollback-focus-time-timer.sh <tag>`
- どちらのスクリプトも、clean worktree 上の `main` を前提に、`origin/main` へ追従してから `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml` を更新し、commit、push、Argo CD refresh まで行う。
- 詳細な使い方:
  - `docs/operations/focus-time-timer-gitops-helper-scripts.md`

## Trigger の前提
- GitHub webhook secret が `demo-cicd/github-webhook-secret` に存在する
- EventListener は `push` event のみ受け付ける
- EventListener は `refs/heads/main` の push のみ受け付ける
- `src/focus-time-timer/` 配下に変更がある push のみを再起動対象とする
- `deploy/gitops/` のみの変更では Tekton を再起動しない
- `chore(gitops):` で始まる GitOps 更新コミットは再起動対象から除外する
- 初回確認は webhook ではなく手動 `PipelineRun` から始めてもよい

## ロールバックデモ
1. 新版に不具合があることを確認する。
2. `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml` の `images[].newTag` を、デモ基準版 `v2` へ戻す。
3. 変更を Git に push する。
4. Tekton が再起動しないことを確認する。
5. Argo CD が再同期し、Deployment の image が `v2` へ戻ることを確認する。
6. Route で復旧を確認する。

## 手動確認チェック項目
- `oc -n demo-cicd get eventlistener focus-time-timer-listener`
- `oc -n demo-cicd get route focus-time-timer-listener`
- `oc -n demo-cicd get secret git-auth github-webhook-secret image-registry-auth`
- `oc -n demo-cicd get secret dockerhub-auth`
- `oc -n demo-cicd auth can-i create pipelineruns --as system:serviceaccount:demo-cicd:pipeline-bot`
- `oc -n demo-apps auth can-i create deployments --as system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller`
- `oc -n demo-apps get istag focus-time-timer:v2`
- `oc -n demo-apps get istag focus-time-timer:stable`

## 自動確認チェック項目
- GitHub webhook delivery が 2xx を返す
- `focus-time-timer-listener` が `PipelineRun` を生成する
- `chore(gitops):` commit では EventListener が再起動しない
- Argo CD Application が `Synced` / `Healthy` になる
- `demo-apps/focus-time-timer:v2` を rollback 候補として参照できる

## デモ中に強調する説明
- Tekton はビルド担当であり、直接クラスタ状態を正本化しない
- Argo CD は Git の宣言状態をクラスタへそろえる
- ロールバックは「クラスタを手で直す」のではなく、「Git の正本を安定状態へ戻す」

## rollback 時の運用注意
- `v2` をデモ基準版として扱い、通常の rollback 説明は `v2` へ戻す流れで固定する
- `stable` は補助的な控えとして扱い、毎回自動更新しない
- `v2` が未作成のまま GitOps が `v2` を参照すると、`manifest unknown` により `ImagePullBackOff` になる
- rollback 前に、戻すタグが `demo-apps` ImageStream に存在することを確認する
- 手動 rollback で `deploy/gitops/**` だけを変更した場合、Tekton は起動しない前提で確認する
- Route や RoleBinding などの基盤資産に問題がある場合は、先に `oc apply -k deploy/openshift` で基盤差分を復旧する
- secret を更新したときは、EventListener / PipelineRun の再試行前に対象 Pod の再作成を確認する

## デモ簡略化のための注意
- この runbook は説明優先の最小構成であり、本番運用の secrets 設計までは含まない
- `deploy/openshift/bootstrap/secret-templates.yaml` は template であり、実値は別管理にする
- `v2` はデモ開始前に必ず存在確認する
