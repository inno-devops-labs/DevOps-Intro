import time, urllib.request, urllib.error
base = "http://127.0.0.1:8080"
end = time.time() + 330
n = 0
while time.time() < end:
    try:
        urllib.request.urlopen(base + "/health", timeout=2).read()
    except Exception:
        pass
    try:
        req = urllib.request.Request(
            base + "/notes",
            data=b"not-json",
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req, timeout=2).read()
    except Exception:
        pass
    n += 1
    time.sleep(1)
print("loops", n)
