# Runbook: High Error Rate in QuickNotes

## What this alert means
The HTTP error rate has exceeded the 5% threshold for the last 5 minutes, indicating service degradation for our users.

## Triage steps
1. Check the "Golden Signals" dashboard in Grafana to see if Traffic and Latency have also been affected.
2. Inspect the container logs by running: `docker compose logs quicknotes --tail 100`.
3. Check the container status via `docker ps` (ensure the container is not crash-looping or constantly restarting).

## Mitigations
1. **Rollback:** If new changes were recently deployed, roll back to the previous Docker image.
2. **Restart:** Run `docker compose restart quicknotes` to clear temporary in-memory states and reset the service.

## Post-incident
After the service has been stabilized, conduct a root cause analysis according to the [Lecture 1 Post-mortem template](https://github.com/alinkaPestoletik/DevOps-Intro/blob/main/lectures/lec1.md#-slide-19---when-devops-wasnt-there-real-incidents).