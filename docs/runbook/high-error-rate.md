# QuickNotes: high HTTP error rate

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx for at least five consecutive minutes.

## Triage

1. Open the [golden-signals dashboard](http://localhost:3000/d/quicknotes-golden-signals) and [Prometheus alert page](http://localhost:9090/alerts); confirm the alert is firing, note when it began, and compare Traffic, Errors, and Latency before and after onset.
2. Determine which status codes dominate: query `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))` in Prometheus. A 400 spike may be malformed clients; 500s or rising latency may indicate server or storage failure.
3. Verify the service path: `curl -i http://localhost:8080/health`, `curl -i http://localhost:8080/notes`, `docker compose ps`, and `docker compose logs --tail=100 quicknotes`. If the host port was overridden, use `QUICKNOTES_HOST_PORT` instead of 8080.
4. Check recent deployments, changed client traffic, and the `/data` volume. Record the first bad request, affected endpoints, and whether users can still read or create notes.

## Mitigations

- If a new QuickNotes release caused 5xx responses, roll back to the last known-good image and verify `/health`, `/notes`, and the error ratio. Preserve the named data volume; do not use `docker compose down -v` during an incident.
- If malformed or abusive client requests dominate 4xx, fix or pause that caller (or apply a temporary rate limit at the edge), then verify that normal clients recover. Do not hide genuine server errors by changing the alert threshold.
- If the service is stuck but data is healthy, restart only the QuickNotes service with `docker compose restart quicknotes` and confirm the named volume remains mounted.

## Post-incident

Record customer impact, timeline, contributing conditions, what worked, and dated owners for follow-up actions. Use the [Lecture 1 blameless postmortem format](../../lectures/lec1.md) and link the dashboard/alert evidence. Update this runbook and add a regression test for the failure mode.
