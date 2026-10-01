# Runbook — QuickNotesHighErrorRate

## What this alert means

More than 5% of all HTTP responses QuickNotes returned over the last 5 minutes were 4xx or 5xx,
sustained for at least 5 minutes — users are being refused or erroring out right now.

## Triage steps

1. **Confirm it is real and still happening.** Open the Errors panel on the
   *QuickNotes — Golden Signals* dashboard (Grafana, `http://localhost:3000`, dashboard uid
   `quicknotes-golden`). If the ratio has already fallen back under 5%, the incident is
   self-resolving — keep reading, but do not page anyone else.

2. **Find out which status code it is.** In Prometheus (`http://localhost:9090`) run:

   ```promql
   sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))
   ```

   This splits the symptom into two very different incidents. **5xx** means QuickNotes is
   failing — go to step 3. **4xx** means callers are sending bad requests: a broken client
   deploy, a bad integration, or a scanner hitting nonexistent paths. A pure-4xx spike usually
   is not an outage of *this* service, but it is still worth finding the source before
   silencing it.

3. **Check whether the service is healthy at all.**

   ```bash
   curl -s http://localhost:8080/health      # expect {"notes":N,"status":"ok"}
   docker compose ps quicknotes              # expect Up ... (healthy)
   docker compose logs --tail=100 quicknotes
   ```

   A container stuck restarting, or `/health` not answering, means this is an availability
   incident rather than an error-rate one.

4. **Check whether anything changed.** Look at the most recent deploy — a new image tag, a
   changed env var (`ADDR`, `DATA_PATH`, `SEED_PATH`), or an Ansible run against the VM. Most
   sudden error-rate jumps follow a change within the previous hour.

5. **Check storage.** QuickNotes persists to `DATA_PATH` on a named volume. If the volume is
   full or the file is unwritable, writes fail while reads keep succeeding — which shows up as
   5xx on `POST /notes` only:

   ```bash
   docker compose exec quicknotes /app/healthcheck; echo $?
   docker system df
   ```

## Mitigations

- **Roll back the last change.** If the error rate started right after a deploy, redeploy the
  previous image tag: `docker compose up -d` with the prior tag pinned, or re-run the Ansible
  play from the last good commit. Fastest way to stop the bleeding; diagnose afterwards.

- **Restart the service.** `docker compose restart quicknotes` clears a wedged process or a
  leaked resource. It costs a few seconds of downtime and destroys the evidence in memory, so
  grab `docker compose logs quicknotes > /tmp/incident.log` first.

- **If it is 4xx from one caller**, block or rate-limit that source at the proxy rather than
  changing QuickNotes. The service is behaving correctly; the traffic is not.

- **If storage is the cause**, free space on the volume or move `DATA_PATH` to a larger one,
  then restart. Do not delete the notes file to make the alert stop — that is data loss, not a
  mitigation.

## Post-incident

1. Write a blameless postmortem using the template from Lecture 1 — what happened, the
   timeline, contributing factors, and what change makes the next occurrence less likely or
   less severe. No individual is named as a cause.
2. Record whether this alert actually helped. If it fired after users had already noticed, the
   threshold or the `for:` window is too slow. If it fired and nobody was affected, it is too
   noisy — see the alert-fatigue threshold in `submissions/lab8.md`.
3. If the fix was a rollback, file the real fix as follow-up work before closing the incident.
