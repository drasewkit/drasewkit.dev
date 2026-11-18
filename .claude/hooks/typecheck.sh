#!/bin/sh
# 応答を終える前に型チェックし、エラーがあれば Claude に直させる
input=$(cat)
cd "$CLAUDE_PROJECT_DIR" || exit 0

# npm install 前は何もしない（tsc が無いことを型エラー扱いにしない）
[ -x node_modules/.bin/tsc ] || exit 0

# npm run typecheck と同じく、生成物の型を先に用意する。
# 無いとき・wrangler.jsonc より古いときだけ作り直す
if [ ! -f worker-configuration.d.ts ] || [ wrangler.jsonc -nt worker-configuration.d.ts ]; then
  if ! out=$(npm run --silent cf-typegen 2>&1); then
    out=$(printf 'npm run cf-typegen が失敗しました（wrangler.jsonc を確認してください）。\n%s' "$out")
  else
    out=$(node_modules/.bin/tsc --noEmit 2>&1) && exit 0
  fi
else
  out=$(node_modules/.bin/tsc --noEmit 2>&1) && exit 0
fi

# hook から再開した直後は止めない（直しても通らないときに止まり続けないように）。
# 見逃さずにユーザーへ警告として表示する
active=$(printf '%s' "$input" | node -e '
  let s = ""
  process.stdin.on("data", (d) => (s += d)).on("end", () => {
    try { process.stdout.write(String(JSON.parse(s).stop_hook_active === true)) } catch { process.stdout.write("false") }
  })')
if [ "$active" = "true" ]; then
  printf '%s' "$out" | node -e '
    let s = ""
    process.stdin.on("data", (d) => (s += d)).on("end", () => {
      process.stdout.write(JSON.stringify({ systemMessage: "型エラーが残ったまま終了しました。\n" + s }))
    })'
  exit 0
fi

printf '型エラーがあります。直してから終えてください。\n%s\n' "$out" >&2
exit 2
