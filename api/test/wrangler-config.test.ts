// テストの exports.default.fetch() は Worker を直接呼び、静的アセットの振り分け
// （run_worker_first / not_found_handling）は通らない。
// 振り分けを決める設定が意図どおりであることを、設定ファイルそのもので確かめる
import raw from '../../wrangler.jsonc?raw'
import { describe, expect, it } from 'vitest'

// 行頭からの // コメントと末尾カンマを取り除いて JSON として読む
const config = JSON.parse(
  raw.replace(/^\s*\/\/.*$/gm, '').replace(/,(\s*[}\]])/g, '$1'),
)

describe('wrangler.jsonc の静的アセットの振り分け', () => {
  it('/api/* だけ Worker を先に通す', () => {
    expect(config.assets.run_worker_first).toEqual(['/api/*'])
  })

  it('アセットに無いパスは 404 ページを返す', () => {
    expect(config.assets.not_found_handling).toBe('404-page')
  })

  it('Hono から使う ASSETS バインディングがある', () => {
    expect(config.assets.binding).toBe('ASSETS')
  })
})
