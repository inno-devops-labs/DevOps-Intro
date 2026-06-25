# Runbook — QuickNotes High Error Rate

To whom might read this at 3AM —

## What does this error even mean?
QuickNotes is returning 4xx/5xx for more than 5% of requests, sustained over
5 minutes - users are seeing failures right now.

## Triage steps
1. Confirm scope in Grafana -> "QuickNotes - Golden Signals" -> Errors panel
   (http://localhost:3000): is the ratio still climbing?
2. Break down by status code in Prometheus:
   `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))`.
   5xx = server fault; 4xx = bad client input or a broken deploy contract.
3. Check the app is alive: `docker compose ps` (is `quicknotes` healthy?),
   `curl -s localhost:8080/health`, and `docker compose logs --tail=100 quicknotes`.
4. Correlate with changes: any deploy/config change in the last 30 min?

## How to mitigate
- Roll back the last image/config: `docker compose down`, restore the last good
  `compose.yaml`/image, `docker compose up -d --build`.
- Shed the bad source: if one client/IP floods malformed requests, block it at the
  proxy; if a feature faults, revert that change.
- If saturation-driven (disk/data dir full), free space and restart the container
  to restore service while you investigate.

## After it calms down
- When the error ratio holds under 5% for 10+ minutes, resolve the alert.
- Write a postmortem (Lecture 1 postmortem template): timeline, root cause, what
  detection/mitigation worked, action items.
