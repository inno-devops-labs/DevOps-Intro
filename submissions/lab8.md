# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

## Task 1 — Prometheus + Grafana with a Provisioned Dashboard

### `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: "quicknotes"
    static_configs:
      - targets: ["quicknotes:8080"]
```

### `monitoring/grafana/provisioning/datasources/datasource.yml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

### `monitoring/grafana/provisioning/dashboards/dashboard.yml`

```yaml
apiVersion: 1

providers:
  - name: QuickNotes Golden Signals
    orgId: 1
    folder: QuickNotes
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

### `monitoring/grafana/dashboards/golden-signals.json`

```json
{
  "uid": "quicknotes-golden-signals",
  "title": "QuickNotes Golden Signals",
  "tags": [
    "quicknotes",
    "sre",
    "golden-signals"
  ],
  "timezone": "browser",
  "schemaVersion": 39,
  "version": 3,
  "refresh": "10s",
  "panels": [
    {
      "id": 1,
      "title": "Latency / Proxy — Request Rate",
      "type": "timeseries",
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(rate(quicknotes_http_requests_total[1m]))",
          "legendFormat": "request-rate latency proxy"
        }
      ],
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      }
    },
    {
      "id": 2,
      "title": "Traffic — Requests per second",
      "type": "timeseries",
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(rate(quicknotes_http_requests_total[1m]))",
          "legendFormat": "req/s"
        }
      ],
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      }
    },
    {
      "id": 3,
      "title": "Errors — Error ratio",
      "type": "timeseries",
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "targets": [
        {
          "refId": "A",
          "expr": "((sum(rate(quicknotes_http_responses_by_code_total{code=~\"4..|5..\"}[5m])) or vector(0)) / sum(rate(quicknotes_http_requests_total[5m])))",
          "legendFormat": "error ratio"
        }
      ],
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 8
      }
    },
    {
      "id": 4,
      "title": "Saturation — Notes total",
      "type": "timeseries",
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "targets": [
        {
          "refId": "A",
          "expr": "quicknotes_notes_total",
          "legendFormat": "notes"
        }
      ],
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 8
      }
    }
  ]
}
```

### `compose.yaml`

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    user: "65532:65532"
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true

  prometheus:
    image: prom/prometheus:v3.11.3
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./monitoring/prometheus/rules:/etc/prometheus/rules:ro
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped

  grafana:
    image: grafana/grafana:13.0.3
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: "admin"
      GF_SECURITY_ADMIN_PASSWORD: "quicknotes-lab8-admin"
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  quicknotes-data:
```

### Screenshot of the Grafana dashboard with traffic

![Grafana dashboard](/screenshots/grafanadashboard.png)

### Stack verification

Prometheus target check:

```bash
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"up"'
```

Output:

```text
"health":"up"
```

## Task 1 — Design Questions

### a) Pull vs push: Prometheus pulls. What does that mean for which side needs to be reachable? What is the failure mode if Prometheus cannot reach QuickNotes?

Prometheus uses a pull model, so Prometheus must be able to reach the QuickNotes `/metrics` endpoint. QuickNotes does not push metrics to Prometheus; it only exposes metrics over HTTP. In this Compose setup, Prometheus reaches QuickNotes by the Compose service name `quicknotes:8080`. If Prometheus cannot reach QuickNotes, the target becomes `down`, the `up` metric becomes `0`, and dashboards or alerts based on QuickNotes metrics will show missing or stale data.

### b) What query problems are created by setting `scrape_interval` to `5s`? To `5m`?

A `5s` scrape interval creates more samples, more storage usage, and more query load for very little benefit in this small app. It can also make dashboards look noisy because very short windows react to tiny bursts. A `5m` scrape interval is too slow for incident response because Prometheus would collect too few samples for useful `rate()` calculations over short windows. With a long scrape interval, alerts and dashboards react late, and a 5-minute alert window may have too little data to evaluate accurately.

### c) `rate()` vs `irate()` vs `delta()` — which one is right for the Traffic panel and why?

`rate()` is the right function for the Traffic panel because `quicknotes_http_requests_total` is a counter. `rate()` calculates the average per-second increase over a time window and smooths short bursts, which is useful for dashboarding request traffic. `irate()` uses only the last two samples, so it is better for very spiky instant views but can be too noisy for a golden-signals dashboard. `delta()` shows the raw difference over a range and is less appropriate for a per-second request-rate panel.

### d) Why provision Grafana from files instead of clicking through the UI on every fresh stack?

Provisioning Grafana from files makes the dashboard and data source reproducible. A fresh `docker compose up` can rebuild the monitoring stack without manual UI steps. It also keeps monitoring configuration in Git, so changes are reviewable in pull requests and can be reused by other team members. Manual clicking is easy for exploration, but provisioned files are better for repeatable infrastructure.

## Task 2 — One Good Alert + Runbook

### Alert rule definition

`monitoring/prometheus/rules/quicknotes-alerts.yml`:

```yaml
groups:
  - name: quicknotes-alerts
    rules:
      - alert: QuickNotesHighErrorRate
        expr: |
          (
            (sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) or vector(0))
            /
            clamp_min(sum(rate(quicknotes_http_requests_total[5m])), 0.001)
          ) > 0.05
        for: 5m
        labels:
          severity: page
          service: quicknotes
        annotations:
          summary: "QuickNotes high HTTP error rate"
          description: "More than 5% of QuickNotes requests have returned 4xx or 5xx responses for at least 5 minutes."
          runbook: "docs/runbook/high-error-rate.md"
```

### Alert firing evidence

![Firing](/screenshots/firingscreenshot.png)

### Runbook

`docs/runbook/high-error-rate.md`:

````markdown
# Runbook — QuickNotes High Error Rate

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes.

## Triage steps

1. Open the Grafana QuickNotes Golden Signals dashboard and check whether the error ratio increased together with traffic.
2. Check Prometheus response-code metrics:
   ```promql
   sum(rate(quicknotes_http_responses_by_code_total[5m])) by (code)
   ```

3. Check QuickNotes logs:

   ```bash
   docker compose logs quicknotes --tail=100
   ```
4. Verify that the service is still healthy:

   ```bash
   curl -s http://localhost:8080/health
   ```
5. Check whether the errors are caused by malformed client traffic, a broken endpoint, or application failures.

## Mitigations

1. If the errors are caused by a bad client or test script, stop that traffic source.
2. If the latest deployment caused the issue, roll back to the previous known-good image or configuration.
3. If the service is stuck, restart QuickNotes:

   ```bash
   docker compose restart quicknotes
   ```

## Post-incident

After the incident, write a short postmortem using the Lecture 1 postmortem template. Include the timeline, user impact, root cause, detection, mitigation, and concrete follow-up actions.

````

## Task 2 — Design Questions

### e) Why "sustained for 5 minutes" instead of "fire immediately on first bad request"?

A single bad request is usually not worth paging someone because it may be a user typo, a bot request, or a short test. Sustained failure for 5 minutes is more likely to represent real user impact or a broken endpoint. The `for: 5m` condition reduces alert noise and prevents one-off errors from waking up an on-call engineer. It also gives the system time to recover from short transient spikes before the alert becomes actionable.

### f) Symptom alerts vs cause alerts: what is an example of a cause alert for QuickNotes? Why is it worse?

An example of a cause alert would be "container CPU is above 80%" or "memory usage is high". This is worse as a page because high CPU may not actually affect users if the service is still fast and successful. The high-error-rate alert is a symptom alert because it measures something users directly experience: failed HTTP responses. Symptom alerts are better for paging because they are closer to real user impact.

### g) Alert fatigue: what quantitative threshold would mean this alert is too noisy?

I would consider this alert too noisy if more than 20% of pages did not correspond to real or potential user impact. For example, if 1 out of every 5 pages is caused by harmless test traffic, bots, or short-lived noise, the alert should be tuned. Good paging alerts should be rare, actionable, and connected to user-visible problems. If the false-positive rate is higher than that, I would increase the `for` duration, adjust the threshold, or filter known non-user traffic.

## Bonus — Synthetic Monitoring from the Outside

### Checkly configuration

The Checkly API check was configured as an external synthetic probe:

```text
Method: GET
Path: /health
Frequency: 1 minute
Locations: Frankfurt, London
Assertions:
- HTTP status equals 200
- Response time is less than 2000 ms
```

QuickNotes was exposed publicly through Cloudflare Tunnel:

```bash
docker run --rm -it cloudflare/cloudflared:latest tunnel --url http://host.docker.internal:8080
```

### Compare internal vs external

QuickNotes does not expose a real HTTP request-duration histogram, so Prometheus p50/p95 uses `scrape_duration_seconds` as an internal scrape-duration proxy. Checkly measures real external HTTP response time from public regions.

| Metric          | Prometheus (inside the Compose net) | Checkly (from 2 regions) |
| --------------- | ----------------------------------: | -----------------------: |
| Avg latency p50 |      ~0.75 ms scrape-duration proxy |                   294 ms |
| Avg latency p95 |      ~1.56 ms scrape-duration proxy |                   641 ms |
| Errors observed |                                   0 |        4 HTTP 530 events |

Checkly can catch failures that internal Prometheus cannot, such as public tunnel failure, DNS problems, TLS issues, routing problems, or high latency from a specific external region. These are user-facing failures because the service may look healthy inside the Compose network while external users still cannot reach it. Prometheus can catch internal application behavior that Checkly cannot see, such as detailed response-code counters, scrape health, internal service metrics, and changes in stored notes. Prometheus is better for understanding what is happening inside the system, while Checkly is better for verifying the external user path. Together they cover different failure domains, so using both gives better monitoring than either one alone.
