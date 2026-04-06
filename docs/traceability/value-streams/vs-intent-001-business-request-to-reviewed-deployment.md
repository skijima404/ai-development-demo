# 価値の流れ

- intent_id: intent-001
- title: 業務要求からレビュー済みデプロイ準備まで
- owner: shared
- status: draft
- created_at: 2026-03-30
- updated_at: 2026-04-04
- related_enablers:
  - intent-000
  - intent-004
- related_feature_proposals:
  - intent-001

## 目的
業務要求が、AI 支援による要件具体化、実装、レビュー、デプロイ準備までどう価値として流れるかを記述する。

## 開始条件
- 業務関係者が業務上の必要や自動化要求を持っている
- このリポジトリが持続的なデリバリー作業基盤として使われる
- AI 支援が要求整理と実装支援に利用できる

## 価値の流れ
1. 要求受付:
   業務ユーザーが課題を自然言語で説明する。
2. 要求整理ゲート:
   Product Vision と既存 intent を基に、この変更が既存範囲か新規 intent 作成対象かを判定する。
3. 要件具体化:
   AI が確認質問を行い、要求を構造化する。
4. 仕様化ゲート:
   必要な intent / proposal / spec / expected output / operations 資産の有無を確認し、不足資産を補う。
5. 追跡可能な仕様化:
   現時点の正本が product / traceability 文書に記録される。
6. 実装着手ゲート:
   実装対象と spec の対応、対象外境界、運用影響の更新先を確認する。
7. 実装:
   AI が合意済みの境界の中でコードや関連資産を生成する。
8. レビューゲート:
   vision / intent / spec / code / operations の整合性と、traceability 更新漏れを確認する。
9. レビュー:
   人間レビュアーが関連する意図とレビューパッケージを基に確認する。
10. デプロイ準備ゲート:
   expected output、runbook、rollback 観点、GitOps 影響の説明責務を満たしているか確認する。
11. コミットとデプロイ準備:
   変更が引き継ぎ可能なデリバリー準備として整理される。

## 段階ごとの価値
- 要求受付:
  - 業務ユーザーが業務の言葉で話せる
- 要求整理ゲート:
  - 作りたいものが product vision と既存意図に照らして説明可能になる
- 要件具体化:
  - 曖昧さを減らせる
- 仕様化ゲート:
  - 必要な正本資産の不足を実装前に減らせる
- 追跡可能な仕様化:
  - なぜその変更が必要かをリポジトリに残せる
- 実装着手ゲート:
  - 実装境界と下流更新対象が先に明確になる
- 実装:
  - AI が構造化された要求から成果物を作れると示せる
- レビューゲート:
  - 変更整合性を人間レビュー前に整理できる
- レビュー:
  - 人間の判断が残る
- デプロイ準備ゲート:
  - 運用引き継ぎと巻き戻し責務を明示できる
- コミットとデプロイ準備:
  - デリバリーが現実的な工程として見える

## ゲート定義
- 要求整理ゲート:
  - `docs/product/vision.md` と矛盾しない
  - 既存 intent の範囲内か、新しい intent が必要かを判断できる
  - 想定ユーザー価値と対象外が説明できる
- 仕様化ゲート:
  - `docs/traceability/intent-registry.md` に intent が登録されている
  - 必要な proposal / spec / expected output / operations 資産の不足が列挙されている
  - 変更が value stream 上のどの工程に影響するかを示せる
- 実装着手ゲート:
  - 実装対象と spec の対応がある
  - 対象外境界を越えていない
  - OpenShift や運用影響がある場合、更新対象の `docs/operations/` または `docs/product/expected-outputs/` が決まっている
- レビューゲート:
  - traceability の参照切れ、資産不足、更新漏れが検出されている
  - product vision、intent、spec、実装差分の意味的なずれが確認されている
  - レビューパッケージに確認観点とリスクが含まれている
- デプロイ準備ゲート:
  - expected output と runbook が最新の変更内容を反映している
  - rollback 観点が説明可能である
  - GitOps / deployment 変更時に、誰が何を引き継ぐか明示されている

## 重要なプロダクト仮説
- 要求整理とレビューが見えるほど、業務ユーザーの信頼は上がる
- AI 生成は、リポジトリ資産と結びついているほど説明可能になる
- 変更整合性ゲートがあるほど、業務ユーザーの「速いが雑ではない」という信頼が上がる
- デプロイ準備は別工程ではなく、同じ作業フローの延長として見せるべきである

## この価値の流れの失敗モード
- 要求が曖昧すぎてレビュー可能な範囲にならない
- product vision に合わない変更が、既存要求の延長として進んでしまう
- コード生成だけが見えて仕様の追跡線がない
- 必要な traceability 資産の不足がレビュー後半まで見つからない
- レビューが儀式化して意味を失う
- デプロイが暗黙に飛ばされ、引き継ぎが存在しない

## 必須の支援資産
- `docs/product/vision.md`
- `docs/product/concepts/business-demo-development-loop.md`
- `docs/product/expected-outputs/review-package.md`
- `docs/traceability/enabler-proposals/ep-intent-000-ai-native-traceability-scaffold.md`
- `docs/traceability/enabler-proposals/ep-intent-004-traceability-check-gate.md`
