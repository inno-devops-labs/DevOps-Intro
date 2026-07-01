# High Error Rate

## Summary
This alert indicates that more than 5% of HTTP requests are returning 4xx or 5xx responses for at least 5 minutes.

## Detection
Check the Grafana Golden Signals dashboard:
- Error Ratio
- Traffic
- Saturation
Verify the current error rate and identify whether errors are client-side (4xx) or server-side (5xx).

## Investigation
Inspect application logs:
```bash
docker-compose logs quicknotes
```
Inspect container health:
```bash
docker-compose ps
```
Verify Prometheus target status:
```bash
curl -s http://localhost:9090/api/v1/targets | jq .
```

## Mitigation
- Restart QuickNotes if the service is unhealthy.
- Investigate recent code or configuration changes.
- Reduce malformed client traffic if excessive 4xx responses are observed.

## Escalation
Severity: page
Escalate if the error rate remains above threshold after mitigation attempts.

## Post-incident
After the error ratio is back under 5% and stable, write a blameless postmortem (what happened, why, and what changes) with timeline, root cause, what detected it and follow-up actions.
