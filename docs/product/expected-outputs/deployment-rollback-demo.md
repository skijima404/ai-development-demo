# 期待出力

- output_id: output-deployment-rollback-demo
- title: OpenShift デモで見せるデプロイとロールバック
- owner: shared
- status: draft
- created_at: 2026-03-31
- updated_at: 2026-03-31

## 目的
デモ参加者に、AI 支援開発の成果が OpenShift にデプロイされ、不具合時に安定版へ戻せることを短時間で伝える。

## 見せたい結果
1. `focus-time-timer` の新しい版が Tekton と Argo CD を通じて OpenShift に反映される。
2. 新版に不具合があることを確認した後、前のイメージタグへ戻して安定版に復旧できる。
3. どの版が出ているかを Git 履歴とマニフェスト差分で説明できる。

## 成功条件
- Tekton, Argo CD, GitOps の役割を 1 枚の流れとして話せる
- ロールバックを UI の偶然操作ではなく、Git に基づく再現可能な手順として説明できる
- デモ参加者が「AI で作って終わりではない」と理解できる

## デモで使う物
- `deploy/openshift/tekton/focus-time-timer-pipeline.yaml`
- `deploy/openshift/argocd/focus-time-timer-application.yaml`
- `deploy/gitops/focus-time-timer/overlays/demo/kustomization.yaml`
- `docs/operations/openshift-demo-rollout-rollback-runbook.md`
