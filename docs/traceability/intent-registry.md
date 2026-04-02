# 意図レジストリ

最終更新日: 2026-04-02

| intent_id | proposal_type | title | stage | enabler_proposal | feature_proposal | related_enablers | ui_spec | implementation_spec | status | updated_at |
|---|---|---|---|---|---|---|---|---|---|---|
| intent-000 | enabler | AI ネイティブなトレーサビリティ基盤 | implementation | docs/traceability/enabler-proposals/ep-intent-000-ai-native-traceability-scaffold.md |  |  |  | docs/traceability/implementation-specs/is-intent-000-repository-bootstrap.md | draft | 2026-03-30 |
| intent-001 | feature | 業務要求からレビュー済みデプロイ準備までのフロー | proposal |  | docs/traceability/feature-proposals/fp-intent-001-business-request-to-reviewed-deployment-flow.md | intent-000 | docs/traceability/ui-specs/ui-intent-001-request-review-deploy-surface.md |  | draft | 2026-03-30 |
| intent-002 | feature | フォーカスタイムタイマーのフロントエンド MVP | implementation |  | docs/traceability/feature-proposals/fp-intent-002-focus-time-timer-mvp.md | intent-000 | docs/traceability/ui-specs/ui-intent-002-focus-time-timer-screen.md | docs/traceability/implementation-specs/is-intent-002-focus-time-timer-skeleton-mvp.md | draft | 2026-03-30 |
| intent-003 | enabler | OpenShift デモ向け GitOps デプロイとロールバック基盤 | implementation | docs/traceability/enabler-proposals/ep-intent-003-openshift-gitops-rollout-rollback-demo.md |  | intent-000, intent-001, intent-002 |  | docs/traceability/implementation-specs/is-intent-003-tekton-argocd-openshift-pipeline-demo.md | draft | 2026-04-02 |

## 段階の定義
- `proposal`: 基盤提案 / 機能提案を策定またはレビュー中
- `ui-spec`: UI / 操作仕様の策定を進めている段階
- `implementation`: 実装構造化または実装中
- `done`: 実装と検証が完了した状態

## 提案種別の定義
- `enabler`: 複数の下流資産が依存する基盤
- `feature`: ユーザー向けまたは作業フロー向けの変化

## 状態の定義
- `draft`: 作成中
- `review`: レビュー中
- `approved`: 次段階へ進めてよい状態
- `superseded`: 新しい資産に置き換えられた状態
- `archived`: 履歴として保存されるが現時点の正本ではない状態
