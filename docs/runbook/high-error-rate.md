# Runbook: QuickNotesHighErrorRate

| | |
|---|---|
| **Alert** | `QuickNotesHighErrorRate` |
| **Severity** | `page` |
| **Rule** | [`monitoring/prometheus/alerts.yml`](../../monitoring/prometheus/alerts.yml) |
| **Fires when** | 4xx + 5xx responses > 5% of all responses, for 5 minutes |
| **Dashboard** | Grafana -> QuickNotes -> QuickNotes - Golden Signals (`http://localhost:3000/d/quicknotes-golden-signals`) |
| **Owner** | Ilia Kulichenko (@Kulichcom) |

## What this alert means

For at least 5 minutes, more than 5% of requests to QuickNotes have failed with a 4xx or 5xx status, so users are getting errors right now.

## The system in 30 seconds

- **QuickNotes** is a small Go HTTP API for notes. It runs in Docker Compose as the service `quicknotes`, on port `8080`.
- Endpoints: `GET /notes`, `GET /notes/{id}`, `POST /notes`, `DELETE /notes/{id}`, `GET /health`, `GET /metrics`.
- Notes are stored in `/data/notes.json` on the Docker volume `quicknotes-data`.
- **Prometheus** (`http://localhost:9090`) scrapes `/metrics` every 15 s. **Grafana** (`http://localhost:3000`) shows the dashboard.
- All commands below are run from the repo root (`~/DevOps-Intro`).

## Triage steps

1. **Confirm the alert is real and see how big it is.**
   Open the Grafana dashboard. Check the **Errors** panel (how far above the red 5% line?) and **Traffic** (normal load, or a sudden spike?). Note the time the errors started.

2. **Find out which status codes are failing.**
   In Prometheus (`http://localhost:9090` -> Query), run:
```promql
   sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))
```
   - Mostly **4xx** (`400`, `404`, `405`): clients are sending bad or wrong requests. Often one broken client, script, or frontend release. The service itself may be fine.
   - Any **5xx** (`500`): the server is failing. Treat as more urgent - go straight to steps 3 and 4.

3. **Check that the service is up and healthy.**
```bash
   docker compose ps quicknotes
   curl -s http://localhost:8080/health
   docker inspect -f '{{.RestartCount}}' devops-intro-quicknotes-1
```
   Expected: status `(healthy)`, `/health` returns `{"status":"ok",...}`, restart count not growing. A growing restart count means the app is crashing.

4. **Read the logs from around the start time.**
```bash
   docker compose logs --since 15m quicknotes | tail -100
```
   Look for panics, "permission denied" or other errors writing `/data/notes.json`, or one request pattern repeating many times.

5. **Check what changed recently.**
```bash
   git log --oneline -5
   docker compose images quicknotes
```
   If a deploy or config change happened shortly before the errors started, it is the most likely cause.

## Mitigations

Goal: stop the bleeding first, find the root cause later.

1. **Roll back the last change** (if errors started right after a deploy):
```bash
   git log --oneline -5                 # find the last good commit
   git checkout <last-good-commit> -- app/ compose.yaml
   docker compose up -d --build quicknotes
```
   Then watch the Errors panel go back under 5%.

2. **Restart the service** (for 5xx errors with no recent change, e.g. the app is stuck):
```bash
   docker compose restart quicknotes
```
   Data on the volume is kept. If errors come back soon, a restart is not enough - use mitigation 1 or 3.

3. **Stop the misbehaving client** (for 4xx from one source, e.g. a script or job sending malformed requests):
   find and stop that client, or contact its owner. The service is working correctly by rejecting bad input, so the fix is on the client side.

4. **Last resort - storage problem** (5xx with write errors in the logs): back up the volume first, then ask the owner before touching data:
```bash
   docker run --rm -v devops-intro_quicknotes-data:/data -v "$PWD":/backup alpine \
     tar czf /backup/quicknotes-data-backup.tgz -C /data .
```

**Escalate** to the owner if the error ratio is not below 5% within 30 minutes, or right away if you are about to lose data.

## Post-incident

1. When the alert resolves, check the dashboard for 15 more minutes to make sure errors stay low.
2. Within 2 working days, write a **blameless postmortem** using the template from [Lecture 1](../../lectures/lec1.md): timeline (first error, alert pending, alert firing, mitigation, resolved), impact, root cause, what went well and badly, and action items with owners.
3. Update this runbook with anything that was missing or wrong during the incident.
4. Review the alert itself: did it fire at the right time? If it fired on harmless client 4xx traffic, consider splitting 4xx and 5xx into separate alerts.
