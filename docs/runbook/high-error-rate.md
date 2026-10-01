# Runbook — QuickNotesHighErrorRate

**Alert:** `QuickNotesHighErrorRate` · **Severity:** `page` · **Rule:** [`monitoring/prometheus/alerts.yml`](../../monitoring/prometheus/alerts.yml)
**Dashboard:** Grafana → QuickNotes → *QuickNotes - Golden Signals* (http://localhost:3000) · **Prometheus:** http://localhost:9090/alerts

## 1. What this alert means

More than **5% of QuickNotes HTTP responses have been 4xx or 5xx for at least 5 minutes**, so a real share of users is getting failed requests right now.

## 2. Triage steps

1. **Confirm it's real and see how bad it is.** Open the *Errors* panel on the dashboard (or run the query below in Prometheus). Is the ratio still above 5%? Rising or falling? When did it start?
   ```promql
   sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[1m])) / sum(rate(quicknotes_http_requests_total[1m]))
   ```
2. **Find which status code is growing** — this tells you whether it's the server or the clients:
   ```promql
   sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))
   ```
   - mostly **5xx** → the app itself is failing (go to step 3 and 4)
   - mostly **4xx** (`400`, `404`, `405`) → clients send bad requests: a broken client release, a bot/scanner, or a changed API path
3. **Check the app is up and healthy.**
   ```bash
   docker compose ps                     # quicknotes must be "Up (healthy)"; check RESTARTS
   curl -s http://localhost:8080/health  # {"status":"ok",...}
   ```
   Also look at the *Traffic* panel: a sudden traffic spike at the same time points to a bot or a client loop.
4. **Read the logs around the start time.**
   ```bash
   docker compose logs --since 15m quicknotes
   ```
   Look for errors writing `/data/notes.json` (disk full / volume problem), panics, or restarts.
5. **Check what changed.** Was anything deployed or reconfigured just before the alert (`git log`, a new image, a changed env var)? A change right before the start time is the most likely cause.

## 3. Mitigations

- **Roll back the last change** — redeploy the previous image / commit (`git checkout <previous>` → `docker compose up -d --build`). First choice if the errors started right after a deploy.
- **Restart the service** if it looks stuck or broken: `docker compose restart quicknotes`, then watch the *Errors* panel for 5 minutes.
- **Block the noisy client** if one bot/client is causing the 4xx flood (rate limit or block it at the reverse proxy / firewall), so real users aren't drowned out.
- **Free disk space / fix the volume** if logs show the data file can't be written.

If none of this helps within 30 minutes, escalate to the QuickNotes owner and post a status update.

## 4. Post-incident

- Write a **blameless postmortem** using the template from [Lecture 1 — Slide 20: Blameless Postmortems](../../lectures/lec1.md): timeline, impact, root cause, what went well/badly, action items with owners.
- Add a link to the postmortem here and update this runbook if a triage step was missing or wrong.
- If the alert fired but users were not actually affected, record it — that counts toward the alert-noise budget (see `submissions/lab8.md`, question g).
