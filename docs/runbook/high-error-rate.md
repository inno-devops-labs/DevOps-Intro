# QuickNotes High Error Rate Runbook

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses continuously for at least 5 minutes.

## Triage steps

1. Check the QuickNotes container status and health with `docker compose ps`.
2. Check recent application logs with `docker compose logs quicknotes --tail=100`.
3. Check the current error ratio and HTTP response codes in Prometheus and identify which status codes increased.
4. Check the Grafana Golden Signals dashboard to determine whether the error increase coincides with changes in traffic or saturation.

## Mitigations

- Restart the QuickNotes service if the application is unhealthy or stuck: `docker compose restart quicknotes`.
- Roll back the latest application or configuration change if the error increase started immediately after a deployment.

## Post-incident

After service is restored, document the timeline, impact, root cause, resolution, and follow-up actions using the [blameless postmortem format from Lecture 1](../../lectures/lec1.md#-slide-20--blameless-postmortems).