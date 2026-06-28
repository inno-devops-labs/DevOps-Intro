# Runbook: QuickNotes High Error Rate

## What This Alert Means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes, so users may be unable to create, read, or delete notes reliably.

## Triage Steps

1. Open Grafana at `http://localhost:3000`, go to the `QuickNotes Golden Signals` dashboard, and confirm the `Errors` panel is above 5% while `Traffic` is non-zero.
2. In Prometheus at `http://localhost:9090`, run `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))` to identify whether errors are mostly client-side 4xx responses or server-side 5xx responses.
3. Check QuickNotes health with `curl -s http://localhost:8080/health` and verify Prometheus still shows the `quicknotes` target as `UP` on `/targets`.
4. Inspect recent application logs with `docker compose logs --tail=100 quicknotes` and look for persistence errors, startup loops, or malformed request patterns.
5. If 5xx responses are present, verify the data volume is writable and has space available with `docker compose exec quicknotes /healthcheck http://127.0.0.1:8080/health` and host-level Docker volume inspection.

## Mitigations

1. If malformed client traffic is causing a 4xx flood, temporarily rate-limit or block the offending client at the ingress layer, tunnel, or reverse proxy.
2. If QuickNotes is unhealthy or returning 5xx responses, restart it with `docker compose restart quicknotes` and keep watching the error-ratio query for recovery.
3. If the data file or volume is corrupted, stop the service, preserve a copy of the Docker volume, and restore `notes.json` from the last known-good backup before bringing QuickNotes back.
4. If the problem began after a deployment, roll back to the previous known-good image tag and leave Prometheus/Grafana running to confirm recovery.

## Post-Incident

After the alert clears, write a short postmortem using the Lecture 1 template in [`lectures/lec1.md`](../../lectures/lec1.md): timeline, impact, root cause, what went well, what went poorly, and action items with owners. Attach the relevant Grafana screenshot, PromQL query results, and any log excerpts used during triage.
