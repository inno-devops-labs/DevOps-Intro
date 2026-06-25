# Lab 8 — SRE & Monitoring

## Task 1 — Prometheus + Grafana (6 pts)

### Prometheus config

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



### Dashboard panels
<img width="2089" height="369" alt="image" src="https://github.com/user-attachments/assets/65e830fa-4995-45fa-b37d-693563e16f17" />

    Traffic: rate(quicknotes_http_requests_total[5m])
    Error Ratio: sum(rate(quicknotes_http_errors_total[5m])) / sum(rate(quicknotes_http_requests_total[5m]))
    Notes Count: quicknotes_notes_total
    Health: up{job="quicknotes"}

### Dashboard JSON
{
  "title": "Golden Signals",
  "panels": [
    {
      "title": "Traffic (req/s)",
      "targets": [{"expr": "rate(quicknotes_http_requests_total[5m])"}]
    },
    {
      "title": "Error Ratio",
      "targets": [{"expr": "sum(rate(quicknotes_http_errors_total[5m])) / sum(rate(quicknotes_http_requests_total[5m]))"}]
    },
    {
      "title": "Notes Count",
      "targets": [{"expr": "quicknotes_notes_total"}]
    },
    {
      "title": "Service Health",
      "targets": [{"expr": "up{job=\"quicknotes\"}"}]
    }
  ],
  "schemaVersion": 36
}


### Grafana provisioning

**datasource.yml**
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

**dashboard.yml**
apiVersion: 1
providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards


###Design Questions
a) Pull vs push: Prometheus pulls. What does that mean for which side (Prometheus or QuickNotes) needs to be reachable? What's the failure mode if Prometheus can't reach QuickNotes?

Prometheus must be able to reach QuickNotes (pull model). QuickNotes doesn't need to know about Prometheus. If Prometheus can't reach QuickNotes - metrics are missing, no alerts, monitoring is blind until connectivity is restored.

b) scrape_interval: 15s is a default. What query problems do you create by setting it to 5s? To 5m?

5s = too much load on services, more network traffic, unnecessary resource usage. 5m = too slow to detect problems, incidents go unnoticed for 5 minutes, SLOs likely violated before detection.

c) PromQL rate() vs irate() vs delta() — which one is right for the Traffic panel and why?

rate() is best for traffic panel - smooth average over time, shows trends clearly. irate() is too spiky, delta() shows total change not per-second rate.

d) Why provision Grafana from files instead of clicking through the UI on every fresh stack?

Reproducible, version controlled in Git, consistent across environments, no manual errors, automated deployments.


###Task 2

##Alert rule

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

###Design Questions

e) Why "sustained for 5 minutes" instead of "fire immediately on first bad request"?

Prevents false alarms from single bursts. One 4xx error shouldn't wake anyone at 3 AM. Only sustained issues matter.

f) Symptom alerts vs cause alerts: the alert above is a symptom alert. What's an example of a cause alert someone might write for QuickNotes? Why is it worse?

CPU alert is a cause alert - worse because high CPU doesn't always mean user impact. Symptom alerts (error ratio) directly measure user experience.

g) Alert fatigue: Lecture 8 cited it as the bigger danger than too few alerts. What's a quantitative threshold ("page X% of the time the user wasn't actually affected") that would mean your alert is too noisy?

If >1-2% alerts are false positives - too noisy. Team starts ignoring pages, misses real incidents.
