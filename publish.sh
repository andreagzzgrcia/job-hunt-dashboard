#!/usr/bin/env bash
# Rebuild the dashboard and deploy it to a Cloudflare Worker.
# Required environment variables (never commit these):
#   CLOUDFLARE_API_TOKEN
#   CF_ACCOUNT_ID
#   CF_KV_NAMESPACE_ID
# Optional:
#   CF_WORKER_NAME   (default: job-hunt-dashboard)
# A file `.secret` in this directory holds the private URL path prefix (mode 600).
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; cd "$D"

: "${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN}"
: "${CF_ACCOUNT_ID:?Set CF_ACCOUNT_ID}"
: "${CF_KV_NAMESPACE_ID:?Set CF_KV_NAMESPACE_ID}"
W="${CF_WORKER_NAME:-job-hunt-dashboard}"

if [[ ! -f "$D/.secret" ]]; then
  echo "ERROR: missing .secret (the private URL path). Create it with a long random string and chmod 600." >&2
  exit 2
fi

bash "$D/pull_state.sh" || echo "pre-pull failed (non-fatal)"
python3 build.py

python3 - <<'WORKERPY'
import json, base64, os
h = open("job-hunt.html", encoding="utf-8").read()
d = json.load(open("apps.json", encoding="utf-8"))
n = sum(1 for a in d["apps"] if a.get("status") in ("todo", "in_progress", "drafting", "draft_ready", "mod_requested"))
hm = open("home.html", encoding="utf-8").read().replace(
    "__LEGALCOUNT__",
    (str(n) + " offre" + ("s" if n != 1 else "") + " à traiter") if n else "Tout est traité",
)
icon = "assets/apple-touch-icon.png" if os.path.exists("assets/apple-touch-icon.png") else "apple-touch-icon.png"
i = base64.b64encode(open(icon, "rb").read()).decode()
open("/tmp/jhd_worker.js", "w").write(
    "const HTML=" + json.dumps(h) + ";\n"
    "const HOME=" + json.dumps(hm) + ";\n"
    "const ICON=" + json.dumps(i) + ";\n"
    + open("worker_src.js").read()
)
json.dump({
    "main_module": "worker.js",
    "compatibility_date": "2026-10-01",
    "bindings": [
        {"type": "kv_namespace", "name": "KV", "namespace_id": os.environ["CF_KV_NAMESPACE_ID"]},
        {"type": "secret_text", "name": "SECRET", "text": open(".secret").read().strip()},
    ],
}, open("/tmp/jhd_meta.json", "w"))
WORKERPY

R=$(curl -sS -X PUT -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts/$W" \
  -F "metadata=@/tmp/jhd_meta.json;type=application/json" \
  -F "worker.js=@/tmp/jhd_worker.js;filename=worker.js;type=application/javascript+module")
echo "$R" | python3 -c "import sys,json;r=json.load(sys.stdin);print('deploy:',r['success'],r.get('errors'));sys.exit(0 if r['success'] else 1)"
curl -sS -X POST -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" \
  -d '{"enabled":true}' \
  "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts/$W/subdomain" >/dev/null
rm -f /tmp/jhd_meta.json /tmp/jhd_worker.js
sleep 3
bash "$D/pull_state.sh" || echo "pull failed (non-fatal)"
