 # Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + Docker Compose + Lab 6 QuickNotes image

---

## Task 1 — Prometheus + Grafana with provisioned dashboard

### Layout

```text
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   └── rules/high-error-rate.yml
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/datasource.yml
│   │   └── dashboards/dashboard.yml
│   └── dashboards/golden-signals.json
└── scripts/
    ├── generate-traffic.sh
    └── inject-errors.sh
```

Extended [`compose.yaml`](../compose.yaml) with `prometheus` and `grafana` services.

### Config files

See [`monitoring/`](../monitoring/) directory.

### Prometheus targets health

```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
```

```text
"up"
```

### Grafana dashboard

Screenshot: [`submissions/screenshots/grafana.png`](screenshots/grafana.png)

Login: `admin` / `lab8-grafana-admin` (set in compose — not default `admin`/`admin`).

Traffic generated with `bash monitoring/scripts/generate-traffic.sh` — all four panels show non-trivial data.

### Design questions (Task 1)

**a) Pull vs push — reachability and failure mode?**

Prometheus **pulls** by HTTP-scraping QuickNotes `/metrics`. QuickNotes must be reachable **from Prometheus** on the Compose network (`quicknotes:8080`), not the other way around. If Prometheus cannot reach QuickNotes, the scrape fails, `up == 0`, and metrics go stale — you lose visibility even if the app is still serving some users via the published host port.

**b) `scrape_interval: 15s` — problems at 5s vs 5m?**

At **5s**: more frequent scrapes → higher load on QuickNotes and Prometheus, larger TSDB churn, and noisier graphs; diminishing returns for a small lab API. At **5m**: coarse resolution — short spikes and brief outages can be missed or averaged away; alert rules using `[5m]` windows react slowly and dashboards feel “stale.”

**c) `rate()` vs `irate()` vs `delta()` for Traffic panel?**

Use **`rate()`** on the `quicknotes_http_requests_total` counter over a range (e.g. `[5m]`). `rate()` smooths per-second increase across the window — right for “requests per second” traffic. `irate()` only uses the last two samples → spiky, bad for dashboards/alerts. `delta()` is for gauges, not counters.

**d) Why provision Grafana from files?**

Dashboard + datasource JSON/YAML lives in Git next to the app: reproducible `docker compose up`, reviewable in PRs, same panels for every teammate/CI environment — no manual UI clicking after each fresh stack.

---

## Task 2 — Alert + runbook

### Alert rule

Prometheus rule: [`monitoring/prometheus/rules/high-error-rate.yml`](../monitoring/prometheus/rules/high-error-rate.yml)

```yaml
expr: |
  (
    sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
    /
    sum(rate(quicknotes_http_requests_total[5m]))
  ) > 0.05
for: 5m
labels:
  severity: page
```

### Trigger demo

```bash
bash monitoring/scripts/inject-errors.sh
# 360s of mixed healthy + malformed POST /notes traffic
```

Errors panel during injection (sustained **~40–50%** error ratio, well above 5% threshold):

Screenshot: [`submissions/screenshots/grafana_2.png`](screenshots/grafana_2.png)

Prometheus alert rule loaded (`HighErrorRate`, `for: 5m`, `severity: page`, runbook annotation):

Screenshot: [`submissions/screenshots/alerts.png`](screenshots/alerts.png)

During `inject-errors.sh`, the rule transitions **Inactive → Pending → Firing** while error ratio stays >5% for 5 minutes; returns to **Inactive** after injection stops (as in screenshot).

### Runbook

[`docs/runbook/high-error-rate.md`](../docs/runbook/high-error-rate.md)

### Design questions (Task 2)

**e) Why sustained 5 minutes instead of first bad request?**

A single malformed `POST /notes` returns one 400 — not an outage. Requiring **5 minutes** above 5% filters bursty bad clients and avoids paging on noise; you alert when users are *sustainedly* affected, matching SLO-style “budget over time” thinking.

**f) Symptom vs cause alert example for QuickNotes?**

**Symptom (good):** error ratio > 5% — what users see. **Cause (worse as a page):** `container_cpu_usage > 80%` — CPU can be high while errors are zero, or errors can happen at low CPU (bad deploy, bug). Cause metrics create false positives and send on-call chasing the wrong layer.

**g) Alert fatigue — quantitative threshold for “too noisy”?**

If **`HighErrorRate` pages more than ~1–2 times per month** when users were **not** actually impaired (checked via health checks / support tickets), the threshold or `for:` duration is too aggressive. Rule of thumb from Lecture 8: if **>30% of pages** are false alarms, fix or silence the alert before adding more.

---

## Bonus — Synthetic monitoring (not completed)

**Attempted** ngrok, `trycloudflare.com` quick tunnel, and named Cloudflare Zero Trust tunnel (`lab8-quicknote`).

**Blocked by network** — `cloudflared` connectivity pre-checks:

| Check | Result |
|-------|--------|
| DNS Resolution | PASS |
| Cloudflare API (`api.cloudflare.com:443`) | PASS |
| UDP/QUIC to `region*.v2.argotunnel.com` | **FAIL** |
| TCP/HTTP2 to `region*.v2.argotunnel.com:7844` | **FAIL** — blocked or unreachable |

```
ERROR: Allow outbound QUIC traffic on port 7844 or use HTTP2.
ERROR: Allow outbound TCP on port 7844.
SUMMARY: Environment has critical failures. cloudflared may not be able to establish a tunnel.
```

Tunnel dashboard stayed **Inactive** (0 replicas). Checkly could not be configured without a public URL.

Setup notes: [`monitoring/docs/bonus-checkly-setup.md`](../monitoring/docs/bonus-checkly-setup.md)

### Failure-mode analysis

**Checkly would catch, Prometheus cannot:** Internet path failures (DNS, TLS, regional routing, tunnel down) — external probes hit the public URL like real users; Prometheus only scrapes `quicknotes:8080` inside Docker.

**Prometheus catches, Checkly cannot:** In-app error ratios across all routes, saturation (`quicknotes_notes_total`), and sustained 5xx/4xx alerts — Checkly only probes `/health` once per minute per region.

---

## Lab 8 completion checklist

### Task 1 (6 pts)

- [x] Prometheus scrapes QuickNotes (`up`)
- [x] Grafana 4-panel golden-signals dashboard
- [x] Traffic generated, graphs non-trivial
- [x] Design questions a–d answered

### Task 2 (4 pts)

- [x] Alert rule with 5% / 5m sustained gate
- [x] Runbook complete
- [x] Alert observed Firing
- [x] Design questions e–g answered

### Bonus (2 pts)

- [x] Attempted (ngrok + cloudflared) — blocked on port **7844**
- [ ] Checkly 2-region comparison (not possible without public URL)
- [x] Failure-mode analysis written

### Submission

- [x] Course PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1222
- [x] Fork PR: https://github.com/selysecr332/DevOps-Intro/pull/9
- [x] Moodle URL submitted

