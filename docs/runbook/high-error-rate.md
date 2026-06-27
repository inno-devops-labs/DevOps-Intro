# Runbook — QuickNotes High Error Rate

**Alert:** `HighErrorRate` · **Severity:** page

## What this alert means

More than 5% of QuickNotes HTTP responses have been 4xx/5xx for at least 5 minutes — users are
getting errors right now, not a one-off blip.

## Triage steps

1. **Confirm it's real.** Open the Golden Signals dashboard (Grafana → QuickNotes — Golden Signals)
   and look at the **Errors** panel. Is the ratio still above 5%, and is it 4xx (client/bad input)
   or 5xx (server)? Check **Traffic** too — a tiny request volume can make the ratio jump on noise.
2. **Check the service is up.** `curl -s http://localhost:8080/health` and
   `docker compose ps quicknotes`. If it's unhealthy or restarting, jump to Mitigations.
3. **Read the logs.** `docker compose logs --tail=100 quicknotes` — look for panics, repeated
   handler errors, or a flood of the same bad request (e.g. malformed `POST /notes`). Note whether
   the errors started right after a deploy.

## Mitigations (stop the bleeding)

- **If it started after a deploy:** roll back to the previous image tag and `docker compose up -d`.
  Reverting the change is faster than diagnosing it live.
- **If one client is flooding bad requests:** rate-limit or block that source at the proxy, so a
  single misbehaving caller stops dominating the error ratio.
- **If the process is wedged/unhealthy:** `docker compose restart quicknotes` to get back to a known
  state while you investigate the root cause.

## Post-incident

Once the error ratio is back under 5% and stable, file a blameless postmortem using the Lecture 1
template: timeline, impact, root cause, what made detection/mitigation slow, and concrete follow-ups.
Link the Grafana time range and the offending deploy/commit.
