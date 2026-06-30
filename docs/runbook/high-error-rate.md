# Runbook: High Error Rate

## What this alert means

More than 5% of HTTP requests to QuickNotes are returning 4xx or 5xx status codes, sustained for at least 5 minutes.

## Triage steps

1. Check the Grafana Golden Signals dashboard — confirm the error ratio panel and check if traffic also dropped (could mean clients gave up).
2. Check QuickNotes logs: `docker compose logs quicknotes --tail=100` or on the VM `journalctl -u quicknotes --no-pager -n 100`.
3. Check if the data file at `/var/lib/quicknotes/notes.json` is readable and valid JSON. A corrupted data file causes 500s on every request.

## Mitigations

1. Restart QuickNotes: `docker compose restart quicknotes` or on the VM `systemctl restart quicknotes`. This clears transient state.
2. Roll back the last deployment or config change. Restore a known-good version of `notes.json` from backup.

## Post-incident

File a blameless postmortem following the template from Lecture 1. Document what caused the errors, how long they lasted, and what check should catch this earlier.
