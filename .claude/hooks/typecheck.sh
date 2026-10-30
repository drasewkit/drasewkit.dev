#!/bin/sh
# 応答を終える前に型チェックし、エラーがあれば Claude に直させる
# 直しても通らないときに止まり続けないよう、hook から再開した直後は見逃す
if [ "$(jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi
cd "$CLAUDE_PROJECT_DIR" || exit 0
if ! out=$(node_modules/.bin/tsc --noEmit 2>&1); then
  printf '型エラーがあります。直してから終えてください。\n%s\n' "$out" >&2
  exit 2
fi
exit 0
