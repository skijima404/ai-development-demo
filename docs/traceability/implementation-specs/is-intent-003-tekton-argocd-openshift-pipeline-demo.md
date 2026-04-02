# 実装仕様

- intent_id: intent-003
- title: Tekton + Argo CD による OpenShift デプロイデモ
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-04-02
- related_enabler_proposal: docs/traceability/enabler-proposals/ep-intent-003-openshift-gitops-rollout-rollback-demo.md
- depends_on_enablers:
  - intent-000
  - intent-001
  - intent-002

## 基盤との整合
この実装は、既存の `focus-time-timer` フロントエンドを OpenShift デモに乗せるための最小 GitOps 資産を追加する。目的は高度な運用の完全再現ではなく、デリバリーの責務分離と巻き戻し可能性を短時間で示すことである。

## 目標
次の説明が実際のリポジトリ資産だけで可能になることを目標とする。
- Tekton がアプリをビルドしてイメージを更新する
- Argo CD が GitOps マニフェスト差分を検知して OpenShift を同期する
- 新版に不具合があれば、Git の前の安定コミットへ戻して復旧できる

## スコープ
- 対象範囲:
  - GitOps ベース構成:
    - Deployment
    - Service
    - Route
    - `kustomization.yaml`
  - GitOps デモオーバーレイ:
    - namespace
    - image tag の差し替えポイント
  - Argo CD:
    - `Application` 1 件
  - Tekton:
    - `Pipeline`
    - `TriggerTemplate`
    - `TriggerBinding`
    - `EventListener`
    - 必要最小限の `ServiceAccount`
  - 運用資産:
    - デモシナリオ
    - ロールバック runbook
- 対象外:
  - Secrets の自動作成
  - イメージ署名や SBOM
  - 複数環境 promotion

## 構成方針
1. デプロイ対象の正本は `deploy/gitops/focus-time-timer/` 配下に置く。
2. Tekton は `src/focus-time-timer/` をビルドし、生成したイメージ参照を GitOps オーバーレイへ反映する。
3. Argo CD は `deploy/gitops/focus-time-timer/overlays/demo` を監視する。
4. ロールバックは Argo CD の UI 操作ではなく、まず Git の状態を戻す説明を主にする。
5. Tekton Trigger は `main` への push のうち、`src/focus-time-timer/` 配下に変更を含むものだけを受け付ける。
6. GitOps オーバーレイのみの変更は Argo CD の同期対象であり、Tekton の再起動対象にしない。

## 実行メモ
- 変更してよいファイル:
  - `deploy/gitops/**`
  - `deploy/openshift/**`
  - `docs/product/**`
  - `docs/operations/**`
  - `docs/traceability/**`
- 明示的に対象外のファイル:
  - `src/focus-time-timer/**` の機能変更
- 前提:
  - OpenShift Pipelines と OpenShift GitOps が導入済み
  - イメージ push 先レジストリ資格情報は別途準備済み
  - Tekton が Git push 可能な資格情報を持つ

## 実装の流れ
1. GitOps 用 base / overlay を作る。
2. Argo CD Application を追加する。
3. Tekton パイプラインで build, push, GitOps 更新を定義する。
4. Webhook または手動 `PipelineRun` の入口を追加する。
5. ロールバック手順を文書化する。

## 検証
1. `kustomization.yaml` からデモ環境のイメージ参照が確認できること。
2. Tekton マニフェスト上で build と GitOps 更新の順序が読み取れること。
3. Argo CD Application が GitOps オーバーレイを参照していること。
4. `deploy/gitops/**` のみを変更した push では EventListener 条件を満たさないことがマニフェストから読み取れること。
5. runbook だけでロールバック経路を説明できること。

## デモ説明用の要点
- Tekton は「作る側」
- Argo CD は「適用してそろえる側」
- GitOps オーバーレイは「いま出したい版の正本」
- 不具合時は「GitOps の正本を安定版に戻す」
