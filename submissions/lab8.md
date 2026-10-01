# Lab 8 — SRE and monitoring

## Reproduce the stack

This branch extends the Lab 6 Compose setup because [Lab 6 is still awaiting merge](https://github.com/inno-devops-labs/DevOps-Intro/pull/1640). From the repository root, set a unique local `GRAFANA_ADMIN_PASSWORD`, then run `docker compose up -d --build`. The default host ports are QuickNotes 8080, Prometheus 9090, and Grafana 3000. On my Windows host 8080 is occupied by PostgreSQL and 28080 by the Lab 6 stack, so I used `QUICKNOTES_HOST_PORT=28081` for this test; all three services still use their normal ports inside Compose.

The configuration is in [compose.yaml](../compose.yaml), [Prometheus scrape config](../monitoring/prometheus/prometheus.yml), [Grafana datasource](../monitoring/grafana/provisioning/datasources/datasource.yml), [Grafana dashboard provider](../monitoring/grafana/provisioning/dashboards/dashboard.yml), and [four-panel dashboard JSON](../monitoring/grafana/provisioning/dashboards/golden-signals.json). The stack uses pinned `prom/prometheus:v3.13.1` and `grafana/grafana:13.0.9` images. The Grafana password is required at runtime and is not committed.

QuickNotes originally had request counters but no latency histogram. I added `quicknotes_http_request_duration_seconds` so Latency is a real p95 duration metric rather than a traffic-rate proxy. The other panels show request rate, 4xx+5xx ratio, and stored-note count. `go test ./...` passed.

`promtool check config` validated the scrape configuration and the single alert rule. Its optional `check metrics` linter flags the course app's pre-existing gauge name `quicknotes_notes_total` because names ending in `_total` normally denote counters; I retained the metric name required by this lab. Prometheus parses and scrapes it successfully.

## Task 1 — scrape and dashboard evidence

After `docker compose up -d --build`, Prometheus reported the target as healthy:

```text
GET http://localhost:9090/api/v1/targets
health: "up"
scrapeUrl: "http://quicknotes:8080/metrics"
lastError: ""
```

I sent 200 mixed requests (160 successful `GET /notes`, 40 malformed `POST /notes`) and then sustained traffic for the alert test. Grafana automatically loaded the `QuickNotes — Four Golden Signals` dashboard with four populated panels: [dashboard screenshot](evidence/lab8-dashboard.jpg). A raw `/metrics` check showed nonzero histogram observations (`quicknotes_http_request_duration_seconds_count 441` during the capture).

### Design answers

a) Prometheus initiates requests to `quicknotes:8080/metrics`, so Prometheus must be able to reach QuickNotes on the Compose network. If it cannot, the target becomes `down`, new samples stop arriving, and graphs become stale or empty. A separate availability alert would be appropriate in production.

b) At 5 seconds, scraping costs roughly three times the storage/network of 15 seconds and short-window rates become noisier when traffic is sparse. At 5 minutes, short outages can be missed and a `[2m]` rate window has too few samples to work; alert and dashboard feedback also lag badly.

c) `rate()` is appropriate for Traffic: it estimates per-second growth of a counter over a window and handles counter resets. `irate()` uses only the last two samples and is too spiky for an overview panel; `delta()` is an absolute change, not a per-second rate.

d) File provisioning gives a versioned, reproducible dashboard and datasource on every fresh stack, without manual UI clicks or configuration drift.

## Task 2 — one actionable alert

The [Prometheus rule](../monitoring/prometheus/rules.yml) evaluates the ratio of 4xx+5xx responses to all requests over two minutes. It enters `Firing` only when the ratio remains above `0.05` for `5m`; the rule has `severity: page` and a `runbook_url` annotation pointing to [the runbook](../docs/runbook/high-error-rate.md). A single short 4xx burst cannot satisfy the five-minute gate.

I generated malformed `POST /notes` traffic alongside healthy `GET /notes` requests at roughly one pair per second. The rule was observed as `inactive`, then `pending`, then `firing`. The [Firing screenshot](evidence/lab8-alert-firing.jpg) shows the rule expression, `for: 5m`, `severity="page"`, runbook URL, and an evaluated error ratio of about 45.6%.

### Runbook (full text)

The same document is versioned at [docs/runbook/high-error-rate.md](../docs/runbook/high-error-rate.md).

#### What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx for at least five consecutive minutes.

#### Triage

1. Open the [golden-signals dashboard](http://localhost:3000/d/quicknotes-golden-signals) and [Prometheus alert page](http://localhost:9090/alerts); confirm the alert is firing, note when it began, and compare Traffic, Errors, and Latency before and after onset.
2. Determine which status codes dominate: query `sum by (code) (rate(quicknotes_http_responses_by_code_total[5m]))` in Prometheus. A 400 spike may be malformed clients; 500s or rising latency may indicate server or storage failure.
3. Verify the service path: `curl -i http://localhost:8080/health`, `curl -i http://localhost:8080/notes`, `docker compose ps`, and `docker compose logs --tail=100 quicknotes`. If the host port was overridden, use `QUICKNOTES_HOST_PORT` instead of 8080.
4. Check recent deployments, changed client traffic, and the `/data` volume. Record the first bad request, affected endpoints, and whether users can still read or create notes.

#### Mitigations

- If a new QuickNotes release caused 5xx responses, roll back to the last known-good image and verify `/health`, `/notes`, and the error ratio. Preserve the named data volume; do not use `docker compose down -v` during an incident.
- If malformed or abusive client requests dominate 4xx, fix or pause that caller (or apply a temporary rate limit at the edge), then verify that normal clients recover. Do not hide genuine server errors by changing the alert threshold.
- If the service is stuck but data is healthy, restart only the QuickNotes service with `docker compose restart quicknotes` and confirm the named volume remains mounted.

#### Post-incident

Record customer impact, timeline, contributing conditions, what worked, and dated owners for follow-up actions. Use the [Lecture 1 blameless postmortem format](../lectures/lec1.md) and link the dashboard/alert evidence. Update this runbook and add a regression test for the failure mode.

### Design answers

e) The five-minute duration filters a transient bad request or brief client mistake and pages only for sustained user-visible degradation. It trades some detection speed for a much lower false-page rate.

f) A cause alert might page on container CPU above 80%. That can happen during harmless load and may stay normal during a storage failure or malformed-client storm; the HTTP error-ratio symptom is closer to user impact.

g) I would review this rule if over 10% of its pages had no meaningful user impact (more than one false page per ten alerts), and tighten traffic-volume gating or classification instead of accepting routine noise.

## Bonus

The external two-region synthetic-monitoring bonus was not attempted: no Checkly or equivalent account is available, and I did not publish a local service to the internet. No external latency or error numbers are claimed.
