#!/bin/sh
# 応答を終える前に型チェックし、エラーがあれば Claude に直させる。
# この応答で型に関わるファイルを編集したとき（post-edit.sh が印を付ける）だけ実行する。
# 印のファイルの中身が blocked なら、この hook が一度止めたあと（ほかの Stop hook の
# 影響を受けないよう stop_hook_active ではなく自分で記録する）
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0
# npm install 前は何もしない（tsc が無いことを型エラー扱いにしない）
[ -x node_modules/.bin/tsc ] || exit 0

sid=$(node .claude/hooks/hook-json.mjs get session_id)
# post-edit.sh と同じ場所
marker="${TMPDIR:-/tmp}/drasewkit-dev-typecheck-${sid:-default}"
[ -f "$marker" ] || exit 0

# npm run typecheck と同じく、生成物の型（worker-configuration.d.ts）を使う。
# wrangler types は wrangler.jsonc と .dev.vars / .env を読み、出力は wrangler の版でも変わるので、
# 型が無いとき・それらより古いときだけ作り直す
regen=
typegen_failed=
[ -f worker-configuration.d.ts ] || regen=1
for src in wrangler.jsonc .dev.vars .dev.vars.* .env .env.* package-lock.json; do
  [ -f "$src" ] && [ "$src" -nt worker-configuration.d.ts ] && regen=1
done

if [ -n "$regen" ] && ! out=$(FORCE_COLOR=0 NO_COLOR=1 npm run --silent cf-typegen 2>&1); then
  typegen_failed=1
  problem='型の生成（npm run cf-typegen）に失敗し、型チェックできませんでした。wrangler.jsonc を確認してください'
elif out=$(node_modules/.bin/tsc --noEmit 2>&1); then
  rm -f "$marker"
  exit 0
else
  problem='型エラーがあります'
fi

# 一度止めたあとなら止めない（直しても通らないときに止まり続けないように）。ユーザーへ警告として表示する
if [ "$(cat "$marker")" = "blocked" ]; then
  if [ -n "$typegen_failed" ]; then
    # 型チェック自体ができていないので、次の応答でもう一度確かめる
    : >"$marker"
  else
    rm -f "$marker"
  fi
  printf '%s（直せないまま終了しました）。\n%s' "$problem" "$out" | node .claude/hooks/hook-json.mjs message
  exit 0
fi

echo blocked >"$marker"
printf '%s。直してから終えてください。\n%s\n' "$problem" "$out" >&2
exit 2
