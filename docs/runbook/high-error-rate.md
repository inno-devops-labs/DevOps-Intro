# High error rate — QuickNotes

## What this alert means

The share of HTTP responses with status **4xx or 5xx** has stayed above **5%** for at least **five minutes**, so users are seeing sustained failures — not a one-off blip.

## Triage steps

1. **Confirm the symptom in Grafana** — open the *QuickNotes Golden Signals* dashboard → **Errors** panel. Note current ratio and whether Traffic is still flowing.
2. **Check Prometheus target health** — `http://localhost:9090/targets` must show `quicknotes` as `UP`. If `DOWN`, the alert may be noisy or the scrape path is broken; fix networking/scrape first.
3. **Inspect recent error codes** — query  
   `sum by (code) (rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))`  
   Distinguish floods of `400` (bad clients / bad deploy of clients) from `500` (server bug) or `404` storms.
4. **Sample failing requests** — from a host that can reach the service:  
   `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/notes`  
   and a deliberate bad POST to see if 400s dominate.
5. **Check recent deploys / compose logs** — `docker compose logs --tail=200 quicknotes` for panics, bind errors, or seed/data path issues.

## Mitigations

1. **Rollback / redeploy the last known-good image** — `docker compose up -d --build quicknotes` from a good commit, or pin the previous image tag.
2. **Shed bad traffic** — if errors are almost all `400` from a misbehaving client or load script, stop that client; if saturation (`quicknotes_notes_total` exploding), temporarily rate-limit or restart with a clean volume *only* if data loss is acceptable in this lab environment.
3. **Scale out / reduce load** (lab: single container) — stop non-essential load generators so the error ratio can recover and you can debug calmly.

## Post-incident

1. Leave the alert in **Resolved** and capture screenshots + PromQL values in the ticket.
2. Write a short blameless postmortem (timeline, contributing factors, action items) using the course Lab 1 / Lecture 1 postmortem template.
3. File follow-ups: missing latency histogram, tighter SLO burn alerts, or synthetic checks (Lab 8 bonus) if this incident was invisible from inside the Compose network alone.
4. Re-read the runbook and update triage steps if anything here was wrong or incomplete.
