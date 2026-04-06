# 意図

- intent_id: intent-001
- title: 業務要求からレビュー済みデプロイ準備までのフロー
- owner: shared
- status: draft
- created_at: 2026-03-30
- updated_at: 2026-04-04
- related_value_streams:
  - docs/traceability/value-streams/vs-intent-001-business-request-to-reviewed-deployment.md
- related_enablers:
  - intent-000
  - intent-004

## 望む変化
業務ユーザー向けの AI 開発の流れを、要求受付からコミット・デプロイ準備まで、理解しやすくレビュー可能な形で見せられるようにする。

## 問題
AI 開発はコード生成だけで語られがちで、業務側から見ると要件整理、レビュー、デリバリー統制がどうつながるのか分かりにくい。

## 境界
- 対象範囲:
  - 要求説明と要件具体化の流れ
  - 仕様と実装の結びつき
  - 人間レビュー
  - コミットとデプロイ準備の可視化
- 対象外:
  - 完全自律なソフトウェア工場の主張
  - 人間レビューの排除
  - 詳細な本番インフラ設計

## 成功シグナル
1. 業務ユーザーが要求からレビューパッケージまでの流れを追える。
2. 実装がリポジトリ資産との関係で説明できる。
3. コミットとデプロイ準備が境界のある工程として見える。

## 下流成果物
- 想定する基盤提案:
  - AI ネイティブなトレーサビリティ基盤
- 想定する機能提案:
  - 業務要求からレビュー済みデプロイ準備までのフロー
- 想定する UI 仕様:
  - 要求・レビュー・デプロイ画面
- 想定する実装仕様:
  - 今後追加するデモアプリ固有の実装仕様

## 参考
- `docs/product/vision.md`
- `docs/product/concepts/business-demo-development-loop.md`
