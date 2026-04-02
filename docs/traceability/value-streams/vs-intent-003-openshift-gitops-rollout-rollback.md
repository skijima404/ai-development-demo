# 価値の流れ

- intent_id: intent-003
- title: OpenShift への GitOps デプロイとロールバック
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-04-02
- related_enablers:
  - intent-000
  - intent-001
  - intent-002

## 目的
レビュー済みの変更が OpenShift に反映され、問題発生時には安定版へ巻き戻せることを、デモとして一続きで示す。

## 開始条件
- `focus-time-timer` のソースとコンテナ化資産がリポジトリに存在する
- OpenShift クラスタに Tekton と Argo CD が導入されている
- Git リポジトリを Argo CD が参照できる

## 価値の流れ
1. ソース変更:
   `src/focus-time-timer/` のアプリ変更が main 系ブランチへ取り込まれる。
2. Tekton 実行:
   パイプラインがソースを取得し、フロントエンドをビルドし、コンテナイメージを生成する。
3. GitOps 更新:
   パイプラインが GitOps マニフェストのイメージタグを書き換えてコミットする。
4. Argo CD 同期:
   Argo CD が差分を検知し、OpenShift 上の Deployment を更新する。
5. 動作確認:
   デモ参加者が新機能または不具合を確認する。
6. ロールバック:
   GitOps 側のイメージタグを前の安定版へ戻し、Argo CD で再同期する。

## 運用境界
- Tekton が受け持つのは、アプリ実装変更からイメージ生成と GitOps 更新までとする。
- Argo CD が受け持つのは、GitOps オーバーレイを OpenShift の実状態へ同期することとする。
- GitOps オーバーレイのみの変更は Argo CD だけで反映し、Tekton を再起動しない。
- 自動更新コミットが再度パイプラインを起動してループしないことを前提とする。

## 段階ごとの価値
- ソース変更:
  - 何を変えたかが Git に残る
- Tekton 実行:
  - ビルド責務が手作業から切り離される
- GitOps 更新:
  - デプロイ対象の正本が Git に残る
- Argo CD 同期:
  - クラスタ反映が宣言的に説明できる
- 動作確認:
  - 新版の価値とリスクが見える
- ロールバック:
  - 安定版へ戻す経路を短く示せる

## 重要なプロダクト仮説
- デプロイとロールバックが見えるほど、AI 支援開発への心理的抵抗は下がる
- GitOps で環境状態を Git に寄せるほど、業務ユーザーにも復旧手順を説明しやすい
- デモでは高度な運用より、役割分離と巻き戻し可能性を明示することが重要である

## この価値の流れの失敗モード
- Tekton がイメージを作っても、GitOps 側が更新されず反映責務が曖昧になる
- Argo CD の同期対象が不明瞭で、どの状態が正本か説明できない
- ロールバック手順が口頭説明のみで、再現できない

## 必須の支援資産
- `docs/product/expected-outputs/deployment-rollback-demo.md`
- `docs/operations/openshift-demo-rollout-rollback-runbook.md`
- `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml`
- `deploy/openshift/tekton/focus-time-timer-pipeline.yaml`
- `deploy/openshift/argocd/focus-time-timer-application.yaml`
