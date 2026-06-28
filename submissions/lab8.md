# Lab 8 Submission

## Task 1 — Prometheus + Grafana with a Provisioned Dashboard

### Config files

#### `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'quicknotes'
    static_configs:
      - targets: ['quicknotes:8080']
```

#### monitoring/grafana/provisioning/datasources/datasource.yml
```
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

#### monitoring/grafana/provisioning/dashboards/dashboard.yml
```
apiVersion: 1

providers:
  - name: 'QuickNotes'
    orgId: 1
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

#### Extended compose.yaml
```
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/app/seed.json
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/app/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp

  prometheus:
    image: prom/prometheus:v3.2.1
    container_name: prometheus
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
    depends_on:
      quicknotes:
        condition: service_healthy

  grafana:
    image: grafana/grafana:12.0.0
    container_name: grafana
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=secureadmin123
    ports:
      - "3000:3000"
    depends_on:
      prometheus:
        condition: service_started

volumes:
  quicknotes-data:
    name: quicknotes-data
```

### Prometheus Targets
![Target is UP](image.png)

### Golden Signals Dashboard
The dashboard auto-loads in Grafana at http://localhost:3000 with four golden-signal panels.
![Dashboard](image-1.png)


### Design Questions
a) Pull vs push: what does it mean for which side needs to be reachable?

Prometheus pulls metrics from targets. This means Prometheus must be able to reach QuickNotes. If Prometheus can't reach QuickNotes (network issue, service down), the target becomes DOWN and no data is collected. In a push model, QuickNotes would need to reach Prometheus.

b) scrape_interval: 15s is a default. What query problems do you create by setting it to 5s? To 5m?

5s: Increases load on both Prometheus and QuickNotes. More frequent scrapes mean more network traffic and CPU usage.

5m: Reduces granularity. You may miss short-lived spikes in latency or errors that last less than 5 minutes.

c) PromQL rate() vs irate() vs delta() — which one is right for Traffic panel and why?

rate() is the right choice for the Traffic panel because it calculates the average per-second rate over the interval, smoothing out bursts. irate() captures instant changes but can be noisy. delta() is for gauges, not counters.

d) Why provision Grafana from files instead of clicking through the UI?

File provisioning makes the setup reproducible, version-controlled, and consistent across environments. Clicking through the UI is error-prone and not scalable — you can't easily recreate the same dashboard after a restart or in a new environment.

## Task 2 — One Good Alert + Runbook
### Runbook
#### File: docs/runbook/high-error-rate.md
```
# Runbook — QuickNotes High Error Rate

**Alert:** `HighErrorRate` · **Severity:** page

## What this alert means

More than 5% of QuickNotes HTTP responses have been 4xx/5xx for at least 5 minutes — users are
getting errors right now, not a one-off blip.

## Triage steps

1. **Confirm it's real.** Open the Golden Signals dashboard (Grafana → QuickNotes — Golden Signals)
   and look at the **Errors** panel. Is the ratio still above 5%, and is it 4xx (client/bad input)
   or 5xx (server)? Check **Traffic** too — a tiny request volume can make the ratio jump on noise.
2. **Check the service is up.** `curl -s http://localhost:8080/health` and
   `docker compose ps quicknotes`. If it's unhealthy or restarting, jump to Mitigations.
3. **Read the logs.** `docker compose logs --tail=100 quicknotes` — look for panics, repeated
   handler errors, or a flood of the same bad request (e.g. malformed `POST /notes`). Note whether
   the errors started right after a deploy.

## Mitigations (stop the bleeding)

- **If it started after a deploy:** roll back to the previous image tag and `docker compose up -d`.
  Reverting the change is faster than diagnosing it live.
- **If one client is flooding bad requests:** rate-limit or block that source at the proxy, so a
  single misbehaving caller stops dominating the error ratio.
- **If the process is wedged/unhealthy:** `docker compose restart quicknotes` to get back to a known
  state while you investigate the root cause.

## Post-incident

Once the error ratio is back under 5% and stable, file a blameless postmortem using the Lecture 1
template: timeline, impact, root cause, what made detection/mitigation slow, and concrete follow-ups.
Link the Grafana time range and the offending deploy/commit.
```
### Alert Rule
Rule name: High Error Rate - QuickNotes
#### PromQL:
```
sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m])) / clamp_min(sum(rate(quicknotes_http_responses_by_code_total[5m])), 1e-9) > 0.05
```
Evaluation: 30s interval, 5m pending period

Labels:

severity: page

Annotations:

summary: QuickNotes error rate is high

description: Error rate is above 5% for 5 minutes. Check runbook: docs/runbook/high-error-rate.md

Screenshot of Alert Rule: ![alert rule](image-2.png)

Alert Firing: ![alert firing](image-3.png)

![Dashboard after firing](image-4.png)

### Design Questions

e) Why "sustained for 5 minutes" instead of "fire immediately"?

Firing immediately would trigger on every single error, including transient blips. A sustained 5-minute window filters out noise and ensures the alert only pages when users are actually affected.

f) Symptom alert vs cause alert: what's an example of a cause alert for QuickNotes? Why is it worse?

A cause alert would be "CPU > 80%". It's worse because high CPU can be normal during traffic spikes and doesn't directly mean users are affected. A symptom alert like "5% errors" directly measures user impact and is more reliable.

g) Alert fatigue: what threshold means it's too noisy?

If the alert fires more than 10% of the time when no user is affected, it's too noisy. The on-call engineer gets paged unnecessarily and starts ignoring alerts — exactly what we want to avoid.