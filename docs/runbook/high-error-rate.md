# Runbook: QuickNotes High Error Rate

## What this alert means

More than 5% of QuickNotes HTTP requests have returned a 4xx or 5xx response continuously for at least five minutes, so users are likely failing to read or modify notes.

## Triage steps

1. Confirm the alert and its scope. Open Prometheus at `http://localhost:9090/alerts`, check that `QuickNotesHighErrorRate` is `Firing`, and note the start time. In the Grafana dashboard at `http://localhost:3000`, compare the **Errors** and **Traffic** panels to determine whether the ratio represents sustained traffic rather than a tiny sample.
2. Identify which status codes dominate. Run the following query in Prometheus:

   ```promql
   sum by (code) (rate(quicknotes_http_responses_by_code_total{job="quicknotes"}[5m]))
   ```

   A rise in `400` or `404` responses usually points to bad client input or invalid IDs. A rise in `500` responses is a server-side failure and should be treated as more urgent.
3. Verify the application and monitoring target. Run `docker compose ps`, check `curl -fsS http://localhost:8080/health`, and confirm that `http://localhost:9090/targets` reports the `quicknotes` target as `UP`. If the target is down, inspect `docker compose logs --since=10m quicknotes prometheus` before restarting anything.
4. Correlate the start of the errors with recent activity. Review `docker compose logs --since=15m quicknotes`, recent configuration or image changes, and any load generator or client that started at the same time. Reproduce one failing request with `curl -v` and capture its status and response body without including secrets.
5. Check storage symptoms. Use the Grafana **Saturation** panel and the `/health` response to see whether the note count is growing unexpectedly. If writes fail with 5xx responses, inspect the QuickNotes logs for persistence errors and verify that the `quicknotes-data` volume is mounted.

## Mitigations

- Stop or rate-limit a misbehaving client or load generator that is producing malformed requests. This reduces user impact immediately while preserving the service and its data.
- If the errors began after an application or configuration change, roll back to the last known-good image/configuration and restart only the affected service with `docker compose up -d quicknotes`.
- If the QuickNotes process is unhealthy but the configuration and volume are intact, restart it with `docker compose restart quicknotes`, then verify `/health`, the Prometheus target, and the error ratio. Do not use `docker compose down -v`, because that deletes the persistent notes volume.

## Post-incident

After service is stable, preserve the timeline, Prometheus queries, relevant logs, the triggering request, and the mitigation result. Write a blameless postmortem using the structure in [Lecture 1 — Blameless Postmortems](../../lectures/lec1.md#-slide-20--blameless-postmortems), record corrective actions with owners and dates, and update this runbook if any triage step was missing or misleading.
