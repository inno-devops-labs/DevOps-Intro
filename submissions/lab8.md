<h1>Task 1</h1>

Structure:

monitoring/
├── prometheus/
│   └── prometheus.yml
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── datasource.yml
        └── dashboards/
            ├── dashboard.yml
            └── golden-signals.json

docs/
└── runbook/
    └── high-error-rate.md

<b>monitoring/prometheus/prometheus.yml</b>

global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'quicknotes'
    static_configs:
      - targets: ['quicknotes:8080']


<b>monitoring/grafana/provisioning/datasources/datasource.yml</b>

apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true

<b>monitoring/grafana/provisioning/dashboards/dashboard.yml</b>

apiVersion: 1

providers:
  - name: 'QuickNotes'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards


<b>monitoring/grafana/provisioning/dashboards/golden-signals.json</b>

{
  "title": "QuickNotes Golden Signals",
  "uid": "quicknotes-golden",
  "panels": [
    {
      "id": 1,
      "title": "Latency (p95)",
      "type": "graph",
      "targets": [
        {
          "expr": "histogram_quantile(0.95, rate(quicknotes_request_duration_seconds_bucket[5m]))",
          "legendFormat": "p95 latency"
        }
      ],
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
    },
    {
      "id": 2,
      "title": "Traffic (requests/sec)",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(quicknotes_http_requests_total[5m])",
          "legendFormat": "req/s"
        }
      ],
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
    },
    {
      "id": 3,
      "title": "Error Ratio",
      "type": "graph",
      "targets": [
        {
          "expr": "sum(rate(quicknotes_http_requests_total{status=~\"4..|5..\"}[5m])) / sum(rate(quicknotes_http_requests_total[5m]))",
          "legendFormat": "error ratio"
        }
      ],
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
    },
    {
      "id": 4,
      "title": "Saturation (notes count)",
      "type": "graph",
      "targets": [
        {
          "expr": "quicknotes_notes_total",
          "legendFormat": "total notes"
        }
      ],
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
    }
  ],
  "schemaVersion": 27,
  "version": 1
}

<b>Change (add in) compose.yml</b>
services:
  quicknotes:
    # ... существующая конфигурация из Lab 6 ...
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  prometheus:
    image: prom/prometheus:v3.0.1
    container_name: prometheus
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
    depends_on:
      quicknotes:
        condition: service_healthy
    networks:
      - quicknotes-net

  grafana:
    image: grafana/grafana:13.0.0
    container_name: grafana
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/provisioning/dashboards/golden-signals.json:/var/lib/grafana/dashboards/golden-signals.json:ro
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=securepassword123
      - GF_INSTALL_PLUGINS=
    depends_on:
      - prometheus
    networks:
      - quicknotes-net

networks:
  quicknotes-net:
    driver: bridge

```docker-compose up -d```
Creating network "devops-intro_quicknotes-net" with driver "bridge"
Pulling prometheus (prom/prometheus:v3.0.1)...
v3.0.1: Pulling from prom/prometheus
935db57dac66: Pull complete
a95abf182525: Pull complete
bd0d00e67847: Pull complete
9818abf4f966: Pull complete
6e463c39e3fe: Pull complete
33efd2f692f0: Pull complete
1617e25568b2: Pull complete
9fa9226be034: Pull complete
1008d9ab3b47: Pull complete
4a3328469f0b: Pull complete
Digest: sha256:565ee86501224ebbb98fc10b332fa54440b100469924003359edf49cbce374bd
Status: Downloaded newer image for prom/prometheus:v3.0.1
Pulling grafana (grafana/grafana:13.0.0)...


<b>Task 2</b>

Only task1 my bad :(


<h1>Questions</h1>

a) Pull vs push: Prometheus pulls. What does that mean for which side (Prometheus or QuickNotes) needs to be reachable? What's the failure mode if Prometheus can't reach QuickNotes?

Prometheus uses a pull model: it periodically scrapes /metrics endpoints from applications. This means that Prometheus must have network reachability to QuickNotes, not the other way around

b) scrape_interval: 15s is a default. What query problems do you create by setting it to 5s? To 5m?

<b>5s:</b>

* Higher load on QuickNotes (frequent /metrics requests)
* Increased network traffic and storage pressure on Prometheus (more data points)
* Can produce noisy graphs, especially for slow‑changing metrics

<b>5m:</b>

* Graphs become too smoothed, losing important short‑term spikes
* Alerts may fire with significant delay
* Hard to detect transient error bursts

c) PromQL rate() vs irate() vs delta() — which one is right for the Traffic panel and why?

For the Traffic panel (requests per second), the correct function is rate():

* <b>rate()</b> computes the average per‑second rate over the specified interval (e.g., [5m]), giving a stable, smoothed graph
* <b>irate()</b> uses only the last two data points - too sensitive to noise
* <b>delta()</b> shows the absolute change over time, not a rate, so it does not represent "requests per second"

d) Why provision Grafana from files instead of clicking through the UI on every fresh stack?

* <b>Reproducibility</b> - the dashboard is created automatically on every stack start without manual steps.
* <b>Version control</b> - the JSON file is stored in Git, allowing change tracking and code review.
* <b>Automation</b> - when deploying to a new environment (CI/CD), the dashboard appears immediately.

e) Why "sustained for 5 minutes" instead of "fire immediately on first bad request"?

To avoid false positives from short‑lived spikes (e.g., a single 4xx from a bot or a brief network glitch). The for: 5m condition ensures the problem is persistent and real, not a transient anomaly

f) Symptom alerts vs cause alerts: the alert above is a symptom alert. What's an example of a cause alert someone might write for QuickNotes? Why is it worse?

Symptom alert (ours): error_ratio > 5% - indicates that users are actually seeing errors. Cause alert: CPU > 90% on the QuickNotes container - points to a possible cause of high load

g) Alert fatigue: Lecture 8 cited it as the bigger danger than too few alerts. What's a quantitative threshold ("page X% of the time the user wasn't actually affected") that would mean your alert is too noisy?

An alert is considered too noisy if >5-10% of its firings occur during periods when users did not experience any problem (e.g., errors on internal endpoints not used by clients, or brief outages that were not noticeable)