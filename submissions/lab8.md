# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

## Layout

```
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   └── rules/
│       └── alerts.yml
└── grafana/
    ├── provisioning/
    │   ├── datasources/
    │   │   └── datasource.yml
    │   └── dashboards/
    │       └── dashboard.yml
    └── dashboards/
        └── golden-signals.json

docs/runbook/high-error-rate.md
compose.yaml  (extended from Lab 6)
```

---

## Task 1 — Configuration Files

### `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: quicknotes
    static_configs:
      - targets:
          - quicknotes:8080
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
  - name: default
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

### `compose.yaml` (extended from Lab 6)

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      start_period: 5s
      retries: 3
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:v3.4.1
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./monitoring/prometheus/rules:/etc/prometheus/rules:ro
      - prometheus-data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped

  grafana:
    image: grafana/grafana:12.0.2
    ports:
      - "3000:3000"
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
      - grafana-data:/var/lib/grafana
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: quicknotes-lab8
      GF_USERS_ALLOW_SIGN_UP: "false"
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  quicknotes-data:
  prometheus-data:
  grafana-data:
```

---

## Task 1 — Prometheus Target Verification

```bash
$ curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
"up"
```

Full targets API response:
```json
{
  "activeTargets": [{
    "labels": {
      "__address__": "quicknotes:8080",
      "instance": "quicknotes:8080",
      "job": "quicknotes"
    },
    "health": "up"
  }]
}
```

---

## Task 1 — Dashboard

The dashboard (`monitoring/grafana/dashboards/golden-signals.json`) is provisioned automatically on Grafana startup. It contains four panels:

| Panel | Signal | PromQL |
|-------|--------|--------|
| Latency | Request rate as proxy | `rate(quicknotes_http_requests_total[1m])` |
| Traffic | Requests/s by status code | `sum(rate(quicknotes_http_responses_by_code_total[1m])) by (code)` |
| Errors | 4xx+5xx ratio | `sum(rate(quicknotes_http_responses_by_code_total{code=~"4\|5.."}[1m])) / sum(rate(quicknotes_http_requests_total[1m]))` |
| Saturation | Notes stored (gauge) | `quicknotes_notes_total` |

After generating ~217 requests (80 GET /notes, 40 GET /health, 30 GET /notes/1, 20 GET /notes/999 → 404, 15 POST valid, 15 POST bad JSON → 400):

```
quicknotes_http_requests_total         = 217
quicknotes_http_responses_by_code_total{code="200"} = 167
quicknotes_http_responses_by_code_total{code="201"} = 15
quicknotes_http_responses_by_code_total{code="400"} = 15
quicknotes_http_responses_by_code_total{code="404"} = 20
```

Error ratio: (15+20)/217 = **16.1%** — well above the 5% threshold.

---

## Task 1 — Design Questions

### a) Pull vs push — which side must be reachable?

Prometheus pulls from targets, so **QuickNotes must be reachable from Prometheus**, not the other way around. Prometheus initiates every scrape over HTTP; QuickNotes only needs to expose `/metrics` on a stable address and port. If Prometheus cannot reach QuickNotes (network partition, wrong Compose service name, wrong port), the target transitions to `state: down` and `up == 0` — no new metrics are collected, but the Prometheus process itself continues running and serving existing data. The failure is visible immediately in `/targets` as a red "down" badge.

### b) `scrape_interval` at 5 s vs 5 m

**5 s:** `rate()` calculations become more precise (smaller steps), but Prometheus writes 12× more data per minute, increasing disk I/O, TSDB WAL size, and CPU. Long-term storage costs multiply. For a lightly-loaded app, the precision gain does not justify the overhead; you should only go this low for latency-sensitive alerting where 15 s granularity misses transient spikes.

**5 m:** A `rate(metric[1m])` query becomes useless (not enough samples in the window), and you'd need `rate(metric[10m])` at minimum, which smooths over short bursts. Alerting `for: 5m` now has only 1 data point, so the sustained-breach gate provides almost no noise reduction. A spike → recovery → spike pattern would never be visible.

### c) `rate()` vs `irate()` vs `delta()` for Traffic

**`rate()`** is correct for the Traffic panel. It computes the per-second average increase of a counter over the full range window, which is resilient to scrape misses (it uses all samples in the window, not just the last two). This makes it stable for dashboards that display trends over time. `irate()` uses only the last two samples, making it more reactive but also more volatile — suitable for alerting on instantaneous spikes, not for a display panel. `delta()` is for gauges (it measures change, not rate), and would produce incorrect results on the counter `quicknotes_http_requests_total`.

### d) Why provision Grafana from files?

Because dashboards and datasources created through the UI are stored only in Grafana's internal SQLite database, which is not tracked in git. Every fresh `docker compose up` on a new machine (or after `docker volume rm`) would start Grafana with a blank state — no datasources, no dashboards, no alert rules. File-based provisioning means the complete monitoring setup is part of the repository: reproducible, reviewable, diffable, and deployable with a single `docker compose up`. It also makes dashboard changes auditable via git history instead of invisible in a UI.

---

## Task 2 — Alert Rule

`monitoring/prometheus/rules/alerts.yml`:

```yaml
groups:
  - name: quicknotes
    rules:
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
            /
            sum(rate(quicknotes_http_requests_total[5m]))
          ) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "QuickNotes error rate exceeds 5%"
          runbook_url: "https://github.com/1r444444/DevOps-Intro/blob/feature/lab8/docs/runbook/high-error-rate.md"
          description: "Error ratio is above 5% sustained for 5 minutes. Check QuickNotes logs."
```

---

## Task 2 — Alert Firing State

Alert triggered by running a script that continuously sent bad JSON `POST /notes` and `GET /notes/9999` (404) requests alongside healthy traffic, maintaining error rate ~29% for 5+ minutes.

Transition observed:
- `state: pending` at 10:28:36 UTC — alert condition met, waiting for `for: 5m` gate
- `state: firing` at 10:33:41 UTC — sustained breach confirmed after 5 minutes 5 seconds

```
$ curl -s http://localhost:9090/api/v1/alerts | python3 -c "
import sys, json
r = json.load(sys.stdin)
for a in r['data']['alerts']:
    print('alertname:', a['labels']['alertname'])
    print('state:', a['state'])
    print('severity:', a['labels']['severity'])
    print('activeAt:', a['activeAt'])
"
alertname: HighErrorRate
state: firing
severity: page
activeAt: 2026-07-05T10:28:36.918698186Z
```

---

## Task 2 — Runbook

See [`docs/runbook/high-error-rate.md`](../docs/runbook/high-error-rate.md).

Summary of sections:
1. **What this alert means** — >5% HTTP errors sustained 5 min
2. **Triage steps** — check `/health`, identify error codes via PromQL, read app logs, inspect data file, check resources
3. **Mitigations** — restart service; restore data file from backup
4. **Post-incident** — confirm resolution, write postmortem, file follow-up tasks

---

## Task 2 — Design Questions

### e) Why "sustained for 5 minutes" instead of firing immediately?

A single bad request — a client that sent malformed JSON once, a momentary blip — should never page an engineer at 3 AM. The `for: 5m` gate requires the expression to evaluate to `true` on every evaluation within a 5-minute window before the alert transitions from `pending` to `firing`. This eliminates transient spikes (a deploy restart briefly causing 500s, one misbehaving client, a single slow request). An alert that fires on any single 4xx is an alert that pages constantly and produces no signal — engineers learn to ignore it, which defeats the purpose entirely (alert fatigue). A sustained breach is a symptom that something is actually wrong for real users, not a one-off blip.

### f) Symptom alert vs cause alert — example for QuickNotes

A **cause alert** someone might write: `alert: HighCPUUsage` — fires when the QuickNotes container uses more than 80% CPU for 2 minutes.

This is worse because: CPU usage is not directly user-visible. CPU can spike during a legitimate traffic increase and users see perfectly fast responses. Conversely, users can experience 500 errors from a corrupted data file while CPU is completely idle. Cause alerts produce false positives (CPU spike → no user impact → page) and false negatives (data corruption → 500s → no CPU spike → no page). The symptom alert (error ratio) fires if and only if users are actually seeing errors, regardless of the internal cause.

### g) Quantitative threshold for "alert is too noisy"

From the Google SRE book: an alert is too noisy if it pages more than **~10% of the time when no user-visible impact occurred** — i.e., the precision of the alert drops below ~90%. A practical threshold for this alert: if it fires more than once per week and the on-call investigation finds no user-visible problem on more than 1 in 10 pages, the alert needs a higher threshold, a longer `for:` duration, or a better expression. Measured differently: if the MTTD (mean time to detection) is low but the false-positive rate exceeds 10%, tighten the gate — otherwise oncall trains themselves to ignore the alert without investigating.
