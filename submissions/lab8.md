# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

## Task 1 — Prometheus + Grafana with a Provisioned Dashboard

### monitoring/prometheus/prometheus.yml

```yaml
global:
  scrape_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: quicknotes
    static_configs:
      - targets: ["quicknotes:8080"]
```

### monitoring/prometheus/rules/quicknotes.yml

```yaml
groups:
  - name: quicknotes
    rules:
      - alert: HighErrorRate
        expr: |
          sum without(code)(rate(quicknotes_http_responses_by_code_total{code=~"[45].."}[5m]))
          /
          rate(quicknotes_http_requests_total[5m])
          > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "QuickNotes error rate > 5% sustained for 5 minutes"
          runbook_url: "docs/runbook/high-error-rate.md"
```

### monitoring/grafana/provisioning/datasources/datasource.yml

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

### monitoring/grafana/provisioning/dashboards/dashboard.yml

```yaml
apiVersion: 1

providers:
  - name: default
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards
```

### compose.yaml (full)

```yaml
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/app/seed.json"
    healthcheck:
      test: ["CMD", "/app/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=16m
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true

  prometheus:
    image: prom/prometheus:v3.4.2
    volumes:
      - ./monitoring/prometheus:/etc/prometheus:ro
    ports:
      - "9090:9090"
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped

  grafana:
    image: grafana/grafana:11.6.1
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana-data:/var/lib/grafana
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: quicknotes-lab8
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  quicknotes-data:
  grafana-data:
```

### Prometheus target health

```
$ curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
"up"
```

### Grafana dashboard — 4 panels auto-loaded

```
$ curl -s -u admin:quicknotes-lab8 \
    http://localhost:3000/api/dashboards/uid/quicknotes-golden \
  | jq '{title: .dashboard.title, panels: (.dashboard.panels | length)}'

{
  "title": "QuickNotes — Golden Signals",
  "panels": 4
}
```

Panels:
1. **Latency (req/s proxy)** — `rate(quicknotes_http_requests_total[1m])` — no histogram in the app, request rate used as load proxy
2. **Traffic** — `rate(quicknotes_http_requests_total[5m])` (req/s)
3. **Errors** — `sum without(code)(rate(quicknotes_http_responses_by_code_total{code=~"[45].."}[5m])) / rate(quicknotes_http_requests_total[5m])` — red threshold at 5%
4. **Saturation** — `quicknotes_notes_total` (gauge)

### Design questions (Task 1.5)

**a) Pull vs push — which side needs to be reachable?**

In the pull model, Prometheus reaches out to the scrape target. QuickNotes must be reachable from Prometheus (same Docker network satisfies this); Prometheus itself does not need to be reachable from QuickNotes. The failure mode is one-sided: if QuickNotes goes down or its `/metrics` endpoint times out, Prometheus marks the target `down` and fires a `TargetDown` alert — but the monitoring system itself keeps running. In push-based systems (StatsD, InfluxDB line protocol), the reverse is true: the app sends metrics and the receiver must be reachable, meaning a monitoring outage silently drops metrics.

**b) `scrape_interval: 5s` vs `5m` — query problems**

At 5 s the cardinality-per-series multiplies by 3×, TSDB WAL writes spike, and `rate()` windows filled with noisy short bursts give jittery graphs. At 5 m, `rate()` can only look back over a window that contains at most a handful of samples — a 15-minute rate window would have 3 points, making the line nearly flat and masking short spikes entirely. 15 s is the industry default because it gives ~20 samples per 5-minute `rate()` window: smooth enough for alerting, cheap enough for storage.

**c) `rate()` vs `irate()` vs `delta()` for Traffic**

`rate()` is correct for the Traffic panel. It computes the per-second average across the full range window (here 5 m), which smooths out momentary spikes and gives a stable "throughput" line — the right view for a golden-signal dashboard. `irate()` uses only the last two samples, making it very sensitive to bursts and unsuitable for a slow-moving traffic gauge. `delta()` gives the raw change in value over the window (not per-second), so the unit changes with the range selector — confusing and wrong here.

**d) Why provision Grafana from files instead of clicking through the UI?**

A Grafana instance that depends on manual clicks is a pet: it can't be reproduced, its state isn't version-controlled, and spinning up a fresh stack (CI, staging, disaster recovery) requires human intervention. File-based provisioning makes the dashboard a code artifact committed alongside the service it monitors — a `docker compose up` on any machine produces an identical, fully configured Grafana with no post-start manual steps.

---

## Task 2 — One Good Alert + Runbook

### Alert rule

```yaml
# monitoring/prometheus/rules/quicknotes.yml
groups:
  - name: quicknotes
    rules:
      - alert: HighErrorRate
        expr: |
          sum without(code)(rate(quicknotes_http_responses_by_code_total{code=~"[45].."}[5m]))
          /
          rate(quicknotes_http_requests_total[5m])
          > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "QuickNotes error rate > 5% sustained for 5 minutes"
          runbook_url: "docs/runbook/high-error-rate.md"
```

### Alert observed Firing

Error injection (50% bad POST requests for 6 minutes):

```bash
for i in $(seq 1 360); do
  curl -sf -X POST http://localhost:8080/notes \
    -H "Content-Type: application/json" -d '{bad}' > /dev/null 2>&1 &
  curl -sf http://localhost:8080/notes > /dev/null 2>&1 &
  sleep 1
done
```

Timeline:
- **16:56:46 UTC** — injection running, error ratio ~26%; alert enters **Pending**
- **17:01:37 UTC** — sustained for 5 min; alert transitions to **Firing**
- **17:02 UTC** — injection ends; alert returns to Inactive

```
$ curl -s http://localhost:9090/api/v1/rules | jq '
  .data.groups[].rules[]
  | select(.type == "alerting")
  | {name, state, alerts: [.alerts[] | {state, labels, annotations, activeAt}]}'

{
  "name": "HighErrorRate",
  "state": "firing",
  "alerts": [
    {
      "state": "firing",
      "labels": {
        "alertname": "HighErrorRate",
        "instance": "quicknotes:8080",
        "job": "quicknotes",
        "severity": "page"
      },
      "annotations": {
        "runbook_url": "docs/runbook/high-error-rate.md",
        "summary": "QuickNotes error rate > 5% sustained for 5 minutes"
      },
      "activeAt": "2026-06-30T16:56:46.133220496Z"
    }
  ]
}
```

### Runbook — docs/runbook/high-error-rate.md

#### What this alert means

More than 5% of QuickNotes HTTP requests have been returning 4xx or 5xx responses continuously for at least 5 minutes, indicating a user-visible failure.

#### Triage steps

1. **Check which status codes are spiking.**
   Run `rate(quicknotes_http_responses_by_code_total[5m])` in Prometheus. A spike in 400 suggests bad client input or a broken upstream caller. A spike in 500 suggests a server-side bug or failed dependency (e.g., disk full).

2. **Check application logs.**
   ```
   docker compose logs --tail=100 quicknotes
   ```
   Look for `log.Fatalf`, `store:`, or `listen:` lines. If the process restarted, `docker compose ps` shows restart count > 0.

3. **Verify the data path is writable.**
   ```
   docker compose exec quicknotes df -h /data
   ```
   A 100% disk or "read-only file system" error explains 500s on POST/DELETE.

4. **Reproduce manually.**
   ```
   curl -v http://localhost:8080/notes
   curl -v -X POST http://localhost:8080/notes \
     -H "Content-Type: application/json" -d '{"title":"test","body":"ok"}'
   ```

#### Mitigations

1. **Restart the service** if logs show a transient panic or crash loop:
   ```
   docker compose restart quicknotes
   ```
   Safe — state is persisted to the named volume.

2. **Roll back the last deploy** if the spike correlates with a recent image push:
   ```
   # pin previous image tag in compose.yaml, then:
   docker compose up -d quicknotes
   ```

#### Post-incident

1. Confirm alert returns to Normal in Prometheus `/alerts`.
2. Confirm `curl http://localhost:8080/health` returns `{"status":"ok"}`.
3. Write a postmortem using the [Lecture 1 postmortem template](../../lectures/lec1.md): timeline, root cause, action items with owners and due dates.
4. Add a regression test or pre-deploy smoke check to CI if root cause was a bad deploy.

### Design questions (Task 2.2)

**e) Why "sustained for 5 minutes" instead of immediate?**

A single bad request or a momentary spike (a client retry storm, a health-check race at startup) will naturally produce a non-zero error ratio for one scrape interval. Firing immediately would page an on-call engineer for a self-correcting blip. The `for: 5m` gate requires the condition to hold across ~20 consecutive scrapes — meaning the problem has persisted long enough that it will not resolve on its own. The cost of a 5-minute delay in paging is a few minutes of user-visible impact; the cost of missing `for:` is alert fatigue, which causes engineers to start ignoring pages.

**f) Symptom vs cause alert — example**

A cause alert would be: *"CPU usage of the QuickNotes container > 80%."* It is worse because CPU is an internal resource metric: a user may never notice high CPU (the service remains fast), and high CPU does not guarantee user-visible errors. Conversely, the service can be returning 500s with near-zero CPU (disk-full, logic bug). The symptom alert (`error_ratio > 5%`) fires exactly when users are experiencing failures, not before and not when they aren't.

**g) Quantitative alert-fatigue threshold**

A standard heuristic from Google's SRE book: if the alert fires and the user was *not* actually affected in more than ~50% of pages, the alert is too noisy. Concretely: if a weekly alert-quality review shows that `HighErrorRate` fires without a corresponding user-facing incident (ticket, complaint, SLO breach) more than half the time, tighten the threshold, raise the `for:` duration, or add a minimum-volume guard (`rate(...) > 0.1` to suppress 1 error in 10 requests at very low traffic).

---

## Bonus — Synthetic Monitoring from the Outside

### Setup

- Public URL via GitHub Dev Tunnel: `https://qjnjpz3k-8080.uks1.devtunnels.ms`
- Checkly API check: GET `/health`, frequency 1 min, from **2 regions** (EU + US)
- Assertions: status == 200, response time < 2000 ms
- Availability: **100%** over 30-minute window, 0 failure alerts

### Checkly results (30-minute window)

```
Availability:   100 %
Retry ratio:    0.93 %
P50:            588 ms
P95:            922 ms
Failure Alerts: 0
```

### Prometheus vs Checkly comparison

| Metric | Prometheus (inside Compose net) | Checkly (2 regions, public URL) |
|---|---|---|
| Avg latency p50 | N/A — no histogram exposed | **588 ms** |
| Avg latency p95 | N/A — no histogram exposed | **922 ms** |
| Errors observed | 0 (after injection ended) | 0 |
| Req rate (idle) | 0.19 req/s (Prometheus scrape traffic only) | 1 req/min per region |

**What Checkly catches that Prometheus cannot:** A failure in the public network path — the Dev Tunnel dropping connections, a TLS certificate issue, a DNS resolution failure for the public hostname, or regional routing problems between user locations and the server. Prometheus scrapes from inside the Compose network over the service name `quicknotes:8080`; it reports `up` even if the public-facing tunnel has completely stopped forwarding traffic.

**What Prometheus catches that Checkly cannot:** Internal process-level failures that don't affect the `/health` endpoint — a goroutine panic that only breaks POST `/notes` while GET `/health` still returns 200, a slow memory leak visible in process metrics before it causes timeouts, a data-layer error producing 500s only on write paths, or the `quicknotes_notes_total` gauge drifting unexpectedly due to a delete bug. The synthetic probe only knows what the one probed endpoint returns; Prometheus sees all routes and all internal counters.
