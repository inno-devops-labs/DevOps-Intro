# Runbook: QuickNotesHighErrorRate

**Severity:** page
**Alert:** `QuickNotesHighErrorRate` — error ratio (4xx + 5xx) above 5% sustained for 5 minutes

**Trigger query:**

```
(sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
 / clamp_min(sum(rate(quicknotes_http_responses_by_code_total[5m])), 1)) > 0.05
```

## What this alert means

Users are getting HTTP errors (4xx or 5xx) at a rate above 5% of total traffic for a sustained 5-minute window — enough to be a real degradation, not a single bad request.

## Triage

1. **Open the Golden Signals dashboard** — `http://localhost:3000/d/golden-signals`. Look at the **Errors** panel to see *when* the ratio started climbing and the **Traffic** panel to see which status code is responsible (`code=400`, `code=404`, `code=405`, `code=500`).

2. **Check which code dominates.** Hit `/metrics` on the running service:

   ```bash
   curl -s http://localhost:8080/metrics | grep quicknotes_http_responses_by_code_total
   ```

   - A spike in `code=400` → clients are sending malformed requests. Check the request logs / a recent API contract change.
   - A spike in `code=404` → clients are hitting a path that doesn't exist. Check whether a route was renamed or a caller is on an old version.
   - A spike in `code=500` → server-side bug. Check container logs: `docker compose logs quicknotes --tail 200`.

3. **Correlate with a recent deploy.** Run:

   ```bash
   git log --oneline -10
   docker compose ps
   ```

   If QuickNotes was rebuilt or restarted within the last 15 minutes, the most likely cause is a regression in the new revision.

## Mitigations

1. **Roll back to the last known-good image.** If the error spike began right after a deploy, revert:

   ```bash
   docker compose down
   git checkout <previous-commit> -- app/
   docker compose up -d --build
   ```

   This stops the bleeding immediately; root-cause analysis happens after.

2. **If 400s dominate, rate-limit or block the offending client at the proxy layer.** In this stack, QuickNotes has no proxy — but in production you would add a rule at nginx/Caddy/Cloudflare to throttle the client by IP until the upstream issue is understood.

3. **If 5xx dominate and a rollback is not possible, scale down load.** Shed non-critical traffic so the service can recover. QuickNotes is stateless — a restart is safe:

   ```bash
   docker compose restart quicknotes
   ```

## Post-incident

After the alert clears:

1. Write a **blameless postmortem** following the Lab 1 template (`docs/postmortem-template.md` if present, or the Lecture 1 format).
2. Add a **regression test** that would have caught the issue at CI time — ideally a failing request shape that produced the 4xx/5xx.
3. Update this runbook if a step was missing or misleading.
4. If the alert fired without user impact, consider whether the threshold or `for:` duration needs tuning (see design question **g** in `submissions/lab8.md`).

## Related

- Dashboard: Grafana → SRE → **QuickNotes Golden Signals**
- Metrics source: `http://quicknotes:8080/metrics` (Prometheus job `quicknotes`)
- Design docs: `submissions/lab8.md`
