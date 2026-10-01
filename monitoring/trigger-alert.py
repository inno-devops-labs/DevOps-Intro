import json
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

output = Path("submissions/lab8-logs")
output.mkdir(parents=True, exist_ok=True)

def timestamp():
    return datetime.now(timezone.utc).isoformat()

def send(method, path, body=None):
    req = Request(
        "http://localhost:8080" + path,
        data=body,
        method=method,
        headers={"Content-Type": "application/json"} if body else {},
    )
    try:
        with urlopen(req, timeout=5) as response:
            response.read()
            return response.status
    except HTTPError as error:
        status = error.code
        error.read()
        error.close()
        return status

seen = set()

def record_state():
    with urlopen("http://localhost:9090/api/v1/rules", timeout=5) as response:
        data = json.load(response)

    rule = next(
        rule
        for group in data["data"]["groups"]
        for rule in group["rules"]
        if rule["name"] == "QuickNotesHighErrorRate"
    )
    if rule["health"] != "ok":
        raise RuntimeError(f"Rule evaluation failed: {rule.get('lastError')}")

    state = rule["state"]
    print(f"{timestamp()} state={state}", flush=True)

    if state not in seen:
        evidence = {"observed_at": timestamp(), "response": data}
        path = output / f"alert-{state}.json"
        path.write_text(json.dumps(evidence, indent=2) + "\n")
        seen.add(state)
        print(f"Saved: {path}", flush=True)

        if state == "firing":
            print(
                "FIRING: refresh the Prometheus Alerts page "
                "and capture a screenshot now.",
                flush=True,
            )

print("Started:", timestamp(), flush=True)
record_state()
pairs = 0

try:
    for i in range(600):
        statuses = (
            send("GET", "/notes"),
            send("POST", "/notes", b'{"title":'),
        )
        if statuses != (200, 400):
            raise RuntimeError(f"Unexpected HTTP responses: {statuses}")
        pairs += 1

        if i % 15 == 0:
            record_state()
        time.sleep(1)
except KeyboardInterrupt:
    print("\nTraffic stopped with Ctrl+C.", flush=True)

record_state()
print("Finished:", timestamp(), flush=True)
print("Request pairs:", pairs, flush=True)
print("Observed states:", ", ".join(sorted(seen)), flush=True)

if "firing" not in seen:
    raise SystemExit("Firing was not observed; inspect the output.")
