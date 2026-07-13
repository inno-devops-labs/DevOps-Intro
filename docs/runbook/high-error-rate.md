# Runbook: High Error Rate (QuickNotes)

## What this alert means

More than 5% of QuickNotes HTTP responses are 4xx or 5xx for at least five minutes — users are seeing elevated failures.

## Triage steps

1. **Confirm the alert is real** — open Prometheus (`http://localhost:9090/alerts`) or Grafana and verify `HighErrorRate` is `Firing`, not a stale flap. Check `up{job="quicknotes"}` is `1`.
2. **Check QuickNotes health** — `curl -s http://localhost:8080/health` and `docker compose logs quicknotes --tail=100` for panics, disk errors, or seed/data path issues.
3. **Inspect error mix** — in Prometheus explore, run  
   `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`  
   to see whether errors are mostly `400` (bad clients) vs `500` (server/data failure).
4. **Check recent deploys or traffic** — did a load test, bad client, or compose change start at the same time? Correlate with `docker compose ps` and image tag.

## Mitigations

1. **Stop bad traffic** — disable or rate-limit the offending client, stop error-injection scripts, or remove a broken integration sending malformed `POST /notes` bodies.
2. **Restart QuickNotes** — `docker compose restart quicknotes` if the process is wedged but the data volume is healthy (quick recovery while investigating root cause).

## Post-incident

After the error rate is back to normal for ≥ 15 minutes, write a blameless postmortem using the [Lecture 1 postmortem template](https://github.com/inno-devops-labs/DevOps-Intro/blob/main/lectures/lec1.md) (timeline, impact, root cause, action items). Link the postmortem in the incident ticket and update this runbook if triage steps were wrong or incomplete.
