import { cloudflareTest } from '@cloudflare/vitest-plugin'
import { unstable_readConfig } from 'wrangler'
import { defineConfig } from 'vitest/config'

const configPath = './wrangler.jsonc'

// テストは Workers ランタイム上で動き、wrangler.jsonc を直接読めない。
// デプロイと同じ読み方で取り出した assets の設定を inject('wranglerAssets') で渡す
const { assets } = unstable_readConfig({ config: configPath })

export default defineConfig({
  plugins: [cloudflareTest({ wrangler: { configPath } })],
  test: {
    provide: {
      wranglerAssets: {
        binding: assets?.binding,
        not_found_handling: assets?.not_found_handling,
        run_worker_first: assets?.run_worker_first,
      },
    },
  },
})
