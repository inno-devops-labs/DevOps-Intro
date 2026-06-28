# Runbook — QuickNotes High Error Rate

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes.

## Triage steps

1. Open the Grafana QuickNotes Golden Signals dashboard and check whether the error ratio increased together with traffic.

2. Check Prometheus response-code metrics:

   ```promql
   sum(rate(quicknotes_http_responses_by_code_total[5m])) by (code)
   ```

3. Check QuickNotes logs:

   ```bash
   docker compose logs quicknotes --tail=100
   ```

4. Verify that the service is still healthy:

   ```bash
   curl -s http://localhost:8080/health
   ```

5. Check whether the errors are caused by malformed client traffic, a broken endpoint, or application failures.

## Mitigations

1. If the errors are caused by a bad client, bot, or test script, stop that traffic source.

2. If the latest deployment caused the issue, roll back to the previous known-good image or configuration.

3. If the service is stuck or behaving incorrectly, restart QuickNotes:

   ```bash
   docker compose restart quicknotes
   ```

## Post-incident

After the incident, write a short postmortem using the Lecture 1 postmortem template. Include the timeline, user impact, root cause, detection, mitigation, and concrete follow-up actions.
