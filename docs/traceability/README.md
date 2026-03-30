# 追跡可能性領域

目的: 業務要求、プロダクトスコープ、実装計画を、永続的かつリンク可能な形で管理する。

## 構成
- `intent-registry.md`: 意図と関連資産の正本インデックス
- `intents/`: 何を変えたいのかを表す持続的な単位
- `enabler-proposals/`: 複数の機能や作業フローが依存する基盤資産
- `feature-proposals/`: ユーザー向けまたは作業フロー向けの機能提案
- `ui-specs/`: 画面・操作・レビュー導線の仕様
- `value-streams/`: エンドツーエンドの価値の流れ
- `implementation-specs/`: 実装フェーズ向けの具体化仕様

## 基本ワークフロー
1. `docs/product/` の現時点の正本を定義または更新する
2. 対象の価値の流れを定義する
3. 関連する意図を定義または更新する
4. 再利用可能な基盤が必要なら基盤提案を作る
5. ユーザー向けの変化があるなら機能提案を作る
6. 実行スコープが固まったら UI 仕様と実装仕様を作る
7. `intent-registry.md` を更新する

## 開発ゲート
- 非自明な作業は、この領域の意図または提案に結びついてから進めます。
- 軽微な修正は、既存スコープ内であれば新しい意図を作らなくても構いません。

## 命名規則
- Intent: `in-intent-###-<slug>.md`
- Enabler Proposal: `ep-intent-###-<slug>.md`
- Feature Proposal: `fp-intent-###-<slug>.md`
- User Interaction Spec: `ui-intent-###-<slug>.md`
- Value Stream: `vs-intent-###-<slug>.md`
- Implementation Spec: `is-intent-###-<slug>.md`
- Intent ID: `intent-###`
