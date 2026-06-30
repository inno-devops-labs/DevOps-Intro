# Runbook: QuickNotes High Error Rate Alert

### 1. What this alert means
This alert fires when the HTTP error rate (4xx and 5xx responses) for the QuickNotes service exceeds 5% of total traffic sustained over a 5-minute window.

### 2. Triage steps
1. **Check Dashboard:** Open the Grafana "QuickNotes Golden Signals" dashboard and view the Errors panel to confirm if the drop is caused by 4xx client errors or 5xx server faults.
2. **Inspect Container Logs:** Run `docker compose logs quicknotes` on the deployment host to scan for application panics, database connection drops, or unhandled exceptions.
3. **Verify Upstream/Dependencies:** Ensure the container has enough disk space and file descriptors by checking host metrics (`df -h`, `free -m`).

### 3. Mitigations
* **Option A (Rollback):** If a recent deployment occurred, roll back to the previous stable Docker image tag immediately using Git or by modifying the compose file.
* **Option B (Service Restart):** If the service is stuck or suffering from a resource deadlock, force a clean restart via `docker compose restart quicknotes`.

### 4. Post-incident
Once the error rate drops below 5% and the alert resolves, open a postmortem issue in the repository tracking root-cause analysis, timeline, and preventative actions using the standard Lecture 1 postmortem template.
