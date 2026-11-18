#!/bin/sh
# 編集したファイルを Prettier で整形する（.prettierignore の対象と、Prettier が扱えない拡張子は無視）。
# 型に関わるファイルなら、応答の終わりに typecheck.sh が型チェックするよう印を付ける
[ -n "$CLAUDE_PROJECT_DIR" ] || exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0
# npm install 前は何もしない
[ -x node_modules/.bin/prettier ] || exit 0

vals=$(node .claude/hooks/hook-json.mjs get tool_input.file_path session_id)
f=$(printf '%s\n' "$vals" | sed -n 1p)
sid=$(printf '%s\n' "$vals" | sed -n 2p)
case "$f" in
  "$CLAUDE_PROJECT_DIR"/*) ;;
  *) exit 0 ;;
esac

case "$f" in
  *.ts | */tsconfig.json | */wrangler.jsonc | */package.json)
    # typecheck.sh と同じ場所
    touch "${TMPDIR:-/tmp}/drasewkit-dev-typecheck-${sid:-default}"
    ;;
esac

# 整形できなかった（構文エラーなど）ときは Claude に伝えて直させる
if ! out=$(node_modules/.bin/prettier --write --ignore-unknown "$f" 2>&1 >/dev/null); then
  printf 'Prettier で整形できませんでした（構文を確認してください）: %s\n%s\n' "$f" "$out" >&2
  exit 2
fi
exit 0
