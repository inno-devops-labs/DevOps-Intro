# Lab 8 bonus — synthetic monitoring notes

Public QuickNotes URL (Cloudflare quick tunnel):
https://turtle-associated-roller-suddenly.trycloudflare.com

Primary evidence for the bonus uses **check-host.net** multi-node HTTP checks every ~1 minute from **Germany (de2)** and **Singapore (sg1)** for ≥30 minutes (Checkly-equivalent external probes; no SaaS account required).

Optional Checkly-as-code (same URL / 2 regions / 1 min) lives in `monitoring/checkly/` — deploy with:
```bash
cd monitoring/checkly
export CHECKLY_API_KEY=...
export CHECKLY_ACCOUNT_ID=...
export QUICKNOTES_PUBLIC_URL=https://turtle-associated-roller-suddenly.trycloudflare.com
npx checkly deploy
```

Collectors:
- `scripts/lab8-synthetic-checkhost.py` → `submissions/lab8-artifacts/synthetic-*.json*`
- `scripts/lab8-prom-bonus-sample.py` → `submissions/lab8-artifacts/prom-bonus-*.json*`
