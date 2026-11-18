#!/bin/sh
# 編集したファイルを Prettier で整形する（.prettierignore の対象と、Prettier が扱えない拡張子は無視）
cd "$CLAUDE_PROJECT_DIR" || exit 0
# npm install 前は何もしない
[ -x node_modules/.bin/prettier ] || exit 0

f=$(node -e '
  let s = ""
  process.stdin.on("data", (d) => (s += d)).on("end", () => {
    try { process.stdout.write(JSON.parse(s).tool_input?.file_path ?? "") } catch {}
  })')
case "$f" in
  "$CLAUDE_PROJECT_DIR"/*) ;;
  *) exit 0 ;;
esac

# 整形できなかった（構文エラーなど）ときは Claude に伝えて直させる
if ! out=$(node_modules/.bin/prettier --write --ignore-unknown "$f" 2>&1 >/dev/null); then
  printf 'Prettier で整形できませんでした（構文を確認してください）: %s\n%s\n' "$f" "$out" >&2
  exit 2
fi
exit 0
