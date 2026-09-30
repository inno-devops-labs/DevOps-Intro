# QuickNotes high error rate

## What this alert means

More than 5% of QuickNotes HTTP responses have been 4xx or 5xx continuously
for at least five minutes, so users are experiencing a sustained failure.

## Triage steps

1. Acknowledge the page, record the start time, and confirm the alert expression
   in Prometheus: `sum(rate(quicknotes_http_responses_by_code_total{code=~"[45].."}[2m])) / clamp_min(sum(rate(quicknotes_http_responses_by_code_total[2m])), 0.001)`.
2. Separate client and server failures by querying rates for `code=~"4.."` and
   `code=~"5.."`. A 4xx increase usually points to callers or a contract change;
   a 5xx increase usually points to QuickNotes or its writable data path.
3. Check scope and user impact: inspect the Traffic and Errors dashboard panels,
   request `/health`, and issue a known-good `GET /notes` from the host.
4. Inspect runtime evidence with `docker compose ps`,
   `docker compose logs --since=15m quicknotes`, and
   `docker inspect --format '{{json .State.Health}}' "$(docker compose ps -q quicknotes)"`.
5. Correlate the first error increase with recent deployments, configuration
   changes, disk-full errors, volume permissions, and malformed-request sources.

## Mitigations

- Roll back the most recent application or configuration change and verify that
  the five-minute error ratio falls below 5%.
- If one caller is producing invalid requests, rate-limit or temporarily block
  that source while preserving healthy traffic.
- If the process is unhealthy but persistent data is intact, restart only the
  QuickNotes service with `docker compose restart quicknotes`; do not delete the
  named volume during incident response.

## Post-incident

After recovery, preserve the alert and container logs, record detection and
mitigation timestamps, identify why tests or rollout controls missed the issue,
and assign measurable corrective actions. Write a blameless postmortem using
the guidance in [Lecture 1, Slide 20](../../lectures/lec1.md#-slide-20----blameless-postmortems),
then update this runbook and the alert if any step was ambiguous or noisy.
