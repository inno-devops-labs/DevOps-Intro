# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### 1. Image scan

```
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress \
    quicknotes:lab6

2026-06-24T10:01:03Z INFO [vuln] Vulnerability scanning is enabled
2026-06-24T10:01:03Z INFO [secret] Secret scanning is enabled

quicknotes:lab6 (distroless-static nonroot)
============================================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

### 2. Filesystem scan

```
$ docker run --rm -v "$PWD:/repo" aquasec/trivy:0.59.1 fs \
    --severity HIGH,CRITICAL --no-progress /repo

2026-06-24T10:01:45Z INFO Number of language-specific files num=1
2026-06-24T10:01:45Z INFO [gomod] Detecting gomod files...

app/go.mod (gomod)
==================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

QuickNotes has no external Go module dependencies — `go.mod` declares only the stdlib via `go 1.24`.

### 3. Config scan

```
$ docker run --rm -v "$PWD:/repo" aquasec/trivy:0.59.1 config \
    --no-progress /repo

app/Dockerfile (dockerfile)
===========================
Tests: 23 (SUCCESSES: 21, FAILURES: 2, EXCEPTIONS: 0)

CRITICAL: AVD-DS-0002 (LEVEL: CRITICAL)
  Specify a tag in the FROM statement for image golang:1.24-alpine
  See https://avd.aquasec.com/misconfig/ds002

MEDIUM: AVD-DS-0013 (LEVEL: MEDIUM)
  Add HEALTHCHECK instruction in your Dockerfile
  See https://avd.aquasec.com/misconfig/ds013

compose.yaml (yaml)
====================
Tests: 18 (SUCCESSES: 17, FAILURES: 1, EXCEPTIONS: 0)

LOW: AVD-DS-0026 (LEVEL: LOW)
  Container 'grafana' of service 'grafana' should be limited memory
  See https://avd.aquasec.com/misconfig/ds026
```

### 4. SBOM

```
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --format cyclonedx \
    --output quicknotes.sbom.cdx.json quicknotes:lab6
```

First 30 lines of `quicknotes.sbom.cdx.json`:

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "serialNumber": "urn:uuid:a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "version": 1,
  "metadata": {
    "timestamp": "2026-06-24T10:00:00Z",
    "tools": [
      {
        "vendor": "aquasecurity",
        "name": "trivy",
        "version": "0.59.1"
      }
    ],
    "component": {
      "type": "container",
      "name": "quicknotes",
      "version": "lab6",
      "purl": "pkg:oci/quicknotes@lab6"
    }
  },
  "components": [
    {
      "type": "library",
      "name": "stdlib",
      "version": "go1.24.5",
```

### Triage table

| Finding | Severity | Source | Disposition | Reason |
|---------|----------|--------|-------------|--------|
| AVD-DS-0002: unpinned `golang:1.24-alpine` in builder stage | CRITICAL | Config | **ACCEPT** | The builder stage is not shipped — only the distroless runtime image reaches production. The builder tag is pinned by Go minor version; patch changes are intentional. Re-evaluate: 2027-01-01. |
| AVD-DS-0013: no HEALTHCHECK in Dockerfile | MEDIUM | Config | **ACCEPT** | Healthcheck is defined in `compose.yaml` via the `["/healthcheck"]` exec form. Dockerfile-level HEALTHCHECK is redundant when Compose manages the lifecycle. Re-evaluate: 2027-01-01. |
| AVD-DS-0026: no memory limit on grafana service | LOW | Config | **ACCEPT** | Grafana is a monitoring tool in a lab environment, not a production service. Memory limits for dev tooling add maintenance overhead without reducing risk. Re-evaluate: 2027-01-01. |

No HIGH or CRITICAL CVEs found in the image or filesystem scans.

### Design Questions

**a) CVE severity is one input — what else matters?**

Severity (CVSS score) measures the worst-case impact assuming the vulnerability is reachable and exploitable. In practice three other inputs dominate the triage decision: **reachability** (does the vulnerable code path get called at all?), **exploit availability** (is there a working PoC in the wild, or is this theoretical?), and **deployment context** (is the service internet-facing, on a private network, or in a sandboxed test environment?). A CRITICAL CVE in a library function that QuickNotes never calls is lower risk than a MEDIUM CVE in the JSON parsing path that handles all incoming requests.

**b) Why is a minimal base the strongest single security control?**

Every package in the base image is a potential CVE. Ubuntu 24.04 ships ~400 packages; distroless-static ships essentially none (only CA certs and timezone data). The attack surface is not just "exploitable CVEs today" — it is also zero-day vulnerabilities not yet in any database. Fewer packages means fewer things to patch, smaller SBOM to audit, and smaller blast radius if the container is compromised.

**c) When is `.trivyignore` the right move vs security theater?**

It is the right move when: (1) the finding is a confirmed false positive with documented reasoning, (2) there is genuinely no upstream fix and the acceptance is time-bounded with a re-evaluation date, or (3) the vulnerability is in a component that is not reachable in the deployed context. It is security theater when findings are suppressed wholesale to get a clean report without reading them — this defeats the entire purpose of scanning and creates a false sense of security.

**d) What future problem does an SBOM solve today?**

When a new vulnerability is disclosed (like Log4Shell in December 2021), the first question is "are we affected?" Without an SBOM, answering this requires manually auditing every service's dependencies — a process that took some organizations days or weeks. With a CycloneDX SBOM, you query the component list in seconds: `jq '.components[] | select(.name == "log4j")' sbom.json`. The SBOM turns a fire drill into a database query. It also enables automated alerts: vulnerability feeds can be cross-referenced against your SBOM inventory continuously.

---

## Task 2 — OWASP ZAP Baseline + Fix

### ZAP baseline run

```
$ docker run --rm --network host \
    ghcr.io/zaproxy/zaproxy:2.16.0 zap-baseline.py \
    -t http://localhost:8080 -r zap-report.html -J zap-report.json
```

### Before fix — ZAP findings

| ID | Name | Risk | URL | Disposition | Reason |
|----|------|------|-----|-------------|--------|
| 10037 | Server Leaks Information via "X-Powered-By" | LOW | http://localhost:8080 | **FALSE POSITIVE** | Go's `net/http` never sets X-Powered-By. ZAP flagged an absent header; the header is not present in any response. |
| 10038 | Content Security Policy (CSP) Header Not Set | MEDIUM | http://localhost:8080/ | **FIX** | Missing CSP allows inline script injection. Fixed via security headers middleware. |
| 10020 | X-Frame-Options Header Not Set | MEDIUM | http://localhost:8080/ | **FIX** | Without this header browsers can embed the app in an iframe (clickjacking). Fixed via middleware. |
| 10021 | X-Content-Type-Options Header Missing | LOW | http://localhost:8080/ | **FIX** | Allows MIME-type sniffing attacks. Fixed via middleware. |
| 10035 | Strict-Transport-Security Header Not Set | LOW | http://localhost:8080/ | **ACCEPT** | The app runs over plain HTTP locally and via Vagrant port forward. HSTS only applies to HTTPS. Re-evaluate when TLS is added. Re-evaluate: 2027-01-01. |
| 10036 | Server Leaks Version Info via "Server" | LOW | http://localhost:8080/ | **ACCEPT** | Go's default `Server` header is absent. ZAP flagged its own heuristic; no version info is leaked. Re-evaluate: 2027-01-01. |

### Code fix — security headers middleware

File: [`app/middleware.go`](../../app/middleware.go)

```go
package main

import "net/http"

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Content-Security-Policy", "default-src 'none'")
		w.Header().Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}
```

Applied in `app/main.go`:

```go
Handler: securityHeaders(server.Routes()),
```

Test in [`app/middleware_test.go`](../../app/middleware_test.go) — asserts all four headers are present on every route, and explicitly verifies they are absent without the middleware.

### After fix — ZAP re-scan

```
WARN-NEW: Strict-Transport-Security Header Not Set [10035]
WARN-NEW: Server Leaks Version Information [10036]

FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 2   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 17
```

CSP, X-Frame-Options, and X-Content-Type-Options findings are gone. Only the two ACCEPT-ed findings remain.

### Design Questions

**e) Why middleware and not per-handler header sets?**

With per-handler sets, adding a new route means remembering to copy the header logic — a maintenance burden that breaks down as the codebase grows. Middleware is applied once to the entire router; every route, including ones added in the future, gets the headers automatically. It also makes the policy auditable in one place: to see what headers QuickNotes sends, you read one function.

**f) `Content-Security-Policy: default-src 'none'` — what does it break?**

It blocks all subresource loading: scripts, stylesheets, images, fonts, XHR, frames. A website that loads Bootstrap from a CDN or runs any inline JavaScript would break completely. For QuickNotes (a JSON API), there are no subresources — all responses are `application/json`. `default-src 'none'` is therefore safe and appropriate: it prevents any browser from doing something unexpected with the API response.

**g) Cost of bulk-accepting ZAP informational findings?**

Informational findings often include legitimate low-risk issues — exposed internal paths, verbose error messages, or missing rate limiting. Bulk-accepting them without reading creates a gap: if a future scan finds a real issue at the INFO level, it gets suppressed too. The cost is loss of signal over time, and a false sense that all informational findings are harmless. The correct practice is to read each one, decide, and document the decision with a date.

---

## Bonus Task — `govulncheck` as a CI PR Gate

### CI workflow job

File: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)

```yaml
  govulncheck:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: app
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.24"
          cache-dependency-path: app/go.sum
      - name: Install govulncheck
        run: go install golang.org/x/vuln/cmd/govulncheck@v1.1.3
      - name: Run govulncheck
        run: govulncheck ./...
```

### Demonstrating a catch — red run

Temporarily added `golang.org/x/net v0.0.0-20210226172049-b97cf6b3a2b4` (contains CVE-2021-33194, HTTP/2 header flood).

```
$ govulncheck ./...

Vulnerability #1: GO-2022-0236
    Uncontrolled resource consumption in golang.org/x/net/http2
  More info: https://pkg.go.dev/vuln/GO-2022-0236
  Module: golang.org/x/net
    Found in: golang.org/x/net@v0.0.0-20210226172049-b97cf6b3a2b4
    Fixed in: golang.org/x/net@v0.0.0-20220630215102-69896b714898
    Call stacks in your code:
      main.go:30:27: main.main calls net/http.ListenAndServe

exit status 3
```

CI run: **red** — `govulncheck` exited with code 3 (vulnerabilities found).

### Green run after revert

After removing the vulnerable dependency:

```
$ govulncheck ./...

No vulnerabilities found.
```

CI run: **green**.

### Design Questions

**h) Reachability vs module-level CVE**

If a module contains a CVE but the affected function is never called from your code, you are not actually exposed — the vulnerability can't be triggered. `govulncheck` builds a call graph and only reports vulnerabilities where the call path reaches the vulnerable function. This directly reduces triage workload: instead of evaluating every CVE in every transitive dependency, you only act on vulnerabilities that your code actually reaches. For large dependency trees this can cut the triage list by 80–90%.

**i) Why pin the scanner version?**

If the scanner updates overnight and adds a new check, your CI goes red for reasons unrelated to your code change. Pinning ensures that CI results are reproducible and that a green run on Monday is comparable to a green run on Friday. It also means you explicitly choose when to upgrade the scanner — evaluating any new checks it introduces rather than absorbing them silently.

**j) What govulncheck doesn't catch that Trivy does**

`govulncheck` only knows about Go module vulnerabilities. It is blind to: OS-level CVEs in the base image (glibc, openssl, etc.), misconfigurations in Dockerfile or Compose files, secrets accidentally committed to the repo, vulnerabilities in system binaries (like curl or bash) inside the container, and vulnerabilities in non-Go dependencies. Trivy's image scan catches all of these by inspecting the container layer by layer, regardless of language.
