# Lab 8 — SRE & Monitoring

## Task 1 — Prometheus + Grafana (6 pts)

### Prometheus config
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'quicknotes'
    static_configs:
      - targets: ['quicknotes:8080']
Targets status
<img width="1629" height="432" alt="image" src="https://github.com/user-attachments/assets/267e4482-f497-4197-869a-019c34525eee" />

$ curl http://localhost:9090/api/v1/targets | python3 -m json.tool | grep health
"health": "up"


Dashboard panels
<img width="2089" height="369" alt="image" src="https://github.com/user-attachments/assets/65e830fa-4995-45fa-b37d-693563e16f17" />


    Traffic: rate(quicknotes_http_requests_total[5m])

    Error Ratio: sum(rate(quicknotes_http_errors_total[5m])) / sum(rate(quicknotes_http_requests_total[5m]))

    Notes Count: quicknotes_notes_total

    Health: up{job="quicknotes"}

Design Questions

a) Pull vs push: Prometheus pulls metrics. This means Prometheus must be able to reach QuickNotes. If Prometheus can't reach it - metrics are missing, no alerts.

b) scrape_interval 5s vs 5m: 5s = too much load, 5m = too slow to detect problems.

c) rate() vs irate(): rate() is better for traffic panel - smooth average over time.

d) Provision from files: Reproducible, version controlled, no manual clicks.


Task 2

Alert rule

sum(rate(quicknotes_http_errors_total[5m])) / sum(rate(quicknotes_http_requests_total[5m])) > 0.05
FOR: 5m
severity: page
### Alert Rule Screenshot
Alert rule is configured in Grafana. It will fire when error ratio exceeds 5% for 5 minutes.

### Alert rule definition
sum(rate(quicknotes_http_errors_total[5m])) / sum(rate(quicknotes_http_requests_total[5m])) > 0.05
FOR: 5m
severity: page

### Runbook

#### High Error Rate Runbook

**What this alert means**
More than 5% of HTTP requests to QuickNotes are failing.

**Triage steps**
1. Check QuickNotes logs: `docker logs quicknotes --tail 50`
2. Check service health: `curl http://localhost:8080/health`
3. Check metrics for errors: `curl http://localhost:8080/metrics | grep errors`
4. Check if data directory is accessible: `docker exec quicknotes ls -la /data`

**Mitigations**
1. Restart QuickNotes: `docker restart quicknotes`
2. Check for disk space: `df -h`
3. Rollback to previous version if recent deployment

**Post-incident**
1. Write postmortem with timeline
2. Identify root cause
3. Add preventive measures
4. Update runbook

Design Questions

e) Why 5 minutes sustained? Prevents false alarms from single bursts.

f) Symptom vs cause alerts: CPU alert is cause alert - worse because high CPU doesn't always mean user impact.

g) Alert fatigue: If >1% alerts are false positives - too noisy.
