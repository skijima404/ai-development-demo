# 意図

- intent_id: intent-003
- title: OpenShift デモ向け GitOps デプロイとロールバック基盤
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-03-31
- related_value_streams:
  - docs/traceability/value-streams/vs-intent-003-openshift-gitops-rollout-rollback.md
- related_enablers:
  - intent-000
  - intent-001
  - intent-002

## 望む変化
AI 支援で開発したアプリを OpenShift にデプロイし、不具合時に安定版へ巻き戻せるまでを、デモとして短く説明できるようにする。

## 問題
実装やレビューまで見えても、実際のデリバリーと障害時の復旧が見えないと、業務ユーザーには「本当に現場で使えるのか」が伝わりにくい。

## 境界
- 対象範囲:
  - OpenShift 上の Tekton パイプラインによるビルドとイメージ更新
  - Argo CD による GitOps 同期
  - Git の履歴を使ったデモ向けロールバック導線
  - `focus-time-timer` を対象にした最小構成
- 対象外:
  - 本番レベルのマルチクラスタ設計
  - 複雑な認可設計や秘密情報管理の最終形
  - 複数環境にまたがる昇格フロー

## 成功シグナル
1. 開発変更から OpenShift 反映までの責務分離を説明できる。
2. 不具合時に GitOps の変更を戻せば安定版へ復旧できることを示せる。
3. デモ参加者が Tekton と Argo CD の役割差を理解できる。

## 下流成果物
- 想定する実装仕様:
  - Tekton + Argo CD による OpenShift デプロイデモ
- 想定する運用資産:
  - デプロイとロールバックの実演手順

## 参考
- `docs/product/concepts/business-demo-development-loop.md`
- `docs/traceability/intents/in-intent-001-business-request-to-reviewed-deployment-flow.md`
- `docs/traceability/intents/in-intent-002-focus-time-timer-mvp.md`
