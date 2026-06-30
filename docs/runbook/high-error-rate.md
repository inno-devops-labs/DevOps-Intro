# Runbook: QuickNotes High Error Rate

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes.

## Triage steps

1. Open the QuickNotes Golden Signals dashboard in Grafana and check whether the error ratio is still above 5%.
2. Check whether traffic changed sharply at the same time. A real traffic spike plus errors may indicate a user-facing incident.
3. In Prometheus, inspect the request metric by status code to identify whether the errors are mostly 4xx or 5xx.
4. Check the QuickNotes container logs:

       docker compose logs quicknotes --tail=100

5. Confirm the service is reachable:

       curl -s http://localhost:8080/health

6. Check whether recent deploy/config changes happened:

       git log --oneline -5
       docker compose ps

## Mitigations

1. Restart the QuickNotes service if it is returning 5xx responses or appears stuck:

       docker compose restart quicknotes

2. Roll back the most recent configuration or image change if the issue started immediately after a deploy.
3. If malformed client traffic is causing a flood of 4xx responses, temporarily block or rate-limit the offending client/source if available.
4. If the data volume is suspected to be corrupt, stop the service and inspect `/data/notes.json` before deleting or replacing anything.

## Post-incident

After the incident is mitigated:

1. Write a short postmortem using the Lecture 1 postmortem template.
2. Record the timeline: detection time, start time, mitigation time, and resolution time.
3. Identify whether users were affected and for how long.
4. Add or improve tests, alerts, dashboard panels, or validation so this failure is easier to detect next time.
5. Update this runbook if any step was missing or misleading.
