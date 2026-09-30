"""Sample Prometheus latency/error proxies for the same bonus window."""
from __future__ import annotations

import json
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PROM = "http://127.0.0.1:9090"
OUT = Path(__file__).resolve().parents[1] / "submissions" / "lab8-artifacts" / "prom-bonus-window.jsonl"
SUMMARY = Path(__file__).resolve().parents[1] / "submissions" / "lab8-artifacts" / "prom-bonus-summary.json"
DURATION_MIN = 30
INTERVAL_SEC = 60


def q(expr: str):
    url = PROM + "/api/v1/query?" + urllib.parse.urlencode({"query": expr})
    with urllib.request.urlopen(url, timeout=10) as r:
        d = json.loads(r.read().decode())
    res = d.get("data", {}).get("result", [])
    if not res:
        return None
    return float(res[0]["value"][1])


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("", encoding="utf-8")
    end = time.time() + DURATION_MIN * 60
    rows = []
    i = 0
    while time.time() < end:
        i += 1
        row = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "round": i,
            "request_rate": q("rate(quicknotes_http_requests_total[1m])"),
            "error_ratio_5m": q(
                'sum(rate(quicknotes_http_responses_by_code_total{code=~"4..|5.."}[5m]))'
                "/clamp_min(sum(rate(quicknotes_http_requests_total[5m])),1e-9)"
            ),
            "notes_total": q("quicknotes_notes_total"),
        }
        rows.append(row)
        with OUT.open("a", encoding="utf-8") as f:
            f.write(json.dumps(row) + "\n")
        print(row)
        time.sleep(INTERVAL_SEC)

    rates = [r["request_rate"] for r in rows if r["request_rate"] is not None]
    errs = [r["error_ratio_5m"] for r in rows if r["error_ratio_5m"] is not None]
    summary = {
        "note": "QuickNotes has no latency histogram; request_rate used as internal traffic proxy. Error ratio from status counters.",
        "rounds": i,
        "request_rate_avg": sum(rates) / len(rates) if rates else None,
        "error_ratio_avg": sum(errs) / len(errs) if errs else None,
        "error_ratio_max": max(errs) if errs else None,
        "finished_at": datetime.now(timezone.utc).isoformat(),
    }
    SUMMARY.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print("SUMMARY", summary)


if __name__ == "__main__":
    main()
