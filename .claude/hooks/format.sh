#!/bin/sh
# 編集したファイルを Prettier で整形する（.prettierignore の対象と、Prettier が扱えない拡張子は無視）
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in
  "$CLAUDE_PROJECT_DIR"/*) ;;
  *) exit 0 ;;
esac
cd "$CLAUDE_PROJECT_DIR" && node_modules/.bin/prettier --write --ignore-unknown "$f" >/dev/null 2>&1
exit 0
