# フォーカスタイムタイマー実装領域

このディレクトリは、`Focus Time Timer` の本番向け実装コードを配置するための領域です。

## 目的
- フロントエンドのみで成立する MVP の実装コードを置く
- 要件・設計資産とは分離して、本番資産として扱う

## 現時点の想定
- 単一画面のフォーカスタイマー
- 25 分を既定値にした時間設定
- 状態表示、開始、停止、リセット
- 終了時のアラーム音と固定メッセージ表示

## 技術前提
- フロントエンド技術は `TypeScript + React + Vite` を前提とする
- バックエンドやデータベースは使わない
- 単一画面で完結する構成とする
- 残り時間は 1 秒ごとに表示更新する
- 残り時間の計算は、単純減算ではなく開始時刻と現在時刻から都度再計算する

## 実行方法
- 開発時:
  - `cd src/focus-time-timer`
  - `npm install`
  - `npm run dev`
- ビルド:
  - `cd src/focus-time-timer`
  - `npm install`
  - `npm run build`

## OpenShift 向け資産
- コンテナビルド用:
  - `src/focus-time-timer/Dockerfile`
  - `src/focus-time-timer/nginx/default.conf`
- 配備用:
  - `deploy/openshift/focus-time-timer.yaml`

## 初期実装の方針
- 最初は「動くが味気ない」スケルトン MVP を目指す
- Look & Feel は作り込みすぎない
- 後からデモ中に改善しやすい余地を残す

## デモ中に追加しやすい改善例
- 残り時間表示をデジタルからアナログ風に変える
- Look & Feel をその場で調整する
- 停止から再開できるようにする

## 注意
- 実行履歴、音楽再生、時計時刻指定タイマー、タイムゾーン対応は MVP の対象外です。
- 仕様変更時は、先に `docs/traceability/` 側の資産を更新してから実装を広げてください。
