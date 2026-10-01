# Runbook: QuickNotes HighErrorRate

## What this alert means?

More than 5% of QuickNotes HTTP responses over the last 5 minutes failed with the codes in  "4xx" or "5xx" format and the condition held for more than 5 minutes.

## Triage steps

1. On http://localhost:9090/alerts, check the ratio of the errors over all requests, to estimate the scale of the disruption.
2. On http://localhost:9090/targets. Check if `quicknotes` is DOWN or UP. If it's down, check the status bu running ```docker compose ps```
3. Check the logs ```docker compose logs quicknotes```. Do mitigatin #1 in case of errors caused by quicknotes. Otherwise do mitigation #2
4. If the quicknotes is UP, check at the Prometheus UI: ```sum(rate(quicknotes_http_responses_by_code_total[5m])) by (code)```. If it shows a lot of errors in 5xx format, then the app fails frequently for some reason. Do mitigation #1

## Mitigations

1. Roll back to the previous app version from the git and rebuild the docker containers, the problem is probably caused by the app itself.
2. The error is most likely in the container, as an example, disk space may be depleted. In this case free the disk space.
3. Unpredicted cases. Two of the mitigations above, cover most of the errors. In other cases, deeper and more professional inspection needed.

## Post-incident

Write a blameless postmortem about the error. The example can be found in the first Lecture: ([lec1.md, Slide 20](../../lectures/lec1.md)). It must be described in details and using the strict technical language, what exactly went wrong, why did it went wrong and how to prevent it in future.
