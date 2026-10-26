"""Seed read-only API routes that an HTML spider cannot discover.

The baseline remains passive: no writes, active scan, or rule suppression.
Only run against the isolated QuickNotes instance on the lab network.
"""


def zap_started(zap, target):
    for path in (
        "/health",
        "/metrics",
        "/notes",
        "/notes/1",
        "/notes/999999",
        "/notes/not-an-int",
        "/does-not-exist",
    ):
        url = target.rstrip("/") + path
        print("Passive baseline seed: " + url)
        zap.core.access_url(url, followredirects=False)
