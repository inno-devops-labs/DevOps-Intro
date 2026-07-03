# Runbook — QuickNotes `HighErrorRate`

**Alert:** `HighErrorRate` · **Severity:** `page` · **Dashboard:** QuickNotes — Golden Signals (Errors panel)

## What this alert means

More than **5% of all HTTP responses have been 4xx/5xx for a sustained 5 minutes** —
users are actively getting errors from QuickNotes right now, not a one-off blip.

## Triage steps (do these in order)

1. **Confirm it's real and current.** Open the *Errors* panel on the Golden
   Signals dashboard (`:3000`) and Prometheus `:9090/graph`. Is the ratio still
   above 5%, or already recovering? Note when it started (correlate with a deploy,
   config change, or traffic spike).
2. **Find which status code dominates.** Run in Prometheus:
   `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`.
   - Mostly **5xx** → the service itself is failing (panic, dependency, disk).
   - Mostly **4xx** → likely a bad client/deploy sending malformed requests, or a
     broken caller — still user-visible, still page-worthy.
3. **Check the service is healthy and serving.** `docker compose ps` (is
   `quicknotes` `healthy`?), `docker compose logs --tail=100 quicknotes`, and
   `curl -s localhost:8080/health`. Look for restart loops, panics, or
   `bind`/permission errors in the logs.
4. **Check saturation & recent change.** Glance at the *Saturation* panel and
   `git log`/deploy history — did notes volume or a recent release line up with
   the error onset?

## Mitigations (stop the bleeding first, root-cause later)

- **Roll back the last change.** If the errors started right after a deploy or
  config/env change, revert to the previous known-good image tag and
  `docker compose up -d` (or redeploy the prior release). Fastest fix for a bad
  release.
- **Restart the unhealthy container.** `docker compose restart quicknotes` —
  clears a wedged process, a leaked resource, or a stuck state; buys time while
  you investigate.
- **Shed / block the bad traffic.** If a specific caller is flooding malformed
  requests (4xx), rate-limit or block it at the proxy/ingress so healthy users
  aren't drowned out.

## Post-incident

Once the ratio is back under 5% and stable, **write a blameless postmortem** using
the template from Lecture 1 (`lectures/lec1.md`, *Blameless Postmortems*): timeline,
impact, root cause, what made detection/mitigation slow, and concrete action items
with owners. File it and link it from the incident channel. Fix the *systemic*
cause (the thing that let a 5% error rate reach users), not just the symptom.
