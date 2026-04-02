# 運用メモ

- operation_id: ops-focus-time-timer-gitops-helper-scripts
- title: focus-time-timer の GitOps tag 切り替え補助スクリプト
- owner: shared
- status: draft
- created_at: 2026-04-02
- updated_at: 2026-04-02

## 目的
`focus-time-timer` の GitOps オーバーレイに対する tag 切り替えとロールバックを、毎回の手作業差分編集ではなく、再利用可能な手順として扱えるようにする。

## 想定する使い方
- 人が AI コーディング支援エージェントへ「この tag に切り替えて」「この版へ戻して」と依頼する。
- AI コーディング支援エージェントが、このリポジトリ内の補助スクリプトをキックする。
- 例:
  - Codex から `scripts/openshift/set-focus-time-timer-tag.sh <tag>` を実行する
  - Codex から `scripts/openshift/rollback-focus-time-timer.sh <tag>` を実行する

## 対象スクリプト
- `scripts/openshift/set-focus-time-timer-tag.sh`
- `scripts/openshift/rollback-focus-time-timer.sh`
- `scripts/openshift/focus-time-timer-gitops-common.sh`

## 前提
- clean worktree であること
- 実行ブランチが `main` であること
- `origin/main` へ fetch / rebase 可能であること
- `oc` が使える場合は Argo CD refresh まで行うこと

## スクリプトが行うこと
1. git repository root へ移動する。
2. worktree が clean であることを確認する。
3. `main` 上であることを確認する。
4. `origin/main` へ追従する。
5. `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml` の `newTag` を指定 tag へ更新する。
6. commit と push を行う。
7. 可能なら Argo CD Application に `refresh=hard` を付与する。
8. デプロイ確認コマンドを表示する。

## 注意
- このスクリプトは image tag 自体を作らない。指定した tag がレジストリ側に存在することを前提とする。
- `deploy/gitops/**` のみの変更では Tekton が再起動しない前提で使う。
- 自動 promote が進行している場合は、`origin/main` への追従後に指定 tag を最終状態として再度 commit する動きになる。

## 関連資産
- `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml`
- `deploy/openshift/tekton/focus-time-timer-pipeline.yaml`
- `docs/operations/openshift-demo-rollout-rollback-runbook.md`
