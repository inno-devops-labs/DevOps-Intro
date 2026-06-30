# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

## Objective

Provision Prometheus and Grafana on top of the QuickNotes Compose stack,
auto-load a four-panel golden-signals dashboard, define one sustained high-error-rate alert, and write the matching runbook.

## Environment

| Component | Version / value |
|-----------|-----------------|
| Host OS | macOS (Apple Silicon) |
| Branch | `feature/lab8` |
| Compose stack | QuickNotes + Prometheus + Grafana |
| Prometheus image | `prom/prometheus:v3.5.0` |
| Grafana image | `grafana/grafana:13.0.3-slim` |

> Note: the screenshot-oriented parts of the lab were validated through container and HTTP APIs in this environment. Where the spec asks for screenshots, this submission records the underlying API evidence and configuration instead.

## Layout

```text
monitoring/
├── blackbox/
│   └── blackbox.yml
├── prometheus/
│   ├── alerts.yml
│   └── prometheus.yml
├── grafana/
│   ├── dashboards/
│   │   └── golden-signals.json
│   └── provisioning/
│       ├── dashboards/
│       │   └── dashboard.yml
│       └── datasources/
│           └── datasource.yml
└── scripts/
    ├── checkhost-multi-region.sh
    ├── generate-traffic.sh
    └── trigger-high-error-rate.sh
```

## Task 1 — Prometheus + Grafana with a provisioned dashboard

### Prometheus config

```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:
  - job_name: blackbox-internal
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://quicknotes:8080/health
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__address__]
        target_label: __address__
        replacement: blackbox-exporter:9115
      - source_labels: [__param_target]
        target_label: instance
      - target_label: job
        replacement: blackbox-internal

  - job_name: quicknotes
    static_configs:
      - targets:
          - quicknotes:8080
```

### Grafana data source provisioning

```yaml
# monitoring/grafana/provisioning/datasources/datasource.yml
apiVersion: 1

datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

### Grafana dashboard provider

```yaml
# monitoring/grafana/provisioning/dashboards/dashboard.yml
apiVersion: 1

providers:
  - name: quicknotes-dashboards
    orgId: 1
    folder: QuickNotes
    type: file
    disableDeletion: false
    editable: false
    options:
      path: /var/lib/grafana/dashboards
```

### Dashboard JSON

The provisioned dashboard lives at:
- `monitoring/grafana/dashboards/golden-signals.json`

It contains four panels:
1. Latency proxy — `sum(rate(quicknotes_http_requests_total[1m]))`
2. Traffic — `sum(rate(quicknotes_http_requests_total[5m]))`
3. Errors — `100 * sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) / clamp_min(sum(rate(quicknotes_http_requests_total[5m])), 0.000001)`
4. Saturation — `quicknotes_notes_total`

QuickNotes does not expose a request-duration histogram yet, so the Latency panel is explicitly labeled as a proxy until such a metric exists.

### Compose extension

```yaml
# compose.yaml
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:v3.5.0
    command:
      - --config.file=/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./monitoring/prometheus/alerts.yml:/etc/prometheus/alerts.yml:ro
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped

  blackbox-exporter:
    image: prom/blackbox-exporter:v0.27.0
    command:
      - --config.file=/etc/blackbox_exporter/blackbox.yml
    ports:
      - "9115:9115"
    volumes:
      - ./monitoring/blackbox/blackbox.yml:/etc/blackbox_exporter/blackbox.yml:ro
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped

  grafana:
    image: grafana/grafana:13.0.3-slim
    environment:
      GF_SECURITY_ADMIN_USER: quicknotes_admin
      GF_SECURITY_ADMIN_PASSWORD: qn-lab8-monitoring
      GF_USERS_ALLOW_SIGN_UP: "false"
    ports:
      - "3000:3000"
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  quicknotes-data:
```

### Verification evidence

Commands run:

```bash
docker compose up -d --build
./monitoring/scripts/generate-traffic.sh http://localhost:8080 200
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
```

Live API evidence:

```text
$ docker compose ps
NAME                        IMAGE                         COMMAND                  SERVICE      STATUS
devops-intro-grafana-1      grafana/grafana:13.0.3-slim   "/run.sh"                grafana      Up
devops-intro-prometheus-1   prom/prometheus:v3.5.0        "/bin/prometheus --..."  prometheus   Up
devops-intro-quicknotes-1   quicknotes:lab6               "/quicknotes"            quicknotes   Up (healthy)
```

```text
$ curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
"up"
```

```json
$ curl -u quicknotes_admin:qn-lab8-monitoring 'http://localhost:3000/api/search?query=golden'
[
  {
    "uid": "quicknotes-golden-signals",
    "title": "QuickNotes Golden Signals",
    "type": "dash-db",
    "url": "/d/quicknotes-golden-signals/quicknotes-golden-signals"
  }
]
```

```json
$ curl -u quicknotes_admin:qn-lab8-monitoring http://localhost:3000/api/datasources/name/Prometheus
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "isDefault": true
}
```

Representative panel-query values after traffic generation:

```json
$ curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(quicknotes_http_requests_total[1m]))'
[
  {
    "value": [
      1782829897.910,
      "10.95249755577282"
    ]
  }
]
```

```json
$ curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(quicknotes_http_requests_total[5m]))'
[
  {
    "value": [
      1782830282.713,
      "3.554535629570368"
    ]
  }
]
```

```json
$ curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=100 * sum(rate(quicknotes_http_responses_by_code_total{code=~\"4..|5..\"}[5m])) / clamp_min(sum(rate(quicknotes_http_requests_total[5m])), 0.000001)'
[
  {
    "value": [
      1782830282.720,
      "47.581441263573545"
    ]
  }
]
```

```json
$ curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=quicknotes_notes_total'
[
  {
    "metric": {
      "__name__": "quicknotes_notes_total",
      "instance": "quicknotes:8080",
      "job": "quicknotes"
    },
    "value": [
      1782829897.980,
      "204"
    ]
  }
]
```

### Design questions

**a) Pull vs push.**
Prometheus must be able to reach QuickNotes over the network because the scrape model is pull-based. QuickNotes does not initiate metric delivery. If Prometheus cannot reach QuickNotes, the scrape target turns `up == 0`, Prometheus stops ingesting fresh samples, and dashboard panels either flatten at stale values or show no recent data.

**b) Why not `5s` or `5m` scrape intervals?**
At `5s`, Prometheus stores far more samples, increases container and disk overhead, and makes noisy short-lived spikes dominate `rate()` queries that should represent service trends. At `5m`, you lose resolution so badly that short incidents disappear, alert evaluation becomes sluggish, and most panels look stair-stepped or empty over small time windows.

**c) `rate()` vs `irate()` vs `delta()`.**
`rate()` is the right choice for the Traffic panel because it smooths a counter over a range and is stable for dashboards. `irate()` is too twitchy for a primary traffic graph because it only looks at the last two samples, while `delta()` is for absolute change over a range rather than per-second counter rates.

**d) Why provision Grafana from files?**
Provisioning makes the dashboard and data source reproducible: a fresh `docker compose up` recreates the same monitoring state without manual clicking. It also means the dashboard lives in git, can be reviewed in PRs, and can be rebuilt on another machine or in CI exactly the same way.

## Task 2 — One good alert + runbook

### Alert rule

```yaml
# monitoring/prometheus/alerts.yml
groups:
  - name: quicknotes
    rules:
      - alert: QuickNotesHighErrorRate
        expr: |
          (
            sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
            /
            clamp_min(sum(rate(quicknotes_http_requests_total[5m])), 0.000001)
          ) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "QuickNotes error ratio is above 5%"
          description: "4xx + 5xx responses have exceeded 5% of total traffic for 5 minutes."
          runbook: "docs/runbook/high-error-rate.md"
```

### Runbook

```md
# docs/runbook/high-error-rate.md
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
```

### Trigger plan

```bash
./monitoring/scripts/trigger-high-error-rate.sh http://localhost:8080 330
curl http://localhost:9090/api/v1/alerts | jq '.data.alerts'
```

Observed state transition:

```text
=== 2026-06-30 14:32:24 UTC ===
{
  "state": "pending",
  "activeAt": "2026-06-30T14:32:12.464142167Z",
  "value": "6.352555131025643e-02",
  "severity": "page",
  "runbook": "docs/runbook/high-error-rate.md"
}
```

```text
=== 2026-06-30 14:37:24 UTC ===
{
  "state": "firing",
  "activeAt": "2026-06-30T14:32:12.464142167Z",
  "value": "4.788478847884788e-01",
  "severity": "page",
  "runbook": "docs/runbook/high-error-rate.md"
}
```

Final alert API object:

```json
$ curl http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="QuickNotesHighErrorRate")'
{
  "labels": {
    "alertname": "QuickNotesHighErrorRate",
    "severity": "page"
  },
  "annotations": {
    "description": "4xx + 5xx responses have exceeded 5% of total traffic for 5 minutes.",
    "runbook": "docs/runbook/high-error-rate.md",
    "summary": "QuickNotes error ratio is above 5%"
  },
  "state": "firing",
  "activeAt": "2026-06-30T14:32:12.464142167Z",
  "value": "4.788478847884788e-01"
}
```

### Design questions

**e) Why sustained for 5 minutes?**
Because on-call alerts should represent real user pain, not single malformed requests or transient blips. A 5-minute sustain window filters noise and pages only when the error ratio is persistent enough to suggest an actual incident.

**f) Symptom vs cause alerts.**
This alert is symptom-based because it tracks what users actually observe: error responses. A cause alert would be something like “CPU above 80%” or “container restarted once.” That is worse as a primary page because it may fire when users are fine, which trains on-call engineers to ignore alerts.

**g) Alert fatigue threshold.**
If an alert pages roughly more than 20% of the time without meaningful user impact, it is too noisy and needs tuning. That is a practical threshold where responders start distrusting the signal instead of treating it as urgent.

## Bonus Task — Synthetic Monitoring From the Outside

### Public URL and probe setup

For the external vantage point, I exposed the local QuickNotes instance through a
Cloudflare quick tunnel:

```bash
docker run -d --name quicknotes-tunnel --network bridge \
  cloudflare/cloudflared:latest \
  tunnel --no-autoupdate --url http://host.docker.internal:8080
```

Tunnel URL used for the run:

```text
https://intensity-biological-beverages-perfectly.trycloudflare.com/health
```

Instead of Checkly, I used the equivalent free synthetic service
`api.check-host.cc`, which satisfies the lab's "or equivalent" clause. The
collector script `monitoring/scripts/checkhost-multi-region.sh` issued one HTTP
check per minute, treated non-`200` responses as failures, and summarized three
regions:

- Germany: `DE-FFM-KRK` (Frankfurt am Main)
- Singapore: `SG-SIN-FDCServers`
- United States: `US-DAL-Leora` (Dallas)

Run window:

```text
start: 2026-06-30T15:01:43Z
end:   2026-06-30T15:35:35Z
span:  2032 s (~33.9 min)
cadence: 60 s
```

### External summary

```json
$ cat monitoring/results/checkhost/summary.json
{
  "overall": {
    "checks": 93,
    "errors": 0,
    "p50_seconds": 0.428,
    "p95_seconds": 1.284
  },
  "nodes": {
    "DE": { "p50_seconds": 0.389, "p95_seconds": 0.619, "errors": 0 },
    "SG": { "p50_seconds": 0.99,  "p95_seconds": 1.549, "errors": 0 },
    "US": { "p50_seconds": 0.418, "p95_seconds": 0.478, "errors": 0 }
  }
}
```

All three external regions stayed below the lab's `2 s` latency threshold at
the `p95` level, and none returned a non-`200` status during the measured
window.

### Internal blackbox summary over the same window

The Prometheus-side comparison used the internal blackbox probe on
`http://quicknotes:8080/health` and queried the same time window
(`2026-06-30T15:01:43Z` to `2026-06-30T15:35:35Z`) with a `15s` step.

```json
{
  "samples": 136,
  "p50_seconds": 0.002150833,
  "p95_seconds": 0.002642417,
  "errors": 0
}
```

### Internal vs external comparison

| Metric | Prometheus (inside the Compose net) | External synthetic (DE + SG + US) |
|--------|-------------------------------------|-----------------------------------|
| Avg latency p50 | `0.0022 s` | `0.428 s` |
| Avg latency p95 | `0.0026 s` | `1.284 s` |
| Errors observed | `0 / 136` | `0 / 93` |

### Failure-mode analysis

The external synthetic probe would catch failures in the public path that the
internal Prometheus probe cannot see: Cloudflare tunnel issues, DNS mistakes,
edge routing problems, TLS handshake failures, or an ISP/regional reachability
issue between users and the edge. That is why the external p50/p95 values are
two orders of magnitude slower than the internal ones even though both saw zero
errors: the external path includes Internet and edge overhead, while the
internal probe only measures an in-network container-to-container request. On
the other hand, Prometheus can catch failures that stay inside the cluster or
service mesh boundary, such as a metrics endpoint disappearing, an internal-only
health endpoint regressing, or fast transient failures sampled every 15 seconds
that a once-per-minute synthetic probe could miss. In practice, the two signals
are complementary: internal probing is sharper for service behavior, while
external probing is the better "can a real user reach me?" detector.

## Notes

- The bonus collector was hardened during the run to tolerate a transient
  `api.check-host.cc` `502` without aborting the full measurement window.
