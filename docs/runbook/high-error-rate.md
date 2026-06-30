# High Error Rate Alert

## What this alert means
More than 5% of requests to QuickNotes are failing with HTTP 4xx or 5xx statuses over the last 5 minutes.

## Triage steps
1. Check the Grafana dashboard → Errors panel to confirm the error ratio and see which endpoints are affected.
2. Look at the QuickNotes logs (`docker logs quicknotes`) for stack traces or specific error messages.
3. Verify the health of dependent services (database, external APIs) by checking their connectivity and response times.

## Mitigations
- **Rollback** the latest deployment if a code change was recently pushed (revert to the previous image tag).
- **Increase logging** and enable debug mode to capture more details, then restart the service to clear any transient state.

## Post-incident
After resolving, create a postmortem following the [template](https://github.com/your-repo/docs/postmortem-template.md) to document the root cause, impact, and action items.