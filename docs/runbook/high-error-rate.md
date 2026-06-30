# Runbook: QuickNotes High Error Rate

**Alert:** `QuickNotes High Error Rate`
**Severity:** page
**Condition:** HTTP error ratio (4xx + 5xx) > 5% sustained for 5 minutes

---

## What this alert means

More than 5% of requests to QuickNotes have been returning errors continuously for at least 5 minutes, meaning users are actively experiencing failures.

---

## Triage steps

1. **Check which status codes are spiking.**
   Open Grafana → Golden Signals dashboard → Errors panel, or run:
   ```
   curl -s http://localhost:9090/api/v1/query \
     --data-urlencode 'query=quicknotes_http_responses_by_code_total' \
     | jq '.data.result[] | {code: .metric.code, value: .value[1]}'
   ```
   5xx = server-side fault. 4xx = client or routing issue.

2. **Check if the container is running and healthy.**
   ```
   docker compose ps
   docker compose logs quicknotes --tail=50
   ```
   Look for panics, `listen` errors, or `store:` failures. If the container has restarted, check `docker compose logs --since=10m`.

3. **Check if the data volume is writable.**
   QuickNotes writes `notes.json` on every `POST` and `DELETE`. If the named volume is full or permissions changed, writes return 500:
   ```
   docker compose exec -it quicknotes df -h   # won't work on scratch — check host instead
   docker volume inspect quicknotes-data
   ```
   On scratch images, check volume usage from the host: `df -h $(docker volume inspect quicknotes-data --format '{{ .Mountpoint }}')`.

4. **Confirm Prometheus is still scraping.**
   Open `http://localhost:9090/targets` — verify `quicknotes` shows `UP`. If `DOWN`, the metrics themselves may be stale and the alert could be a false positive from a scrape gap.

---

## Mitigations

1. **Restart the container** — if logs show a transient fault (SIGPIPE, temporary lock contention):
   ```
   docker compose restart quicknotes
   ```
   Verify traffic normalises within 30 seconds by watching the Errors panel.

2. **Roll back to the last known-good image** — if the error spike started after a deploy:
   ```
   docker compose down
   # edit compose.yaml: change image: quicknotes:lab6 to the previous tag
   docker compose up -d
   ```

---

## Post-incident

Once the alert resolves:

1. Record the incident timeline: when the alert fired, when it was acknowledged, when it resolved.
2. Identify root cause from logs and metrics.
3. Write a postmortem following the Lecture 1 postmortem template — focus on what failed, what detected it, and what prevents recurrence.
4. If the alert fired on noise (e.g. a deploy rollout that resolved in <5 min), consider tightening `for:` duration or excluding specific codes (e.g. `404` from static asset probes).
