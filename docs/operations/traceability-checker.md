# Traceability Checker

- checker_id: traceability-checker
- owner: shared
- status: draft
- created_at: 2026-04-04
- updated_at: 2026-04-04

## 目的
火曜日デモ向けの最小構成として、`docs/product/vision.md` と `docs/traceability/` を中心に、文書の追跡可能性と AI 可読性をレビューする。

## 現在の対象
- `docs/traceability/intent-registry.md` の参照整合
- `docs/traceability/` 配下の主要文書の必須メタデータと必須節
- 文書内で参照している `docs/`, `deploy/`, `scripts/`, `src/` パスの存在確認
- 境界記述や曖昧語に関する軽い AI 可読性チェック
- 要求文を受けたときの `standard_requirement` / `top_level_source_change` の軽いモード分類

## 現在の非対象
- 実装差分と spec の意味整合チェック
- OpenShift 実環境との接続確認
- 文書の自動修正

## 実行方法
1. レポート出力のみ:
   `node scripts/traceability/check-docs.mjs`
2. blocking error で失敗扱いにする:
   `node scripts/traceability/check-docs.mjs --fail-on-blocking`
3. 要求文も一緒に判定する:
   `node scripts/traceability/check-docs.mjs --request "所定の時刻が来たら鳴るようにして欲しい"`
4. Vision や MVP 変更を上位正本変更として扱う例:
   `node scripts/traceability/check-docs.mjs --request "MVP の対象外を見直して、所定時刻タイマーを入れたい"`

## 判定の使い方
- `blocking`:
  - Requirement から Development へ進める前に直す
- `warning`:
  - レビュー前までに補完する
- `advisory`:
  - 文書改善や AI 可読性向上の観点として扱う
- `mode: top_level_source_change`:
  - まず `docs/product/vision.md` や関連資産の更新を整理し、その後に通常ゲートへ戻す

## 今後の拡張候補
- 書き漏れの自動補完
- implementation spec とコード差分の突合
- OpenShift / GitOps 変更時の運用資産更新要否判定
