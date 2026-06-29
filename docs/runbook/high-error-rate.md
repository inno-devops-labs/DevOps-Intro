# High Error Rate Runbook

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes.

## Triage steps

1. Open Prometheus at `http://localhost:9090/alerts` and confirm `QuickNotesHighErrorRate` is firing.
2. Check the current error ratio in Prometheus with `sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) / sum(rate(quicknotes_http_requests_total[5m]))`.
3. Check which status codes are increasing with `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`.
4. Review QuickNotes logs with `docker compose logs quicknotes`.
5. Verify the application health endpoint with `curl http://localhost:8080/health`.

## Mitigations

1. If malformed client traffic is causing 4xx errors, stop or block the bad traffic source.
2. If QuickNotes is returning 5xx errors, restart the service with `docker compose restart quicknotes`.
3. If logs show persistence or data volume errors, stop write traffic temporarily and inspect the `quicknotes-data` volume before restarting.

## Post-incident

After the incident, write a postmortem using the Lecture 1 postmortem template. Include the timeline, user impact, root cause, detection path, response actions, and follow-up work.
