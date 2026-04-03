# 実装仕様

- intent_id: intent-003
- title: Tekton + Argo CD による OpenShift デプロイデモ
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-04-02
- related_enabler_proposal: docs/traceability/enabler-proposals/ep-intent-003-openshift-gitops-rollout-rollback-demo.md
- depends_on_enablers:
  - intent-000
  - intent-001
  - intent-002

## 基盤との整合
この実装は、既存の `focus-time-timer` フロントエンドを OpenShift デモに乗せるための最小 GitOps 資産を追加する。目的は高度な運用の完全再現ではなく、デリバリーの責務分離と巻き戻し可能性を短時間で示すことである。
追加で、初回セットアップ時に必要だった OpenShift 固有の手作業を repo 資産へ落とし込み、Codex が再準備しやすい状態にする。

## 目標
次の説明が実際のリポジトリ資産だけで可能になることを目標とする。
- Tekton がアプリをビルドしてイメージを更新する
- Argo CD が GitOps マニフェスト差分を検知して OpenShift を同期する
- 新版に不具合があれば、Git の前の安定コミットへ戻して復旧できる

## スコープ
- 対象範囲:
  - GitOps ベース構成:
    - Deployment
    - Service
    - Route
    - `kustomization.yaml`
  - GitOps デモオーバーレイ:
    - namespace
    - image tag の差し替えポイント
  - Argo CD:
    - `Application` 1 件
    - target namespace 配備用 RoleBinding
  - Tekton:
    - `Pipeline`
    - `TriggerTemplate`
    - `TriggerBinding`
    - `EventListener`
    - 必要最小限の `ServiceAccount`
    - EventListener 用 Route
    - 手動検証用 `PipelineRun`
    - EventListener 実行用 RoleBinding / ClusterRoleBinding
    - Buildah 実行用 SCC binding
  - 初回セットアップ:
    - operator 導入
    - namespace
    - ImageStream
    - secret template
    - webhook 接続情報
  - 運用資産:
    - 初回セットアップ runbook
    - デモシナリオ
    - 手動確認 / 自動確認
    - ロールバック runbook
  - 補助スクリプト:
    - operator 導入
    - secret 作成と ServiceAccount link
    - 環境検査
    - ImageStream tag 作成
- 対象外:
  - Secrets の自動作成
  - イメージ署名や SBOM
  - 複数環境 promotion

## 構成方針
1. デプロイ対象の正本は `deploy/gitops/focus-time-timer/` 配下に置く。
2. Tekton は `src/focus-time-timer/` をビルドし、生成したイメージ参照を GitOps オーバーレイへ反映する。
3. Argo CD は `deploy/gitops/focus-time-timer/overlays/demo` を監視する。
4. 素の OCP では operator 導入を先行し、その後 `deploy/openshift/kustomization.yaml` を入口に namespace, RBAC, Route, Application を一括適用できるようにする。
5. EventListener は GitHub webhook secret を前提に `push` event のみを受け付ける。
6. ロールバックは Argo CD の UI 操作ではなく、まず Git の状態を戻す説明を主にする。
7. Tekton Trigger は `main` への push のうち、`src/focus-time-timer/` 配下に変更を含むものだけを受け付ける。
8. GitOps オーバーレイのみの変更は Argo CD の同期対象であり、Tekton の再起動対象にしない。
9. 新しい OpenShift 環境では `v2` をデモ基準版 tag として持ち、rollback の説明先を固定する。

## 実行メモ
- 変更してよいファイル:
  - `deploy/gitops/**`
  - `deploy/openshift/**`
  - `docs/product/**`
  - `docs/operations/**`
  - `docs/traceability/**`
- 明示的に対象外のファイル:
  - `src/focus-time-timer/**` の機能変更
- 前提:
  - OpenShift Pipelines と OpenShift GitOps が導入済み
  - イメージ push 先レジストリ資格情報は別途準備済み
  - Tekton が Git push 可能な資格情報を持つ

## 実装の流れ
1. GitOps 用 base / overlay を作る。
2. Argo CD Application を追加する。
3. Tekton パイプラインで build, push, GitOps 更新を定義する。
4. EventListener の Route と webhook secret 参照を追加する。
5. 初回確認用の手動 `PipelineRun` を追加する。
6. 初回セットアップ、手動確認、自動確認、ロールバック手順を文書化する。
7. secret 作成、ServiceAccount link、環境確認、ImageStream tag 作成を補助する script を追加する。

## 検証
1. `kustomization.yaml` からデモ環境のイメージ参照が確認できること。
2. Tekton マニフェスト上で build と GitOps 更新の順序が読み取れること。
3. Argo CD Application が GitOps オーバーレイを参照していること。
4. `deploy/openshift/` と補助 script から namespace, RBAC, Route, secret 作成手順を再現できること。
5. `deploy/gitops/**` のみを変更した push では EventListener 条件を満たさないことがマニフェストから読み取れること。
6. runbook だけで初回セットアップ、手動確認、自動確認、ロールバック経路を説明できること。

## デモ説明用の要点
- Tekton は「作る側」
- Argo CD は「適用してそろえる側」
- GitOps オーバーレイは「いま出したい版の正本」
- 不具合時は「GitOps の正本を安定版に戻す」
