# Runbook: HighErrorRate

**Alert:** `HighErrorRate` — `severity: page`
**Expression:** `sum without(code)(rate(quicknotes_http_responses_by_code_total{code=~"[45].."}[5m])) / rate(quicknotes_http_requests_total[5m]) > 0.05` for 5 min

---

## What this alert means

More than 5% of QuickNotes HTTP requests have been returning 4xx or 5xx responses continuously for at least 5 minutes, indicating a user-visible failure.

---

## Triage steps

1. **Check which status codes are spiking.**
   Run in Prometheus or query directly:
   ```
   rate(quicknotes_http_responses_by_code_total[5m])
   ```
   A spike in 400 suggests bad client input or a broken upstream caller. A spike in 500 suggests a server-side bug or failed dependency (e.g., disk full preventing note persistence).

2. **Check application logs for errors.**
   ```
   docker compose logs --tail=100 quicknotes
   ```
   Look for `log.Fatalf`, `store:`, or `listen:` lines. If the process exited and restarted, the restart count in `docker compose ps` will be > 0.

3. **Verify the data path is writable.**
   QuickNotes writes notes to the data volume. If the volume is full or the mount failed:
   ```
   docker compose exec quicknotes df -h /data
   ```
   A 100% disk or "read-only file system" error here explains 500s on POST/DELETE.

4. **Reproduce manually.**
   ```
   curl -v http://localhost:8080/notes
   curl -v -X POST http://localhost:8080/notes -H "Content-Type: application/json" -d '{"title":"test","body":"ok"}'
   ```
   Note the exact HTTP status and response body to narrow the scope.

---

## Mitigations

1. **Restart the service** if logs show a transient panic or the process is in a crash loop:
   ```
   docker compose restart quicknotes
   ```
   This is safe because QuickNotes persists state to a named volume; an in-memory crash does not lose data already written.

2. **Roll back the last deploy** if the error spike correlates with a recent image push:
   ```
   docker compose pull quicknotes   # or pin the previous image tag in compose.yaml
   docker compose up -d quicknotes
   ```
   Check `git log --oneline -5` to identify when the image was last changed.

---

## Post-incident

1. Confirm the alert returns to Normal in Prometheus (`/alerts`).
2. Confirm `curl http://localhost:8080/health` returns `{"status":"ok"}`.
3. Write a postmortem using the [Lecture 1 postmortem template](../../lectures/lec1.md):
   - **Timeline** of when the alert fired, when it was acknowledged, when it was resolved.
   - **Root cause** (code bug, bad deploy, infrastructure failure).
   - **Action items** with owners and due dates.
4. If the root cause was a bad deploy, add a regression test or a pre-deploy smoke check to CI.
