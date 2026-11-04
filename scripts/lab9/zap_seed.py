"""Visit read-only API routes because JSON responses contain no spider links."""


def zap_started(zap, target):
    for path in ("/health", "/notes", "/notes/1", "/metrics"):
        zap.urlopen(target.rstrip("/") + path)
