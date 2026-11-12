#!/usr/bin/env bash
# Pull synced choices (from phone or desktop) into synced_state.json via the Cloudflare KV API.
# Required: CLOUDFLARE_API_TOKEN, CF_ACCOUNT_ID, CF_KV_NAMESPACE_ID
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
: "${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN}"
: "${CF_ACCOUNT_ID:?Set CF_ACCOUNT_ID}"
: "${CF_KV_NAMESPACE_ID:?Set CF_KV_NAMESPACE_ID}"

code=$(curl -sS -o "$D/synced_state.json.tmp" -w "%{http_code}" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces/$CF_KV_NAMESPACE_ID/values/state")
if [ "$code" = "404" ]; then
  echo '{"choices":{},"spont":{},"edits":{}}' > "$D/synced_state.json.tmp"
elif [ "$code" != "200" ]; then
  echo "pull failed: HTTP $code" >&2
  rm -f "$D/synced_state.json.tmp"
  exit 1
fi
python3 -c "import json,sys;d=json.load(open(sys.argv[1]));[d.setdefault(k,{}) for k in ('choices','spont','edits')];json.dump(d,open(sys.argv[1],'w'),ensure_ascii=False)" "$D/synced_state.json.tmp"
mv "$D/synced_state.json.tmp" "$D/synced_state.json"
echo "pulled: $D/synced_state.json"
