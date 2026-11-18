// hook の標準入力（JSON）を扱う小さな補助。jq に頼らないために node で書く
//   node hook-json.mjs get <キー>...  … 指定したキーの値を1行ずつ出す（無ければ空行）。a.b でネストを辿る
//   node hook-json.mjs message        … 標準入力の文字列を {"systemMessage": ...} にして出す
import { readFileSync } from 'node:fs'

const [mode, ...keys] = process.argv.slice(2)
const stdin = readFileSync(0, 'utf8')

if (mode === 'message') {
  process.stdout.write(JSON.stringify({ systemMessage: stdin }))
} else {
  let data = {}
  try {
    data = JSON.parse(stdin)
  } catch {
    // 読めないときはすべて空として扱う
  }
  const values = keys.map((key) => {
    const value = key.split('.').reduce((obj, part) => obj?.[part], data)
    return value == null ? '' : String(value)
  })
  process.stdout.write(values.join('\n') + '\n')
}
