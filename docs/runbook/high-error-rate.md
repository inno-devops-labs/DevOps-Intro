# Runbook: QuickNotes High Error Rate

**Alert:** `QuickNotesHighErrorRate`  ·  **Severity:** `page`

## What this alert means

More than 5% of all HTTP responses QuickNotes served in the last 5 minutes were
4xx or 5xx, sustained for at least 5 minutes - real users are getting failed
requests right now.

## Triage steps

Do these in order. You do not need to have seen QuickNotes before.

1. **Confirm it on the dashboard.** Open Grafana at <http://localhost:3000>
   (dashboard *QuickNotes Golden Signals*). Look at the **Errors** panel: is the
   ratio still above the red 5% line, and is it rising or recovering? Glance at
   **Traffic** - a flat error ratio on a traffic spike is different from errors
   with normal traffic.
2. **Find which status codes are failing.** Open Prometheus at
   <http://localhost:9090> and run:

   ```promql
   sum by (code) (rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
   ```

   - Mostly **5xx** (500): the server itself is failing - usually persistence
     (cannot write `notes.json`). Go to mitigation A.
   - Mostly **4xx** (400/404/405): clients are sending bad requests - a broken
     caller, a bad deploy, or an abusive source. Go to mitigation B.
3. **Check the service and its logs.**

   ```bash
   docker compose ps
   curl -s http://localhost:8080/health
   docker compose logs quicknotes --tail=50
   ```

   A failing `/health` or a restart loop points at the server (mitigation A).
4. **Check for a recent change.** Did someone just deploy, restart, or change
   config? `docker compose ps` shows container age; correlate with the start of
   the error spike on the dashboard. A change that lines up with the spike is
   your prime suspect - go to mitigation C.

## Mitigations

Pick the one that matches triage. Goal: stop the bleeding fast, investigate
after.

- **A. Server (5xx) - restart and check storage.** Restart the app to clear a
  wedged process:

  ```bash
  docker compose restart quicknotes
  ```

  If 5xx persists, the data volume is the usual cause (full disk or wrong
  ownership on `/data`). Check free space (`df -h`) and the volume
  (`docker volume inspect devops-intro_quicknotes-data`); free space or fix
  permissions, then restart.
- **B. Clients (4xx) - cut off the bad traffic.** If a single source or caller
  is flooding malformed requests, block or rate-limit it at the proxy/firewall
  in front of QuickNotes so healthy users are not drowned out. If the bad
  requests come from a recently shipped client, coordinate a client rollback.
- **C. Bad deploy - roll back.** If the spike started with a deploy, redeploy
  the last known-good image and re-check the Errors panel:

  ```bash
  # pin the previous good tag, then:
  docker compose up -d quicknotes
  ```

  Confirm the error ratio drops back under 5% before standing down.

## Post-incident

Once the error ratio is back to normal and stable:

1. Write a **blameless postmortem** within 48 hours using the course template -
   see [Lecture 1, "Blameless Postmortems"](../../lectures/lec1.md). Record the
   timeline, the root cause, and concrete action items with owners.
2. **Blame systems, not people.** The goal is to make this failure mode
   impossible (or self-healing) next time, not to find who to fault.
3. File the action items as issues so they are tracked to completion.
