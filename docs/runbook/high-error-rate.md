# QuickNotes High Error Rate

## What this alert means

QuickNotes has returned 4xx or 5xx responses for more than 5% of requests for at least five consecutive minutes.

## Triage steps

1. Open the QuickNotes Golden Signals dashboard and confirm that the Errors panel is above 5%.
2. Identify the failing status codes in Prometheus with `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`.
3. Check service health with `docker compose ps` and inspect recent application logs with `docker compose logs --since 15m quicknotes`.
4. Check whether a recent deployment, configuration change, or client release coincides with the start of the errors.

## Mitigations

- Roll back QuickNotes to the last known-good image or deployment version if a recent change caused the errors.
- Block or rate-limit the client or request pattern producing malformed requests while the underlying issue is investigated.
- Restart QuickNotes only when logs indicate a transient failure and a restart is unlikely to lose data.

## Post-incident

Record the incident timeline, impact, root cause, and follow-up actions in a blameless postmortem. Use the [Lecture 1 blameless postmortems guidance](../../lectures/lec1.md#-slide-20--blameless-postmortems) and create actions that make recurrence less likely.
