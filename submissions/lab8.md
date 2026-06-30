# Lab 8 submission

**Host:** Apple Silicon Mac. **Stack:** Lab 6 QuickNotes + Prometheus v3.2.1 + Grafana 13.0.2 (Compose).

---

## Task 1 — Prometheus + Grafana + Golden Signals Dashboard

### Layout

```text
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   └── alert.rules.yml
└── grafana/
    ├── dashboards/
    │   └── golden-signals.json
    └── provisioning/
        ├── datasources/datasource.yml
        └── dashboards/dashboard.yml
```

### `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/alert.rules.yml

scrape_configs:
  - job_name: quicknotes
    static_configs:
      - targets:
          - quicknotes:8080
    metrics_path: /metrics
```

### `monitoring/grafana/provisioning/datasources/datasource.yml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

### `monitoring/grafana/provisioning/dashboards/dashboard.yml`

```yaml
apiVersion: 1

providers:
  - name: golden-signals
    orgId: 1
    folder: QuickNotes
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

### Compose extension (`compose.yaml`)

Added `prometheus` (port **9090**) and `grafana` (port **3000**):

- Prometheus mounts `prometheus.yml` + `alert.rules.yml` read-only
- `depends_on: quicknotes: condition: service_healthy`
- Grafana mounts provisioning + dashboards; admin password via `GF_SECURITY_ADMIN_PASSWORD=lab8-grafana-dev` (not default `admin/admin`)

Full file: [`compose.yaml`](../compose.yaml)

### Golden signals panels

| Panel | PromQL |
|-------|--------|
| **Latency** (proxy — no histogram) | `rate(quicknotes_http_requests_total[5m])` |
| **Traffic** | `sum(rate(quicknotes_http_requests_total[5m]))` |
| **Errors** | `100 * sum(rate(quicknotes_http_responses_by_code_total{code=~"4..\|5.."}[5m])) / clamp_min(sum(rate(quicknotes_http_requests_total[5m])), 0.001)` |
| **Saturation** | `quicknotes_notes_total` |

Dashboard JSON: [`monitoring/grafana/dashboards/golden-signals.json`](../monitoring/grafana/dashboards/golden-signals.json)

### Verify

```bash
docker compose up --build -d
./scripts/lab8-generate-traffic.sh
./scripts/lab8-capture-evidence.sh
```

**Targets health:**

```
$ curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
["up"]
```

Evidence: [`targets-health.txt`](attachments/lab8/targets-health.txt), [`prometheus-targets.json`](attachments/lab8/prometheus-targets.json), [`compose-ps.txt`](attachments/lab8/compose-ps.txt), [`verify.txt`](attachments/lab8/verify.txt)

Grafana dashboard auto-loaded: **QuickNotes Golden Signals** (4 panels) in folder **QuickNotes** — verified via API: [`grafana-dashboard-meta.txt`](attachments/lab8/grafana-dashboard-meta.txt), [`grafana-dashboard-search.json`](attachments/lab8/grafana-dashboard-search.json).

Login: http://localhost:3000 — `admin` / `lab8-grafana-dev`

### Design questions (a–d)

**a) Pull vs push**

Prometheus **pulls** metrics by HTTP-scraping `/metrics` on a schedule. QuickNotes must be reachable **from Prometheus** on the Compose network (`quicknotes:8080`); QuickNotes does not need to know Prometheus exists. If Prometheus cannot scrape, the target goes **down** (`up=0`) and metrics go stale — you lose visibility but the app may still serve users.

**b) `scrape_interval: 15s` trade-offs**

At **5s**: finer resolution but 3× more scrape load, larger TSDB, noisier `rate()` on low-traffic counters. At **5m**: very coarse graphs, slow alert detection, `rate()` windows need to be wide — you can miss short incidents entirely.

**c) `rate()` vs `irate()` vs `delta()` for Traffic**

**`rate()`** — per-second average over the range window; smooth, right for dashboards and alerts on counters. **`irate()`** — instant rate from last two points; spiky, good for debugging spikes. **`delta()`** — raw increase over window, not normalized per second. Traffic panel uses **`rate()`** because we want a stable requests-per-second view.

**d) Why provision Grafana from files**

Dashboards and datasources become **version-controlled** and reproducible: `docker compose up` on any machine yields the same monitoring stack without manual UI clicks. Reviewers and teammates get identical panels; changes go through PR like application code.

---

## Task 2 — Alert + Runbook

### Alert rule (`monitoring/prometheus/alert.rules.yml`)

```yaml
groups:
  - name: quicknotes
    rules:
      - alert: HighHTTPErrorRate
        expr: |
          (
            sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
            /
            clamp_min(sum(rate(quicknotes_http_requests_total[5m])), 0.001)
          ) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: QuickNotes HTTP error ratio exceeds 5%
          runbook_url: docs/runbook/high-error-rate.md
          description: More than 5% of HTTP responses are 4xx/5xx for 5 minutes.
```

### Runbook

Full document: [`docs/runbook/high-error-rate.md`](../docs/runbook/high-error-rate.md)

Sections: what the alert means, triage steps (≥3), mitigations (≥2), post-incident (links Lecture 1 postmortem).

### Trigger alert deliberately

```bash
./scripts/lab8-trigger-alert.sh http://localhost:8080 360
# ~33% errors (1 bad POST + 2 good per loop) sustained ≥6 min
# Watch: http://localhost:9090/alerts → Pending → Firing
./scripts/lab8-capture-evidence.sh   # saves prometheus-alerts.json
```

Evidence: [`alert-trigger.log`](attachments/lab8/alert-trigger.log), [`prometheus-alerts-firing.json`](attachments/lab8/prometheus-alerts-firing.json), [`alert-firing.txt`](attachments/lab8/alert-firing.txt)

```
$ curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {name: .labels.alertname, state, value}'
{
  "name": "HighHTTPErrorRate",
  "state": "firing",
  "value": "0.317"
}
```

Error ratio during firing: **~31.7%** (well above 5% threshold).

### Design questions (e–g)

**e) Why sustained 5 minutes?**

A single malformed request or flaky client should not page anyone. **`for: 5m`** requires the error ratio to stay above threshold across multiple evaluation cycles — real user-impacting degradation, not noise.

**f) Symptom vs cause alert**

**Symptom:** high HTTP error ratio (what users feel). **Cause example:** `container_cpu_usage > 90%` — CPU can be high while errors are zero, or errors can happen at normal CPU (bad deploy, corrupt JSON file). Cause alerts page on internal state that may not correlate with user pain → alert fatigue.

**g) Alert fatigue threshold**

If **>30% of pages** fire when users were **not** affected (false positive rate from on-call survey or incident review), the alert is too noisy — widen `for:`, raise threshold, or fix the client causing 4xx bursts.

---

## Bonus — Synthetic Monitoring

**Not attempted** — requires a public URL (ngrok/cloudflared) and Checkly account. Can be added after Lab 10 deploy or with a free tunnel + Checkly API check from 2 regions.

---

## Helper scripts

| Script | Purpose |
|--------|---------|
| [`scripts/lab8-generate-traffic.sh`](../scripts/lab8-generate-traffic.sh) | ~200 mixed requests |
| [`scripts/lab8-trigger-alert.sh`](../scripts/lab8-trigger-alert.sh) | Sustained 4xx injection |
| [`scripts/lab8-capture-evidence.sh`](../scripts/lab8-capture-evidence.sh) | Dump targets/alerts JSON |

---

## Quick start

```bash
# Start Docker Desktop first, then:
cd /Users/markovav/dev/DevOps-Intro
git checkout feature/lab8
docker compose up --build -d
./scripts/lab8-generate-traffic.sh
./scripts/lab8-capture-evidence.sh
open http://localhost:3000    # Grafana
open http://localhost:9090    # Prometheus
```

## Cleanup

```bash
docker compose down           # keep volume: omit -v
docker compose down -v        # remove quicknotes data volume
# Optional: docker rmi prom/prometheus:v3.2.1 grafana/grafana:13.0.2
```
