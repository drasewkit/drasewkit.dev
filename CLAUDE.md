# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

[drasewkit.dev](https://drasewkit.dev) のサイト。Cloudflare Workers 1つで、API（Hono）と静的ページ（Astro 予定）を配信する。作成中。

## コマンド

```sh
npm install
npm run dev        # wrangler dev（http://localhost:8787）
npm run typecheck  # wrangler types で型を生成してから tsc --noEmit
npm test           # Vitest（Workers ランタイム上で実行）
npm test -- api/test/contact.test.ts  # 1ファイルだけ
npm test -- -t '422'                  # テスト名で絞る
npm run format     # Prettier（format:check で確認のみ）
npm run deploy     # wrangler deploy
```

- リンターはまだない。
- `.claude/settings.json` の hooks（`.claude/hooks/`）:
  - Write / Edit で編集したファイルは Prettier で自動整形される（`post-edit.sh`）。整形できないとき（構文エラーなど）はエラーとして返る。
  - その応答で型に関わるファイル（`*.ts`・`tsconfig.json`・`wrangler.jsonc`・`package.json`）を Write / Edit したときだけ、応答を終える前に `tsc --noEmit` が走る（`typecheck.sh`）。Bash での編集は対象外なので、そのときは `npm run typecheck` を自分で実行する。
  - `worker-configuration.d.ts` が無いか、`wrangler.jsonc`・`.dev.vars`・`package-lock.json` などより古いときは、先に `npm run cf-typegen` で作り直す。
  - 型エラーで止められたあと、再開しても直らなかったときは止めずにユーザーへ警告を出す。
- デプロイ・`wrangler versions` / `rollback` / `delete` / `secret` は実行前に確認が入る。
- `.dev.vars*` と `.env*` は Read ツールでの読み取りを禁止している。Bash は `.dev.vars` を名指しするコマンドを止めるだけで、完全には防げない。シークレットの中身は読まないこと。
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
- テストは API ごとに `api/test/<ルート名>.test.ts` を書き、README の表にあるステータスをすべて確かめる。`vitest.config.ts` の `@cloudflare/vitest-plugin` が `wrangler.jsonc` を読み、テストからは `import { exports } from 'cloudflare:workers'` の `exports.default.fetch()` で Worker を呼ぶ。
- `exports.default.fetch()` は Worker を直接呼ぶので、静的アセットの振り分け（`run_worker_first` / `not_found_handling`）は通らない。振り分けの設定は `api/test/wrangler-config.test.ts` で `wrangler.jsonc` の中身を確かめている。設定を変えたらこのテストも直す。

### 未実装

`POST /api/contact` は入力検証までで、Turnstile の検証と Resend での送信は TODO。

## 運用

- コミットメッセージ・README・コード中のコメントは日本語。
- 作業は feature ブランチ（例: `feat/contact-api`）で行い、PR で `main` にマージする。
