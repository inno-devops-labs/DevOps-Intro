# High Error Rate

## What this alert means

QuickNotes is returning more than 5% `4xx` and `5xx` responses for at least 5 minutes, which indicates sustained user-visible failures.

## Triage steps

1. Open Prometheus or Grafana and confirm the alert is real by checking the current error ratio together with request traffic volume.
2. Split the failing traffic by status code and endpoint to determine whether the spike is mostly client errors (`400`/`404`) or server-side failures (`500`).
3. Check recent QuickNotes container logs and `docker compose ps` to confirm the application is still healthy and has not restarted unexpectedly.
4. Compare the Errors panel with the Traffic and Saturation panels to see whether the incident lines up with a traffic spike, data growth, or a specific request pattern.

## Mitigations

1. Stop the bleeding by throttling or blocking the failing request pattern if one bad client or script is generating malformed traffic.
2. Roll back the most recent QuickNotes configuration or image change if the error spike started immediately after a deploy.
3. If the data file is corrupted or the app is unhealthy, restart the QuickNotes container and validate `/health` before sending more traffic.

## Post-incident

Write a blameless postmortem with timeline, root cause, customer impact, and follow-up actions. Use the course guidance in [Lecture 1](../../lectures/lec1.md) under the blameless postmortem section as the template baseline.