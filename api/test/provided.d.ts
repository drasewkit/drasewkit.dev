// vitest.config.ts の test.provide でテストに渡す値の型
import 'vitest'

declare module 'vitest' {
  export interface ProvidedContext {
    wranglerAssets: {
      binding?: string
      not_found_handling?: string
      run_worker_first?: boolean | string[]
    }
  }
}
