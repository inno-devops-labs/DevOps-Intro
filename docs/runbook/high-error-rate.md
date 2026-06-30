# Runbook — QuickNotes High Error Rate

**Alert:** `HighErrorRate` · **Severity:** page · **Dashboard:** QuickNotes — Golden Signals (Errors panel)

## What this alert means

More than 5% of QuickNotes HTTP responses have been 4xx or 5xx, sustained for 5 minutes — users are getting failures right now, not a one-off blip.

## Triage steps

1. **Confirm the scope.** Open Prometheus → `http://localhost:9090/graph` and run
   `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`.
   This tells you whether the errors are **5xx** (the app is broken) or **4xx** (clients/probes sending bad input).
2. **Check the target is up.** `http://localhost:9090/targets` — if `quicknotes` is `DOWN`, the app crashed or the container is unhealthy; skip to Mitigations.
3. **Read the app logs.** `docker compose logs --tail=100 quicknotes`. Look for panics, failed writes to `/data/notes.json`, or a repeating stack trace timestamped with the alert.
4. **Correlate with change.** `git log --oneline -5` and `docker compose images` — did a deploy, image bump, or config change land just before the spike? Recent change is the most likely cause.

## Mitigations

- **Roll back the image.** If a recent deploy is implicated, redeploy the previous known-good tag: edit `image:` in `compose.yaml` back to the prior version and `docker compose up -d quicknotes`.
- **Restart the service.** For a wedged process or a corrupt in-memory state: `docker compose restart quicknotes`. Cheap, fast, and often enough for 5xx caused by a stuck process.
- **Shed bad traffic.** If the Errors panel is dominated by 4xx from one source (a misbehaving client or load test), block/stop that source rather than touching the app.

## Post-incident

Once errors are back under 5% and stable, open a **blameless postmortem** following the course template in [Lecture 1](../../lectures/lec1.md): timeline, contributing factors, what detection/mitigation worked, and concrete follow-up actions. File the action items as issues so they don't get lost.
