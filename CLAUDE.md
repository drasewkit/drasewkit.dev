# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

[drasewkit.dev](https://drasewkit.dev) のサイト。Cloudflare Workers 1つで、API（Hono）と静的ページ（Astro 予定）を配信する。作成中。

## コマンド

```sh
npm install
npm run dev        # wrangler dev（http://localhost:8787）
npm run typecheck  # wrangler types で型を生成してから tsc --noEmit
npm run deploy     # wrangler deploy
```

- テストとリンターはまだない。変更後の確認は `npm run typecheck` と `npm run dev` での動作確認。
- `worker-configuration.d.ts`（`CloudflareBindings` の型）は `wrangler types` の生成物で gitignore 対象。`wrangler.jsonc` のバインディングを変えたら `npm run cf-typegen` で再生成する。
- シークレットは `.dev.vars` に置く（gitignore 済み）。

## アーキテクチャ

リクエストの振り分けは `wrangler.jsonc` の `assets` 設定と `api/src/index.ts` の組み合わせで決まる。

- `run_worker_first: ["/api/*"]` により、`/api/*` だけは静的アセットより先に Worker（Hono）が処理する。
- それ以外のパスは Workers Static Assets が直接返す。一致しないときは `not_found_handling: "404-page"` でアセット側の `404.html` が返る。
- Hono の `notFound` は、`/api/*` なら JSON の 404、それ以外なら `c.env.ASSETS.fetch()` でアセット側に委ねる。
- アセットのディレクトリは現在 `./site/placeholder`（仮の HTML）。Astro のサイトができたら `./site/dist` に差し替える予定。

### API の規約

- ルートは `api/src/routes/` に Hono のサブアプリとして定義し、`api/src/index.ts` で `app.route()` する。`Hono<{ Bindings: CloudflareBindings }>` で型付けする。
- `/api/*` 全体に `bodyLimit`（16KB、超えたら 413）がかかる。
- 入力検証は `@hono/zod-validator` + Zod v4（`import * as z from 'zod'`）。検証エラーは 422 で `{ ok: false, errors: <項目ごとのメッセージ> }`（`z.flattenError(...).fieldErrors`）。
- レスポンスは成功時 `{ ok: true }`、エラー時 `{ ok: false, error: string }` の形に揃える。`HTTPException`（壊れた JSON の 400 など）は `onError` でそのステータスのまま JSON にし、それ以外は 500。
- API の仕様（ステータスと内容）は README.md の「API」節に表で書いている。API を変えたら README も更新する。

### 未実装

`POST /api/contact` は入力検証までで、Turnstile の検証と Resend での送信は TODO。

## 運用

- コミットメッセージ・README・コード中のコメントは日本語。
- 作業は feature ブランチ（例: `feat/contact-api`）で行い、PR で `main` にマージする。
