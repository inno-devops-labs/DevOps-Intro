\# High Error Rate Alert



\## What this alert means

The proportion of HTTP requests returning 4xx or 5xx status codes has exceeded 5% for 5 minutes.



\## Triage steps

1\. Open Grafana dashboard and check which endpoints are failing (use the Error Ratio panel).

2\. Check QuickNotes logs: `docker compose logs quicknotes`.

3\. Verify the data directory `/data` is writable and not full.



\## Mitigations

1\. Restart QuickNotes: `docker compose restart quicknotes`.

2\. If the binary is corrupted, rebuild and redeploy: `docker compose up -d --build`.



\## Post-incident

\- Write a brief postmortem with timeline, root cause, and action items.

\- Review if the alert threshold should be adjusted.

