# High HTTP Error Rate

## What this alert means

More than 5% of QuickNotes HTTP responses are 4xx or 5xx for at least five minutes — users are seeing failures at a rate worth paging on.

## Triage steps

1. **Confirm the alert** — open Grafana dashboard *QuickNotes Golden Signals* (or Prometheus `/alerts`) and verify the error panel is elevated, not a scrape glitch. Check `curl -s http://localhost:9090/api/v1/targets` shows `quicknotes` target `up`.
2. **Check QuickNotes health** — `curl -s http://localhost:8080/health | jq` and `docker compose logs quicknotes --tail=50` for panics, permission errors on `/data/notes.json`, or OOM kills.
3. **Identify error type** — in Prometheus/Grafana, break down `quicknotes_http_responses_by_code_total` by `code` label. Dominant `400` suggests bad client payloads; `500` suggests application or storage failure.
4. **Check recent changes** — `docker compose ps`, recent deploys, volume mount issues, or config/env drift (`ADDR`, `DATA_PATH`, `SEED_PATH`).

## Mitigations

1. **Restart the service** — `docker compose restart quicknotes` (fastest way to clear a wedged process; data persists on the named volume).
2. **Roll back bad traffic** — if a client or load script is sending malformed requests, stop or fix it; scale down the offending job.
3. **Restore from known-good state** — if data corruption is suspected, stop QuickNotes, restore `/data/notes.json` from backup or re-seed, then `docker compose up -d quicknotes`.

## Post-incident

After the error rate returns to normal and the alert clears:

- Write a blameless postmortem using the [Lecture 1 postmortem template](https://github.com/inno-devops-labs/DevOps-Intro/blob/main/lectures/lec1.md) (timeline, root cause, action items).
- Add or tune alerts/runbooks if the failure mode was not covered.
- Track follow-up tasks (fix validation, add integration test, improve dashboard panel) in your issue tracker.
