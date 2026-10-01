# Lab 8 — Monitoring, Golden Signals, and Alerting

## Goal

Configure Prometheus and Grafana to monitor QuickNotes, build a Golden Signals dashboard, define a sustained high-error-rate alert, and document the incident response procedure.

## Task 1 — Prometheus and Grafana

### Prometheus configuration

Prometheus scrapes the QuickNotes service every 15 seconds using the Docker Compose service name:

    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: quicknotes
        static_configs:
          - targets:
              - quicknotes:8080

The target is `quicknotes:8080`, so Prometheus communicates with QuickNotes through the internal Compose network.

### Grafana datasource

Grafana is provisioned with Prometheus as the default datasource:

    apiVersion: 1

    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
        isDefault: true
        uid: prometheus
        editable: false

### Golden Signals dashboard

The dashboard contains four panels:

1. **Latency** — QuickNotes does not expose a request-duration histogram, so the dashboard uses the allowed request-rate proxy based on `quicknotes_http_requests_total`.
2. **Traffic** — request rate calculated with `rate()`.
3. **Errors** — percentage of HTTP 4xx/5xx responses relative to total request rate.
4. **Saturation** — current number of stored notes from `quicknotes_notes_total`.

Important PromQL expressions:

    rate(quicknotes_http_requests_total[5m])

    100 *
    sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
    /
    sum(rate(quicknotes_http_requests_total[5m]))

    quicknotes_notes_total

### Prometheus target verification

The QuickNotes Prometheus target was verified through the Prometheus API:

    {
      "job": "quicknotes",
      "instance": "quicknotes:8080",
      "health": "up",
      "lastError": ""
    }

Prometheus and Grafana were also checked through their health endpoints.

### Design questions

#### a) Why pull instead of push?

Prometheus uses a pull model because it periodically scrapes application metrics from known endpoints. This keeps metric collection centralized and makes target health directly observable.

#### b) Why this scrape interval?

A 15-second interval provides sufficiently fresh monitoring data for the lab while avoiding unnecessary scrape overhead.

#### c) When would `rate()`, `irate()`, or `delta()` be used?

- `rate()` is appropriate for a smoothed per-second rate over a time window and is used for the dashboard request/error metrics.
- `irate()` focuses on the most recent counter samples and can be useful for short-lived spikes.
- `delta()` is appropriate for gauges when measuring their change over a period.

#### d) Why provision Grafana from files?

File provisioning makes the datasource and dashboard reproducible. The monitoring configuration can be stored in Git and recreated automatically when the Compose stack starts.

## Task 2 — Alerting and Runbook

### Alert definition

The alert is based on the HTTP 4xx/5xx error ratio:

    - alert: QuickNotesHighErrorRate
      expr: |
        (
          sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
          /
          sum(rate(quicknotes_http_requests_total[5m]))
        ) > 0.05
      for: 5m
      labels:
        severity: page
      annotations:
        summary: "QuickNotes error rate is above 5%"
        description: "QuickNotes has sustained an HTTP error ratio above 5% for 5 minutes."
        runbook: "docs/runbook/high-error-rate.md"

The `for: 5m` condition prevents the alert from firing because of a single short burst of errors.

The alert rules were validated with:

    promtool check rules /etc/prometheus/alerts.yml
    SUCCESS: 1 rules found

### Deliberate alert test

A sustained stream of malformed requests was generated to produce HTTP 400 responses while normal health requests continued.

The resulting error ratio exceeded the 5% threshold for more than five minutes.

The alert transitioned through:

    Normal → Pending → Firing

The Prometheus alert API reported:

    {
      "name": "QuickNotesHighErrorRate",
      "state": "firing",
      "health": "ok",
      "duration": 300
    }

The Grafana alert view also showed the alert in the `FIRING` state with `severity="page"` and the runbook annotation.

### Runbook

The incident runbook is available at:

`docs/runbook/high-error-rate.md`

It documents:

- what the alert means;
- checking the current Prometheus error ratio;
- identifying the HTTP status codes causing the errors;
- checking QuickNotes health and container status;
- inspecting application logs;
- mitigation options;
- resolution verification;
- a blameless post-incident review based on the course postmortem approach.

### Design questions

#### e) What would happen if the threshold were 1%?

The alert would become more sensitive and could trigger on smaller error-rate increases. This would increase the chance of detecting minor degradations but could also produce more alerts from relatively small error bursts.

#### f) How would you avoid paging on a single 4xx burst?

Use a time window and a sustained `for` condition, as in the implemented rule:

    [5m]
    for: 5m

This requires the error ratio to remain above the threshold instead of reacting immediately to a short spike.

#### g) Why should the runbook be linked from the alert?

The runbook gives the responder immediate operational guidance during an incident. Linking it directly from the alert reduces the time needed to find the appropriate triage and mitigation procedure.

## Verification

The monitoring stack was started with:

    docker compose up -d

Verified components:

- QuickNotes — healthy
- Prometheus — ready
- Grafana — database/API healthy
- Prometheus QuickNotes target — `up`
- Grafana Golden Signals dashboard — provisioned
- High-error-rate alert — successfully observed in `Firing` state

The final implementation includes:

    monitoring/
    ├── prometheus/
    │   ├── prometheus.yml
    │   └── alerts.yml
    └── grafana/
        ├── dashboards/
        │   └── golden-signals.json
        └── provisioning/
            ├── dashboards/
            │   └── dashboard.yml
            └── datasources/
                └── datasource.yml

    docs/
    └── runbook/
        └── high-error-rate.md

The optional Checkly/external synthetic monitoring bonus was not implemented.
