# 基盤提案

- intent_id: intent-004
- title: Traceability チェックによる変更整合性ゲート
- owner: shared
- status: draft
- created_at: 2026-04-04
- updated_at: 2026-04-04
- enables:
  - intent-001
  - intent-002
  - intent-003

## 目的
`docs/product/vision.md` を上位の正本として、intent、proposal、spec、実装、レビュー、運用資産の関係を継続的に確認し、変更の整合性をレビュー前およびデプロイ前に判定できる基盤を定義する。

## 問題
トレーサビリティ資産が存在していても、変更時にそれらを継続確認する仕組みがないと、実装だけが先行し、product vision や intent、runbook とのずれがレビュー後半やデプロイ直前まで発見されない。

## 資産定義
この基盤は次の資産で構成する。
- 上位正本:
  - `docs/product/vision.md`
  - `docs/product/concepts/business-demo-development-loop.md`
- トレーサビリティ正本:
  - `docs/traceability/intent-registry.md`
  - `docs/traceability/intents/`
  - `docs/traceability/enabler-proposals/`
  - `docs/traceability/feature-proposals/`
  - `docs/traceability/implementation-specs/`
  - `docs/traceability/ui-specs/`
  - `docs/traceability/value-streams/`
- デリバリー・運用正本:
  - `docs/product/expected-outputs/`
  - `docs/operations/`
- 検査資産:
  - traceability の静的検査スクリプト
  - 変更整合性レポートの出力仕様
  - 必要に応じて AI 支援による意味整合チェックのプロンプト資産

## 成功基準
1. `intent-registry` を基点に、存在しない参照、欠落した下流資産、更新漏れを機械的に検出できる。
2. 実装差分に対して、`docs/product/vision.md` と既存 intent の範囲内か、追加資産が必要かを判定できる。
3. OpenShift デモ向けの変更で、runbook、rollback、expected output の更新漏れをデプロイ前に検出できる。
4. レビュー時に、変更整合性レポートを人間レビュアーが確認材料として使える。

## スコープ
- 対象範囲:
  - リンク整合、存在確認、メタデータ整合などの静的検査
  - product vision と intent / spec / 実装差分の方向整合確認
  - 実装変更に応じた traceability / operations 資産の更新要否判定
  - レビュー前およびデプロイ前に実行するゲート設計
- 対象外:
  - すべての設計妥当性や業務妥当性の完全自動保証
  - OpenShift 監視イベントのリアルタイム解析
  - 特定 AI ベンダーの UI や機能に依存した実装前提

## 運用上の使い方
- 意図がこの資産をどう参照すべきか:
  - 非自明な変更の intent は、この基盤に従って必要な下流資産と整合チェック観点を明示する。
- 機能提案がこの資産をどう参照すべきか:
  - 機能提案は、product vision と intent のどの範囲を実現するかを明示し、必要な spec や expected output を結びつける。
- 実装仕様がこの資産をどう参照すべきか:
  - 実装仕様は、対象ファイル境界だけでなく、関連する runbook、review package、deployment 資産への影響も示す。

## 現在の設計意図
- 静的検査は、存在確認、参照整合、必須メタデータ確認を担当する。
- AI 支援判定は、product vision、intent、spec、実装差分の意味的なずれや不足を補助的に判定する。
- 実装変更の種類ごとに、必要な traceability 更新対象をルール化する。
- OpenShift 関連変更では、`docs/operations/` と `docs/product/expected-outputs/` の更新要否も確認対象に含める。
- 検査結果は、単なる pass/fail だけでなく、不足資産、追加推奨資産、レビュー観点をレポートとして返す。

## 変更契約
- 許可される変更:
  - 静的検査ルールの追加
  - 変更整合性レポート項目の追加
  - product vision や traceability 構造に追随するルール更新
- 禁止される変更:
  - 実装先行を正当化するためにゲートを無効化すること
  - 特定ツール専用の実行前提を repo 標準ルールとして埋め込むこと
- 承認が必要:
  - `intent-registry` の段階定義や proposal 種別定義を変更すること
  - product vision を参照しない運用へ後退させること
- 検証:
  - 意図、提案、仕様、運用資産の代表ケースで、不足や参照切れを再現可能に検出できること
  - 実装変更ケースで、追加すべき traceability 資産候補をレポートに含められること
- 巻き戻し:
  - 誤検知が強いルールは個別に無効化または前版へ戻し、資産正本自体は維持する

## 未解決事項
- [ ] 変更種別ごとの必須更新対象をどの粒度でルール化するか
- [ ] AI 支援判定の結果を fail 条件にするか、警告にとどめるか
- [ ] レビュー時の出力形式を Markdown レポート、JSON、両方のどれにするか

## 参考
- `docs/product/vision.md`
- `docs/product/concepts/business-demo-development-loop.md`
- `docs/traceability/intents/in-intent-004-traceability-check-gate.md`
- `docs/traceability/intents/in-intent-001-business-request-to-reviewed-deployment-flow.md`
- `docs/traceability/intents/in-intent-003-openshift-gitops-rollout-rollback-demo.md`
- `docs/operations/review-checklist.md`
