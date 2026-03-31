# AI 開発デモ

業務ユーザー向けに、AI を使った開発の流れを「要求整理 -> 仕様化 -> 実装 -> レビュー -> コミット/デプロイ準備 -> GitOps デプロイ/ロールバック」まで見せるためのデモ用リポジトリです。

## 目的
このリポジトリは、RPA や Excel VBA の代替となりうる AI 支援開発の実務的な姿を見せるための作業基盤です。

デモでは、次の流れが見えることを重視します。
1. ユーザーが業務要求を AI に説明する
2. AI とユーザーが要件を具体化する
3. AI が実装資産を作る
4. 人間がレビューする
5. コミットやデプロイ準備まで一連で扱える
6. デプロイ後に不具合が見つかった場合のロールバックも見せられる

現時点では、具体的なデモアプリ実装の前段として、AI ネイティブな追跡可能性の基盤を整備しています。

加えて、`focus-time-timer` を題材に、Tekton と Argo CD を使った OpenShift 向けの GitOps デプロイデモ資産を含みます。

## 現在のスコープ
- 永続的に使える追跡可能性の骨格を作る
- 現時点の正本情報をチャットではなくリポジトリに残す
- 今後の仕様、UI、実装計画、運用ルールが接続できる構造を用意する

## 追跡モデル
このリポジトリで現在採用している基本チェーンは次の通りです。

1. `docs/product/vision.md`
2. `docs/traceability/value-streams/`
3. `docs/traceability/intents/`
4. `docs/traceability/enabler-proposals/` と `docs/traceability/feature-proposals/`
5. `docs/traceability/ui-specs/`
6. `docs/traceability/implementation-specs/`

補助的な正本・運用資産:
- `AGENTS.md`
- `docs/operations/`
- `docs/decisions/`
- `docs/product/expected-outputs/`

## 現在のディレクトリ構成
- `docs/product/`: プロダクトの現時点の正本、コンセプト、期待出力
- `docs/traceability/`: 意図、提案、仕様、レジストリなどの接続資産
- `docs/operations/`: 運用ルールとチェックリスト
- `docs/decisions/`: 重要な方針転換の履歴
- `deploy/gitops/`: Argo CD が参照する GitOps マニフェスト
- `deploy/openshift/`: OpenShift, Tekton, Argo CD 向けの適用資産

## 現在の主要資産
- `docs/product/vision.md`
- `docs/product/concepts/business-demo-development-loop.md`
- `docs/traceability/intent-registry.md`
- `docs/traceability/value-streams/vs-intent-001-business-request-to-reviewed-deployment.md`
- `docs/traceability/intents/in-intent-000-ai-native-traceability-scaffold.md`
- `docs/traceability/intents/in-intent-001-business-request-to-reviewed-deployment-flow.md`
- `docs/traceability/enabler-proposals/ep-intent-000-ai-native-traceability-scaffold.md`
- `docs/traceability/feature-proposals/fp-intent-001-business-request-to-reviewed-deployment-flow.md`
- `docs/traceability/implementation-specs/is-intent-000-repository-bootstrap.md`
- `docs/traceability/implementation-specs/is-intent-003-tekton-argocd-openshift-pipeline-demo.md`
- `deploy/openshift/tekton/focus-time-timer-pipeline.yaml`
- `deploy/openshift/argocd/focus-time-timer-application.yaml`

## 次のステップ
次のリポジトリ作業では、この骨格の上で具体的なデモアプリ仕様を作成し、実装やレビューの作業が自然に追跡チェーンへ接続される状態を作ります。
