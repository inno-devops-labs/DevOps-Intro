# Lab 8 - SRE & Monitoring: Golden Signals Dashboard + One Good Alert

## Overview

This lab extends the QuickNotes Docker Compose stack with Prometheus and Grafana. Prometheus scrapes QuickNotes metrics from inside the Compose network, Grafana provisions a Prometheus datasource and a four-panel golden signals dashboard, and Prometheus evaluates one alert rule for sustained high HTTP error rate. A runbook is included for the alert.

---

# Task 1 - Prometheus + Grafana with a Provisioned Dashboard

## File layout

```text
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   └── alerts.yml
└── grafana/
    ├── dashboards/
    │   └── golden-signals.json
    └── provisioning/
        ├── datasources/
        │   └── datasource.yml
        └── dashboards/
            └── dashboard.yml

docs/
└── runbook/
    └── high-error-rate.md

submissions/
└── lab8.md
```

---

## compose.yaml

```yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true

  prometheus:
    image: prom/prometheus:v3.11.3
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./monitoring/prometheus/alerts.yml:/etc/prometheus/alerts.yml:ro
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
    depends_on:
      quicknotes:
        condition: service_healthy
    restart: unless-stopped

  grafana:
    image: grafana/grafana:13.0.3
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: "admin"
      GF_SECURITY_ADMIN_PASSWORD: "lab8-admin-please-change"
      GF_USERS_DEFAULT_THEME: "dark"
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  quicknotes-data:
```

---

## Prometheus config

File: `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:
  - job_name: "quicknotes"
    static_configs:
      - targets:
          - "quicknotes:8080"
```

This config sets the global scrape interval to 15 seconds and defines one scrape job for QuickNotes. The target is `quicknotes:8080`, using the Compose service name and internal container port.

---

## Prometheus alert rule

File: `monitoring/prometheus/alerts.yml`

```yaml
groups:
  - name: quicknotes-alerts
    rules:
      - alert: QuickNotesHighErrorRate
        expr: |
          (
            sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
            /
            clamp_min(sum(rate(quicknotes_http_responses_by_code_total[5m])), 0.001)
          ) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "QuickNotes high HTTP error rate"
          description: "More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes."
          runbook_url: "docs/runbook/high-error-rate.md"
```

This alert fires only when the error ratio is above 5% for a sustained 5 minutes. It uses `quicknotes_http_responses_by_code_total` because the total request counter does not include status/code labels.

---

## Grafana datasource provisioning

File: `monitoring/grafana/provisioning/datasources/datasource.yml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

This provisions Prometheus as the default Grafana datasource using the Compose service name `prometheus`.

---

## Grafana dashboard provider

File: `monitoring/grafana/provisioning/dashboards/dashboard.yml`

```yaml
apiVersion: 1

providers:
  - name: "QuickNotes dashboards"
    orgId: 1
    folder: "QuickNotes"
    type: file
    disableDeletion: false
    allowUiUpdates: true
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
```

This tells Grafana to load dashboards from `/var/lib/grafana/dashboards`, where the dashboard JSON is mounted.

---

## Grafana dashboard JSON

File: `monitoring/grafana/dashboards/golden-signals.json`

```json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "description": "p95 request duration if histogram exists; otherwise falls back to request rate as a proxy.",
      "fieldConfig": {
        "defaults": {
          "unit": "s"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "histogram_quantile(0.95, sum(rate(quicknotes_http_request_duration_seconds_bucket[5m])) by (le)) or sum(rate(quicknotes_http_requests_total[5m]))",
          "legendFormat": "p95 latency or request-rate proxy",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Latency",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "description": "Total request rate.",
      "fieldConfig": {
        "defaults": {
          "unit": "reqps"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 2,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(rate(quicknotes_http_requests_total[1m]))",
          "legendFormat": "requests/sec",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Traffic",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "description": "Ratio of HTTP 4xx and 5xx responses to all responses.",
      "fieldConfig": {
        "defaults": {
          "max": 1,
          "min": 0,
          "unit": "percentunit"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 8
      },
      "id": 3,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "sum(rate(quicknotes_http_responses_by_code_total{code=~\"4..|5..\"}[5m])) / clamp_min(sum(rate(quicknotes_http_responses_by_code_total[5m])), 0.001)",
          "legendFormat": "error ratio",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Errors",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "description": "Current number of notes stored by QuickNotes.",
      "fieldConfig": {
        "defaults": {
          "min": 0,
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 8
      },
      "id": 4,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "editorMode": "code",
          "expr": "quicknotes_notes_total",
          "legendFormat": "notes",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Saturation",
      "type": "timeseries"
    }
  ],
  "preload": false,
  "refresh": "10s",
  "schemaVersion": 41,
  "tags": [
    "quicknotes",
    "golden-signals",
    "lab8"
  ],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-30m",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "browser",
  "title": "QuickNotes Golden Signals",
  "uid": "quicknotes-golden-signals",
  "version": 1,
  "weekStart": ""
}
```

The dashboard has four golden signal panels:

1. Latency
2. Traffic
3. Errors
4. Saturation

---

## Stack startup

Command:

```powershell
docker compose down -v
docker compose up --build -d
Start-Sleep -Seconds 20
docker compose ps
```

Expected services:

```text
quicknotes
prometheus
grafana
```

---

## Prometheus target health

Command:

```powershell
$targets = Invoke-RestMethod http://localhost:9090/api/v1/targets
$targets.data.activeTargets.health
```

Output:

```text
up
```

Raw target API also showed:

```json
"health":"up"
```

This confirms that Prometheus successfully scrapes QuickNotes.

---

## QuickNotes metrics check

Command:

```powershell
curl.exe -s http://localhost:8080/metrics | Select-String "quicknotes_http_requests_total"
```

Output:

```text
# HELP quicknotes_http_requests_total All HTTP requests.
# TYPE quicknotes_http_requests_total counter
quicknotes_http_requests_total 1354
```

The status-code-specific metric used for the alert was:

```text
quicknotes_http_responses_by_code_total
```

The alert and dashboard error panel use this metric because it includes the `code` label.

---

## Traffic generation

Command:

```powershell
1..200 | ForEach-Object {
  curl.exe -s http://localhost:8080/health | Out-Null

  if ($_ % 5 -eq 0) {
    curl.exe -s -X POST -H "Content-Type: application/json" --data "{bad json" http://localhost:8080/notes | Out-Null
  }

  Start-Sleep -Milliseconds 100
}
```

This generated healthy requests and malformed POST requests to make the dashboard show non-trivial traffic and errors.

---

## Grafana dashboard screenshot

Dashboard with generated traffic:

https://gyazo.com/3a3a5d95e93616b63f5ef8f60e833cfb

---

## Task 1 Design Questions

### a) Pull vs push: what does Prometheus pulling mean?

Prometheus uses a pull model, which means Prometheus initiates HTTP requests to scrape metrics from QuickNotes. Therefore, QuickNotes does not need to know where Prometheus is, but Prometheus must be able to reach QuickNotes.

In this Compose stack, Prometheus reaches QuickNotes at `quicknotes:8080` using Docker Compose DNS. If Prometheus cannot reach QuickNotes, then the target becomes `down`, the `up` metric becomes `0`, and Prometheus stops receiving fresh application metrics. The application may still be running, but monitoring visibility is lost.

### b) What query problems come from setting `scrape_interval` to `5s` or `5m`?

A 5-second scrape interval increases metric volume and storage load. It also makes short-window queries more sensitive to noise and can produce unnecessarily spiky graphs. It may be useful for very fast systems, but for a small app like QuickNotes it is excessive.

A 5-minute scrape interval is too slow for operational monitoring. Queries like `rate(metric[1m])` may not have enough samples, alerts take longer to detect real incidents, and dashboards feel stale. A 15-second interval is a practical middle ground for a lab service because it gives enough samples for rate calculations without generating too much data.

### c) `rate()` vs `irate()` vs `delta()` for the Traffic panel

The Traffic panel should use `rate()` because HTTP requests are represented by a counter. `rate(counter[window])` calculates the average per-second increase over the selected time window and handles counter resets.

`irate()` uses only the last two samples, so it is more volatile and better for debugging very short spikes, not for a stable golden signals dashboard. `delta()` returns the raw difference over a time range, not a per-second rate, so it is less appropriate for requests-per-second traffic.

### d) Why provision Grafana from files?

Provisioning Grafana from files makes the dashboard and datasource reproducible. A fresh `docker compose up` can recreate the monitoring stack without manual clicking in the UI. It also means the dashboard JSON, datasource config, and provider config can be reviewed in pull requests, versioned in Git, and restored after a container or volume is deleted.

Manual UI configuration is easy to lose and hard to audit. File provisioning treats observability configuration like code.

---

# Task 2 - One Good Alert + Runbook

## Alert rule definition

File: `monitoring/prometheus/alerts.yml`

```yaml
groups:
  - name: quicknotes-alerts
    rules:
      - alert: QuickNotesHighErrorRate
        expr: |
          (
            sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
            /
            clamp_min(sum(rate(quicknotes_http_responses_by_code_total[5m])), 0.001)
          ) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "QuickNotes high HTTP error rate"
          description: "More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes."
          runbook_url: "docs/runbook/high-error-rate.md"
```

The alert fires when the error ratio exceeds 5% for 5 minutes. It has `severity: page` and a runbook annotation.

---

## Alert rule loaded

Command:

```powershell
curl.exe -s http://localhost:9090/api/v1/rules | Select-String "quicknotes_http_responses_by_code_total"
```

Relevant output:

```text
"state":"pending"
"name":"QuickNotesHighErrorRate"
"query":"(sum(rate(quicknotes_http_responses_by_code_total{code=~\"4..|5..\"}[5m])) / clamp_min(sum(rate(quicknotes_http_responses_by_code_total[5m])), 0.001)) > 0.05"
"duration":300
"labels":{"severity":"page"}
"runbook_url":"docs/runbook/high-error-rate.md"
"value":"3.089430894308943e-01"
"health":"ok"
```

This shows the rule loaded correctly, evaluated successfully, and entered pending state.

---

## Alert trigger traffic

Command:

```powershell
$end = (Get-Date).AddMinutes(6)

while ((Get-Date) -lt $end) {
  curl.exe -s http://localhost:8080/health | Out-Null
  curl.exe -s -X POST -H "Content-Type: application/json" --data "{bad json" http://localhost:8080/notes | Out-Null
  Start-Sleep -Seconds 1
}
```

This produced a sustained error ratio above 5% for more than 5 minutes.

---

## Alert pending screenshot

The alert entered Pending state after the error ratio exceeded 5%:

https://gyazo.com/59a9f7162d2921e879226449096a7165

---

## Alert firing screenshot

The alert entered Firing state after the sustained 5-minute error-rate breach:

https://gyazo.com/ce7bbea0442daab07c1f015e18a3301c

---

## Alert API output in firing state

Command:

```powershell
curl.exe -s "http://localhost:9090/api/v1/alerts"
```

Output:

```json
{
  "status": "success",
  "data": {
    "alerts": [
      {
        "labels": {
          "alertname": "QuickNotesHighErrorRate",
          "severity": "page"
        },
        "annotations": {
          "description": "More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes.",
          "runbook_url": "docs/runbook/high-error-rate.md",
          "summary": "QuickNotes high HTTP error rate"
        },
        "state": "firing",
        "activeAt": "2026-06-30T18:21:56.291370819Z",
        "value": "4.605263157894737e-01"
      }
    ]
  }
}
```

This confirms that the alert reached `firing`, carried the `severity: page` label, and linked to the runbook.

---

# Runbook

File: `docs/runbook/high-error-rate.md`

```md
# Runbook: QuickNotes High Error Rate

## What this alert means

More than 5% of QuickNotes HTTP requests have returned 4xx or 5xx responses for at least 5 minutes.

## Triage steps

1. Open the QuickNotes Golden Signals dashboard in Grafana and check whether the error ratio is still above 5%.
2. Check whether traffic changed sharply at the same time. A real traffic spike plus errors may indicate a user-facing incident.
3. In Prometheus, inspect the request metric by status code to identify whether the errors are mostly 4xx or 5xx.
4. Check the QuickNotes container logs:

       docker compose logs quicknotes --tail=100

5. Confirm the service is reachable:

       curl -s http://localhost:8080/health

6. Check whether recent deploy/config changes happened:

       git log --oneline -5
       docker compose ps

## Mitigations

1. Restart the QuickNotes service if it is returning 5xx responses or appears stuck:

       docker compose restart quicknotes

2. Roll back the most recent configuration or image change if the issue started immediately after a deploy.
3. If malformed client traffic is causing a flood of 4xx responses, temporarily block or rate-limit the offending client/source if available.
4. If the data volume is suspected to be corrupt, stop the service and inspect `/data/notes.json` before deleting or replacing anything.

## Post-incident

After the incident is mitigated:

1. Write a short postmortem using the Lecture 1 postmortem template.
2. Record the timeline: detection time, start time, mitigation time, and resolution time.
3. Identify whether users were affected and for how long.
4. Add or improve tests, alerts, dashboard panels, or validation so this failure is easier to detect next time.
5. Update this runbook if any step was missing or misleading.
```

---

## Task 2 Design Questions

### e) Why “sustained for 5 minutes” instead of firing immediately on the first bad request?

A single bad request is not necessarily an incident. It could be one malformed client request, a user typo, or a harmless probe. Firing immediately on the first error would create noisy alerts and train on-call engineers to ignore pages.

A 5-minute sustained threshold filters out short bursts and focuses the alert on user-visible, persistent degradation. It is still fast enough to detect real incidents, but slow enough to avoid paging on one-off noise.

### f) Symptom alerts vs cause alerts: what is a cause alert someone might write for QuickNotes, and why is it worse?

A cause alert might be something like “CPU usage above 80%” or “container memory usage above 80%.” That is worse as a page because high CPU or memory does not always mean users are affected. The app could be busy but still serving requests successfully.

The high error-rate alert is a symptom alert because it measures something users actually experience: failed requests. Cause metrics are useful for dashboards and investigation, but symptom alerts are better for paging because they are closer to real user impact.

### g) What quantitative threshold would show the alert is too noisy?

If this alert pages more than about **10% of the time when users are not actually affected**, I would consider it too noisy. In other words, if more than 1 in 10 pages turns out to be a false positive or non-actionable event, the alert threshold or duration should be adjusted.

Another useful threshold is actionability: if fewer than 90% of pages require a real investigation or mitigation, the alert is probably causing alert fatigue. Paging should be reserved for problems that need human attention now.

---

# Bonus Task - Synthetic Monitoring

Bonus was not attempted.

---

# Final Result

The Lab 8 stack successfully runs:

```text
QuickNotes
Prometheus
Grafana
```

Prometheus scrapes QuickNotes successfully:

```text
up
```

Grafana provisions the QuickNotes Golden Signals dashboard from JSON and shows traffic:

https://gyazo.com/3a3a5d95e93616b63f5ef8f60e833cfb

The high-error-rate alert transitions through Pending and reaches Firing:

```json
"state": "firing"
```

Firing screenshot:

https://gyazo.com/ce7bbea0442daab07c1f015e18a3301c

```
```
