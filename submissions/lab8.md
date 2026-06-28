# Lab 8 Submission

## Task 1: Prometheus and Grafana

### Files

- [`compose.yaml`](../compose.yaml)
- [`monitoring/prometheus/prometheus.yml`](../monitoring/prometheus/prometheus.yml)
- [`monitoring/grafana/provisioning/datasources/datasource.yml`](../monitoring/grafana/provisioning/datasources/datasource.yml)
- [`monitoring/grafana/provisioning/dashboards/dashboard.yml`](../monitoring/grafana/provisioning/dashboards/dashboard.yml)
- [`monitoring/grafana/dashboards/golden-signals.json`](../monitoring/grafana/dashboards/golden-signals.json)

### Prometheus Config

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: quicknotes
    metrics_path: /metrics
    static_configs:
      - targets:
          - quicknotes:8080
```

### Grafana Datasource

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
    jsonData:
      httpMethod: POST
```

### Grafana Dashboard Provider

```yaml
apiVersion: 1

providers:
  - name: quicknotes-golden-signals
    orgId: 1
    folder: QuickNotes
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
```

### Dashboard

The dashboard is provisioned from [`monitoring/grafana/dashboards/golden-signals.json`](../monitoring/grafana/dashboards/golden-signals.json). It contains four panels:

1. Latency proxy: `sum(rate(quicknotes_http_requests_total[5m]))`
2. Traffic: `sum(rate(quicknotes_http_requests_total[1m]))`
3. Errors: `sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) / sum(rate(quicknotes_http_requests_total[5m]))`
4. Saturation: `quicknotes_notes_total`

QuickNotes does not expose a request duration histogram, so the latency panel uses the lab-allowed synthetic request-rate proxy.

### Verification Commands

```bash
docker compose up --build -d
./scripts/generate-lab8-traffic.sh
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
```

Expected Prometheus target health:

```text
quicknotes	up	http://quicknotes:8080/metrics
```

Prometheus metric check after generated traffic:

```text
sum(quicknotes_http_requests_total) = 222
```

Prometheus config and alert rule validation:

```text
Checking /etc/prometheus/prometheus.yml
  SUCCESS: 1 rule files found
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax

Checking /etc/prometheus/rules/high-error-rate.yml
  SUCCESS: 1 rules found
```

Grafana provisioning check:

```text
Prometheus http://prometheus:9090 default=true
QuickNotes Golden Signals	dash-db	db/quicknotes-golden-signals
```

Grafana runs at `http://localhost:3000` with:

- Username: `quicknotes_admin`
- Password: `quicknotes_lab8_observe`

Dashboard screenshot: capture `QuickNotes / QuickNotes Golden Signals` after running `./scripts/generate-lab8-traffic.sh`.

### Design Questions

**a) Pull vs push:** Prometheus pulls metrics, so Prometheus must be able to reach QuickNotes over the Compose network at `quicknotes:8080`. QuickNotes does not need to know where Prometheus is. If Prometheus cannot reach QuickNotes, the target becomes `DOWN`, new samples stop arriving, and dashboards/alerts either show stale data or no data.

**b) Scrape interval trade-offs:** At `5s`, Prometheus stores many more samples, increases disk and CPU usage, and makes short-range queries noisier unless the query windows are adjusted. At `5m`, graphs become coarse, alerts react late, and `rate()` over short windows may have too few samples to be meaningful.

**c) `rate()` vs `irate()` vs `delta()`:** The Traffic panel should use `rate()` because `quicknotes_http_requests_total` is a counter and traffic should be smoothed across a short range. `irate()` is better for very spiky instant debugging, not dashboards or alerts. `delta()` is for gauges or raw change over a range, not per-second counter rates.

**d) Why provision Grafana from files:** Provisioning makes dashboards and data sources repeatable, reviewable, and version-controlled. A fresh `docker compose up` recreates the same monitoring view without manual clicking, which is exactly what an operations repo should do.

## Task 2: One Good Alert and Runbook

### Alert Rule

```yaml
groups:
  - name: quicknotes.rules
    rules:
      - alert: QuickNotesHighErrorRate
        expr: |
          (
            sum(increase(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
            /
            sum(increase(quicknotes_http_requests_total[5m]))
          ) > 0.05
          and
          sum(increase(quicknotes_http_requests_total[5m])) >= 20
        for: 5m
        labels:
          severity: page
          service: quicknotes
        annotations:
          summary: QuickNotes error ratio is above 5%
          description: More than 5% of QuickNotes requests have returned 4xx or 5xx responses for at least 5 minutes.
          runbook: docs/runbook/high-error-rate.md
```

The full rule file is [`monitoring/prometheus/rules/high-error-rate.yml`](../monitoring/prometheus/rules/high-error-rate.yml). The `for: 5m` gate and `>= 20` requests in the 5-minute window prevent paging on a single bad request during low traffic.

### Trigger Command

```bash
docker compose up --build -d
./scripts/trigger-lab8-alert.sh
```

Then open `http://localhost:9090/alerts` and watch `QuickNotesHighErrorRate` transition from `Pending` to `Firing`.

Observed alert states from Prometheus:

```text
QuickNotesHighErrorRate	pending	2026-06-28T17:29:47.060952278Z
QuickNotesHighErrorRate	firing	2026-06-28T17:29:47.060952278Z
```

Alert screenshot: capture the `Firing` state from Prometheus `Alerts` after the trigger script runs for at least 5 minutes.

### Runbook

The runbook is in [`docs/runbook/high-error-rate.md`](../docs/runbook/high-error-rate.md).

### Design Questions

**e) Why sustained for 5 minutes:** A single malformed request or short client retry burst is not a page-worthy incident. Requiring 5 sustained minutes filters transient noise and pages only when users are likely seeing an ongoing reliability problem.

**f) Symptom vs cause alert:** A cause alert might be "the Docker volume is 80% full" or "CPU is high." That is worse as a page because it may not affect users, and it may miss real user-visible failures caused by bugs, bad input, or broken dependencies. The error-ratio alert pages on the symptom users actually experience.

**g) Alert fatigue threshold:** If more than 25% of pages happen when users were not actually affected, this alert is too noisy and should be tuned. At that false-page rate, on-call engineers learn to distrust the signal, which is worse than having fewer but sharper alerts.