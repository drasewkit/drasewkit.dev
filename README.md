# drasewkit.dev

[drasewkit.dev](https://drasewkit.dev) のサイトです。

## 構成

Cloudflare Workers 1つで動かします。

- `/api/*` — [Hono](https://hono.dev) の API（問い合わせフォーム `POST /api/contact`）
- それ以外 — [Astro](https://astro.build) で静的ビルドしたページを Workers Static Assets として配信

## 状態

作成中です。

## 開発

```sh
npm install
npm run dev        # http://localhost:8787
npm run typecheck  # 型を生成してから tsc
```

## API

### `POST /api/contact`

```json
{ "name": "名前", "email": "you@example.com", "message": "本文" }
```

| ステータス | 内容 |
| --- | --- |
| 200 | `{ "ok": true }` |
| 400 | JSON として読めない |
| 413 | 本文が 16KB を超える |
| 422 | 入力エラー。`errors` に項目ごとのメッセージ |
