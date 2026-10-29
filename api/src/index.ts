import { Hono } from 'hono'
import { bodyLimit } from 'hono/body-limit'
import { HTTPException } from 'hono/http-exception'
import { contact } from './routes/contact'

const app = new Hono<{ Bindings: CloudflareBindings }>()

app.use(
  '/api/*',
  bodyLimit({
    maxSize: 16 * 1024,
    onError: (c) => c.json({ ok: false, error: 'Payload Too Large' }, 413),
  }),
)

app.route('/api/contact', contact)

// /api/* 以外で静的アセットに一致しなかったリクエストは、アセット側の 404 ページに任せる
app.notFound((c) => {
  if (c.req.path.startsWith('/api/')) {
    return c.json({ ok: false, error: 'Not Found' }, 404)
  }
  return c.env.ASSETS.fetch(c.req.raw)
})

app.onError((err, c) => {
  // bodyLimit の 413 や、JSON が壊れているときの 400 などはそのままのステータスで返す
  if (err instanceof HTTPException) {
    return c.json({ ok: false, error: err.message }, err.status)
  }
  console.error(err)
  return c.json({ ok: false, error: 'Internal Server Error' }, 500)
})

export default app
