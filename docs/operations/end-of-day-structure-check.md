# 日次構造チェック

- checklist_id: end-of-day-structure-check
- owner: shared
- status: draft
- created_at: 2026-03-30
- updated_at: 2026-03-30

## 目的
意味のある変更を入れた日の終わりに、構造と追跡可能性が崩れていないかを軽く確認する。

## チェック項目
1. プロダクト正本:
   現在のプロダクト前提は `docs/product/` に反映されているか
2. 追跡リンク:
   非自明な作業は意図または提案に結びついているか
3. 資産境界:
   要件・設計資産と将来の本番・検証資産が混ざっていないか
4. レジストリ整合:
   `docs/traceability/intent-registry.md` は現在の主要文書を反映しているか
5. 意思決定整理:
   重要な方針転換があったなら ADR を追加すべきではないか
