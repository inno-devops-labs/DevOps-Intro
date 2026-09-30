"""
Lab 8 bonus — multi-region synthetic probe via check-host.net (no API key).
Hits QuickNotes /health every ~60s from Germany + Singapore for DURATION_MIN minutes.
"""
from __future__ import annotations

import json
import statistics
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PUBLIC_URL = "https://turtle-associated-roller-suddenly.trycloudflare.com/health"
# Prefer DE + SG nodes (Frankfurt-area + Singapore). Fallbacks applied if missing.
PREFERRED = ("de1.node.check-host.net", "de2.node.check-host.net", "sg1.node.check-host.net", "sg2.node.check-host.net")
DURATION_MIN = 30
INTERVAL_SEC = 60
OUT = Path(__file__).resolve().parents[1] / "submissions" / "lab8-artifacts" / "synthetic-checkhost.jsonl"
SUMMARY = Path(__file__).resolve().parents[1] / "submissions" / "lab8-artifacts" / "synthetic-summary.json"


def http_json(url: str, timeout: float = 30.0) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "Mozilla/5.0 Lab8Synthetic/1.0 (DevOps-Intro)",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())


def pick_nodes() -> list[str]:
    # Prefer explicit DE + SG; API may ignore unknown nodes and pick others —
    # we still request 3+ nodes so we get ≥2 countries.
    return ["de2.node.check-host.net", "sg1.node.check-host.net"]


def start_check(nodes: list[str]) -> str:
    # First try pinned nodes; on failure fall back to max_nodes.
    q = urllib.parse.urlencode({"host": PUBLIC_URL})
    for n in nodes:
        q += "&node=" + urllib.parse.quote(n)
    try:
        data = http_json(f"https://check-host.net/check-http?{q}")
    except Exception:
        q = urllib.parse.urlencode({"host": PUBLIC_URL, "max_nodes": 3})
        data = http_json(f"https://check-host.net/check-http?{q}")
    rid = data.get("request_id")
    if not rid:
        raise RuntimeError(f"no request_id: {data}")
    # stash nodes used for logging
    start_check.last_nodes = list((data.get("nodes") or {}).keys())
    return rid


def fetch_result(rid: str) -> dict:
    return http_json(f"https://check-host.net/check-result/{rid}")


def parse_node_result(payload) -> dict | None:
    # Typical: [[1, 0.12, "OK", "200", "https://..."]]
    if not payload or not isinstance(payload, list) or not payload:
        return None
    row = payload[0]
    if not isinstance(row, list) or len(row) < 4:
        return None
    ok_flag, seconds, _msg, status = row[0], row[1], row[2], str(row[3])
    return {
        "ok": bool(ok_flag == 1 and status == "200"),
        "latency_s": float(seconds) if seconds is not None else None,
        "status": status,
    }


def main() -> None:
    nodes = pick_nodes()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("", encoding="utf-8")
    print(f"public={PUBLIC_URL}")
    print(f"nodes={nodes}")
    print(f"duration_min={DURATION_MIN} interval={INTERVAL_SEC}s")
    end = time.time() + DURATION_MIN * 60
    samples = []
    round_i = 0
    while time.time() < end:
        round_i += 1
        ts = datetime.now(timezone.utc).isoformat()
        rec = {"ts": ts, "round": round_i, "nodes": {}}
        try:
            rid = start_check(nodes)
            # wait for nodes to report
            time.sleep(8)
            result = fetch_result(rid)
            for node, payload in (result or {}).items():
                parsed = parse_node_result(payload)
                if parsed:
                    rec["nodes"][node] = parsed
            rec["request_id"] = rid
        except Exception as e:
            rec["error"] = str(e)
        samples.append(rec)
        with OUT.open("a", encoding="utf-8") as f:
            f.write(json.dumps(rec) + "\n")
        print(json.dumps(rec))
        # sleep remaining of the minute (minus work time)
        time.sleep(max(1, INTERVAL_SEC - 8))

    # summary
    lats = []
    errors = 0
    total = 0
    by_node = {}
    for s in samples:
        for node, p in s.get("nodes", {}).items():
            total += 1
            by_node.setdefault(node, {"ok": 0, "err": 0, "lats": []})
            if p.get("ok"):
                by_node[node]["ok"] += 1
            else:
                by_node[node]["err"] += 1
                errors += 1
            if p.get("latency_s") is not None:
                lats.append(p["latency_s"])
                by_node[node]["lats"].append(p["latency_s"])

    def pct(xs, p):
        if not xs:
            return None
        xs = sorted(xs)
        i = min(len(xs) - 1, max(0, int(round((p / 100) * (len(xs) - 1)))))
        return xs[i]

    summary = {
        "public_url": PUBLIC_URL,
        "tool": "check-host.net (multi-region HTTP checks)",
        "regions_nodes": nodes,
        "rounds": round_i,
        "samples_total": total,
        "errors": errors,
        "error_rate": (errors / total) if total else None,
        "latency_s": {
            "p50": pct(lats, 50),
            "p95": pct(lats, 95),
            "avg": statistics.mean(lats) if lats else None,
            "max": max(lats) if lats else None,
        },
        "by_node": {
            n: {
                "ok": v["ok"],
                "err": v["err"],
                "p50_s": pct(v["lats"], 50),
                "p95_s": pct(v["lats"], 95),
            }
            for n, v in by_node.items()
        },
        "alert_rule": "status!=200 OR latency>2s counted as error/degraded",
        "finished_at": datetime.now(timezone.utc).isoformat(),
    }
    SUMMARY.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print("SUMMARY", json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
