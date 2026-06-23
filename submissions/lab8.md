# Lab 8 Submission — SRE & Monitoring

Configure Prometheus to scrape QuickNotes, a Grafana dashboard for the four golden
signals, one good alert, and its runbook.

> **Builds on Lab 6.** This lab extends the Lab 6 `compose.yaml` and uses the Lab 6
> image, so `feature/lab8` is based on `feature/lab6`. All results below are from a
> real `docker compose up` of the full stack.

## Files

- [compose.yaml](../compose.yaml) — adds pinned `prometheus` + `grafana` services.
- [monitoring/prometheus/prometheus.yml](../monitoring/prometheus/prometheus.yml) — scrape config.
- [monitoring/prometheus/alerts.yml](../monitoring/prometheus/alerts.yml) — `HighErrorRate` rule.
- [monitoring/grafana/provisioning/datasources/datasource.yml](../monitoring/grafana/provisioning/datasources/datasource.yml)
- [monitoring/grafana/provisioning/dashboards/dashboard.yml](../monitoring/grafana/provisioning/dashboards/dashboard.yml)
- [monitoring/grafana/provisioning/dashboards/golden-signals.json](../monitoring/grafana/provisioning/dashboards/golden-signals.json)
- [docs/runbook/high-error-rate.md](../docs/runbook/high-error-rate.md)

---

## Task 1 — Prometheus + Grafana

### Config summary

| Requirement | How it's met |
|---|---|
| Global scrape interval 15s | `global.scrape_interval: 15s` |
| One job targeting QuickNotes by service name | `job_name: quicknotes`, `targets: ["quicknotes:8080"]` |
| Metrics endpoint | `metrics_path: /metrics` |
| Pinned versions (no `:latest`) | `prom/prometheus:v3.1.0`, `grafana/grafana:11.4.0` |
| Config files mounted | compose `volumes:` (read-only binds) |
| Credentials via env | `GF_SECURITY_ADMIN_USER/PASSWORD` |
| Health dependency | prometheus `depends_on: quicknotes: condition: service_healthy` |
| Grafana datasource auto-provisioned | `datasource.yml` (uid `prometheus`) |
| Dashboard provider → mounted JSON | `dashboard.yml` → `golden-signals.json` |
| Four panels | Latency / Traffic / Errors / Saturation |

### Verification (measured)

```bash
docker compose up --build -d
# Prometheus: target healthy
curl -sG localhost:9090/api/v1/query --data-urlencode 'query=up{job="quicknotes"}'
#  -> value = 1   instance="quicknotes:8080"   ✅ up == 1
# active target: job=quicknotes  health=up  http://quicknotes:8080/metrics
# traffic: sum(rate(quicknotes_http_requests_total[1m])) -> ~0.35 req/s
# rule loaded: group "quicknotes" -> HighErrorRate (inactive)

# Grafana (admin/admin) auto-provisioned:
curl -s http://admin:admin@localhost:3000/api/datasources
#  -> [("Prometheus","prometheus","prometheus")]                       ✅
curl -s 'http://admin:admin@localhost:3000/api/search?type=dash-db'
#  -> [("QuickNotes — Four Golden Signals","quicknotes-golden")]       ✅
```

### Four golden signals — the queries used

| Signal | Query | Note |
|---|---|---|
| **Traffic** | `sum(rate(quicknotes_http_requests_total[1m]))` | requests/sec |
| **Errors** | `sum(rate(...{code=~"5.."}[5m])) / sum(rate(...total[5m]))` | 5xx ratio (+ non-2xx) |
| **Latency** | `scrape_duration_seconds{job="quicknotes"}` | **proxy** — see below |
| **Saturation** | `quicknotes_notes_total` | **proxy** — storage growth |

> **Honest limitation.** QuickNotes' `/metrics` exposes only counters/gauges
> (`http_requests_total`, `http_responses_by_code_total{code}`, `notes_total`, …) —
> **no request-duration histogram and no resource gauges**. So Latency uses
> Prometheus' own `scrape_duration_seconds` as a proxy, and Saturation uses
> `notes_total` (storage). A production fix is to add a `prometheus/client_golang`
> histogram (`http_request_duration_seconds`) to the app and a resource exporter;
> that's an app change beyond this lab's scope.

### Design answers

**a) Pull mechanism — implications and failure modes.**
Prometheus **scrapes** (pulls) each target's `/metrics` on a schedule; the target is
passive and doesn't know Prometheus exists. Implications: Prometheus needs network
reachability + service discovery, owns the scrape rate centrally, and gets a free
liveness signal (`up`). Failure modes: if Prometheus is down, data has gaps (no
collection); if a target is unreachable, `up == 0` (itself alertable); metrics are
**point-in-time samples**, so events shorter than the scrape interval are invisible;
scrape timeouts and high cardinality can overload the server.

**b) 5-second vs 5-minute interval — problems.**
**5s**: high resolution but expensive — more CPU/network/TSDB storage and load on the
target, faster cardinality growth, risk of overrunning scrape duration. **5min**:
cheap but coarse — misses short spikes, slow to detect incidents, and `rate(...[5m])`
barely has two samples, making graphs/alerts jumpy. 15s is the usual balance.

**c) `rate()` vs `irate()` vs `delta()`.**
`rate()` = average per-second over the window for **counters**, handles resets,
smooth → best for alerting/dashboards (used here). `irate()` = instantaneous rate
from the **last two** samples, spiky → good for high-res zoomed graphs, bad for
alerts (ignores points in between). `delta()` = difference over a window for
**gauges** (no reset handling). We use `rate()` because the HTTP metrics are counters
and we want smooth 5-minute windows for a stable alert.

**d) Provisioning vs manual UI.**
Provisioning is **infrastructure-as-code**: the datasource and dashboard are
version-controlled, code-reviewed, reproducible from a clean clone, and identical
across environments. Manual UI config is click-ops — undocumented, easy to drift,
and **lost** if the Grafana volume is wiped. Here a fresh `docker compose up`
re-creates the datasource + dashboard automatically (verified above).

---

## Task 2 — Alert + Runbook

### The alert ([alerts.yml](../monitoring/prometheus/alerts.yml))

`HighErrorRate`: fires when the **5xx ratio > 5% sustained for 5 minutes**, with
`severity: page` and a `runbook_url` annotation pointing at the runbook.

### Deliberate trigger — state transitions (measured)

I forced real `500`s by remounting `/data` read-only (the app's `persist()` writes a
temp file then renames; a read-only volume makes that fail → `POST /notes` returns
`500`, while `GET` still returns `200`). For this demo I temporarily set `for: 30s`
to capture transitions quickly (the committed value is **`for: 5m`**):

```
POST /notes -> HTTP 500          (write to read-only /data fails)
t=20s  alertstate=inactive   5xx_ratio=0.935
t=40s  alertstate=pending    5xx_ratio=0.943   <- Normal → Pending
t=60s  alertstate=firing     5xx_ratio=0.939   <- Pending → Firing
t=90s  alertstate=firing     5xx_ratio=0.935
```
After reverting the volume to writable, `POST /notes -> HTTP 201` and the alert
resolves. To reproduce with the real `for: 5m`, keep the fault active for >5 minutes.
<!-- TODO: optionally screenshot Prometheus /alerts showing PENDING then FIRING. -->

### Design answers

**e) Why the 5-minute sustained duration matters.**
`for: 5m` requires the breach to hold **continuously** for 5 minutes before paging,
which filters out transient single-scrape spikes that self-heal. Without it, one bad
moment pages a human at 3am for something already gone — alert flapping and fatigue.
It trades a little detection latency for a lot less noise.

**f) Symptom vs cause alerts (QuickNotes example).**
Page on **symptoms** users feel, not internal **causes**. Symptom alert (good):
`HighErrorRate` — users are getting 5xx right now. Cause alert (avoid paging):
"`notes_total` growing" or "disk 80% full" — may never hurt users (false page) or
miss user-visible failures from other causes. Causes belong on dashboards/tickets
for diagnosis; symptoms belong on the pager.

**g) Quantitative alert-fatigue threshold.**
Make it a number: every page must be **actionable**, and a sustainable rotation gets
**no more than ~2 pages per 12-hour on-call shift** (Google SRE guidance). If a
single alert pages more than that, or fires without a human needing to act, it's
fatigue: raise the threshold, lengthen `for:`, aggregate, or delete it. Track the
actionable-to-total page ratio and treat a low ratio as a bug in the alerting.

---

## Bonus — Synthetic Monitoring (optional, +2)

<!-- TODO if attempting: expose QuickNotes publicly (ngrok/Cloudflare/Lab 10),
probe from 2+ regions every minute (e.g. Checkly), then compare internal Prometheus
metrics vs external observations over 30+ minutes in a table, plus failure-mode
analysis (what each catches that the other misses: e.g. internal misses DNS/TLS/CDN
and last-mile issues; external misses per-handler error breakdown). -->

| Metric | Prometheus (internal) | Checkly (external) |
|---|---|---|
| Availability over 30 min | _TODO_ | _TODO_ |
| p95 latency | _TODO_ | _TODO_ |
| What it uniquely catches | per-code error rates, saturation | DNS/TLS/CDN/region/last-mile failures |

---

## Submission Checklist

- [ ] `monitoring/` tree, `docs/runbook/high-error-rate.md`, extended `compose.yaml`, `submissions/lab8.md`
- [ ] `up == 1` proof + four-panel dashboard auto-provisioned
- [ ] Alert shows Normal → Pending → Firing from a deliberate trigger
- [ ] Runbook: meaning + 3 triage steps + 2 mitigations + post-incident
- [ ] Design answers a–g
- [ ] PR `feature/lab8 → main` against **upstream** and against **your fork**
- [ ] Both PR URLs in Moodle
