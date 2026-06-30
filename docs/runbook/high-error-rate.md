# Runbook — QuickNotes High Error Rate

**Alert:** `QuickNotesHighErrorRate` &nbsp;|&nbsp; **Severity:** `page`

## What this alert means

More than 5% of HTTP responses returned a 4xx or 5xx status code for at least 5 minutes straight — users are getting failures right now, not a one-off blip.

## Triage steps

1. **Confirm it's real, not a scrape gap.** Open `http://localhost:9090/targets` and check that `quicknotes` is `UP`. If it's `DOWN`, the error metric is stale — jump to "QuickNotes is down" under Mitigations.
2. **Find which status code dominates.** In Prometheus, run
   `sum by (code) (rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))`.
   - Mostly **5xx** → the server is failing (crash, panic, bad dependency, disk/IO).
   - Mostly **4xx** → clients are sending bad requests (a broken caller, a bad deploy upstream, or an attack/scanner).
3. **Check the container's health and logs.** `docker compose ps` (is `quicknotes` healthy?) and `docker compose logs --tail=100 quicknotes` — look for panics, repeated stack traces, or the same failing route.
4. **Locate the blast radius.** Is it one endpoint or all of them? Correlate the error spike with the Traffic and Saturation panels on the Golden Signals dashboard, and with the time of the last deploy/config change.

## Mitigations (stop the bleeding first, root-cause later)

- **Roll back the last change.** If errors started right after a deploy or config edit, revert to the previous known-good image/config and redeploy — fastest way to restore service.
- **Restart the container.** `docker compose restart quicknotes` clears a wedged process, leaked handles, or a stuck in-memory state. Cheap and often enough for 5xx caused by a bad runtime state.
- **QuickNotes is down (target DOWN):** `docker compose up -d quicknotes`; if it won't stay up, inspect logs for a startup error (bad `DATA_PATH`/`SEED_PATH`, port conflict, corrupt `notes.json`).
- **If 4xx from one abusive caller:** rate-limit or block the source at the edge so healthy traffic isn't drowned out.

## Post-incident

Once service is restored, write a blameless postmortem: timeline, impact, detection, what fixed it, and follow-up actions to prevent recurrence. Use the course **Lecture 1 postmortem template** (replace this link with the course copy):
- Course template: `docs/templates/postmortem.md` *(adjust path to wherever Lecture 1's template lives in the repo)*
- Reference: Google SRE postmortem template — https://sre.google/sre-book/example-postmortem/

> A 3 AM on-call who has never seen QuickNotes should be able to act from the steps above without asking anyone.
