# drasewkit.dev

[drasewkit.dev](https://drasewkit.dev) のサイトです。

## 構成

Cloudflare Workers 1つで動かします。

- `/api/*` — [Hono](https://hono.dev) の API（問い合わせフォーム `POST /api/contact`）
- それ以外 — [Astro](https://astro.build) で静的ビルドしたページを Workers Static Assets として配信

## 状態

作成中です。
