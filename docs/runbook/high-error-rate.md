# Runbook — QuickNotes High Error Rate

> Alert: `QuickNotesHighErrorRate` · severity: `page`
> Fires when (4xx+5xx) responses exceed **5% of requests, sustained 5 minutes**.

## What this alert means
More than 5% of HTTP responses from QuickNotes have been client/server errors for
five minutes straight — users are seeing failures right now, not a one-off blip.

## Triage steps (in order)
1. **Confirm it's real, not a metrics artifact.** Open Grafana → *QuickNotes —
   Golden Signals* → **Errors** panel. Is the ratio actually climbing, and is the
   **Traffic** panel non-zero? (A near-zero traffic denominator can spike the
   ratio — check absolute error counts in Prometheus:
   `sum(rate(quicknotes_http_responses_by_code_total{code=~"5.."}[5m]))`.)
2. **Split 4xx vs 5xx.** In Prometheus run
   `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`.
   Mostly **5xx** → the service is failing (bug, dependency, disk). Mostly **4xx**
   → likely bad client input or a broken caller/deploy, not the server itself.
3. **Check the service and its recent changes.** `docker compose ps` (is
   `quicknotes` healthy?), `docker compose logs --tail=100 quicknotes` for panics
   or repeated errors, and check whether a deploy/config change landed just before
   the spike.

## Mitigations (stop the bleeding)
- **Roll back** the most recent QuickNotes deploy if the spike lines up with it
  (`docker compose up -d` on the previous known-good image tag).
- **Restart the service** to clear a wedged state: `docker compose restart
  quicknotes` — buys time while you find the root cause.
- If 4xx from one abusive/broken caller: **block or rate-limit** that source at the
  proxy so healthy traffic isn't drowned out.

## Post-incident
Once errors are back under threshold, write a blameless postmortem using the
Lecture 1 template: timeline, impact, root cause, what detected it (this alert),
and follow-up actions. File it next to the code and link it from the incident.
