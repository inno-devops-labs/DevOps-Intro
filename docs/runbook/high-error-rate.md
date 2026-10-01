# Runbook - HighErrorRate (QuickNotes)

**Alert:** `HighErrorRate` · `severity: page`
**Fires when:** 4xx+5xx > 5% of all requests, sustained 5 minutes
**Rule file:** `monitoring/prometheus/rules/high-error-rate.yml`
**Dashboard:** Grafana → folder *QuickNotes* → "QuickNotes - Golden Signals"

## 1. What this alert means

Users are failing: more than 1 in 20 QuickNotes requests over the last
5 minutes returned a client or server error (4xx/5xx) — this is a
sustained, user-visible symptom, not a blip.

## 2. Triage steps (in order, ~5 minutes)

1. **Confirm and classify.** Open the Grafana dashboard, Errors panel:
   is the red 5% line crossed, and which code dominates? Then run:

       curl "http://localhost:9090/api/v1/query?query=sum+by+(code)+(rate(quicknotes_http_responses_by_code_total%5B5m%5D))"

   - 5xx dominates → app-side fault, go to step 3.
   - 4xx (400/404/405) dominates → bad client, bad deploy or a bot — go to step 2.

2. **Check what changed in the last hour.**

       docker compose ps                # are all 3 services Up (healthy)?
       curl http://localhost:8080/health # expect {"status":"ok",...}
       git log --oneline -5              # did the app change recently?

   A wave of 400/404 from one source is usually a broken client or a
   scraper — not an app fault.

3. **If 5xx: read the app logs.**

       docker compose logs --since=30m quicknotes

   Known QuickNotes failure mode: the in-memory store or the /data
   volume becomes unreadable → writes surface as 500.

4. **Cross-check the other golden signals.** Errors + rising Traffic
   and/or maxed Saturation panel = overload/DoS pattern, not a bug.

## 3. Mitigations (stop the bleeding fast)

- **Option A — hostile or broken client flooding 4xx:** block the
  source at the firewall/host level or put a rate limiter in front of
  QuickNotes. Do NOT restart the app — it will not help.
- **Option B — 5xx after a bad release:** roll the app container back
  to the last known-good image (pin the previous tag in compose.yaml),
  then `docker compose up -d quicknotes`. Notes are safe: they live in
  the named volume `quicknotes-lab6-data`, not in the container.
- **Option C — container crash-looping:** `docker compose restart
  quicknotes`; if it is not healthy within 2 minutes, escalate.

## 4. Post-incident

Within 24 hours write a blameless postmortem using the Lecture 1
template — sections: Summary, Impact, Timeline, Root cause, Action
items — and link it from the incident ticket. If the investigation
revealed a monitoring gap (e.g., no 5xx-only view), add that signal to
the Golden Signals dashboard as an action item.
