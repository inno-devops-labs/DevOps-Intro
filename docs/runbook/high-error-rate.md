# Runbook: HighErrorRate

**Alert:** `HighErrorRate`
**Severity:** page
**Source:** `monitoring/prometheus/rules/alerts.yml`

---

## What this alert means

More than 5% of QuickNotes HTTP responses have returned a 4xx or 5xx status code, sustained for at least 5 minutes — users are experiencing errors at a level that affects normal operation.

---

## Triage steps

1. **Check service health** — confirm the process is still running:
   ```bash
   curl -s http://<host>:8080/health
   # Expected: {"status":"ok","notes":<N>}
   # If connection refused: the container has crashed → go to step 5
   ```

2. **Identify the error codes** — query Prometheus to see which status codes are elevated:
   ```promql
   sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))
   ```
   - Mostly **4xx (400/404)** → bad client input or invalid requests hitting the API; check if a client is misbehaving or a frontend deploy shipped a broken API call.
   - Mostly **5xx (500)** → internal server error; check application logs immediately.

3. **Read the application logs** — look for stack traces, panic output, or "invalid JSON" / store errors:
   ```bash
   docker compose logs --tail=100 quicknotes
   # or in Kubernetes:
   kubectl logs -l app=quicknotes --tail=100
   ```

4. **Check the data file** — QuickNotes persists to a JSON file; corruption causes 500s on every read:
   ```bash
   docker exec <quicknotes-container> cat /data/notes.json | python3 -m json.tool
   ```
   If the JSON is malformed, restore from backup (see Mitigations).

5. **Check container/host resource pressure** — memory OOM or disk full can cause unexpected 500s:
   ```bash
   docker stats quicknotes --no-stream
   df -h /var/lib/docker
   ```

---

## Mitigations

1. **Restart the service** (stops the bleeding if the process is in a bad state):
   ```bash
   docker compose restart quicknotes
   # confirm:
   curl -s http://<host>:8080/health
   ```
   This is safe — QuickNotes persists state to disk; an in-flight write may be lost but the store will re-seed if the data file is missing.

2. **Restore the data file from a known-good backup** (if 500s are caused by data corruption):
   ```bash
   docker compose stop quicknotes
   docker cp /backup/notes.json <quicknotes-container>:/data/notes.json
   docker compose start quicknotes
   ```
   If no backup exists, delete `notes.json` — QuickNotes will re-seed from `seed.json` on next start (all user-created notes will be lost; treat as a data-loss incident and open a postmortem).

---

## Post-incident

1. Confirm the alert has resolved in Prometheus (`Normal` state) and the error ratio is back below 1%.
2. Write a postmortem using the [postmortem template from Lecture 1](../../lectures/lecture1.md). Include:
   - Timeline (when alert fired → when mitigated → when resolved)
   - Root cause
   - Contributing factors
   - Action items with owners and due dates
3. File a follow-up task to add structured error logging if the root cause was hard to diagnose from logs alone.
4. Review whether the `for: 5m` gate is appropriate — if the incident caused user impact in under 5 minutes, consider shortening it (with the trade-off of more noise from transient spikes).
