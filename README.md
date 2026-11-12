# Job Hunt Dashboard

A personal dashboard for running a job search end to end: watch new roles, review them one by one, prepare application drafts, and track what has been sent, interviewed or refused — with a hard rule that **nothing goes out without a human review**.

I designed the workflow, the review steps and the interface, and built the tool with AI assistants I direct. The copy in this repository is a sanitized, public version with **example data only**. It does not contain real applications, emails, drafts or access credentials.

Live demo (example data): [GitHub Pages](https://andreagzzgrcia.github.io/job-hunt-dashboard/)

## What it does

- **One-lead-at-a-time review.** Tabs for job announcements, spontaneous applications, recruiters and target companies, plus a follow-up board (`Suivi`) with counters.
- **Drafts with a review gate.** Each card has an editable letter. Applications are prepared as Gmail drafts (CV attached) and are never sent automatically.
- **Scheduled watch.** Matching roles from job boards can be added as new cards; listings already reviewed are remembered so they are not proposed again.
- **Status tracking.** Todo, draft ready, sent, interview, rejected, and “not for me”. Business-development rows, if any, stay out of the legal counters.
- **Sync.** Choices made on a phone or laptop are stored in Cloudflare KV and folded back into the data file on the next build.
- **Private by default.** The live (personal) deploy is served only under a secret URL path; the site root returns 404. That path and every API token stay out of this repository.

## Stack

- Front end: a single HTML/CSS/JS page (`template.html`), with a small home page that opens the legal and business views.
- Data: `apps.json`, compiled into a self-contained page by `build.py`.
- Deploy: a Cloudflare Worker (`worker_src.js`) plus a KV namespace for synced state.
- Scripts: `publish.sh` and `pull_state.sh`, driven by environment variables.

## Run the demo locally

```bash
git clone https://github.com/andreagzzgrcia/job-hunt-dashboard.git
cd job-hunt-dashboard
python3 build.py
python3 -m http.server 8080 --directory demo
```

Then open [http://localhost:8080/](http://localhost:8080/). `build.py` also writes `job-hunt.html` at the repo root, which you can open directly as a file.

`apps.json` in this repository is identical to `apps.example.json`: fictional companies such as Aurum Payments and Cabinet Meridian, used only to show how the board looks.

## Deploy your own (optional)

1. Create a Cloudflare Worker and a KV namespace.
2. Copy `.env.example` to `.env` and fill in `CLOUDFLARE_API_TOKEN`, `CF_ACCOUNT_ID` and `CF_KV_NAMESPACE_ID`.
3. Create `.secret` with a long random path segment (`chmod 600 .secret`).
4. Replace `apps.json` with your own data (start from `apps.example.json`).
5. Run `./publish.sh`.

Never commit `.secret`, `.env`, `synced_state.json` or a real `apps.json`.

## License

MIT. Example names and job descriptions are fictional.
