# Runbook — HighErrorRate (QuickNotes)

**Alert:** `HighErrorRate` · **Severity:** page · **Signal:** Errors (5xx ratio)

## What it means

QuickNotes is returning server-side (5xx) errors for more than **5% of requests**,
sustained over 5 minutes — users are seeing failures right now.

## Triage (in order)

1. **Confirm it's real.** Open the *QuickNotes — Four Golden Signals* dashboard and
   check the **Errors** panel against **Traffic**. A high ratio at near-zero traffic
   is usually noise, not an incident.
2. **Check the target is up.** In Prometheus (`/targets`) confirm the `quicknotes`
   job is `UP`. If it's down, this is an availability problem, not just errors.
3. **Read the logs.** `docker compose logs --tail=100 quicknotes` — look for panics,
   `failed to persist note`, or permission errors on `/data`.
4. **Check the dependency the errors point to.** 5xx from `POST /notes` almost always
   means the **persistence layer** failed (disk full, `/data` not writable, volume
   detached). Verify with `docker compose exec`-free checks: `docker inspect` the
   volume and `df -h` on the host.

## Mitigation (pick based on triage)

- **Disk full / volume issue:** free space or restore the `quicknotes-data` volume,
  then `docker compose restart quicknotes`.
- **Bad recent deploy:** roll back to the previous image tag and `docker compose up -d`.
- **Transient overload / stuck process:** `docker compose restart quicknotes` to get
  back to a known-good state while you investigate.

## Post-incident

- Capture the firing window (screenshot the Errors panel; note start/end times).
- File a short blameless postmortem: trigger, impact, time-to-detect, time-to-mitigate.
- If the alert was noisy or missed the issue, tune the threshold/`for:` duration or
  add a request-duration histogram + resource metrics to QuickNotes for better signals.
