// テストの exports.default.fetch() は Worker を直接呼び、静的アセットの振り分け
// （run_worker_first / not_found_handling）は通らない。
// 振り分けを決める設定が意図どおりであることを、wrangler が読んだ設定そのもので確かめる
// （vitest.config.ts で unstable_readConfig して渡している）
import { describe, expect, inject, it } from 'vitest'

const assets = inject('wranglerAssets')

describe('wrangler.jsonc の静的アセットの振り分け', () => {
  it('/api/* だけ Worker を先に通す', () => {
    expect(assets.run_worker_first).toEqual(['/api/*'])
  })

  it('アセットに無いパスは 404 ページを返す', () => {
    expect(assets.not_found_handling).toBe('404-page')
  })

  it('Hono から使う ASSETS バインディングがある', () => {
    expect(assets.binding).toBe('ASSETS')
  })
})
