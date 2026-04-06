# 意図

- intent_id: intent-004
- title: Traceability チェックによる変更整合性ゲート
- owner: shared
- status: draft
- created_at: 2026-04-04
- updated_at: 2026-04-04
- related_value_streams:
  - docs/traceability/value-streams/vs-intent-001-business-request-to-reviewed-deployment.md
  - docs/traceability/value-streams/vs-intent-003-openshift-gitops-rollout-rollback.md
- related_enablers:
  - intent-000
  - intent-001
  - intent-003

## 望む変化
Product Vision を上位の正本として、要求、仕様、実装、レビュー、運用資産のつながりを変更ごとに確認し、不足や不整合をレビュー前とデプロイ前に検出できるようにする。

## 問題
AI 支援で実装速度が上がるほど、変更が既存 intent や spec、runbook、さらに product vision とずれたまま進むリスクも上がる。現状のトレーサビリティ資産は整備されていても、変更時に継続して確認するゲートがない。

## 境界
- 対象範囲:
  - `docs/product/vision.md` と intent / spec / 実装の方向整合の確認
  - `docs/traceability/intent-registry.md` を基点にした関係整合の確認
  - intent / proposal / spec / expected output / operations 資産の不足検出
  - 実装変更に対して必要な traceability 更新有無の判定
  - レビュー前およびデプロイ前に実行できる変更整合性チェック
- 対象外:
  - すべての設計妥当性を完全自動で保証すること
  - 本番監視データを使った運用異常検知そのもの
  - ツール固有機能に依存した専用 UI の定義

## 成功シグナル
1. 変更に対応する traceability 資産の不足やリンク切れを機械的に検出できる。
2. 実装変更が product vision と既存 intent の範囲内か、追加資産が必要かをレビュー前に判断できる。
3. OpenShift デモ向け変更で runbook や rollback 観点の更新漏れをデプロイ前に検出できる。
4. デモ参加者に対して、AI 支援開発が速いだけでなく統制されたゲートを通っていると説明できる。

## 下流成果物
- 想定する基盤提案:
  - Traceability チェック基盤
- 想定する機能提案:
  - 変更整合性チェックフロー
- 想定する UI 仕様:
  - 必要に応じて結果表示用の最小画面またはレポート形式
- 想定する実装仕様:
  - traceability 静的検査スクリプト
  - AI 支援による変更整合性判定フロー

## 参考
- `docs/product/vision.md`
- `docs/traceability/intent-registry.md`
- `docs/traceability/intents/in-intent-001-business-request-to-reviewed-deployment-flow.md`
- `docs/traceability/intents/in-intent-003-openshift-gitops-rollout-rollback-demo.md`
- `docs/product/concepts/business-demo-development-loop.md`
