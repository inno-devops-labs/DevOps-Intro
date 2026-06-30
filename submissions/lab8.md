# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

## Task 1 — Prometheus + Grafana with Provisioned Dashboard

### Config files
- `monitoring/prometheus/prometheus.yml`
- `monitoring/grafana/provisioning/datasources/datasource.yml`
- `monitoring/grafana/provisioning/dashboards/dashboard.yml`
- `monitoring/grafana/provisioning/dashboards/golden-signals.json`

### Verification
- Prometheus target health:
```bash
$ curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
"up"
Dashboard screenshot: https://screenshots/golden-signals.png
Answers to design questions 1.5


a) Pull vs push
Prometheus pulls metrics from targets. This means the target (QuickNotes) must be reachable from Prometheus. If Prometheus can't reach it, the target goes DOWN and no new data is collected.

b) scrape_interval
Setting it to 5s would create too many data points and high load; 5m would miss short-lived spikes, making alerts less responsive.

c) rate() vs irate() vs delta()
rate() is best for the Traffic panel because it gives a per-second average over a time window, smoothing out bursts. irate() is for instant rate, delta() for raw increase.

d) Provisioning from files
Ensures consistency, version control, and automatic setup without manual UI steps on every fresh deployment
Task 2 — Alert + Runbook


Alert rule

Name: High Error Rate
Expression:
sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) / sum(rate(quicknotes_http_requests_total[5m]))
Threshold: > 0.05
For: 5m
Labels: severity=page
Annotations: runbook = https://github.com/abdra04-gif/DevOps-Intro/blob/feature/lab8/docs/runbook/high-error-rate.md
Screenshot of Firing alert

https://screenshots/alert-firing.png

Runbook

docs/runbook/high-error-rate.md
Answers to design questions 2.4

e) Sustained for 5 minutes
Prevents flapping and alerts only on real, prolonged issues, reducing noise.

f) Symptom vs cause
Symptom alert (errors) is user-facing; cause alert (e.g., CPU high) may be misleading if requests still succeed. The symptom is always relevant.

g) Alert fatigue threshold
If pager triggers > 10% of the time and users are not affected, the alert is too noisy.
Bonus — not attempted

