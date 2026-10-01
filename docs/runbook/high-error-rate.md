# QuickNotes High Error Rate Runbook

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses continuously for at least 5 minutes.

## Triage steps

1. Check the Golden Signals dashboard and confirm whether the error rate is still elevated.
2. Check QuickNotes logs with `docker compose logs quicknotes --tail=100` and identify which status codes or requests are failing.
3. Check `http://localhost:9090/targets` and verify that Prometheus can still scrape QuickNotes.
4. Query `/health` and `/notes` directly to determine whether normal user requests are affected.

## Mitigations

1. Roll back or restart the QuickNotes service if the problem started after a recent deployment or configuration change.
2. Reduce or block the failing traffic source if malformed or abusive requests are causing the elevated error rate.

## Post-incident

After service is stable, document the timeline, impact, root cause, mitigation, and follow-up actions using the blameless postmortem process from Lecture 1.
