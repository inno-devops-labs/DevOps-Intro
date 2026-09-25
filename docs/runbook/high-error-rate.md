# QuickNotes High Error Rate

## What This Alert Means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes.

## Triage Steps

1. Open the QuickNotes Golden Signals dashboard and confirm whether the error ratio, traffic, and note count changed at the same time.
2. Check Prometheus target health for `quicknotes`; if the target is down, inspect the container with `docker compose ps` and `docker compose logs quicknotes`.
3. Look at recent request patterns and reproduce a failing request with `curl` against `/health`, `/notes`, and `POST /notes`.
4. If errors are mostly 4xx, check whether a caller is sending malformed JSON or missing required fields. If errors include 5xx, inspect `/data/notes.json` permissions and disk space.

## Mitigations

1. Roll back the latest application or configuration change and restart the `quicknotes` service.
2. If malformed client traffic is causing sustained 4xx volume, temporarily rate-limit or block the noisy source at the edge.
3. If persistence is broken, restore `/data/notes.json` from backup or move the service to a fresh named volume after preserving the bad file for analysis.

## Post-Incident

Record the timeline, customer impact, root cause, and follow-up actions using the Lecture 1 postmortem template. Add a regression test or alert refinement for the failure mode before closing the incident.
