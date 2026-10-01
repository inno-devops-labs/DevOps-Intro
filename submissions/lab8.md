# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab8

The whole stack runs from the repo: `docker compose up -d` brings up QuickNotes + Prometheus + Grafana; the datasource, dashboard and alert are all provisioned from files.

## Task 1 — Prometheus + Grafana with a Provisioned Dashboard

### Config files

`monitoring/prometheus/prometheus.yml`
```yaml
global:
  scrape_interval: 15s
rule_files:
  - /etc/prometheus/alerts.yml
scrape_configs:
  - job_name: quicknotes
    static_configs:
      - targets: ['quicknotes:8080']
```

`monitoring/grafana/provisioning/datasources/datasource.yml`
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

`monitoring/grafana/provisioning/dashboards/dashboard.yml`
```yaml
apiVersion: 1
providers:
  - name: golden-signals
    orgId: 1
    type: file
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
```

The dashboard itself is `monitoring/grafana/dashboards/golden-signals.json` (4 panels). PromQL per panel:
- **Latency (proxy)**: `sum(rate(quicknotes_http_requests_total[5m]))` — QuickNotes exposes no latency histogram, so request rate is the documented proxy.
- **Traffic**: `sum(rate(quicknotes_http_requests_total[1m]))`
- **Errors**: `sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) / sum(rate(quicknotes_http_responses_by_code_total[5m]))`
- **Saturation**: `quicknotes_notes_total`

Compose extension (added to the Lab 6 `compose.yaml`): a `prometheus` service (`prom/prometheus:v3.1.0`, port 9090, mounts the config, `depends_on quicknotes: service_healthy`) and a `grafana` service (`grafana/grafana:12.0.0`, port 3000, mounts provisioning + dashboards, `GF_SECURITY_ADMIN_*` set, `depends_on prometheus`).

> Note: the lab suggested `grafana/grafana:13.x.y`, but Grafana 13 is not released yet (the `13.0.0` tag 404s on Docker Hub). Pinned the latest available major, `12.0.0`.

### Evidence

Prometheus target health:
```
$ curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
"up"
```

- `submissions/lab8-targets.png` — Prometheus → Targets: `quicknotes 1/1 up`, endpoint `http://quicknotes:8080/metrics`, State **UP**.
- `submissions/lab8-dashboard.png` — Grafana "QuickNotes — Golden Signals" with all four panels showing live data after ~200 mixed requests (traffic ~11 req/s spike, saturation ~200 notes).

### 1.5 Design questions

**a) Pull vs push — which side must be reachable? Failure mode?**
Prometheus pulls: it opens the connection and scrapes `/metrics`, so **Prometheus** must be able to reach QuickNotes; QuickNotes only exposes the endpoint and never needs to reach Prometheus. If Prometheus can't reach QuickNotes, that target goes `up == 0`, its series stop updating (panels show gaps / "No data"), and `up == 0` is itself an alertable signal. QuickNotes keeps serving users regardless — monitoring being down doesn't take the app down.

**b) `scrape_interval` at 5s vs 5m?**
`5s`: ~3× the samples of 15s → more storage, more TSDB churn, and more scrape load on the target, for little extra insight; `rate()` windows must still be several intervals wide, so it mostly helps only very short windows. `5m`: too coarse — `rate()` and alerts react slowly, and spikes shorter than 5 minutes fall between scrapes and are missed (aliasing); a `for: 5m` alert then has too few points to be reliable. 15s is the standard balance.

**c) `rate()` vs `irate()` vs `delta()` for Traffic?**
`rate()` — average per-second increase of a counter over the window, tolerant of counter resets, smoothed — correct for a traffic panel and for alerting. `irate()` uses only the last two samples: very responsive but spiky, good for zoomed high-resolution views, noisy on dashboards/alerts. `delta()` is for **gauges**, not counters — it would mishandle counter resets. So `rate()`.

**d) Why provision Grafana from files?**
Reproducibility and version control: a fresh `docker compose up` comes up with the datasource and dashboard already configured, identically for every teammate and in CI, with no manual clicking. The config lives in git — reviewable, diffable, and it survives container recreation, so there's no "works on my Grafana" drift. It's the same declarative/GitOps principle as the rest of the stack.

## Task 2 — One Good Alert + Runbook

### Alert rule — `monitoring/prometheus/alerts.yml`
```yaml
groups:
  - name: quicknotes
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
          /
          sum(rate(quicknotes_http_responses_by_code_total[5m])) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "QuickNotes 4xx/5xx error ratio above 5% for 5 minutes"
          runbook: ".../docs/runbook/high-error-rate.md"
```

`for: 5m` is the sustained-breach gate — a single 4xx burst does not fire it.

### Firing evidence

Injected malformed `POST /notes` (→ 400) alongside healthy traffic. Observed the transition **Normal → Pending → Firing**:
```
$ curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[]|{alert:.name,state:.state}'
{ "alert": "HighErrorRate", "state": "pending" }   # breach detected, waiting out for:5m
...
{ "alert": "HighErrorRate", "state": "firing" }    # sustained 5 min -> fires
```

`submissions/lab8-alert-firing.png` — Prometheus → Alerts: `HighErrorRate` **FIRING**, `for: 5m`, `severity="page"`, runbook annotation, Value ≈ **0.478** (47.8% error ratio), Active Since ~7m.

### Runbook

Full runbook committed at `docs/runbook/high-error-rate.md` with the four required sections (What it means / Triage / Mitigations / Post-incident), written for a 3 AM on-call who has never seen QuickNotes.

### 2.4 Design questions

**e) Why "sustained for 5 minutes" instead of firing immediately?**
A single bad request or a brief blip is not an incident. Firing on the first error pages for self-healing transients and trains the on-call to ignore the alert. Requiring the breach to persist 5 minutes filters transient spikes and only pages when the degradation is real and ongoing — it trades a few minutes of detection latency for far fewer false pages.

**f) Symptom vs cause alert.**
The error-ratio alert is a **symptom** alert — it fires on what users actually experience. A **cause** alert for QuickNotes would be something like "container CPU > 90%" or "disk > 90% full". Cause alerts are worse: high CPU may not hurt users at all (false page), and you can never enumerate every cause, so you accumulate many noisy cause alerts and still miss real user impact from a cause you didn't foresee. Symptom alerts page exactly when users suffer, whatever the underlying reason.

**g) Alert fatigue — a quantitative "too noisy" threshold.**
If more than ~**50%** of the pages this alert produces are non-actionable (the user wasn't actually affected, or no action was taken), the alert is too noisy and must be retuned or removed. In SRE terms its precision is too low; once a majority of pages are ignorable, the on-call stops trusting it and will miss the real ones.

## Bonus — Synthetic Monitoring (Checkly)

Not attempted for this submission (requires a public tunnel + Checkly account and a ≥30-minute run).
