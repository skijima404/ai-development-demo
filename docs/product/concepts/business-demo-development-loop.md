# プロダクトコンセプト

- concept_id: concept-business-demo-development-loop
- title: 業務要求からレビュー済みデプロイ準備までのループ
- owner: shared
- status: draft
- created_at: 2026-03-30
- updated_at: 2026-04-02

## コンセプト
このプロダクトは、業務向けの軽量なシステム要求が、AI 支援によって要件化され、実装され、レビューされ、デプロイ準備まで進む流れを短く一貫して見せる。

## デモの段階
1. 要求受付:
   業務ユーザーが課題や自動化したい内容を説明する。
2. 要件具体化:
   AI とユーザーがスコープ、前提、受け入れ条件を整理する。
3. 追跡可能な仕様化:
   リポジトリに現時点の正本が保存される。
4. 実装生成:
   AI が決められた境界の中で実装する。
5. 人間レビュー:
   レビュアーが成果物と関連仕様を確認する。
6. コミットとデプロイ準備:
   変更が引き継ぎ可能なデリバリー準備へまとめられる。
7. GitOps デプロイ:
   Tekton と Argo CD により OpenShift へ反映される。
8. 巻き戻し:
   不具合時に直前の安定バージョンへ戻せることを示す。

## デモでの AI 支援の見せ方
- AI は実装だけでなく、GitOps の tag 切り替えやロールバック補助まで担当できるように見せる。
- 補助スクリプトを AI コーディング支援エージェントがキックすることで、人が毎回 YAML を手編集しなくてもよい状態を示す。
- 例として Codex のような AI エージェントが、`set-focus-time-timer-tag.sh` や `rollback-focus-time-timer.sh` を実行する流れを想定する。

## デモで約束したいこと
このデモを通じて、AI 支援開発はスプレッドシートや RPA 的な仕事の一部を置き換えうる一方で、追跡可能性や人の統制を失わず、さらにデプロイ後の巻き戻しまで含めて現実的に扱えることを示す。

## 必須の支援資産
- `docs/product/vision.md`
- `docs/traceability/value-streams/vs-intent-001-business-request-to-reviewed-deployment.md`
- `docs/product/expected-outputs/review-package.md`
- `docs/product/expected-outputs/deployment-rollback-demo.md`
