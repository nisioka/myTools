# jev - TypeSafe AI (Jev) お試し環境

[TypeSafe AI](https://typesafe.ai) の System One モデル **Jev** をローカルで叩くためのサンドボックス。
Jev は文章を生成せず、こちらが定義した「型のついた質問」に確率つきで答えるモデル。
分岐や閾値はアプリ側のコードで持ち、判断だけをモデルに任せる使い方をする。

## セットアップ

```bash
cd jev
pnpm install
cp .env.example .env
# .env の TYPESAFE_API_KEY に https://console.typesafe.ai/keys のキーを書く
```

Node 22.6 以降の TypeScript 直接実行（type stripping）を使っているので、tsx などのビルド系依存は無い。

## 使い方

```bash
pnpm demo                          # 組み込みのサンプル（車の問い合わせを仕分ける）
pnpm demo "好きな日本語の文章"        # state を差し替えて実行
pnpm models                        # アカウントで使えるモデル一覧

# 質問セットを JSON で差し替えて試す
pnpm ask examples/support-triage.json "ナビが3日連続でフリーズする。土曜なら入庫できる。"
cat ../README.md | pnpm ask examples/pr-review.json
```

`pnpm ask` に渡す JSON は API の `questions` そのままの形。編集して投げ直せば、
コードを書き換えずに質問の設計を試せる。

## API の形

```
POST https://api.typesafe.ai/v1/systemone
Authorization: Bearer $TYPESAFE_API_KEY
```

リクエストは `state`（評価対象）、`questions`（質問マップ）、`model`（省略時 `jev-latest`）の3つ。
質問は次の3種類しかない。

| 型 | 用途 | 返るもの |
|----|------|----------|
| `noul` | yes/no | `noul`: yes である確率 (0〜1) |
| `choice` | 名前つき選択肢から1つ | `choice`（選ばれたラベル）、`probabilities`、`confidence` |
| `score` | 順序つきルーブリックで採点 | `score`（0始まりの期待値。小数になりうる）、`legend`、`probabilities`、`confidence` |

`score` の `criteria` は必ず2件以上の配列、`choice` の `criteria` はラベル→説明のマップ。
説明は `null` でもよく、文字列の代わりに JSON 構造を渡すこともできる。

`confidence` は確率とは別軸で、「その答えをそのまま使ってよいか」の指標。
`confidence` が低いものだけ人間に回す、といった分岐に使う（confidence-gated routing）。

## 制限・費用（2026-09 時点の公開情報）

- 課金は入力トークンのみ（$0.042 / MTok）、出力は無料
- レート: 1,200 rpm 前後。超過時は 429、過負荷時は 529
- コンテキスト: 全体 64k トークン、`state` + 最長の質問で 32k トークン

## 参考

- ドキュメント: https://docs.typesafe.ai/ （LLM 向け索引: https://docs.typesafe.ai/llms.txt ）
- Playground: https://console.typesafe.ai/playground
- JS SDK: https://github.com/typesafe-ai/typesafe-sdk-js
