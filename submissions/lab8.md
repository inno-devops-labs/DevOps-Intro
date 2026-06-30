# Lab 8 Submission - SRE & Monitoring

## Task 1 — Prometheus + Grafana + Dashboard

### Configuration Files

prometheus.yml

global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'quicknotes'
    static_configs:
      - targets: ['quicknotes:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
    scrape_timeout: 10s

datasource.yml

apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

dashboard.yml

apiVersion: 1

providers:
  - name: 'QuickNotes Dashboards'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards

golden-signals.json

{
  "title": "QuickNotes Golden Signals",
  "panels": [
    {
      "title": "Latency (p99)",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
      "targets": [{"expr": "histogram_quantile(0.99, sum(rate(quicknotes_http_request_duration_seconds_bucket[5m])) by (le))", "refId": "A"}]
    },
    {
      "title": "Traffic",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
      "targets": [{"expr": "rate(quicknotes_http_requests_total[5m])", "refId": "A"}]
    },
    {
      "title": "Error Ratio",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
      "targets": [{"expr": "sum(rate(quicknotes_http_requests_total{status=~\"4..|5..\"}[5m])) / sum(rate(quicknotes_http_requests_total[5m])) * 100", "refId": "A"}]
    },
    {
      "title": "Saturation",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
      "targets": [{"expr": "quicknotes_notes_total", "refId": "A"}]
    }
  ]
}

### Verification

Prometheus successfully scrapes QuickNotes metrics. The target shows "up" status. QuickNotes exposes metrics at /metrics endpoint including request counts, duration histograms, and notes gauge.

### Design Questions

a) Pull vs push: Prometheus uses a pull model where it actively scrapes metrics from targets. This means Prometheus must be able to reach QuickNotes, not the other way around. If Prometheus cannot reach QuickNotes, the scrape fails, the "up" metric becomes 0, and the dashboard shows "No data". The failure mode is that metrics go stale, but QuickNotes continues operating unaffected.

b) Scrape interval implications: Setting scrape_interval to 5s creates high load on both Prometheus and QuickNotes, increases storage requirements, and may cause network congestion, but provides higher resolution data for debugging. Setting it to 5m reduces load but increases latency in detecting issues, alerting becomes slower, and short-lived problems might be missed. It can also cause aliasing in rate calculations.

c) rate() vs irate() vs delta(): rate() is correct for the Traffic panel because it calculates the per-second average rate over the specified interval, handles counter resets properly, and provides smooth, stable graphs. irate() calculates instantaneous rate over the last two samples, which is too volatile for traffic monitoring. delta() calculates the difference between values without normalizing to per-second rates, making it unsuitable for traffic measurement.

d) Provisioning benefits: Provisioning from files ensures reproducibility with every stack starting with the same configuration, version control with dashboard changes tracked in git, automation without manual UI clicks after restart, consistency across all environments, and quick disaster recovery after container rebuild.

## Task 2 — Alert + Runbook

### Alert Rule

Name: HighErrorRate

Query:
(sum(rate(quicknotes_http_requests_total{status=~"4..|5.."}[5m])) / sum(rate(quicknotes_http_requests_total[5m]))) * 100

Condition: > 5 for 5 minutes

Labels:
severity: page

Annotations:
summary: High error rate detected for QuickNotes
description: Error rate is {{ $value }}% for the last 5 minutes
runbook: https://github.com/your-repo/docs/runbook/high-error-rate.md

### Runbook

What this alert means:
The QuickNotes service is returning HTTP 4xx or 5xx errors at a rate exceeding 5% of total requests sustained over 5 minutes, indicating that users are experiencing failures.

Triage steps:
1. Open the Grafana dashboard and verify the error ratio panel shows elevated errors. Check which endpoints are failing using logs or metrics labels.
2. Check application logs using docker compose logs quicknotes --tail=100. Look for stack traces, database connection errors, or authentication failures.
3. Verify dependencies including database connectivity, disk space, memory, and CPU usage.
4. Reproduce the error using curl -X POST http://localhost:8080/notes -H "Content-Type: application/json" -d '{}'.
5. Check recent deployments and rollback if the error correlates with a recent deployment.

Mitigations:
1. Rollback to the previous version if the error started after a deployment using docker compose down followed by git checkout <previous-commit> and docker compose up -d.
2. Scale up the service using docker compose up -d --scale quicknotes=3 if the issue is related to resource exhaustion.
3. Restart the service using docker compose restart quicknotes.
4. Disable problematic features via configuration or environment variables.

Post-incident:
After resolution, document the incident using the postmortem template. Include timeline of events, root cause analysis, detection time versus resolution time, and action items to prevent recurrence. Schedule a team review within 48 hours and update monitoring and alerting if false positives or negatives occurred.

### Triggering the Alert

Traffic was generated with 10% error rate using a script that sent 50 requests with invalid JSON payloads every 10th request. The alert transitioned from Normal to Pending to Firing after 5 minutes as expected.

### Design Questions

e) Sustained for 5 minutes instead of immediate: This prevents alerting on transient issues and minor bursts of errors. It reduces noise and avoids waking on-call for short-lived problems that self-resolve. It also aligns with SLO-based alerting where sustained degradation over a measurement window matters.

f) Symptom vs cause alerts: Our alert is a symptom alert because it fires when users actually experience failures. A cause alert example would be "Database CPU > 80%" which fires when a dependency has high CPU even if users aren't affected. Cause alerts are worse because they may fire unnecessarily, require more context to interpret, are harder to set accurate thresholds for, and focus on internals rather than user experience.

g) Alert fatigue threshold: A quantitative threshold for too noisy would be when the alert pages people more than 1% of the time when users are not actually affected. In practice, if more than 1 in 100 pages occurs without user impact, it is contributing to alert fatigue and should be recalibrated. Industry best practices suggest a target of less than 1% false positive rate for production alerts.

## Acceptance Criteria

Task 1: Prometheus scrapes QuickNotes with up status, Grafana auto-provisions dashboard with 4 golden-signal panels, non-trivial graphs after traffic, all 4 design questions answered.

Task 2: Alert rule defined with sustained-breach gate, complete runbook with all 4 sections, alert observed in Firing state, design questions e, f, g answered.