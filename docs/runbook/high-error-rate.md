# Runbook: High HTTP Error Rate

## What this alert means

QuickNotes is returning more than 5% HTTP 4xx/5xx responses sustained for five minutes — users are likely seeing failed requests.

## Triage steps

1. **Confirm the alert** — open Prometheus (`http://localhost:9090/alerts`) or Grafana and verify `HighErrorRate` is `Firing`; note the start time.
2. **Check QuickNotes health** — `curl -s http://localhost:8080/health` and `docker compose ps quicknotes`; confirm the container is `healthy` and `status` is `ok`.
3. **Inspect recent logs** — `docker compose logs --tail=100 quicknotes` for panics, permission errors, or repeated 4xx patterns.
4. **Check the error ratio query** — in Prometheus, run:
   ```promql
   sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
   /
   sum(rate(quicknotes_http_requests_total[5m]))
   ```
   Break down by `code` label to see whether errors are mostly 400s (bad clients) or 5xx (server faults).

## Mitigations

1. **Restart QuickNotes** — `docker compose restart quicknotes` to clear a stuck process or bad in-memory state while you investigate.
2. **Stop bad traffic** — if a script or client is sending malformed `POST /notes` bodies, pause or throttle it; errors should fall below 5% within the next evaluation window.

## Post-incident

1. Write a **blameless postmortem** using the format in [Lecture 1 — postmortems](../../lectures/lec1.md) (what happened, why, action items with owners and dates).
2. Add or tighten tests/alerts if the root cause was preventable (e.g., validation bug, missing rate limit).
3. Update this runbook if any triage step was missing or misleading.
