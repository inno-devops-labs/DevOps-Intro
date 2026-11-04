"""Capture real warm requests and three Render idle/wake observations."""

import argparse
import datetime as dt
import json
import math
from pathlib import Path
import statistics
import time
import urllib.error
import urllib.request
import uuid


def request(base, path, payload=None, timeout=180):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(
        base.rstrip("/") + path,
        data=data,
        headers={"Accept": "application/json", "Content-Type": "application/json"},
    )
    started = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            body = response.read().decode()
            status = response.status
    except urllib.error.HTTPError as error:
        body = error.read().decode()
        status = error.code
    return {"status": status, "seconds": time.perf_counter() - started, "body": body}


def healthy(result):
    try:
        return result["status"] == 200 and json.loads(result["body"])["status"] == "ok"
    except (ValueError, KeyError, TypeError):
        return False


def save(path, result):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["warm", "render"])
    parser.add_argument("url")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--runs", type=int, default=50)
    parser.add_argument("--idle-seconds", type=int, default=1260)
    args = parser.parse_args()
    if args.runs < 5 or (args.mode == "render" and args.idle_seconds < 1200):
        parser.error("Use at least 5 warm runs and 1200 idle seconds for Render.")
    result = {"url": args.url, "started_utc": dt.datetime.now(dt.timezone.utc).isoformat()}
    first = request(args.url, "/health")
    if not healthy(first):
        raise RuntimeError(f"Service is not ready: {first}")
    result["warm"] = [request(args.url, "/health") for _ in range(args.runs)]
    if not all(healthy(sample) for sample in result["warm"]):
        raise RuntimeError("A warm response was not QuickNotes JSON.")
    times = sorted(sample["seconds"] for sample in result["warm"])
    result["warm_p50_seconds"] = statistics.median(times)
    result["warm_p95_seconds"] = times[math.ceil(0.95 * len(times)) - 1]
    save(args.output, result)
    if args.mode == "warm":
        return
    result["cold"] = []
    for cycle in range(1, 4):
        title = "sleep-probe-" + uuid.uuid4().hex
        created = request(args.url, "/notes", {"title": title, "body": "disposable lab probe"})
        if created["status"] != 201:
            raise RuntimeError(f"Creating note failed: {created}")
        note = json.loads(created["body"])
        observation = {
            "cycle": cycle,
            "created_note": note,
            "idle_seconds": args.idle_seconds,
            "idle_started_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        }
        result["cold"].append(observation)
        save(args.output, result)
        print(f"Cycle {cycle}: no requests for {args.idle_seconds} seconds", flush=True)
        idle_started = time.perf_counter()
        time.sleep(args.idle_seconds)
        observation["idle_elapsed_seconds"] = time.perf_counter() - idle_started
        observation["wake_requested_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
        started = time.perf_counter()
        observation["first_response"] = request(args.url, "/health")
        current = observation["first_response"]
        attempts = [current]
        while not healthy(current) and time.perf_counter() - started < 240:
            time.sleep(2)
            current = request(args.url, "/health")
            attempts.append(current)
        observation["wake_attempts"] = attempts
        observation["ready_seconds"] = time.perf_counter() - started
        observation["ready"] = healthy(current)
        notes_response = request(args.url, "/notes")
        observation["notes_after_wake"] = notes_response
        if notes_response["status"] != 200:
            raise RuntimeError(f"Reading notes failed: {notes_response}")
        notes = json.loads(notes_response["body"])
        observation["note_survived"] = any(
            item["id"] == note["id"] and item["title"] == title for item in notes
        )
        save(args.output, result)
        print(json.dumps(observation), flush=True)


if __name__ == "__main__":
    main()
