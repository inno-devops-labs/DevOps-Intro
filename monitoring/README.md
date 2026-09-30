# QuickNotes monitoring

I use this stack to monitor QuickNotes with Prometheus and Grafana. Prometheus
scrapes the application every 15 seconds, evaluates one sustained-error alert,
and supplies the provisioned four-panel Grafana dashboard.

## Start the stack

I provide the Grafana password at runtime so no credential is committed:

```bash
export GRAFANA_ADMIN_USER=lab8admin
export GRAFANA_ADMIN_PASSWORD='replace-with-a-long-unique-password'
docker compose up --build -d
docker compose ps
```

The local endpoints are:

- QuickNotes: <http://127.0.0.1:8080>
- Prometheus: <http://127.0.0.1:9090>
- Grafana: <http://127.0.0.1:3000>

Grafana loads the `QuickNotes Golden Signals` dashboard from
`monitoring/grafana/dashboards/golden-signals.json`; I do not need to create the
data source or dashboard through the UI.

## Verify scraping and generate traffic

```bash
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS http://127.0.0.1:9090/api/v1/targets \
  | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

scripts/lab8-generate-traffic.sh mixed
```

I can capture the baseline text evidence with
`scripts/lab8-capture.sh baseline`. It waits for the target to become healthy,
generates traffic, and verifies the provisioned dashboard through Grafana's API.

The dashboard intentionally labels its first panel as a request-rate proxy:
QuickNotes exposes counters and a notes gauge, but it does not expose a request
duration histogram from which a genuine latency percentile could be calculated.

## Exercise the alert

The `QuickNotesHighErrorRate` rule uses a two-minute rolling error ratio and a
five-minute `for` duration. The shorter range prevents one burst from remaining
true for the entire pending period, while a continuous breach still fires after
five minutes.

```bash
scripts/lab8-generate-traffic.sh errors

curl -fsS http://127.0.0.1:9090/api/v1/rules \
  | jq '.data.groups[].rules[] | {name: .name, state: .state}'
```

For the graded firing evidence I use `scripts/lab8-capture.sh alert`; it saves
the initial and pending rule states, prints progress every 30 seconds, waits for
one final Prometheus evaluation, saves the firing rule JSON, and fails unless
the observed transition is `inactive` to `pending` to `firing`.

The error generator sends two healthy requests and one malformed POST per
second for six minutes. I stop it after capturing the transition to `firing`;
the alert returns to inactive after the error samples age out of the range.

## Stop the stack

```bash
docker compose down
```

I use `docker compose down -v` only when I deliberately want to delete the
QuickNotes and Prometheus data volumes.
