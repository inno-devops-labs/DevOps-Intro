# Runbook — HighErrorRate (QuickNotes)

## What this alert means

More than 5% of QuickNotes HTTP responses have been 4xx/5xx for 5+ minutes, users are
seeing failures right now.

## Triage steps

1. Confirm scope in Grafana → "QuickNotes — Golden Signals" → Error-ratio panel. Note whether
   it's climbing, flat, or recovering, and the absolute req/s (low traffic = fewer affected users).
2. Break down by status code in Prometheus:
   `sum by (code) (rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))`.
   - 5xx = server fault (our bug/crash). 
   - 4xx = clients/bad input or a broken caller.
3. Check the container is healthy: `docker compose ps` and `docker compose logs --tail=100 quicknotes`.
   Look for panics, restart loops, or disk/permission errors on `/data/notes.json`.

## Mitigations

- **Restart the service** to clear the broken process: `docker compose restart quicknotes`.
- **Roll back** to the last known-good image tag if a recent deploy caused it
- If 4xx is driven by one abusive client, rate-limit or block that source upstream.

## Post-incident

After the error ratio is back under 5% and stable, write a blameless postmortem (what happened, why, and what changes) with timeline, root cause, what detected it and
follow-up actions.
