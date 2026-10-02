# QuickNotes High Error Rate Runbook

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses continuously for at least five minutes.

## Triage steps

1. Confirm the alert and current error ratio in Prometheus or the Grafana Golden Signals dashboard. Check whether the increase is caused primarily by 4xx or 5xx responses.

2. Check QuickNotes health and container state:

   curl http://localhost:8080/health
   docker compose ps
   docker compose logs --tail=100 quicknotes

3. Inspect the HTTP response metrics to identify which status codes are increasing:

   curl -s http://localhost:8080/metrics | grep quicknotes_http_responses_by_code_total

4. Check whether the error increase correlates with a recent deployment, configuration change, malformed client traffic, or application restart.

## Mitigations

1. If a recent application or configuration change caused the errors, roll back to the last known-good version and verify that the error ratio returns below 5%.

2. If malformed or abusive client traffic is responsible, stop or isolate the offending traffic source while keeping healthy QuickNotes traffic available.

3. If QuickNotes is unhealthy, restart the service and verify `/health`, Prometheus targets, and the Grafana dashboard before declaring recovery.

## Post-incident

After service recovery, document the timeline, impact, root cause, detection, mitigation, and follow-up actions. Record any monitoring or application improvements required to prevent recurrence.
