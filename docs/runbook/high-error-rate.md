# Runbook: High Error Rate on QuickNotes

## What This Alert Means
The ratio of 4xx and 5xx HTTP responses to total requests has exceeded 5% sustained for 5 minutes. Users are experiencing errors.

## Triage Steps
1. **Check the dashboard.** Open Grafana → QuickNotes Golden Signals. Confirm the error panel shows elevated errors and note the time it started.
2. **Check recent deploys.** `git log --oneline -10` — did a change go out just before the spike? If yes, rollback is the first option.
3. **Check downstream dependencies.** Is the database/file store accessible? `docker compose logs quicknotes | tail -50` — look for connection errors or timeouts.
4. **Check resource usage.** `docker stats quicknotes` — is the container CPU/memory saturated?
5. **Check logs for patterns.** `docker compose logs quicknotes | grep -i error | tail -100` — are the errors all 4xx (bad client requests) or 5xx (server failures)?

## Mitigations
1. **Rollback.** If a recent deploy correlates with the spike, revert to the previous known-good image: `docker compose up -d quicknotes` with the previous tag.
2. **Restart.** If the service is degraded without an obvious cause, restart it: `docker compose restart quicknotes`.
3. **Rate-limit.** If the errors are caused by a bad actor, add rate limiting via a reverse proxy or the application itself.

## Post-Incident
After the alert resolves:
- Write an incident report using the postmortem template from Lecture 1.
- Create a GitHub issue linking to the runbook and the postmortem.
- If this alert fired for a reason not covered in the triage steps, update this runbook.