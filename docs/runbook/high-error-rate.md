# QuickNotes High Error Rate Runbook

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses continuously for at least 5 minutes, which indicates sustained user-visible request failures.

## Triage steps

1. Confirm that the alert is still active and check the current error ratio.

   ```bash
   curl -sG http://localhost:9090/api/v1/query \
     --data-urlencode 'query=sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[1m])) / sum(rate(quicknotes_http_requests_total[1m]))' \
     | jq '.data.result'
   ```

   Verify that QuickNotes itself is reachable:

   ```bash
   curl -s http://localhost:8080/health
   curl -s http://localhost:8080/notes
   ```

2. Identify which HTTP status codes are responsible for the failures.

   ```bash
   curl -sG http://localhost:9090/api/v1/query \
     --data-urlencode 'query=sum by (code) (rate(quicknotes_http_responses_by_code_total[1m]))' \
     | jq '.data.result'
   ```

   Check whether the failures are mainly client errors (4xx) or server errors (5xx).

3. Check the application state and recent QuickNotes logs.

   ```bash
   docker compose ps
   docker compose logs --tail=100 quicknotes
   ```

   Confirm that the QuickNotes container is healthy and look for repeated request parsing errors, crashes, storage errors, or other failures.

4. Check recent code and configuration changes that may correspond to the beginning of the incident.

   ```bash
   git log --oneline -5
   git status
   ```

   Compare the incident start time with recent deployments or configuration changes.

## Mitigations

1. If the incident started after a recent application or configuration change, revert or roll back that change and redeploy the last known-good version.

2. If malformed or abusive client traffic is causing the errors, stop, block, or rate-limit that traffic while the client-side problem is corrected.

3. If QuickNotes itself is unhealthy or stuck, preserve useful logs and restart the service:

   ```bash
   docker compose restart quicknotes
   ```

   Then verify recovery:

   ```bash
   curl -s http://localhost:8080/health
   ```

## Post-incident

After recovery, document what happened, why it happened, the user impact, the incident timeline, and the corrective actions.

Keep the postmortem blameless: focus on how the system allowed the failure and what changes will make the system safer rather than assigning fault to an individual.

Follow the course guidance in [Lecture 1 — Blameless Postmortems](../../lectures/lec1.md). Record concrete follow-up actions such as monitoring improvements, additional tests, validation, or deployment safeguards.