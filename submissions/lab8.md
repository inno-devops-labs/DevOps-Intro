# Lab 8 submission

`dashboard.yml`

```
apiVersion: 1

providers:
  - name: default
    folder: ""
    type: file

    options:
      path: /var/lib/grafana/dashboards
```

`datasource.yml`

```
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

`prometeus.yml`

```
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: quicknotes

    static_configs:
      - targets:
          - quicknotes:8080
```

`golden-signals`

```
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
  "links": [],
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "bars",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
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
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.16",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "disableTextWrap": false,
          "editorMode": "builder",
          "expr": "rate(quicknotes_http_requests_total{instance=\"quicknotes:8080\"}[$__rate_interval])",
          "fullMetaSearch": false,
          "hide": false,
          "includeNullMetadata": true,
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "B",
          "useBackend": false
        }
      ],
      "title": "Latency",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
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
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.16",
      "targets": [
        {
          "editorMode": "code",
          "expr": "rate(quicknotes_http_requests_total[$__rate_interval])",
          "legendFormat": "__auto",
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
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
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
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.16",
      "targets": [
        {
          "editorMode": "code",
          "expr": "quicknotes_notes_total",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Saturation",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
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
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.16",
      "targets": [
        {
          "editorMode": "code",
          "expr": "sum(rate(quicknotes_http_responses_by_code_total{code=~\"[45]..\"}[$__rate_interval])) / sum(rate(quicknotes_http_requests_total[$__rate_interval]))",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Errors",
      "type": "timeseries"
    }
  ],
  "preload": false,
  "schemaVersion": 41,
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "browser",
  "title": "New dashboard",
  "uid": "",
  "version": 0
}
```
![alt text](image.png)

```
long1tail@JustSomeLaptop ~/DevOps-Intro (feature/lab8)> curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0   544k      0 --:--:-- --:--:-- --:--:--  597k
"up"
```

- a. Pull means Prometheus must be able to reach QuickNotes (the target must be network-reachable from Prometheus). If Prometheus can't reach QuickNotes, the scrape fails, up becomes 0, and you lose metrics until connectivity is restored.

- b. Setting 5s creates excessive load on both systems and increases cardinality, while making queries slower; setting 5m reduces resolution, causing you to miss short-lived error spikes and making rate() calculations inaccurate.

- c. rate() is the right choice for the Traffic panel because it computes the per‑second average increase over the chosen time window, smoothing out bursts and providing a stable view of request flow, unlike irate() which reacts too sharply to single spikes, and delta() which returns total count rather than a rate.

- d. Provisioning from files ensures dashboards are version‑controlled, reproducible, and automatically applied on every fresh stack start, eliminating manual, error‑prone UI steps and keeping the setup consistent across environments.


```
apiVersion: 1
groups:
    - orgId: 1
      name: main
      folder: folder
      interval: 1m
      rules:
        - uid: efqqj408ng0zke
          title: Errors
          condition: C
          data:
            - refId: A
              relativeTimeRange:
                from: 600
                to: 0
              datasourceUid: PBFA97CFB590B2093
              model:
                editorMode: code
                expr: (sum(rate(quicknotes_http_requests_total{code=~"4..|5.."}[5m])) / sum(rate(quicknotes_http_requests_total[5m]))) > 0.05
                instant: true
                intervalMs: 1000
                legendFormat: __auto
                maxDataPoints: 43200
                range: false
                refId: A
            - refId: C
              datasourceUid: __expr__
              model:
                conditions:
                    - evaluator:
                        params:
                            - 0.05
                        type: gt
                      operator:
                        type: and
                      query:
                        params:
                            - C
                      reducer:
                        params: []
                        type: last
                      type: query
                datasource:
                    type: __expr__
                    uid: __expr__
                expression: A
                intervalMs: 1000
                maxDataPoints: 43200
                refId: C
                type: threshold
          noDataState: NoData
          execErrState: Error
          for: 1m
          annotations: {}
          labels: {}
          isPaused: false
          notification_settings:
            receiver: grafana-default-email
```

![alt text](image-1.png)

- e. A 5‑minute sustain period prevents false positives caused by transient glitches (e.g., a single misbehaving client, a momentary network hiccup). It confirms that the error condition is persistent and actually affecting users, not just a one‑off spike.

- f. A cause alert might be: "Database connection pool usage > 90%".
It's worse because high pool usage doesn't necessarily mean users are seeing errors—the app might be handling the load gracefully. On‑call engineers would then have to correlate this metric with user‑visible symptoms. Symptom alerts (like error ratio) directly measure what users experience, so they are more actionable and reduce cognitive overhead during incidents.

- g. A reasonable rule of thumb: if your alert pages the on‑call team more than 5% of the time when the user was not actually affected (i.e., false‑positive rate > 5%), it's too noisy. In practice, a healthy false‑positive rate should be < 1% to keep on‑call attention sharp and prevent pager fatigue.