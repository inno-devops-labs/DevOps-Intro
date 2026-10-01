# Runbook: QuickNotesHighErrorRate

| | |
|---|---|
| Alert | `QuickNotesHighErrorRate` |
| Severity | `page` |
| Service | QuickNotes |
| Rule file | [monitoring/prometheus/rules/high-error-rate.yml](../../monitoring/prometheus/rules/high-error-rate.yml) |
| Dashboard | Grafana, folder QuickNotes, dashboard "QuickNotes Golden Signals" |

## What this alert means

More than 5% of all HTTP responses from QuickNotes have been 4xx or 5xx for the
last 5 minutes, which means real users are getting errors right now.

## Triage steps

Work top to bottom. Do not skip a step: each one removes a whole group of causes.

1. **Confirm the service is up at all.**

   ```
   curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/health
   docker compose ps
   ```

   If `/health` does not answer, or the container is not `Up (healthy)`, this is
   an outage and not an error-rate problem. Go straight to mitigation 1.

2. **Find out which status code is growing.** A rise in 5xx means the service is
   broken. A rise in 4xx usually means a client, a bad deploy of a caller, or a
   scanner is sending wrong requests.

   ```
   curl -s http://localhost:8080/metrics | grep quicknotes_http_responses_by_code_total
   ```

   The same split is in Prometheus:

   ```
   sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))
   ```

3. **Find out which requests fail.** Read the container log and look at the
   paths and the bodies of the failing requests.

   ```
   docker compose logs --since 15m quicknotes | tail -50
   ```

4. **Check whether anything changed.** Most incidents follow a change. Look at
   the last deploy and the last config change.

   ```
   docker compose images
   git log --oneline -5
   ```

5. **Check the other three golden signals** on the dashboard. If Traffic jumped
   at the same moment, the service is probably overloaded rather than broken. If
   Saturation (`quicknotes_notes_total`) is flat while errors rise, writes are
   failing.

## Mitigations

Stop the bleeding first, find the root cause afterwards.

1. **Restart the service.** It clears a stuck process, an exhausted connection
   pool or a bad in-memory state, and it takes seconds.

   ```
   docker compose restart quicknotes
   ```

2. **Roll back to the last image that was healthy.** Use this when the errors
   started right after a deploy.

   ```
   docker compose down
   docker tag quicknotes:<last-good> quicknotes:lab6
   docker compose up -d
   ```

3. **Block or rate limit the source of bad traffic.** Use this when step 2 of
   triage showed 4xx from one client or one endpoint, and the service itself is
   fine. Drop that source at the proxy, or disable the endpoint, so the rest of
   the users keep working.

4. **Restore the data file.** Use this when the log shows read or write errors
   on `/data/notes.json`. The data lives in the named volume
   `devops-intro_quicknotes-data`, so the container can be recreated without
   losing it.

## Post-incident

1. Write a blameless postmortem: what happened, when, why, and what will change.
   Blame the system and not the person. The course covers this in
   [lectures/lec1.md](../../lectures/lec1.md), Slide 20, and the full format is
   in the Google SRE Workbook, Chapter 9:
   https://sre.google/workbook/postmortem-culture/
2. Record the timeline with real timestamps: first bad request, alert fired,
   human acknowledged, mitigation applied, errors back to normal. These give the
   MTTR number from the DORA metrics.
3. Decide whether the alert behaved well. If it fired late, lower the `for`
   duration. If it fired when nobody was affected, raise the threshold. Note the
   decision in the postmortem.
4. Turn the fix into code. A manual step that was needed during the incident
   belongs in the playbook, the Compose file or the CI pipeline, so that the next
   person does not have to remember it.
