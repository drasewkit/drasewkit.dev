#!/bin/sh
# 応答を終える前に型チェックし、エラーがあれば Claude に直させる。
# この応答で型に関わるファイルを編集したとき（post-edit.sh が印を付ける）だけ実行する
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0
# npm install 前は何もしない（tsc が無いことを型エラー扱いにしない）
[ -x node_modules/.bin/tsc ] || exit 0

vals=$(node .claude/hooks/hook-json.mjs get session_id stop_hook_active)
sid=$(printf '%s\n' "$vals" | sed -n 1p)
active=$(printf '%s\n' "$vals" | sed -n 2p)
# post-edit.sh と同じ場所
marker="${TMPDIR:-/tmp}/drasewkit-dev-typecheck-${sid:-default}"
[ -f "$marker" ] || exit 0

# npm run typecheck と同じく、生成物の型（worker-configuration.d.ts）を使う。
# wrangler types は wrangler.jsonc と .dev.vars / .env を読み、出力は wrangler の版でも変わるので、
# 型が無いとき・それらより古いときだけ作り直す
regen=
[ -f worker-configuration.d.ts ] || regen=1
for src in wrangler.jsonc .dev.vars .dev.vars.* .env .env.* package-lock.json; do
  [ -f "$src" ] && [ "$src" -nt worker-configuration.d.ts ] && regen=1
done

if [ -n "$regen" ] && ! out=$(npm run --silent cf-typegen 2>&1); then
  out=$(printf 'npm run cf-typegen が失敗しました（wrangler.jsonc を確認してください）。\n%s' "$out")
elif out=$(node_modules/.bin/tsc --noEmit 2>&1); then
  rm -f "$marker"
  exit 0
fi

# hook から再開した直後は止めない（直しても通らないときに止まり続けないように）。
# 見逃さずにユーザーへ警告として表示する
if [ "$active" = "true" ]; then
  rm -f "$marker"
  printf '型エラーが残ったまま終了しました。\n%s' "$out" | node .claude/hooks/hook-json.mjs message
  exit 0
fi

printf '型エラーがあります。直してから終えてください。\n%s\n' "$out" >&2
exit 2
