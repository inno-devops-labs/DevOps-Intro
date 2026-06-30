# Runbook: QuickNotes High Error Rate

## What this alert means
The QuickNotes service is returning more than 5% HTTP 4xx/5xx errors sustained over a 5-minute window, indicating a systemic issue affecting user requests.

## Triage steps
1. **Check the Golden Signals dashboard** at `http://localhost:3000` to confirm which signal is degraded (Traffic spike? Latency increase? Saturation?).
2. **Inspect recent deployments:** Run `git log --oneline -n 5` or check CI/CD logs to see if a bad deploy caused the regression. If yes, roll back immediately.
3. **Check application logs:** Run `docker compose logs quicknotes --tail 100` to look for stack traces, panics, or specific error messages (e.g., database connection refused, malformed JSON floods).
4. **Verify dependencies:** Ensure the `quicknotes-data` volume is not full and the `init-data` container hasn't corrupted the `notes.json` file.

## Mitigations
- **Option 1 (Rollback):** If a recent deploy caused this, immediately revert to the previous stable image tag in `compose.yaml` and run `docker compose up -d`.
- **Option 2 (Rate Limiting / Block Bad Traffic):** If the errors are caused by a flood of malformed requests (e.g., 400 Bad Request), temporarily block the offending IP at the firewall or reverse proxy level.
- **Option 3 (Restart):** If the service is in a deadlocked state, run `docker compose restart quicknotes`. (Note: this is a temporary fix; investigate root cause afterward).

## Post-incident
After the incident is resolved, conduct a **blameless postmortem** within 48 hours, following the principles from Lecture 1 (Slide 20) and the Google SRE Workbook Chapter 9. The postmortem should cover:

1. **Timeline** — when did the alert fire, when was it acknowledged, when was it mitigated, when was it fully resolved.
2. **Root cause** — what actually broke (bad deploy, dependency failure, traffic spike, etc.).
3. **Detection gap** — why didn't we catch this earlier? Could the alert have fired sooner?
4. **Action items** — concrete fixes with owners and deadlines.
5. **Follow-up** — schedule a 30-day review to verify action items were completed.

Focus on **systemic fixes**, not individual blame. Link the postmortem document here once written: `[Postmortem YYYY-MM-DD](./postmortem-YYYY-MM-DD.md)`.