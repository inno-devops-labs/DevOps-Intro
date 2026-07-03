# Hook for zap-baseline.py. QuickNotes is a JSON API with no HTML pages, so
# the spider finds nothing from the root URL. This seeds the real endpoints
# into ZAP's site tree so the passive rules examine actual API responses.
# The scan stays passive: access_url only performs plain GET requests.


def zap_started(zap, target):
    for path in ("/health", "/notes", "/notes/1", "/metrics"):
        zap.core.access_url(target.rstrip("/") + path)
