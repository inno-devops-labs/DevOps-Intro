# High Error Rate

## What this alert means

QuickNotes is returning 4xx and 5xx responses for more than 5% of requests, sustained for at least 5 minutes.

## Triage steps

1. Confirm the alert is still active by checking Prometheus `/alerts` and Grafana panels for traffic and error ratio over the last 15 minutes.
2. Compare healthy versus failing requests with `curl` against `/health`, `/notes`, and one deliberately malformed `POST /notes` to determine whether the issue is broad or isolated to a route.
3. Inspect the QuickNotes container logs with `docker compose logs --tail=200 quicknotes` and correlate timestamps with the error spike.
4. Check whether the backing data file or mounted volume is writable and present, because write failures can surface as 5xx on note creation.

## Mitigations

1. Roll back the most recent change to the QuickNotes image or monitoring-related config if the spike started immediately after a deploy.
2. Temporarily reduce bad traffic by blocking malformed clients, rate-limiting the offending caller, or disabling the specific integration sending invalid payloads.
3. Restart the `quicknotes` container if the service is wedged but the root cause is still under investigation.

## Post-incident

Write a short blameless postmortem using the Lecture 1 template: timeline, customer impact, root cause, contributing factors, and concrete follow-up actions.
