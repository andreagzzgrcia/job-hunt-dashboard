#!/usr/bin/env python3
"""Rebuild job-hunt.html from apps.json.
Usage: python3 build.py   (edit apps.json first; bump each changed app's updatedAt and the top-level updatedAt)
Statuses: todo | in_progress | sent | applied | mod_requested | not_interested | expired ("Offre expirée") | no_fit ("Ne correspond pas au profil") | closed | rejected ("Refusée")
  Reconcile: synced choices (synced_state.json, from pull_state.sh) are folded into apps.json for open listings,
  and dismissed ids (not_interested/expired/no_fit/closed) are added to veille_seen.json so the watch never re-adds them.
  Optional "rejectedAt" (ISO, Paris offset) on any entry: date the rejection was received.
  Legal entries with no "posted"/"url" are fine (e.g. EY paralegal, applied before tracking).
Business Development section: top-level "bd": [ {"id": "bd-<slug>", "firm", "role", "channel": "form",
  "url" (leave "" if unknown, never invent), "status": applied|rejected|..., "sentAt", "rejectedAt", "updatedAt"} ]
  Rendered only in its own table + counters under Suivi; never mixed into legal counters or the card deck.
  ALWAYS keep the "bd" key when rewriting apps.json. Never change existing ids (localStorage keys lsgb_choices_v1 / lsgb_spont_v1).
Spontaneous entries: {"type": "spontaneous", "id", "firm", "website", "email", "contact", "note", "subject",
  "status": drafting|draft_ready|sent|not_interested, "draftMessageId", "body": [...], "updatedAt", "sentAt"}
  An entry here hides the local card with the same firm name or website domain.
"""
import json, pathlib
here = pathlib.Path(__file__).parent
data = json.loads((here / "apps.json").read_text(encoding="utf-8"))
OPEN = {"todo","in_progress","drafting","draft_ready","mod_requested","request_sent"}
DISMISS = {"not_interested","expired","no_fit","closed"}
ss = here / "synced_state.json"
if ss.exists():
    ch = json.loads(ss.read_text(encoding="utf-8")).get("choices", {})
    byid = {a["id"]: a for a in data["apps"]}
    vs_p = here / "veille_seen.json"; vs = json.loads(vs_p.read_text(encoding="utf-8")); seen = {(x.get("source"), x.get("id")) for x in vs["seen"]}
    changed = 0; vchanged = 0
    for i, x in ch.items():
        v = (x or {}).get("v") or {}; s = v.get("status"); a = byid.get(i)
        if not a or not s: continue
        if a.get("status") in OPEN and s != a.get("status") and (s in DISMISS or s in ("applied","sent","in_progress")):
            a["status"] = s; a["updatedAt"] = v.get("updatedAt", a.get("updatedAt"))
            if v.get("sentAt"): a["sentAt"] = v["sentAt"]
            changed += 1
        if s in DISMISS and ("dashboard", i) not in seen:
            vs["seen"].append({"source": "dashboard", "id": i, "url": a.get("url", ""), "title": a.get("role", ""), "company": a.get("firm", ""), "status": s}); seen.add(("dashboard", i)); vchanged += 1
    if changed: (here / "apps.json").write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    if vchanged: vs_p.write_text(json.dumps(vs, ensure_ascii=False, indent=1), encoding="utf-8")
    print("reconciled:", changed, "apps,", vchanged, "watch ids")
# Purge: listings marked expired / no_fit are deleted from the dashboard (archived in purged_apps.json, ids kept in veille_seen.json).
PURGE = {"expired","no_fit"}
gone = [a for a in data["apps"] if a.get("status") in PURGE]
if gone:
    vs_p = here / "veille_seen.json"; vs = json.loads(vs_p.read_text(encoding="utf-8")); seen = {(x.get("source"), x.get("id")) for x in vs["seen"]}
    for a in gone:
        if ("dashboard", a["id"]) not in seen:
            vs["seen"].append({"source": "dashboard", "id": a["id"], "url": a.get("url", ""), "title": a.get("role", ""), "company": a.get("firm", ""), "status": a["status"]})
    vs_p.write_text(json.dumps(vs, ensure_ascii=False, indent=1), encoding="utf-8")
    ar_p = here / "purged_apps.json"; ar = json.loads(ar_p.read_text(encoding="utf-8")) if ar_p.exists() else []
    ar += gone; ar_p.write_text(json.dumps(ar, ensure_ascii=False, indent=1), encoding="utf-8")
    data["apps"] = [a for a in data["apps"] if a.get("status") not in PURGE]
    (here / "apps.json").write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    print("purged:", len(gone), "expired/no_fit listings")
tpl = (here / "template.html").read_text(encoding="utf-8")
blob = json.dumps({k: v for k, v in data.items() if k != "bd"}, ensure_ascii=False)  # BD lives on /business/; kept in apps.json only.replace("</", "<\\/")
(here / "job-hunt.html").write_text(tpl.replace("__DATA__", blob), encoding="utf-8")
print("OK:", here / "job-hunt.html", len(data["apps"]), "annonces,", len(data.get("bd", [])), "BD")
