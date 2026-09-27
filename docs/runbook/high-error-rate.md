# QuickNotes High Error Rate

## What this alert means

More than 5% of QuickNotes HTTP responses have been 4xx or 5xx for at least five minutes.

## Triage steps

1. Confirm the current rule state at `http://localhost:9090/alerts` and check `http://localhost:9090/api/v1/targets` for the `quicknotes` target. A DOWN target means the error ratio may be stale.
2. Check `curl -i http://127.0.0.1:8080/health` and `docker compose --env-file .env.lab8 ps`. If the service is unhealthy or restarting, inspect `docker compose --env-file .env.lab8 logs --tail=200 quicknotes`.
3. Query the live ratio in Prometheus using the expression in [alerts.yml](../../monitoring/prometheus/alerts.yml). Inspect the per-code counters with `curl -s http://127.0.0.1:8080/metrics | grep quicknotes_http_responses_by_code_total` to distinguish bad client requests from server failures.
4. Compare the incident start with recent deployments and request patterns. Check whether failures affect `GET /health`, `GET /notes`, or `POST /notes`.

## Mitigations

- If recent malformed requests are the cause, stop the offending traffic generator or client, and confirm the error ratio falls. Do not erase stored notes to clear the alert.
- If QuickNotes is unhealthy after a recent change, roll back that change using the established deployment procedure, then check health, logs, and Prometheus target state. Restart only the affected Compose service when a restart is warranted.

## Post-incident

Record the timeline, user impact, trigger, contributing factors, detection and recovery times, and concrete follow-up actions. Use the course Lecture 1 postmortem approach: document facts without blame and track corrective work to completion. Revisit the 5% threshold and five-minute duration if the page did not correspond to user impact.
