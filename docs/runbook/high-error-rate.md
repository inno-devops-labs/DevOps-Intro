# Runbook — HighErrorRate (QuickNotes)

**Alert:** `HighErrorRate` · **Severity:** `page` · **Dashboard:** QuickNotes — Golden Signals (Errors panel)

---

## What this alert means

More than **5% of QuickNotes HTTP responses have been 4xx/5xx for 5 sustained minutes** — users are being actively failed right now, not just a one-off blip.

## Triage steps (in order)

1. **Confirm it's real, not a probe artifact.** Open the Errors panel at http://localhost:3000 and Prometheus at http://localhost:9090. Check whether the ratio is still above 5% *now* or already recovering.
2. **Split 4xx vs 5xx.** Run in Prometheus:
   `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`.
   - Mostly **5xx** → the app or its storage is failing (server-side). Highest urgency.
   - Mostly **4xx** → likely a bad client/deploy sending malformed requests, or someone scanning endpoints.
3. **Correlate with a recent change.** Did a deploy, config push, or `listen_addr`/env change land just before the spike? Check `docker compose ps` (is `quicknotes` still `healthy`?) and `docker compose logs --tail=100 quicknotes` for panics or write errors (e.g. read-only FS / volume full).

## Mitigations (stop the bleeding first)

- **Roll back the last change.** If the spike lines up with a deploy, redeploy the previous known-good image tag (`quicknotes:lab6` prior digest) / revert the offending commit — fastest way to restore service.
- **Restart the container** to clear a wedged process or exhausted resource: `docker compose restart quicknotes`. Cheap, buys time.
- **Shed the bad traffic.** If it's a single client hammering with malformed requests (4xx flood), block that source at the proxy/ingress so real users aren't drowned out.
- **Verify storage.** If 5xx are write failures, confirm the `quicknotes-data` volume isn't full and `/data` is writable.

## Post-incident

1. Once the Errors panel is back under 5% and stable, silence/resolve the alert.
2. Write a **blameless postmortem** using the Lecture 1 template (`docs/postmortem-template.md` if present): timeline, impact (minutes above SLO / error budget burned), root cause, and dated **action items**.
3. Feed the fix back: add a regression test or a tighter alert/threshold so the same failure pages faster next time — the action items are the real value of the page.
