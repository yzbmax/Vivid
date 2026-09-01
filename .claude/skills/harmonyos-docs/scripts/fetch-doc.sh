#!/usr/bin/env bash
# Fetch a HarmonyOS developer doc as markdown.
# Usage: fetch-doc.sh <slug> [cn|en]
# Example: fetch-doc.sh harmonyos-guides/arkts-get-started
#          fetch-doc.sh harmonyos-guides/arkts-get-started en
# Prints the local temp file path on success.
set -euo pipefail

SLUG="${1:?usage: fetch-doc.sh <slug> [cn|en]}"
LANG="${2:-cn}"

if [[ "$LANG" != "cn" && "$LANG" != "en" ]]; then
  echo "error: LANG must be 'cn' or 'en'" >&2
  exit 2
fi

URL="https://developer.huawei.com/consumer/$LANG/doc/$SLUG.md"
OUT="$(mktemp "${TMPDIR:-/tmp}/harmonyos-doc-XXXXXX.md")"

if ! curl -fsSL --max-time 30 "$URL" -o "$OUT"; then
  rm -f "$OUT"
  echo "error: failed to fetch $URL" >&2
  exit 1
fi

# Sanity check: Huawei portal returns HTML with this marker when slug not found
if grep -q '<html' "$OUT" 2>/dev/null && ! grep -q '^#' "$OUT"; then
  rm -f "$OUT"
  echo "error: slug not found or returned HTML: $SLUG" >&2
  exit 1
fi

echo "$OUT"
