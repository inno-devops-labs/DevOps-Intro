# QuickNotes High Error Rate Runbook

## What This Alert Means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes, so users are likely seeing failed API calls.

## Triage Steps

1. Open the QuickNotes Golden Signals dashboard and confirm whether the error ratio is still above 5% and whether traffic changed at the same time.
2. In Prometheus, compare response-code rates with `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))` to identify whether the failures are mostly 400, 404, or 500.
3. Check application health with `curl http://localhost:8080/health` and inspect the QuickNotes container logs with `docker compose logs quicknotes --since 15m`.
4. If 5xx responses are present, check whether writes to `/data/notes.json` are failing by creating a test note and reading it back.
5. Identify the most recent operational change: image rebuild, Compose restart, data volume change, configuration edit, or traffic generation script.

## Mitigations

1. If the issue followed a new image or config change, roll back to the last known-good image or revert the configuration and restart QuickNotes.
2. If malformed client traffic is causing a 4xx storm, block or rate-limit the source and keep the service running for healthy clients.
3. If persistence is failing, stop write-heavy traffic, preserve the `quicknotes-data` volume, and restore the last good `notes.json` backup before accepting writes again.

## Post-Incident

Write a short blameless postmortem using the approach from [Lecture 1: Blameless Postmortems](../../lectures/lec1.md), including timeline, customer impact, root cause, detection gap, and follow-up action items. Update this runbook if any step was missing or misleading during the incident.
