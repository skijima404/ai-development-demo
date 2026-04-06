# 実装仕様

- intent_id: intent-004
- title: Traceability チェックによる変更整合性ゲート
- owner: shared
- status: draft
- created_at: 2026-04-04
- updated_at: 2026-04-04
- related_enabler_proposal: docs/traceability/enabler-proposals/ep-intent-004-traceability-check-gate.md
- depends_on_enablers:
  - intent-000
  - intent-001
  - intent-003

## 基盤との整合
この実装は、`docs/product/vision.md`、`docs/traceability/intent-registry.md`、各 intent / proposal / spec / operations 資産をもとに、業務ユーザーの要求から実装着手、レビュー、デプロイ準備までの間に変更整合性を確認するゲートを具体化する。目的は、AI 支援による速度向上と、要求や運用文脈からの逸脱防止を両立させることにある。

## 目標
次のことを実現する。
- 業務ユーザーの「これを作って」という要求から、既存 intent の範囲内か新規 intent が必要かを判断できる。
- Requirement から Development へ進む前に、欠落した traceability 資産や product vision との不整合を検出できる。
- レビュー前とデプロイ前に、runbook、expected output、rollback 観点の更新漏れを検出できる。
- 検査結果を、`stop するエラー`、`警告として流す項目`、`レビュー観点として残す項目` に分けて出力できる。

## チェック目的
- 目的 1:
  - product vision に反する変更や、意図不明の実装着手を早期に止める。
- 目的 2:
  - traceability 資産の欠落や参照切れを、レビュー後半ではなく実装前後で見つける。
- 目的 3:
  - すぐ止めるほどではないが、レビューや運用引き継ぎで確認すべき観点を警告として残す。
- 目的 4:
  - `docs/product/vision.md` や ADR のような上位正本変更を、通常の機能要求と混同せずに扱う。

## 判定モデル
- blocking error:
  - Requirement から Development へ進めると、変更の正当性または追跡性を失うもの
  - パイプラインを停止対象とする
- warning:
  - 実装やレビューは継続できるが、追加確認や資産補完が必要なもの
  - パイプラインは継続可能だが、結果に明示する
- advisory:
  - 品質向上や将来の運用に有用だが、現時点で通過条件にはしないもの
  - レビュー観点として記録する

## 自動修正方針
- 自動修正してよいもの:
  - `intent-registry` への定型追記
  - 既知テンプレートに基づく必須メタデータ不足の補完
  - 明白な関連文書パスの追記
  - 定型節の不足補完
- 提案にとどめるもの:
  - product vision との意味整合の修正
  - 新規 intent 作成が妥当かどうかの判断
  - スコープ逸脱や対象外越境の解釈が必要な修正
  - 文書構造の大きな再編
- 運用原則:
  - 機械的に一意に直せる書き漏れは、その場で自動修正して再チェックする
  - 複数解釈がありうるものは修正案として提示し、人間判断を残す

## 上位正本変更モード
- 対象:
  - `docs/product/vision.md` の更新要求
  - MVP 範囲、対象外、成功指標、プロダクトゴールの変更要求
  - `docs/decisions/` に記録すべき大きな方針転換
- 基本方針:
  - 通常の Requirement -> Development ゲートとは別に扱う
  - 現在の vision を絶対基準にして即座に blocking しない
  - まず「上位正本変更提案」として分類し、影響資産を洗い出してから再判定する
- 期待する動作:
  - 変更要求を受けた時点で `top_level_source_change` として分類する
  - 影響先として value streams, intents, proposals, implementation specs, expected outputs, operations を列挙する
  - 必要に応じて ADR 追加要否を warning または advisory で返す
  - 上位正本更新後に、通常ゲートを新しい正本で再実行する
- blocking error:
  - vision や上位方針を実質変更しているのに、通常機能要求として実装へ進めようとする
  - 上位正本変更後の影響資産更新を完全に無視している
- warning:
  - vision 変更は妥当そうだが、関連する value stream や intent の追随が未整理
  - ADR を残すべき規模の方針転換かが未判断
- advisory:
  - 文言の明確化中心で、影響資産が限定的と見込まれる
  - ADR は不要だが、運用メモ更新があるとよい

## ゲートごとの判定方針
- 要求整理ゲート:
  - blocking error:
    - `docs/product/vision.md` と明確に矛盾する
    - 既存 intent の範囲外なのに、新しい intent が作成されていない
  - warning:
    - 既存 intent のどれに近いか曖昧で、追加確認が必要
    - 対象ユーザー価値や対象外境界の記述が弱い
  - special handling:
    - 要求自体が vision, goal, MVP, ADR 対象なら上位正本変更モードへ切り替える
- 仕様化ゲート:
  - blocking error:
    - `docs/traceability/intent-registry.md` に intent が存在しない
    - 必須の下流資産参照が存在しない、またはリンク切れ
  - warning:
    - proposal / spec / expected output / operations 資産のうち、変更影響がありそうなものが未整備
    - value stream への位置づけが不十分
- 実装着手ゲート:
  - blocking error:
    - 実装対象に対応する intent / spec の根拠がない
    - 明示的な対象外を越える変更なのに、資産更新がない
  - warning:
    - 実装変更に対して必要な operations / expected output 更新先が未確定
    - product vision との距離があり、レビュー観点追加が望ましい
- レビューゲート:
  - blocking error:
    - 参照切れ、必須資産欠落、更新漏れが残ったまま
    - intent / spec / code の意味ずれが重大で、変更意図を説明できない
  - warning:
    - 意味ずれの疑いがあるが、人間レビューで判断可能
    - レビューパッケージに追加観点が必要
- デプロイ準備ゲート:
  - blocking error:
    - OpenShift / GitOps 変更なのに rollback 観点が説明できない
    - runbook または expected output の更新が必須なのに未反映
  - warning:
    - デプロイ引き継ぎの説明が弱い
    - 運用向け確認観点が十分に構造化されていない

## AI 可読性チェック観点
- blocking error:
  - stable identifier が欠落し、資産を一意に参照できない
  - 必須節が欠落し、文書の責務や境界を判定できない
  - path 参照が曖昧で、関連資産へ到達できない
- warning:
  - 対象範囲 / 対象外 / 禁止事項が弱く、境界が曖昧
  - 成功基準やゲート条件が観測可能な形で書かれていない
  - 暗黙参照が多く、どの正本に依拠するか分かりにくい
  - `適切に`、`必要に応じて`、`十分に` のような曖昧語が多い
- advisory:
  - 段落が長く、構造的な抽出がしにくい
  - 節粒度がばらつき、類似文書との比較がしづらい
  - 人向けには読めるが、次の AI が再利用しやすい形式になっていない

## AI 可読性チェックの目的
- 目的 1:
  - 次の AI が、どの資産を正本として読むべきか迷わないようにする
- 目的 2:
  - 人と AI の両方が、境界、成功基準、禁止事項を同じ解釈で読めるようにする
- 目的 3:
  - 書き漏れだけでなく、AI にとって誤読しやすい記述を早めに警告する

## スコープ
- 対象範囲:
  - 静的検査ルールの定義
  - AI 支援による意味整合チェックの判定方針
  - 文書の AI 可読性チェック観点
  - 自動修正可能項目と提案止まり項目の境界定義
  - 上位正本変更モードの分類と再判定方針
  - Requirement -> Development, Review, Deployment Readiness 各ゲートでの severity 設計
  - Markdown および JSON を想定した結果出力仕様
- 対象外:
  - OpenShift の実監視イベント解析
  - 本番環境の自動承認フロー
  - 特定ベンダー専用の agent 定義機構

## 変更契約
- 許可される変更:
  - ゲートごとのチェック項目追加
  - blocking / warning / advisory の分類見直し
  - 結果レポート形式の改善
- 禁止される変更:
  - product vision 整合を無視して Requirement から Development へ進めること
  - 参照切れや intent 不在を warning に格下げすること
  - 上位正本変更を通常機能要求に偽装して実装へ進めること
- 承認が必要:
  - blocking 条件の大幅緩和
  - Review / Deployment Readiness のゲートを省略する運用への変更
- 検証:
  - 代表的な欠落ケースで blocking error が出ること
  - 曖昧だが即停止不要のケースで warning が出ること
  - レビュー補助観点が advisory として出力できること
  - 自動修正対象は実際に補完後に再チェックできること
- 巻き戻し:
  - 誤検知が多い AI 判定ルールは warning または advisory に一時的に下げる

## 実行メモ
- 変更してよいファイル:
  - `docs/product/**`
  - `docs/traceability/**`
  - `docs/operations/**`
  - `scripts/**`
- 明示的に対象外のファイル:
  - 業務アプリ固有の本番機能コードそのもの
- リスク:
  - blocking 条件を増やしすぎると、要求整理の初期速度を落とす
  - warning を広げすぎると、実質的に誰も見なくなる
  - AI 判定を早く強制ゲートにしすぎると、誤検知への不信感を招く
  - 自動修正範囲を広げすぎると、意味判断が必要な変更まで暗黙に書き換えてしまう
  - 上位正本変更モードがないと、MVP 後の正当な方向転換まで誤って blocking する

## 実装の流れ
1. ゲート一覧と、各ゲートで守るべきチェック目的を定義する。
2. 静的検査で扱う項目を、存在確認、参照整合、メタデータ整合、更新対象判定に分解する。
3. AI 支援で扱う項目を、vision / intent / spec / code の意味整合と、運用観点の不足検出に限定する。
4. blocking error、warning、advisory の判定条件をゲートごとに定義する。
5. 自動修正してよい書き漏れと、提案止まりにすべき修正を分離する。
6. 文書の AI 可読性チェック観点を severity ごとに定義する。
7. vision / MVP / goal / ADR 対象の要求を、上位正本変更モードへ振り分ける条件を定義する。
8. Markdown レポートと JSON 出力の最低限の結果形式を決める。
9. Requirement -> Development では静的検査中心、Review / Deployment Readiness では AI 支援判定を補助的に使う方針を明示する。

## 出力仕様
- Markdown レポート:
  - ゲート名
  - 判定結果
  - 判定モード
  - 自動修正実施有無
  - blocking error 一覧
  - warning 一覧
  - advisory 一覧
  - 推奨される次アクション
- JSON:
  - `gate_id`
  - `status`
  - `mode`
  - `findings`
  - `auto_fixes_applied`
  - `required_updates`
  - `suggested_review_points`

## 検証
1. product vision に反する要求例で、要求整理ゲートが blocking error を返すことを確認する。
2. intent 未登録やリンク切れのケースで、仕様化ゲートが blocking error を返すことを確認する。
3. 実装変更に対して operations 更新先が未確定のケースで、実装着手ゲートが warning を返すことを確認する。
4. OpenShift / GitOps 変更で rollback 観点がないケースで、デプロイ準備ゲートが blocking error を返すことを確認する。
5. 意味的なずれが軽微なケースでは、AI 支援判定が warning または advisory を返すことを確認する。
6. registry 追記や定型節補完のような書き漏れが自動修正され、再チェック後に結果へ反映されることを確認する。
7. stable identifier 欠落や曖昧語過多の文書で、AI 可読性チェックが blocking error または warning を返すことを確認する。
8. vision や MVP の変更要求を通常機能要求としてではなく、上位正本変更モードとして分類できることを確認する。
9. ADR が必要な方針転換で、関連資産更新と意思決定記録要否を warning または advisory として返せることを確認する。
