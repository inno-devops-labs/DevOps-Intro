# Lab 8 Submission

## Task 1 — Prometheus + Grafana with a Provisioned Dashboard

### Config files

- [compose.yaml](../compose.yaml)
- [monitoring/prometheus/prometheus.yml](../monitoring/prometheus/prometheus.yml)
- [monitoring/grafana/provisioning/datasources/datasource.yml](../monitoring/grafana/provisioning/datasources/datasource.yml)
- [monitoring/grafana/provisioning/dashboards/dashboard.yml](../monitoring/grafana/provisioning/dashboards/dashboard.yml)
- [monitoring/grafana/provisioning/dashboards/golden-signals.json](../monitoring/grafana/provisioning/dashboards/golden-signals.json)

### What was added

- Prometheus `v3.4.2` with a single `quicknotes` scrape job targeting `quicknotes:8080` every 15 seconds.
- Grafana `13.1.0` with a provisioned Prometheus datasource and a provisioned dashboard named `QuickNotes Golden Signals`.
- Four dashboard panels:
  - `Latency (proxy)` using `sum(rate(quicknotes_http_requests_total[5m]))` because QuickNotes does not expose a latency histogram yet.
  - `Traffic` using `sum(rate(quicknotes_http_requests_total[1m]))`.
  - `Errors` using `(4xx + 5xx) / total` over 5 minutes.
  - `Saturation` using `quicknotes_notes_total`.

### Verification

Stack state after `docker compose up -d --build`:

```text
NAME                        IMAGE                    SERVICE      STATUS                        PORTS
devops-intro-grafana-1      grafana/grafana:13.1.0  grafana      Up About a minute             0.0.0.0:3000->3000/tcp
devops-intro-prometheus-1   prom/prometheus:v3.4.2  prometheus   Up About a minute             0.0.0.0:9090->9090/tcp
devops-intro-quicknotes-1   quicknotes:lab6         quicknotes   Up About a minute (healthy)   0.0.0.0:8080->8080/tcp
```

I generated more than 200 mixed requests against QuickNotes: `120x GET /notes`, `40x GET /notes/999999` (intentional `404`), and `40x POST /notes` with valid JSON.

Prometheus target health:

```text
"health":"up"
```

Grafana dashboard auto-provisioning proof via API:

```text
quicknotes-golden-signals
```

Example live query values from Prometheus after traffic generation:

```text
Latency proxy: 0.023733646520512647
Traffic:       0.12782229404055884
Errors:        0
Saturation:    44
```

Grafana dashboard screenshot:

![Grafana dashboard](./assets/grafana_dashboard.png) 

### Design answers

#### - a) **Pull vs push:** Prometheus pulls. What does that mean for *which side* (Prometheus or QuickNotes) needs to be reachable? What's the failure mode if Prometheus can't reach QuickNotes?

Prometheus uses a pull model, which means Prometheus must be able to reach QuickNotes over the network and fetch `/metrics` itself. QuickNotes does not initiate any connection to Prometheus. If Prometheus cannot reach QuickNotes, the failure mode is not that the app stops serving users; the failure mode is observability loss: the target becomes `down`, the `up` metric drops to `0`, and the dashboard and alerts lose fresh data.

#### b) **`scrape_interval: 15s`** is a default. What query problems do you create by setting it to `5s`? To `5m`?

At `5s`, you create much higher storage churn and more scrape overhead for very little value in a small service like QuickNotes. You also make dashboards noisier because short-window `rate()` calculations react to small counter changes more sharply. At `5m`, you go too far the other way: dashboards and alerts become sluggish, short incidents get smoothed away, and a 5-minute alert window may need two full scrape points before it even has enough data to show the trend clearly. 15 seconds is a practical middle ground for a small stack.

#### c) **PromQL `rate()` vs `irate()` vs `delta()`** — which one is right for the Traffic panel and why?

`rate()` is the right choice for the Traffic panel because `quicknotes_http_requests_total` is a counter and the panel should show a stable requests-per-second trend over a time window. `irate()` is more volatile because it only uses the last two samples, which is better for very spiky near-instant inspection than for a default dashboard panel. `delta()` is wrong here because it returns the raw increase over the range rather than a per-second rate, and it is not the standard way to visualize traffic from a counter.

#### d) **Why provision Grafana from files** instead of clicking through the UI on every fresh stack?

Provisioning Grafana from files makes the monitoring stack reproducible, reviewable, and version-controlled. A fresh `docker compose up` gets the same datasource and dashboard every time without manual UI clicks. That also means changes to queries, panel titles, or datasource wiring go through normal Git review instead of living as undocumented state inside one developer's local Grafana volume.