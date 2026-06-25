# Lab 8 Bonus — Checkly + ngrok setup

## 1. Expose QuickNotes publicly

QuickNotes must be running (`docker compose up -d`).

In a **new PowerShell terminal** (keep it open):

```powershell
ngrok http 8080
```

Copy the **Forwarding** HTTPS URL, e.g. `https://abc123.ngrok-free.app`

Test it:

```powershell
Invoke-RestMethod https://YOUR-NGROK-URL/health
```

## 2. Create Checkly API check (free account)

1. Sign up at https://www.checklyhq.com/
2. **Checks → Add check → API check**
3. Settings:
   - **Name:** `QuickNotes health (Lab 8)`
   - **URL:** `https://YOUR-NGROK-URL/health`
   - **Method:** GET
   - **Frequency:** 1 minute
   - **Locations:** pick **2 regions** (e.g. `Frankfurt (eu-central-1)` + `Singapore (ap-southeast-1)`)
   - **Assertion:** status code equals `200`
   - **Assertion:** response time less than `2000` ms
4. Save and enable the check.

## 3. Let it run >= 30 minutes

Leave ngrok + Checkly running. Optionally generate light traffic:

```bash
bash monitoring/scripts/generate-traffic.sh
```

## 4. Collect numbers for `submissions/lab8.md`

**Prometheus (internal):**

```bash
bash monitoring/scripts/bonus-prometheus-snapshot.sh
```

**Checkly (external):** open the check → **Check results** / **Metrics** → note p50/p95 latency and failures per region over the same 30-minute window.

## 5. Stop ngrok when done

`Ctrl+C` in the ngrok terminal.
