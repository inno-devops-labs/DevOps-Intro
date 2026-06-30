# Runbook — `HighErrorRate` on QuickNotes

**Alert:** `HighErrorRate`
**Source:** Prometheus rule `monitoring/prometheus/alerts.yml`
**Severity:** `page` — user-facing impact, not just noise.

---

## 1. What this alert means

Over the past 5 minutes, **more than 5% of QuickNotes HTTP responses returned a 4xx or 5xx status**. End users are seeing failures — broken note saves, error pages, or worse. This is a *symptom* alert (something the user can observe), not a *cause* alert (e.g., CPU is high). Treat it as "users are unhappy right now."

---

## 2. Triage steps

Do these in order; stop at the first that gives a clear answer.

1. **Confirm the alert isn't a misfire.** Open Grafana → "QuickNotes — Golden Signals" → **Errors** panel. The line should be above the orange threshold (5%) for the last 5+ minutes. If it just spiked once and returned, the alert will auto-resolve — keep an eye on it but don't escalate.
2. **Identify which status codes drive the ratio.** Run on the host (or any Prometheus client):
   ```
   sum by (code) (rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))
   ```
   - **500 spike** → server is throwing — pull container logs (`docker compose logs quicknotes --tail=200`) and look for stack traces or `seed:`/`store:` panics.
   - **400 spike** → bad client requests at unusual volume. Most likely a misbehaving client (test script left running) or an attack. Cross-check with `Traffic` panel: did total req/s also jump?
   - **404 spike** → someone is iterating note IDs that don't exist; not always real impact, but check whether legitimate users are hitting it.
3. **Correlate with `Saturation` (notes_total).** If the gauge is flat, the data layer is probably healthy. If it dropped, the JSON file may have been truncated or the container restarted with a clean volume. `docker compose ps` will show recent restarts; `docker volume inspect devops-intro_quicknotes-data` for the data path.
4. **Check the scrape itself.** A "100% error" reading can be a false positive if Prometheus stopped scraping and only the bad samples are recent. Visit `http://localhost:9090/targets` — `quicknotes` must be `UP` with `LastScrape` < 30 s ago.

---

## 3. Mitigations

Two fast options to stop user impact while you investigate the root cause:

- **Restart the QuickNotes container.** Most "the process is in a bad state" classes are paper-cut over with a restart. From the host:
  ```
  docker compose restart quicknotes
  ```
  Lab 6 hardening means the new container has the same data volume — no data loss, only ~5 seconds of downtime. If errors disappear after restart, you have a memory-leak / leaked-state suspect.
- **Roll back to the last known-good image tag.** If a new build was deployed recently (`docker compose images quicknotes` will show the image digest), revert by pinning the previous tag in `compose.yaml` and re-running `docker compose up -d`. Faster than fixing forward when the root cause is "the new code is buggy." (For multi-replica setups, drain traffic from the bad instance first.)

If neither helps, this is no longer a 5-minute mitigation problem — escalate to whoever owns QuickNotes and start an incident channel.

---

## 4. Post-incident

Once errors are back below 5% and have stayed there for ≥ 15 minutes:

- **Confirm resolution** in Grafana (Errors panel back in green band) and in the Prometheus Alerts UI (`HighErrorRate` returns to `Inactive`).
- **Write a postmortem** using the Lecture 1 template: timeline, impact (how many users, for how long), what went well, what went badly, action items with owners and dates.
- **Capture data while it's fresh** — copy the relevant Grafana dashboard time range to the postmortem (Share → Snapshot, or screenshot), grab the matching `docker compose logs quicknotes` window, and any external monitoring data (e.g., Lab 8 Bonus Checkly checks if configured).
- **Tune the alert if needed.** If the alert fired but no user noticed, the threshold or duration may be too tight — consider raising to 7%/10m. If the alert *didn't* fire but users complained, lower it. Document the change in the runbook so the next on-call understands why.
- **Close the loop** — link the postmortem from the original alert annotation if you're using a paging tool that keeps that history.
