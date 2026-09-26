#!/usr/bin/env python3
"""Expose only QuickNotes' health endpoint to an external probe."""

import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.request import urlopen


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/health":
            self.send_error(404)
            return
        try:
            with urlopen("http://127.0.0.1:8080/health", timeout=3) as response:
                body = response.read()
                status = response.status
        except (HTTPError, URLError, TimeoutError):
            self.send_error(502)
            return
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        self.send_error(405)


if __name__ == "__main__":
    port = int(os.environ.get("LAB8_HEALTH_PROXY_PORT", "18181"))
    ThreadingHTTPServer(("127.0.0.1", port), HealthHandler).serve_forever()
