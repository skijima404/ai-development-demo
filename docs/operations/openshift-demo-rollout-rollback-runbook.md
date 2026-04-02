# OpenShift デモ運用手順

- operation_id: ops-openshift-demo-rollout-rollback
- title: Tekton + Argo CD デモのデプロイとロールバック手順
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-04-02

## 目的
`focus-time-timer` の新版デプロイと、前の安定版への巻き戻しを、同じ説明線上で実演できるようにする。

## 前提
- OpenShift Pipelines と OpenShift GitOps が導入済み
- `demo-cicd` namespace に Tekton 関連資産を適用できる
- `demo-apps` namespace にアプリを配備できる
- コンテナレジストリと Git push 用の認証情報が作成済み
- GitHub リポジトリの既定ブランチは `main`
- 初期安定版イメージタグは `stable`

## 初回セットアップ
1. `demo-apps/focus-time-timer:stable` の初期安定版イメージをあらかじめ作成しておく。
2. `deploy/openshift/tekton/focus-time-timer-pipeline.yaml` を適用する。
3. `deploy/openshift/argocd/focus-time-timer-application.yaml` を適用する。
4. Argo CD が `deploy/gitops/focus-time-timer/overlays/demo` を同期し、初期版を配備する。

## 通常のデプロイデモ
1. アプリ変更を Git に反映する。
2. Tekton Trigger または `PipelineRun` を起動する。
3. Tekton が image tag を生成し、GitOps オーバーレイの `newTag` を更新して push する。
4. Argo CD が同期し、OpenShift 上の `focus-time-timer` を更新する。
5. Route へアクセスして新版を確認する。

## Trigger の前提
- EventListener は `refs/heads/main` の push のみ受け付ける
- `src/focus-time-timer/` 配下に変更がある push のみを再起動対象とする
- `deploy/gitops/` のみの変更では Tekton を再起動しない
- `chore(gitops):` で始まる GitOps 更新コミットは再起動対象から除外する
- 初回確認は webhook ではなく手動 `PipelineRun` から始めてもよい

## ロールバックデモ
1. 新版に不具合があることを確認する。
2. `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml` の `images[].newTag` を、直前の安定版タグへ戻す。
3. 変更を Git に push する。
4. Tekton が再起動しないことを確認する。
5. Argo CD が再同期し、Deployment の image が安定版へ戻ることを確認する。
6. Route で復旧を確認する。

## デモ中に強調する説明
- Tekton はビルド担当であり、直接クラスタ状態を正本化しない
- Argo CD は Git の宣言状態をクラスタへそろえる
- ロールバックは「クラスタを手で直す」のではなく、「Git の正本を安定状態へ戻す」

## デモ簡略化のための注意
- この runbook は説明優先の最小構成であり、本番運用の secrets 設計までは含まない
- 安定版タグはデモ前に 1 つ控えておく
