# Runbook — QuickNotes High Error Rate

**Alert:** `QuickNotesHighErrorRate` · **Severity:** page

## What this alert means
More than 5% of HTTP responses from QuickNotes have been 4xx/5xx for at least
5 minutes — users are seeing real failures right now, not a one-off blip.

## Triage steps (in order)
1. **Confirm it's real, not a probe artifact.** Open Grafana →
   *QuickNotes — Golden Signals* (http://localhost:3000) and check the **Errors**
   panel is still above the red 5% line, and **Traffic** is non-zero (a divide on
   near-zero traffic can spike the ratio).
2. **Find which status code dominates.** In Prometheus (http://localhost:9090),
   run `topk(5, sum by (code) (rate(quicknotes_http_responses_by_code_total[5m])))`.
   `5xx` ⇒ server/app fault; mostly `4xx` ⇒ bad client traffic or a broken caller.
3. **Read the logs around the spike.** `docker compose logs --since=15m quicknotes`.
   Look for panics, `failed to persist note`, or a flood of `invalid JSON body`.
4. **Check saturation & the host.** Glance at the **Saturation** panel and
   `docker compose ps` / `docker stats quicknotes` — is the container restarting,
   OOM-killed, or out of disk for `/data`?

## Mitigations (stop the bleeding)
- **Roll back** to the last known-good image: redeploy the previous
  `quicknotes` tag and `docker compose up -d quicknotes`.
- **Restart the service** to clear a wedged process: `docker compose restart quicknotes`.
- **Shed bad traffic** if the errors are an abusive/broken client: block the
  source upstream (reverse proxy / firewall) until the caller is fixed.

## Post-incident
Once errors are back below 5%, mark the alert resolved and write a blameless
postmortem using the Lecture 1 template (`lectures/` → postmortem template):
timeline, root cause, what detected it (this alert), and the follow-up actions
to prevent recurrence.
