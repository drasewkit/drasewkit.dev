import { exports } from 'cloudflare:workers'
import { describe, expect, it } from 'vitest'

const post = (body: BodyInit) =>
  exports.default.fetch('https://example.com/api/contact', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  })

const valid = { name: '名前', email: 'you@example.com', message: '本文' }

describe('POST /api/contact', () => {
  it('正しい入力なら 200', async () => {
    const res = await post(JSON.stringify(valid))
    expect(res.status).toBe(200)
    expect(await res.json()).toEqual({ ok: true })
  })

  it('JSON として読めなければ 400', async () => {
    const res = await post('{')
    expect(res.status).toBe(400)
    expect(await res.json()).toMatchObject({ ok: false })
  })

  it('本文が 16KB を超えたら 413', async () => {
    const res = await post(
      JSON.stringify({ ...valid, message: 'a'.repeat(16 * 1024) }),
    )
    expect(res.status).toBe(413)
    expect(await res.json()).toEqual({ ok: false, error: 'Payload Too Large' })
  })

  it('入力エラーなら 422 で項目ごとのメッセージを返す', async () => {
    const res = await post(
      JSON.stringify({ name: ' ', email: 'not-an-email', message: '本文' }),
    )
    expect(res.status).toBe(422)
    const json = await res.json<{
      ok: boolean
      errors: Record<string, string[]>
    }>()
    expect(json.ok).toBe(false)
    expect(Object.keys(json.errors).sort()).toEqual(['email', 'name'])
  })
})

describe('ルーティング', () => {
  it('存在しない /api/* は JSON の 404', async () => {
    const res = await exports.default.fetch('https://example.com/api/nope')
    expect(res.status).toBe(404)
    expect(await res.json()).toEqual({ ok: false, error: 'Not Found' })
  })

  it('/api/* 以外の存在しないパスはアセットの 404 ページ', async () => {
    const res = await exports.default.fetch('https://example.com/nope')
    expect(res.status).toBe(404)
    expect(await res.text()).toContain('ページが見つかりません')
  })
})
