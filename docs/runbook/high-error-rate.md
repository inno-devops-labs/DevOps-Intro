# Runbook — HighErrorRate

**Alert:** `HighErrorRate` · severity `page`

## What this alert means
QuickNotes has returned 4xx/5xx responses for more than 5% of all requests, sustained for 5 minutes — users are seeing errors right now.

## Triage steps
1. Confirm it's real: open Grafana → "QuickNotes — Golden Signals" → **Errors** panel. Check the ratio is still above 5% and rising, not a single past spike.
2. Find which codes: `curl -s localhost:8080/metrics | grep quicknotes_http_responses_by_code_total`. 5xx points at the app/server; a wall of 4xx points at bad client input or a broken deploy/route.
3. Check the service is healthy and up: `docker compose ps` (is `quicknotes` healthy?) and `docker compose logs --tail=100 quicknotes` for panics or repeated handler errors.
4. Check the dependency it needs: is the data volume writable / disk full? `docker compose exec ... df -h` (or host `df -h`); a full/again read-only `/data` turns writes into 5xx.

## Mitigations (stop the bleeding)
1. **Roll back** to the last known-good image tag: `docker compose down && docker compose up -d` with the previous `quicknotes:` tag — fastest if a recent deploy caused it.
2. **Restart** the service to clear a wedged state: `docker compose restart quicknotes`; if a bad `notes.json` is the cause, restore/replace it and restart.
3. If errors are driven by one abusive client/pattern, block it upstream (rate-limit / WAF / reverse proxy) to protect the rest of traffic.

## Post-incident
Once the error ratio is back under threshold and stable, open an incident record and write a blameless postmortem using the Lecture 1 postmortem template (timeline, root cause, contributing factors, action items). Link the Grafana time range and this alert.
