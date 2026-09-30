# Lab 8 — SRE and Monitoring

Student: Arina ([@sonder314](https://github.com/sonder314))

## Task 1 — Prometheus and Grafana

I extended [compose.yaml](../compose.yaml) with pinned Prometheus and Grafana
services. QuickNotes retains its Lab 6 healthcheck, nonroot image, dropped
capabilities, read-only root filesystem, and restricted temporary filesystem.
Prometheus waits for that healthcheck, mounts its configuration read-only, and
publishes its UI only on host loopback. Grafana receives its administrator
password from the required `GRAFANA_ADMIN_PASSWORD` environment variable, so I
do not commit a default or working credential.

The current host's Docker runtime rejects this image at `execve` when
`no-new-privileges:true` is set, returning `exec /quicknotes: operation not
permitted`. I isolated the behavior by running the same image separately with
each security option: nonroot execution, `cap_drop`, read-only root, and tmpfs
all allowed the binary to execute, while `no-new-privileges` alone reproduced
the failure. I therefore omitted that optional Lab 6 control for this host;
the required Lab 8 monitoring behavior does not depend on it.

The monitoring configuration is fully provisioned from these files:

- [Prometheus scrape configuration](../monitoring/prometheus/prometheus.yml)
- [Prometheus alert rule](../monitoring/prometheus/alerts.yml)
- [Grafana data source](../monitoring/grafana/provisioning/datasources/datasource.yml)
- [Grafana dashboard provider](../monitoring/grafana/provisioning/dashboards/dashboard.yml)
- [Golden Signals dashboard](../monitoring/grafana/dashboards/golden-signals.json)

Prometheus uses a 15-second scrape and evaluation interval and has one scrape
job whose target is `quicknotes:8080`, the Compose service name and container
port. Grafana connects to `http://prometheus:9090` through the same Compose
network and loads the dashboard from `/var/lib/grafana/dashboards`.

The provisioned dashboard has exactly four first-response panels:

| Signal | PromQL | Interpretation |
|---|---|---|
| Latency | `rate(quicknotes_http_requests_total[5m])` | Explicit request-rate proxy because the application exposes no duration histogram |
| Traffic | `sum(rate(quicknotes_http_requests_total[5m]))` | Requests per second |
| Errors | `sum(rate(quicknotes_http_responses_by_code_total{code=~"[45].."}[5m])) / clamp_min(sum(rate(quicknotes_http_responses_by_code_total[5m])), 0.001)` | Fraction of responses that are 4xx or 5xx |
| Saturation | `quicknotes_notes_total` | Current stored-note count, the available saturation signal |

I ran the stack with Docker Compose 2.40.3. The recorded
[service state](evidence/lab8/compose-ps.txt) shows QuickNotes healthy and all
three containers running on their loopback-published ports. The full
[target response](evidence/lab8/prometheus-target.json) contains
`health: "up"`, no scrape error, and `scrapeUrl` set to
`http://quicknotes:8080/metrics`. An independent
[`up` query](evidence/lab8/prometheus-up-query.json) returned the value `1`.

After generating 200 mixed requests, I queried Grafana's dashboard API. The
[recorded response](evidence/lab8/grafana-dashboard-api.json) confirms that the
provisioned `QuickNotes Golden Signals` dashboard loaded with the expected
Latency, Traffic, Errors, and Saturation panels. The dashboard screenshot with
the generated traffic is [stored here](evidence/lab8/dashboard.png). It shows a
request-rate peak of 1.21 requests/s, a maximum error ratio of 9.75%, and four
stored notes, so the panels contain non-trivial live data rather than an empty
provisioning-only view.

### a) Pull versus push

Prometheus initiates each scrape, so Prometheus must be able to resolve and
connect to QuickNotes; QuickNotes does not need an inbound connection to the
Prometheus process beyond exposing `/metrics` on the shared network. If the
target is unreachable, Prometheus records `up{job="quicknotes"} = 0`, stops
receiving new application samples, and dashboards eventually show gaps or stale
last values. This is distinguishable from a healthy target reporting zero
traffic.

### b) Scrape interval trade-offs

A five-second interval triples ingestion, network, storage, and query work
relative to 15 seconds. It can make graphs look more precise than the
instrumentation warrants, magnify short-lived noise, and encourages rate ranges
that contain too few samples. A five-minute interval misses short incidents,
delays target-down detection and alert evaluation, and makes `rate()` unstable
unless its range spans multiple long scrapes. The interval should reflect how
quickly I must detect user impact and the cost of retaining that resolution.

### c) `rate()`, `irate()`, and `delta()`

`rate()` is correct for the Traffic panel because the source is a monotonically
increasing counter and the panel should show a stable per-second trend over a
range. It accounts for counter resets and smooths multiple samples. `irate()`
uses only the last two points and is useful for volatile troubleshooting but is
too noisy for a primary dashboard. `delta()` returns the absolute change over
the range and is intended for gauges; it does not produce the requested
per-second counter rate.

### d) File provisioning

Provisioned files make the data source and dashboard version-controlled,
reviewable, reproducible, and available immediately on a clean stack. UI-only
configuration becomes mutable state inside one Grafana instance, is easy to
forget or misclick, and cannot be reliably reviewed or recreated in CI. The
JSON can still be developed interactively, exported, reviewed, and then treated
as code.

## Task 2 — One actionable alert

The [Prometheus rule](../monitoring/prometheus/alerts.yml) pages when the rolling
ratio of 4xx and 5xx responses exceeds 5% continuously for five minutes. It has
`severity: page` and links directly to the
[high-error-rate runbook](../docs/runbook/high-error-rate.md). The query uses a
two-minute rate range while `for: 5m` enforces the sustained breach; a single
burst ages out before it can satisfy the five-minute pending period.

I used [the traffic generator](../scripts/lab8-generate-traffic.sh) in `errors`
mode to send two healthy requests and one malformed POST per second for six
minutes. The captured API responses preserve the complete transition:

- [Inactive](evidence/lab8/alert-inactive.json), with no active alert;
- [Pending](evidence/lab8/alert-pending.json), at a 24.66% error ratio;
- [Firing](evidence/lab8/alert-rule.json), at a 30.29% error ratio after the
  five-minute hold.

The [Firing screenshot](evidence/lab8/alert-firing.png) visibly shows the
expression, `for: 5m`, `severity="page"`, runbook URL, and an active duration
above six minutes. The rule health remained `ok` throughout the test.

### Runbook

The canonical runbook is versioned at
[`docs/runbook/high-error-rate.md`](../docs/runbook/high-error-rate.md). Its full
operator procedure is reproduced here for grading:

#### What this alert means

More than 5% of QuickNotes HTTP responses have been 4xx or 5xx continuously
for at least five minutes, so users are experiencing a sustained failure.

#### Triage steps

1. Acknowledge the page, record the start time, and confirm the alert expression
   in Prometheus.
2. Separate client and server failures by querying rates for `code=~"4.."` and
   `code=~"5.."`. A 4xx increase usually points to callers or a contract change;
   a 5xx increase usually points to QuickNotes or its writable data path.
3. Check scope and user impact: inspect the Traffic and Errors panels, request
   `/health`, and issue a known-good `GET /notes` from the host.
4. Inspect `docker compose ps`, the last 15 minutes of QuickNotes logs, and the
   container health details.
5. Correlate the first error increase with deployments, configuration changes,
   disk-full errors, volume permissions, and malformed-request sources.

#### Mitigations

- Roll back the most recent application or configuration change and verify that
  the five-minute error ratio falls below 5%.
- Rate-limit or temporarily block a caller producing invalid requests while
  preserving healthy traffic.
- If the process is unhealthy but data is intact, restart only QuickNotes; do
  not delete the named volume during incident response.

#### Post-incident

I preserve the alert and container logs, record detection and mitigation times,
identify why tests or rollout controls missed the issue, and assign measurable
corrective actions. I then write a blameless postmortem using
[Lecture 1, Slide 20](../lectures/lec1.md#-slide-20----blameless-postmortems)
and update the alert and runbook when any step proved ambiguous or noisy.

### e) Why require five sustained minutes

One bad request may be a caller mistake, a probe, or a harmless transient. An
immediate page would wake an operator without proving sustained user impact.
The five-minute gate filters short bursts and flapping while still bounding
detection time. The trade-off is an intentional delay, so urgent catastrophic
failures should be covered by a separate fast signal rather than weakening this
ratio alert.

### f) Symptom alerts versus cause alerts

A cause alert could page when container CPU exceeds 80%, the process restarts,
or disk utilization is high. Those conditions are not necessarily user-visible:
CPU can be high while every request succeeds, and one clean restart can recover
without impact. Paging on the error ratio is better because it directly
represents failed user requests and remains valid across many underlying causes;
cause metrics belong on dashboards or as diagnostic warnings unless they
predict imminent user harm with strong evidence.

### g) Quantifying alert fatigue

I would review this alert if more than 10% of its pages over a rolling 30-day
window occurred when users had no measurable elevated error ratio or required
no operator action. Put differently, at least 90% of pages should correspond to
real user impact and an actionable response. I would classify and track every
page outcome rather than relying on subjective recollection.

## Bonus — external synthetic monitoring

The external probe requires a public tunnel and an authenticated Checkly (or
equivalent) account. I have not invented regional measurements. After the probe
runs for at least 30 minutes from two regions, I will record its configuration,
screenshot, and real p50/p95/error comparison here.

| | Prometheus (inside Compose) | External probe (two regions) |
|---|---:|---:|
| Average latency p50 | Pending real measurement | Pending real measurement |
| Average latency p95 | Pending real measurement | Pending real measurement |
| Errors observed | Pending real measurement | Pending real measurement |

An external probe can detect DNS, TLS, public routing, CDN, firewall, or tunnel
failures that an internal Prometheus scrape cannot see. Prometheus can expose
internal counters, response-code breakdowns, stored-note saturation, and
service health even when no public probe request happens to fail. Together they
separate application health from end-to-end reachability.

## Completion status

- [x] Compose, scrape config, provisioning, four-panel dashboard, and alert rule.
- [x] Actionable runbook and all seven design answers.
- [x] Static YAML, JSON, Compose, shell, and Go validation.
- [x] Live Prometheus target and provisioned Grafana dashboard API evidence.
- [x] Grafana dashboard screenshot with visible traffic.
- [x] Deliberate `Inactive` to `Pending` to `Firing` alert evidence.
- [ ] Optional 30-minute two-region external probe.
- [ ] Signed commits, upstream pull request, and Moodle submission.
