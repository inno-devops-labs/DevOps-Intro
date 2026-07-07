# High Error Rate Runbook

## What this alert means

This alert means that QuickNotes is returning too many failed HTTP responses and users may be experiencing errors.

## Triage steps

1. Open the Grafana Golden Signals dashboard and check the Errors panel.
2. Verify that the QuickNotes service is healthy by visiting `/health`.
3. Check the application logs:
   ```bash
   docker compose ps
   docker compose logs quicknotes
   ```
4. Check whether Prometheus is still scraping the application successfully.

## Mitigations
- Restart the QuickNotes container if the service is unresponsive:
``` bash
docker compose restart quicknotes
```
- Roll back to the previous working version if a recent deployment introduced the errors.

## Post-incident

Write a postmortem describing:

- what happened,
- the root cause,
- how it was resolved,
- and what changes will prevent similar incidents.

Use the Lecture 1 postmortem template.