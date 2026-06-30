# Lab 8 — SRE & Monitoring: Golden Signals Dashboard + One Good Alert

**Author:** Karim Abdulkin (@GrandAdmiralBee)
**Branch:** `feature/lab8`
**Stack:** podman 5.x (dockerCompat) + Compose v2; `prom/prometheus:v3.0.0`; `grafana/grafana:11.4.0`; QuickNotes from Lab 6 (cherry-picked).
**Local ports:** QuickNotes `127.0.0.1:28080` (8080 was taken by Steam, 18080 by the still-running Lab 5 VM SSH forward — picked a non-conflicting port and documented it), Prometheus `:9090`, Grafana `:3000`.

---

## Task 1 — Prometheus + Grafana with a Provisioned Dashboard

### Layout

```text
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   └── alerts.yml
└── grafana/
    ├── provisioning/
    │   ├── datasources/datasource.yml
    │   └── dashboards/dashboard.yml
    └── dashboards/
        └── golden-signals.json
docs/runbook/high-error-rate.md
.env.example      ← committed
.env              ← gitignored (Grafana admin creds)
```

### `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: quicknotes-lab8

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:
  - job_name: quicknotes
    metrics_path: /metrics
    static_configs:
      - targets:
          - quicknotes:8080
        labels:
          app: quicknotes
```

### `monitoring/grafana/provisioning/datasources/datasource.yml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
    jsonData:
      timeInterval: 15s
```

### `monitoring/grafana/provisioning/dashboards/dashboard.yml`

```yaml
apiVersion: 1

providers:
  - name: 'golden-signals'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: true
    editable: false
    updateIntervalSeconds: 30
    allowUiUpdates: false
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: false
```

The dashboard JSON itself (`monitoring/grafana/dashboards/golden-signals.json`) is in the repo — it's verbose so the file is the source of truth.
Schema version 39 (Grafana 11.x), 4 panels in a 2×2 layout, datasource pinned by UID to `prometheus`.

### Compose extension (`compose.yaml` additions)

```yaml
  prometheus:
    image: prom/prometheus:v3.0.0
    ports:
      - "127.0.0.1:9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./monitoring/prometheus/alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus-data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --web.console.libraries=/usr/share/prometheus/console_libraries
      - --web.console.templates=/usr/share/prometheus/consoles
      - --web.enable-lifecycle
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped
    security_opt:
      - "no-new-privileges:true"

  grafana:
    image: grafana/grafana:11.4.0
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: "${GRAFANA_ADMIN_USER:?set in .env}"
      GF_SECURITY_ADMIN_PASSWORD: "${GRAFANA_ADMIN_PASSWORD:?set in .env}"
      GF_AUTH_ANONYMOUS_ENABLED: "false"
      GF_USERS_ALLOW_SIGN_UP: "false"
      GF_INSTALL_PLUGINS: ""
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
      - grafana-data:/var/lib/grafana
    depends_on:
      - prometheus
    restart: unless-stopped
    security_opt:
      - "no-new-privileges:true"
```

The Lab 6 healthcheck pays off: `depends_on: { quicknotes: { condition: service_healthy } }` blocks Prometheus from starting until QuickNotes' `/health` is green,
so the first scrape doesn't waste a 15s cycle on `connection refused`. Both new services keep `no-new-privileges:true`

`GF_SECURITY_ADMIN_*` are read from a gitignored `.env`; `.env.example` ships a placeholder.
The `:?set in .env` syntax means `docker compose up` *fails fast* if `.env` is missing — no accidental boot with empty admin creds.

### Stack boot proof

```console
$ docker compose ps
NAME                        IMAGE                              SERVICE      STATUS
devops-intro-grafana-1      docker.io/grafana/grafana:11.4.0   grafana      Up
devops-intro-prometheus-1   docker.io/prom/prometheus:v3.0.0   prometheus   Up
devops-intro-quicknotes-1   localhost/quicknotes:lab6          quicknotes   Up (healthy)

$ curl -s http://127.0.0.1:9090/api/v1/targets | jq '.data.activeTargets[] | {scrapeUrl, health, lastError}'
{
  "scrapeUrl": "http://quicknotes:8080/metrics",
  "health": "up",
  "lastError": ""
}
```

Target `UP`, no scrape errors. Grafana auto-provisioned the datasource + dashboard:

```console
$ curl -s -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" http://127.0.0.1:3000/api/datasources \
  | jq '.[] | {name, type, uid, url, isDefault}'
{
  "name": "Prometheus",
  "type": "prometheus",
  "uid": "prometheus",
  "url": "http://prometheus:9090",
  "isDefault": true
}

$ curl -s -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" "http://127.0.0.1:3000/api/search?type=dash-db" \
  | jq '.[] | {uid, title, tags}'
{
  "uid": "quicknotes-golden",
  "title": "QuickNotes — Golden Signals",
  "tags": ["golden-signals", "quicknotes", "sre"]
}
```

After hammering QuickNotes with ~200 mixed requests:

```console
$ curl -s 'http://127.0.0.1:9090/api/v1/query?query=rate(quicknotes_http_requests_total[1m])' | jq '.data.result'
[
  {
    "metric": { "app": "quicknotes", "instance": "quicknotes:8080", "job": "quicknotes" },
    "value": [ 1782849785.929, "3.76810074074074" ]
  }
]
```

3.77 req/s — non-trivial. The Errors panel sits at ~0% (all 200/201), the Saturation panel reads 54 notes (4 seeded + 50 created during load).

### Four panels (`golden-signals.json`)

| # | Signal | PromQL |
|---|--------|--------|
| 1 | **Latency proxy** | `rate(quicknotes_http_requests_total[1m])` — QuickNotes has no histogram, per Lab 8 spec we use the request rate as proxy. Marked explicitly in the panel description |
| 2 | **Traffic** | `sum(rate(quicknotes_http_requests_total[1m]))` |
| 3 | **Errors** | `sum(rate(quicknotes_http_responses_by_code_total{code=~"4..\|5.."}[5m])) / sum(rate(quicknotes_http_responses_by_code_total[5m]))` — thresholds at 5% (orange) and 10% (red), same expression as the alert so the dashboard matches what fires |
| 4 | **Saturation** | `quicknotes_notes_total` — gauge, thresholds at 1k (yellow) and 10k (red) |

### Design questions

**a) Pull vs push.** Prometheus pulls — it opens a TCP connection *to* each target and scrapes `/metrics`. That means **Prometheus must be able to reach QuickNotes**, not the other way around. In a Compose network this is free (shared DNS, no firewall), but at scale you need network rules letting Prometheus reach every service it monitors. Failure mode: if Prometheus can't reach QuickNotes (network partition, container down, port blocked), the target shows `DOWN`, all `quicknotes_*` metrics return empty in queries, and panels go "No data". Crucially, **Prometheus doesn't lose the existing alerting rules** — the `up` series itself becomes 0, and a properly configured rule like `up{job="quicknotes"} == 0 for 5m` would fire. The contrast with push: a pushed metric that stops arriving is hard to distinguish from "nothing changed."

**b) `scrape_interval: 15s` — what breaks at 5s vs 5m.**

- **5s**: cost goes through the roof. Each scrape is an HTTP round-trip + parse + persistence cost — 3× more samples, 3× more storage. Worse, `rate(X[1m])` now averages over only 12 samples, which is fine, but `rate(X[5s])` would be unreliable (Prometheus needs at least 2 samples in the range; with `interval=5s` and `[5s]` you often have exactly 1, giving NaN). And cardinality multiplies through Grafana queries that scan it.
- **5m**: queries lose resolution. `rate(X[5m])` over a 1-hour window has only 12 data points; spikes that last < 5 min are *invisible*. Worse, `for: 5m` alerts effectively run on a 1-data-point evaluation — totally unreliable. Storage cost drops but you can't see what users see. 15s is the standard for a reason: enough resolution to catch real outages, not so much that you bankrupt your Prometheus disks.

**c) `rate()` vs `irate()` vs `delta()` for Traffic.** **`rate()`** is correct. It computes the per-second average over the time window (e.g., `[1m]`), and it handles counter resets (process restart → counter goes back to 0) by ignoring negative jumps. `irate()` only looks at the *last two* samples in the window — great for instantaneous diagnostics but it produces a jagged graph in dashboards, and it's deceptive in alerts (single sample noise can fire/clear it). `delta()` is for gauges, not counters — it returns the simple difference between first and last sample without rate-per-second normalization or counter-reset handling, so it gives wrong answers on a counter. Rule of thumb: `rate()` for counters in dashboards, `irate()` only for ad-hoc "show me right now," `delta()` for gauges.

**d) Why provision Grafana from files vs the UI.** Three reasons:

1. **Reproducibility.** A fresh `docker compose down -v && docker compose up -d` should give you the *same* dashboard. UI clicks live in the Grafana SQLite blob (`/var/lib/grafana/grafana.db`) — wipe the volume and they're gone forever. Provisioning lives in your repo.
2. **Code review.** A change to a dashboard arrives as a JSON diff in a pull request; you can review it like any other change. A change made through the UI is invisible to anyone not staring at Grafana right then.
3. **No drift.** When dashboards live in the UI, every operator has the temptation to "just tweak this one panel" without telling anyone. Provisioned dashboards with `editable: false` + `allowUiUpdates: false` prevent that — changes have to go through the repo, which means they go through review.

The workflow is still nice: build the dashboard interactively in the UI, export the JSON (Settings → JSON Model), commit.
The file is the source of truth from then on

---

## Task 2 — One Good Alert + Runbook

### Alert rule — `monitoring/prometheus/alerts.yml`

```yaml
groups:
  - name: quicknotes.golden-signals
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
            /
            sum(rate(quicknotes_http_responses_by_code_total[5m]))
          ) > 0.05
        for: 5m
        labels:
          severity: page
          service: quicknotes
        annotations:
          summary: "QuickNotes error rate > 5% for 5m (current {{ $value | humanizePercentage }})"
          description: |
            5-minute error-ratio (4xx + 5xx over total) on the quicknotes job has been
            above 5% for 5 minutes. Users are seeing failures.
          runbook_url: "https://github.com/GrandAdmiralBee/DevOps-Intro/blob/feature/lab8/docs/runbook/high-error-rate.md"
```

The expression matches the dashboard Errors panel exactly — "what you see firing is what's on the dashboard." `for: 5m` is the sustained-breach gate; `severity: page` marks it as user-impacting; `runbook_url` annotation auto-links the on-call to the relevant runbook.

### Triggering the alert deliberately

A small loadgen script fires bad-JSON `POST /notes` at ~18/sec mixed with 2/sec healthy `GET /health`. Expected error ratio ~90%.

```bash
# /tmp/lab8-loadgen.sh — 9 bad POSTs + 1 healthy GET per ~500ms cycle
URL="http://127.0.0.1:28080"
while …; do
  for _ in $(seq 1 9); do
    curl -s -X POST -H 'Content-Type: application/json' \
      --data "not-json-{$i" "$URL/notes" &
  done
  curl -s "$URL/health" &
  wait
done
```

### Observed transition Normal → Pending → Firing

```text
[20:13:48] state=none     ratio=0.000      ← loadgen starts
[20:14:08] state=pending  ratio=0.857      ← ratio crossed 5% within one 30s eval; `for: 5m` countdown starts
[20:14:28] state=pending  ratio=0.857
[20:14:48] state=pending  ratio=0.857
…
[20:18:48] state=pending  ratio=0.892      ← 4m20s into `for: 5m`
[20:19:08] state=firing   ratio=0.892      ← 5m20s after pending — Firing
```

Full snapshot of the Firing alert from the Prometheus API:

```console
$ curl -s http://127.0.0.1:9090/api/v1/alerts | jq '.data.alerts[0]'
{
  "labels": {
    "alertname": "HighErrorRate",
    "service": "quicknotes",
    "severity": "page"
  },
  "annotations": {
    "description": "5-minute error-ratio (4xx + 5xx over total) on the quicknotes job has been\nabove 5% for 5 minutes. Users are seeing failures.\n",
    "runbook_url": "https://github.com/GrandAdmiralBee/DevOps-Intro/blob/feature/lab8/docs/runbook/high-error-rate.md",
    "summary": "QuickNotes error rate > 5% for 5m (current 89.2%)"
  },
  "state": "firing",
  "activeAt": "2026-06-30T20:13:49.06007921Z",
  "value": "8.919722497522299e-01"
}
```

`activeAt` = 20:13:49, `state=firing` first observed at 20:19:08 → ~5m20s in Pending before firing, which matches `for: 5m` plus one extra eval tick. The summary renders the live value (89.2%) via `humanizePercentage`.

### Runbook

See `docs/runbook/high-error-rate.md` — 4 sections:

1. **What this alert means** — symptom alert ("users are unhappy right now"), one sentence.
2. **Triage steps** — 4 ordered checks: confirm not misfire → break ratio down by status code (500 → server bug; 400 → bad client / attack; 404 → not always real) → cross-check Saturation gauge → verify the scrape itself hasn't silently broken.
3. **Mitigations** — two fast options: restart QuickNotes (5s of downtime; Lab 6 volume survives), or roll back to last-known-good image tag.
4. **Post-incident** — confirm resolution in Grafana + Prom Alerts UI; write a Lecture-1-template postmortem; capture data while fresh; tune the alert if it was noisy or missed real impact; close the loop in the paging tool's history.

The intent is exactly what the lab asks: a 3-AM on-call who has never seen QuickNotes before can act from this runbook.

### Design questions

**e) Why sustained for 5 minutes and not immediate.** A single bad request is *noise* — a misbehaving client testing a webhook, a probe from an attacker, your own e2e test. Paging at 3 AM for one 400 response would mean an on-call resigning within a month. The `for: 5m` gate says "if 5% of users are *consistently* seeing failures for 5 minutes, that's a real problem worth waking someone up for." It also gives self-healing systems room to recover — a container restart, a brief network blip, a Prometheus restart — without burning a page. The cost is detection latency: a true outage that started 30 s ago wakes the on-call ~5 minutes later. That's an acceptable trade because the on-call has to drive in, log in, and triage — those steps eat ~10 minutes regardless of detection latency. So saving 5 minutes of detection latency to gain 100× fewer false pages is the right deal.

**f) Symptom vs cause alerts.** The `HighErrorRate` rule is a symptom alert — it fires on what users actually see (failed responses). A cause alert for the same system might be `quicknotes_cpu_seconds_total rate > 0.8 for 5m` (CPU saturation) or `disk_used_percent{path="/data"} > 0.9` (disk filling). Cause alerts are worse for two reasons. (1) **Wrong signal:** high CPU doesn't necessarily hurt users — maybe the process is just compiling, or QuickNotes scaled to use available compute. Conversely, low CPU with 100% error rate (e.g., the binary is crash-looping) doesn't trip a cause alert at all. (2) **Wrong abstraction:** a cause alert encodes assumptions about *how* the system fails, but real outages take unexpected shapes — disk-full on a partition you weren't alerting on, OOM on a JIT runtime, GC pauses. Symptom alerts catch all of them because they measure the user-visible outcome. Combine with diagnostic dashboards (Saturation panel) to find the cause once paged.

**g) Alert fatigue — quantitative threshold.** A widely-cited Google SRE benchmark: **if more than 50% of pages from a given alert are false positives or non-actionable** — i.e., the on-call looks, sees the system is fine, acknowledges, and goes back to bed — the alert is too noisy and should be tuned or removed. Another sharper threshold from the SRE book: **alerts where the true-positive rate is under 75% should be deleted, not tuned.** Concretely for `HighErrorRate`: if I get paged five times next week and three of them are "the e2e test fired 50 bad requests in a minute and tripped the threshold" — that's 60% false-positive, the alert is broken. The fix is either raising the threshold, lengthening `for:`, or scoping the expression to exclude known traffic patterns (e.g., `code!="400"` if 400 is dominated by intentional bad input from the test suite).

---

## Bonus Task — Synthetic monitoring from outside

Not attempted — explicitly opted out (requires a Checkly account + a public tunnel + 30 min of runtime monitoring). Documented here so the marker isn't searching for it.

---

## Pitfalls Hit

- 🪤 **Port 8080 already in use.** Steam's web-helper binds 8080; Lab 5's still-running Vagrant SSH binds 18080. Settled on **28080** for the host-side QuickNotes mapping. Compose `:?set in .env` syntax fails fast if `.env` is missing — caught early.
- 🪤 **Podman + bind-mounted config gets a stale inode after host-side edit.** The `Edit` tool writes to a temp file and renames over the target (atomic write). The bind mount inside the container holds the *old* inode, so `--web.enable-lifecycle` reload picks up nothing. Fixed by `docker compose restart prometheus` after touching `alerts.yml`. Documented in the runbook *and* learned the hard way mid-lab.
- 🪤 **`humanizePercentage` doesn't compose with `printf "%.1f"`.** First version was `printf "%.1f" (humanizePercentage $value)` — Go's `text/template` renders `humanizePercentage` to a string ("89.2%"), then printf with `%f` gets a string and outputs `%!f(string=8)`. Fixed by piping straight: `{{ $value | humanizePercentage }}` — the function already includes the `%` sign and one decimal.
- 🪤 **`docker pull` doesn't honor `proxychains`.** Podman's helper processes escape LD_PRELOAD. Per the Lab 6 fix: `HTTPS_PROXY=socks5://127.0.0.1:20170 docker pull …` worked on the first try for both Prometheus and Grafana images.

---

## Acceptance checklist

### Task 1 (6 pts)
- [x] Prometheus scrapes QuickNotes (`up == 1`, no `lastError`)
- [x] Grafana auto-provisions dashboard with 4 golden-signal panels
- [x] Non-trivial graphs after ~200 mixed requests (3.77 req/s, 54 notes saturated)
- [x] Design questions a–d answered

### Task 2 (4 pts)
- [x] Alert rule defined with `for: 5m` sustained-breach gate, severity=page label, runbook_url annotation
- [x] Runbook complete with all 4 sections (`docs/runbook/high-error-rate.md`)
- [x] Alert observed `Pending → Firing` end-to-end at 20:13:49 → 20:19:08
- [x] Design questions e, f, g answered

### Bonus (0/2 pts) — explicitly skipped.
