# Runbook — QuickNotes High Error Rate

**Alert:** `QuickNotes high error rate` · **Severity:** `page`
**Dashboard:** Grafana → *QuickNotes — Golden Signals* (`/d/quicknotes-golden`)

---

## 1. What this alert means

More than **5% of HTTP responses have been 4xx or 5xx for at least 5 minutes** —
a sustained share of users (or clients) are getting errors instead of working
responses, so this is a real, ongoing user-facing problem, not a one-off blip.

## 2. Triage steps

Work top to bottom; stop when you find the cause.

1. **Confirm it's still happening.** Open the *Errors — 4xx+5xx ratio* panel on
   the Golden Signals dashboard. If it has already dropped below 5%, the incident
   is self-resolving — keep watching, note it, skip to Post-incident.
2. **Split 4xx from 5xx** — they mean very different things. In Prometheus
   (`http://localhost:9090`) run:
   ```promql
   sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))
   ```
   - Mostly **5xx (500)** → the server itself is failing — likely it can't
     persist notes (disk full, data volume unwritable, corrupt `notes.json`).
     Go to step 3.
   - Mostly **4xx (400/404/405)** → clients are sending bad requests — a broken
     deploy of a caller, a bad client rollout, or a scanner/bot hammering invalid
     routes. Identify the source before mitigating (it may be external noise, not
     an outage).
3. **Check the app is healthy and what it's saying.**
   ```bash
   curl -s http://localhost:8080/health          # expect {"status":"ok","notes":N}
   docker compose ps                              # quicknotes should be "healthy"
   docker compose logs --tail=100 quicknotes      # look for persist/seed errors
   ```
   A failing `/health`, a non-`healthy` container, or `failed to persist note`
   lines point straight at the store/volume.

## 3. Mitigations (stop the bleeding first, diagnose later)

- **Restart the service** to clear a wedged process or transient state:
  ```bash
  docker compose restart quicknotes
  ```
  Fast, low-risk; recovers from most 5xx caused by a bad in-memory state.
- **Roll back the most recent change.** If errors started right after a deploy
  (correlate the Errors panel's rise with your last `git`/release time), redeploy
  the previous known-good image tag — `git revert` the offending commit or
  `docker compose up -d` with the prior `quicknotes:<tag>`.
- **If it's a flood of bad 4xx traffic from one source,** block/rate-limit that
  caller at your ingress/proxy so legitimate traffic stops being drowned out.

## 4. Post-incident

- Silence/resolve the alert only once the Errors panel has held below 5% for a
  full evaluation window.
- Within 48 h, write a blameless postmortem using the template from **Lecture 1**
  (`lectures/` → postmortem template): timeline, root cause, impact, and the
  follow-up actions that stop a recurrence.
- If this alert paged but no user was actually affected (e.g. it was harmless bot
  noise), tune the rule rather than ignoring it next time — see design question
  (g) on alert fatigue.
