# 基盤提案

- intent_id: intent-003
- title: OpenShift デモ向け GitOps デプロイとロールバック基盤
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-04-02
- enables:
  - intent-001
  - intent-002

## 目的
`focus-time-timer` を題材として、Tekton によるビルドと GitOps 更新、Argo CD による OpenShift 反映、Git 変更の巻き戻しによる復旧を、一つのデモとして成立させる。

## 問題
デモアプリが動いていても、配備のしかたと失敗時の戻し方が見えないと、現場導入を想像しにくい。

## 資産定義
次の資産を、この基盤の正本として扱う。
- GitOps マニフェスト:
  - `deploy/gitops/focus-time-timer/base/`
  - `deploy/gitops/focus-time-timer/overlays/demo/`
- OpenShift 連携資産:
  - `deploy/openshift/tekton/focus-time-timer-pipeline.yaml`
  - `deploy/openshift/argocd/focus-time-timer-application.yaml`
- 運用資産:
  - `docs/operations/openshift-demo-rollout-rollback-runbook.md`

## 成功基準
1. Tekton と Argo CD の責務が分離された構成になっている。
2. デプロイ状態の正本が GitOps マニフェストとして Git に残る。
3. 前の安定イメージタグへ戻す手順が 1 つの runbook で示されている。
4. GitOps オーバーレイのみの変更で Tekton が再起動しない。

## スコープ
- 対象範囲:
  - `focus-time-timer` の GitOps ベース/オーバーレイ定義
  - Argo CD Application
  - Tekton Pipeline, TriggerTemplate, EventListener
  - デモ用ロールバック手順
- 対象外:
  - プロダクション品質の secrets 運用
  - 本番監視、通知、承認ゲートのフル実装
  - Blue/Green や Canary など高度な配備方式

## 運用上の使い方
- 意図がこの資産をどう参照すべきか:
  - デプロイと復旧を含むデモ範囲の正本として参照する
- 機能提案がこの資産をどう参照すべきか:
  - `focus-time-timer` のような下流機能が、どう配備されるかの土台として参照する
- 実装仕様がこの資産をどう参照すべきか:
  - GitOps の正本位置、Tekton/Argo CD の責務分離、runbook の存在を前提として詳細化する

## 現在の設計意図
- Tekton は `src/focus-time-timer/` の変更を起点にビルドと GitOps 更新を行う。
- Argo CD は `deploy/gitops/focus-time-timer/overlays/demo` の宣言状態だけを見て同期する。
- `deploy/gitops/**` のみの変更はロールバックや版固定のための GitOps 操作として扱い、Tekton の再起動条件に含めない。
- GitHub 上で GitOps の `newTag` を前の版へ戻せば、Argo CD によるロールバックが成立する構成を目指す。

## 変更契約
- 許可される変更:
  - GitOps 構造の追加
  - Tekton / Argo CD 用マニフェストの追加
  - ロールバック手順書の追加
- 禁止される変更:
  - 既存のアプリ機能に無関係な大規模再設計
  - 本番運用の正解と誤認される過剰な作り込み
- 承認が必要:
  - 外部レジストリや外部 Git リポジトリへの依存を前提にする変更
  - デモの主眼を外れる複数環境昇格フローの導入
- 検証:
  - Tekton -> GitOps 更新 -> Argo CD 同期 -> ロールバックの経路が資産として読めること
- 巻き戻し:
  - GitOps オーバーレイのイメージタグを前の安定コミットへ戻す

## 未解決事項
- [ ] `repoURL` とレジストリ名を実クラスタ値へ置き換える
- [ ] Git push 認証情報の配布方法を環境に合わせて確定する

## 参考
- `docs/traceability/intents/in-intent-003-openshift-gitops-rollout-rollback-demo.md`
- `docs/traceability/value-streams/vs-intent-003-openshift-gitops-rollout-rollback.md`
- `deploy/openshift/focus-time-timer.yaml`
