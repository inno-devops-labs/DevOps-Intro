# QuickNotes High Error Rate Runbook

## What this alert means

The QuickNotes service has returned HTTP 4xx or 5xx responses for more than 5% of requests continuously for at least 5 minutes.

## Triage

1. Check the QuickNotes Golden Signals dashboard in Grafana and confirm when the error rate started increasing.
2. Check Prometheus metrics to identify which HTTP status codes (4xx or 5xx) are contributing to the elevated error rate.
3. Check the QuickNotes container status and logs with `docker compose ps` and `docker compose logs quicknotes` to identify application errors or unusual requests.
4. Verify the service directly with `curl http://localhost:8080/health` and test the affected endpoint.

## Mitigation

- If the issue was introduced by a recent deployment or configuration change, roll back to the last known working version.
- If malformed or unexpected client requests are causing the errors, identify and stop the problematic traffic while keeping healthy requests available.
- If the QuickNotes container is unhealthy because of a transient failure, restart the service and verify its health and metrics.

## Post-incident

After service recovery, document the incident using the [Lecture 1 blameless postmortem template](../../lectures/lec1.md#-slide-20----blameless-postmortems) and record the timeline, impact, root cause, mitigation, and follow-up actions.