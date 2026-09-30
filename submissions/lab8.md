# Lab 8 submission

Author: Telman Nuruzov (`Telman3000`)
Branch: `feature/lab8`
Fork: https://github.com/Telman3000/DevOps-Intro
Stack: Docker Compose — QuickNotes (`quicknotes:lab6`) + Prometheus `v3.2.1` + Grafana `11.6.0`

Course PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1689

Grafana login (local only): user `lab8admin` / password `lab8-quicknotes-sre` (not the Grafana defaults).

---

## Layout

```text
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   └── rules/
│       └── high-error-rate.yml
└── grafana/
    ├── dashboards/
    │   └── golden-signals.json
    └── provisioning/
        ├── datasources/datasource.yml
        └── dashboards/dashboard.yml
docs/runbook/high-error-rate.md
compose.yaml   # Lab 6 quicknotes + prometheus + grafana
```

---

## Task 1 — Prometheus + Grafana + golden signals

### Config files

- [`monitoring/prometheus/prometheus.yml`](../monitoring/prometheus/prometheus.yml) — `scrape_interval: 15s`, job `quicknotes` → `quicknotes:8080`
- [`monitoring/grafana/provisioning/datasources/datasource.yml`](../monitoring/grafana/provisioning/datasources/datasource.yml)
- [`monitoring/grafana/provisioning/dashboards/dashboard.yml`](../monitoring/grafana/provisioning/dashboards/dashboard.yml)
- [`monitoring/grafana/dashboards/golden-signals.json`](../monitoring/grafana/dashboards/golden-signals.json) — 4 panels

### Compose extension

See root [`compose.yaml`](../compose.yaml): `prometheus` depends on `quicknotes` healthy; `grafana` depends on `prometheus`; provisioning mounts; pinned images.

### Targets UP

```text
$ curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[].health'
up
```

Artifact: `submissions/lab8-artifacts/prom-targets-health.txt`

### Dashboard

Open http://localhost:3000 → folder **Lab 8** → **QuickNotes Golden Signals** (auto-provisioned).

Panels:
1. **Latency (proxy)** — `rate(quicknotes_http_requests_total[1m])` (no duration histogram in the app)
2. **Traffic** — `rate(quicknotes_http_requests_total[1m])` + by-code rates
3. **Errors** — `(4xx+5xx rate) / total rate`
4. **Saturation** — `quicknotes_notes_total` (+ create rate)

Screenshot: `submissions/lab8-artifacts/grafana-dashboard.png` _(capture after traffic; see note below)_

### Design questions (1.5)

**a) Pull vs push**

Prometheus **pulls** `/metrics`, so QuickNotes must be reachable **from Prometheus** (Compose DNS `quicknotes:8080`). If scrape fails, target goes `DOWN` / `up==0` — you lose time series and alerts based on them go stale or fire on missing data depending on config; the app itself may still be fine.

**b) `scrape_interval` 5s vs 5m**

`5s` — more load, more samples, noisier `rate()` over short windows, higher TSDB cost.  
`5m` — sparse data; `rate(...[1m])` becomes useless; alerts react slowly; graphs look stepped.

**c) `rate` vs `irate` vs `delta` for Traffic**

Use **`rate()`**: average per-second increase over a range, smooth enough for a traffic panel. `irate` is last two points (spiky). `delta` is absolute change over a range, not a rate.

**d) Why provision Grafana from files?**

Fresh `compose up` gets the same datasource + dashboard without clicking. Reviewable in Git, reproducible for graders and teammates.

---

## Task 2 — Alert + runbook

### Alert rule (Prometheus)

[`monitoring/prometheus/rules/high-error-rate.yml`](../monitoring/prometheus/rules/high-error-rate.yml):

- Expr: error ratio (4xx|5xx) / total `> 0.05`
- `for: 5m` (sustained)
- `labels.severity: page`
- `annotations.runbook_url` → `docs/runbook/high-error-rate.md`

### Runbook

Full text: [`docs/runbook/high-error-rate.md`](../docs/runbook/high-error-rate.md)  
Sections: meaning, triage (≥3), mitigations (≥2), post-incident.

### Trigger → Firing

Script: `scripts/lab8-error-inject.py` — alternate healthy GET + malformed POST for ≥330s.

Observed on Prometheus (`/api/v1/alerts` + rules API):

```text
QuickNotesHighErrorRate pending   # while for: 5m window filling
...
QuickNotesHighErrorRate firing    # after ~5 minutes sustained >5% errors
```

Error ratio during fire (PromQL): **~0.43** (43% ≫ 5%).

Artifacts: `submissions/lab8-artifacts/prom-alert-state.txt`, `prom-rules.json`, `error-ratio-query.json`.

**Screenshot to add before PR:** Prometheus Alerts UI or Grafana with alert Firing → `submissions/lab8-artifacts/alert-firing.png`  
**Dashboard screenshot:** Grafana Lab 8 → Golden Signals with graphs → `grafana-dashboard.png`

### Design questions (2.4)

**e) Why 5 minutes sustained?**

Single bad requests and short blips are normal. Paging on the first 400 trains people to ignore alerts. Sustained breach ≈ real user pain.

**f) Symptom vs cause**

This alert is a **symptom** (users get errors). A **cause** alert example: `process_cpu_seconds > X` or “container memory > 80%”. Cause alerts miss app bugs that don’t move CPU and page on irrelevant resource noise.

**g) Alert fatigue threshold**

If pages fire when users were unaffected more than ~**50%** of the time (false-page rate), the alert is too noisy — tune threshold/`for`, or drop it. Lecture 8: fatigue > silence.

---

## Bonus — Synthetic monitoring from the outside

### Public URL

Cloudflare quick tunnel (no account):

```text
https://turtle-associated-roller-suddenly.trycloudflare.com
GET /health → {"notes":29,"status":"ok"}
```

Artifact: `submissions/lab8-artifacts/public-url.txt`, `cloudflared-err.txt`

### External probe (Checkly-equivalent)

Used **check-host.net** multi-node HTTP checks every ~1 minute for **30 rounds (~30 min)** from:

- **Germany** — `de2.node.check-host.net`
- **Singapore** — `sg1.node.check-host.net`

Success criteria: HTTP **200** and latency **< 2s** (same intent as Checkly alerts).

Optional Checkly-as-code (same URL, `eu-central-1` + `ap-southeast-1`, 1 min): `monitoring/checkly/` — deploy with API key if desired.

### Results (≥30 min window)

| | Prometheus (inside Compose) | check-host.net (DE + SG) |
|--|---|---|
| Avg latency p50 | *n/a* (app has no latency histogram; internal traffic proxy `request_rate` ≈ **0.29 req/s**) | **0.34 s** |
| Avg latency p95 | *n/a* (same) | **1.41 s** |
| Errors observed | **0%** error ratio (avg/max over window) | **0 / 58** probes failed (0%) |

Per-region external (p50 / p95):

- DE: **0.31 s / 0.34 s** (29/29 OK)
- SG: **0.82 s / 1.44 s** (29/29 OK) — higher RTT from Asia, still &lt; 2s

Artifacts: `synthetic-summary.json`, `synthetic-checkhost.jsonl`, `prom-bonus-summary.json`.

### Failure-mode analysis

Checkly/check-host from the public Internet catches failures Prometheus inside the Compose network cannot see: DNS/TLS issues on the tunnel hostname, Cloudflare edge problems, host firewall blocking inbound public paths, or “works on localhost:8080 but not from outside.” Prometheus catches in-cluster symptoms the external probe may miss if it only hits `/health`: rising 4xx/5xx ratios on other routes, saturation (`quicknotes_notes_total`), scrape target `DOWN`, or error storms between minute-spaced probes. Together they cover path-to-user vs path-inside-the-mesh.

---

## How to run

```bash
docker compose up --build -d
# wait healthy
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
# Grafana http://localhost:3000  (lab8admin / lab8-quicknotes-sre)
bash scripts/lab8-traffic.sh
# optional: bash scripts/lab8-error-inject.sh   # ~5.5 min to fire alert
```

**Note:** Push is done by the student (not the agent). Screenshots of Grafana dashboard + alert Firing: save under `submissions/lab8-artifacts/` before opening the PR.
