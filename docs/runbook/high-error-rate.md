# Runbook: High Error Rate — QuickNotes

## What this alert means

The ratio of HTTP 4xx + 5xx responses to total requests has exceeded 5% for at least 5 consecutive minutes, indicating a sustained degradation affecting users.

## Triage steps

1. Open the Grafana dashboard (http://localhost:3000, dashboard "QuickNotes — Golden Signals") and check which status codes are elevated — is it 4xx (client errors) or 5xx (server errors)?
2. Check QuickNotes logs: `docker compose logs quicknotes --tail=100` — look for stack traces, panic messages, or repeated error patterns.
3. Verify the data volume is healthy: `docker compose exec quicknotes ls -la /data/` — check that `notes.json` exists, is not empty, and has correct permissions.
4. Check Prometheus targets (`http://localhost:9090/targets`) — confirm QuickNotes is `UP`. If it's `DOWN`, the issue is the process itself, not the request handling.
5. Check host resources: `docker stats --no-stream` — look for memory pressure or CPU throttling on the QuickNotes container.

## Mitigations

1. **Restart the service:** `docker compose restart quicknotes` — resolves transient issues like file descriptor leaks or corrupted in-memory state.
2. **Roll back to the previous image:** if the error spike correlates with a recent deploy, revert to the last known-good image tag and redeploy with `docker compose up -d`.
3. **Scale horizontally:** if the issue is load-related, run additional instances behind a load balancer to distribute traffic.

## Post-incident

1. Write a postmortem within 48 hours using the blameless template from Lecture 1.
2. Identify the root cause and file a ticket for a permanent fix.
3. Review whether the alert threshold (5% for 5 min) was appropriate — adjust if the alert fired too late or too early.
4. Update this runbook with any new triage steps discovered during the incident.
