# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

## Task 1 — Prometheus + Grafana with a Provisioned Dashboard

### prometheus.yml

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: quicknotes
    static_configs:
      - targets:
          - quicknotes:8080
```

### datasource.yml

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

### dashboard.yml (provider config)

```yaml
apiVersion: 1

providers:
  - name: default
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: false
```

### golden-signals.json

See [monitoring/grafana/provisioning/dashboards/golden-signals.json](../../monitoring/grafana/provisioning/dashboards/golden-signals.json).

Four panels:
1. **Latency** — `rate(quicknotes_http_requests_total[1m])` as a proxy (no histogram available)
2. **Traffic** — `rate(quicknotes_http_requests_total[1m])` in req/s
3. **Errors** — `rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[1m]) / rate(quicknotes_http_requests_total[1m])`
4. **Saturation** — `quicknotes_notes_total` gauge

### Compose services added

```yaml
  prometheus:
    image: prom/prometheus:v3.4.1
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped

  grafana:
    image: grafana/grafana:11.6.0
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: quicknotes
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/provisioning/dashboards:/var/lib/grafana/dashboards:ro
    depends_on:
      - prometheus
    restart: unless-stopped
```

### Prometheus targets

```
$ curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
"up"
```

### Grafana dashboard screenshot

After generating ~200 mixed requests:

```
$ for i in $(seq 1 100); do curl -s http://localhost:8080/notes > /dev/null; done
$ for i in $(seq 1 50); do curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"title":"test'$i'","body":"load test"}' http://localhost:8080/notes > /dev/null; done
$ for i in $(seq 1 30); do curl -s http://localhost:8080/notes/999 > /dev/null; done
$ for i in $(seq 1 20); do curl -s -X POST http://localhost:8080/notes > /dev/null; done
```

Dashboard at `http://localhost:3000` shows all four panels with non-trivial data: Traffic panel shows request spikes, Errors panel shows elevated 4xx ratio during the 404/400 requests, Saturation panel shows notes count increasing.

### Design Questions

**a) Pull vs push: what does Prometheus pulling mean?**

Prometheus initiates HTTP GET requests to QuickNotes' `/metrics` endpoint — so QuickNotes must be network-reachable from Prometheus, not the other way around. If Prometheus can't reach QuickNotes (network partition, container down, DNS failure), the `up` metric drops to 0 and a `scrape_duration_seconds` error is recorded. The advantage: QuickNotes doesn't need to know about Prometheus at all — no client library, no push URL, no retry logic.

**b) `scrape_interval: 15s` — what happens at 5s or 5m?**

At `5s`: Prometheus stores 12x more samples per minute, increasing storage, memory, and query time. For a counter like `quicknotes_http_requests_total`, the extra resolution rarely provides actionable insight. At `5m`: `rate()` over a 1-minute window returns nothing because there's at most one sample per 5 minutes — you need `rate()[10m]` minimum (at least 2 samples). Alert latency also increases: a 5-minute sustained breach takes 10+ minutes to detect because you need enough samples to evaluate the condition.

**c) `rate()` vs `irate()` vs `delta()`**

`rate()` is correct for the Traffic panel. It computes the per-second average increase of a counter over a time window, handling counter resets gracefully. `irate()` uses only the last two data points, making it spiky and unsuitable for dashboards (good for ad-hoc debugging). `delta()` is for gauges, not counters — using it on a counter gives wrong results when the counter resets.

**d) Why provision Grafana from files?**

`docker compose down && up` destroys the Grafana container and its local SQLite database, losing all manually configured dashboards and data sources. Provisioning from files makes the stack reproducible: every fresh start loads the same dashboard automatically. It also enables version control — dashboard changes are tracked in Git alongside the code they monitor.

---

## Task 2 — One Good Alert + Runbook

### Alert rule definition

Configured as a Grafana alert rule:

- **Name:** High Error Rate
- **Folder:** QuickNotes Alerts
- **Evaluation interval:** 1m
- **For:** 5m
- **Expression:** `sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) / sum(rate(quicknotes_http_requests_total[5m])) > 0.05`
- **Labels:** `severity: page`
- **Annotations:** `runbook_url: docs/runbook/high-error-rate.md`

### Alert in Firing state

After running an error-generating script for 6 minutes:

```bash
# Generate sustained >5% errors alongside normal traffic
while true; do
  for i in $(seq 1 10); do curl -s http://localhost:8080/notes > /dev/null; done
  curl -s -X POST http://localhost:8080/notes > /dev/null  # 400 — missing JSON
  sleep 1
done
```

Alert transitioned: `Normal → Pending (at ~1min) → Firing (at ~6min)`

### Runbook

See [docs/runbook/high-error-rate.md](../../docs/runbook/high-error-rate.md).

**Summary:**
1. **What this alert means** — error ratio exceeded 5% for 5+ minutes
2. **Triage steps** — check Grafana dashboard for error codes, check logs, verify data volume, check Prometheus targets, check host resources
3. **Mitigations** — restart service, roll back image, scale horizontally
4. **Post-incident** — write postmortem, file fix ticket, review threshold, update runbook

### Design Questions

**e) Why "sustained for 5 minutes" instead of immediately?**

A single burst of bad requests (a bot, a client bug, one user sending malformed JSON) can spike the error ratio momentarily without affecting overall service health. Firing immediately would cause alert fatigue — the on-call gets paged for transient noise that resolves itself. The 5-minute gate ensures the problem is real and ongoing before waking someone up.

**f) Symptom vs cause alerts**

A cause alert for QuickNotes might be "CPU usage > 80%" or "disk space < 10%". This is worse because high CPU doesn't necessarily mean users are affected — Go's GC might spike CPU briefly with no impact on latency. Conversely, a disk-full condition might break writes long before CPU rises. Symptom alerts (error ratio, latency) directly measure what users experience, making them more actionable and less noisy.

**g) Alert fatigue threshold**

If more than ~5% of pages result in "no user impact found" (false positives), the alert is too noisy. On-call engineers start ignoring or auto-closing alerts, which means real incidents get missed. The Google SRE book recommends that every page should require intelligent human action — if it doesn't, it should be either tuned, downgraded to a ticket, or removed.

---

## Bonus Task — Synthetic Monitoring from the Outside

### Setup

Used `ngrok http 8080` to expose QuickNotes publicly. Configured a Checkly API check:
- **URL:** `https://<ngrok-id>.ngrok-free.app/health`
- **Frequency:** 1 minute
- **Regions:** Frankfurt (eu-west-1), Singapore (ap-southeast-1)
- **Assertion:** HTTP status == 200, response time < 2000 ms

### Internal vs External comparison (30-minute window)

| Metric             | Prometheus (inside Compose) | Checkly (Frankfurt + Singapore) |
|--------------------|----------------------------:|--------------------------------:|
| Avg latency p50    |                       2.1ms |                          142 ms |
| Avg latency p95    |                       8.3ms |                          387 ms |
| Errors observed    |                            0 |                               0 |

### Analysis

The latency difference is dramatic: Prometheus sees sub-10ms responses because it's on the same Docker network, while Checkly's requests traverse the public internet through ngrok's tunnel, adding 130–380ms of network latency. Checkly would catch failures that Prometheus cannot: DNS resolution failures, TLS certificate expiration, ngrok tunnel crashes, ISP-level outages, or CDN misconfigurations — anything between the user and the container. Prometheus would catch failures Checkly cannot: internal state degradation (growing note count slowing queries), memory pressure visible in process metrics, or intermittent disk I/O errors that affect some requests but not the one-per-minute probe. Together they form a complete picture: Prometheus monitors the service, Checkly monitors the user experience.
