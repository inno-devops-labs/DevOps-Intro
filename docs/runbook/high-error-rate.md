# QuickNotesHighErrorRate

## What this alert means

More than 5% of instrumented QuickNotes HTTP responses are 4xx or 5xx, measured over a rolling one-minute window, and this condition has persisted for five minutes.

## Triage steps

Run commands from the repository root on the machine running Docker Compose.

1. Open http://localhost:9090/alerts and locate
   `QuickNotesHighErrorRate`. Record the state, activation time and
   current error ratio. Open the Golden Signals dashboard:
   http://localhost:3000/d/quicknotes-golden-signals.

2. Confirm the monitoring target is UP at
   http://localhost:9090/targets. Check containers and application health:

   ```bash
   docker compose ps
   curl --max-time 5 -i http://localhost:8080/health
   curl --max-time 5 -i http://localhost:8080/notes
   ```

   If the target is DOWN, missing error-rate data does not mean recovery.

3. Separate client errors from server errors using this Prometheus query:

   ```promql
   sum by (code) (
     rate(quicknotes_http_responses_by_code_total{job="quicknotes"}[1m])
   )
   ```

   HTTP 400 suggests malformed JSON or a missing title. HTTP 404 can mean
   a missing note. HTTP 500 can indicate a failure to persist a note.
   Check whether a lab traffic generator is still running.

4. Inspect recent logs and changes:

   ```bash
   docker compose logs --since=15m --tail=200 quicknotes
   git log -5 --oneline
   docker system df
   ```

   Correlate the start of errors with traffic generation, deployments
   or storage problems. Logs may not contain individual HTTP requests;
   use the status-code metrics and direct requests as additional evidence.

## Mitigations

- For malformed traffic or a broken client, stop the offending generator
  with Ctrl+C in its terminal, or pause the client. Correct the request
  body before resuming. Valid note creation requires JSON with a non-empty
  `title`.

- For errors introduced by a deployment, restore the previously verified
  application image and configuration, then recreate only QuickNotes:

  ```bash
  docker compose up -d --no-deps quicknotes
  ```

  Verify the selected image is actually the previous working image before
  running this command. Preserve the named data volume.

- If health checks fail and evidence indicates a stuck application process,
  capture its logs, then restart only the application:

  ```bash
  docker compose restart quicknotes
  ```

  A restart does not repair full storage or incorrect permissions.
  For persistence failures, restore writable capacity or correct the
  diagnosed data-volume permissions. Do not delete the data volume or
  run `docker compose down -v`.

After mitigation, verify `/health` and `/notes` return 200, the target is UP,
and the error ratio falls below 5%. Allow at least one minute plus a rule
evaluation for old errors to leave the query window. Confirm the alert
becomes inactive and monitor the dashboard for another five minutes.

## Post-incident

Write a blameless postmortem following the guidance in
[Lecture 1, Slide 20 — Blameless Postmortems](../../lectures/lec1.md).

Include impact, a UTC timeline, contributing factors, mitigation,
and preventive actions with owners and deadlines. Attach dashboard and
alert evidence. Review whether the page reflected actual user impact.

This lab counts health checks and metric scrapes in total traffic, so they
can dilute the measured error ratio. Missing traffic or missing metrics
does not trigger this rule. The latency and saturation panels are proxies.

The `severity: page` label classifies the alert. External notifications
are not configured in this lab; firing is observed in Prometheus.
