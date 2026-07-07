\# QuickNotes High Error Rate Runbook



\## What this alert means



More than 5% of QuickNotes HTTP responses are 4xx or 5xx for at least 5 minutes.



\## Triage steps



1\. Open the Grafana QuickNotes Golden Signals dashboard and check whether errors increased together with traffic.

2\. Open Prometheus and run the error-ratio query from the alert rule to confirm the alert condition.

3\. Check QuickNotes logs with `docker compose logs quicknotes --tail 100`.

4\. Check whether recent traffic includes malformed `POST /notes` requests.

5\. Verify that `/health` still returns HTTP 200.



\## Mitigations



1\. If malformed client traffic is causing the issue, temporarily block or throttle the bad client.

2\. If the service is unstable, restart QuickNotes with `docker compose restart quicknotes`.

3\. If a recent change caused the issue, roll back to the previous known-good version.



\## Post-incident



After the incident, write a short blameless postmortem using the Lecture 1 postmortem template. Include impact, timeline, root cause, detection gap, and action items.

