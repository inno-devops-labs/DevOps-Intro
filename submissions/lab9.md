
# Lab 9 Submission

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### 1.1 Image Scan

```bash
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL quicknotes:lab6
```

**Summary:**
- `quicknotes:lab6` (Debian base): **0** HIGH/CRITICAL
- `app/quicknotes` (Go binary): **10** HIGH (0 CRITICAL)
- `app/healthcheck` (Go binary): **10** HIGH (0 CRITICAL)

**Vulnerabilities found in Go stdlib:**
- `CVE-2026-25679` — net/url
- `CVE-2026-27145` — crypto/x509
- `CVE-2026-32280` — crypto/x509
- `CVE-2026-32281` — crypto/x509
- `CVE-2026-32283` — crypto/tls
- `CVE-2026-33811` — net
- `CVE-2026-33814` — net/http
- `CVE-2026-39820` — net/mail
- `CVE-2026-39836` — general
- `CVE-2026-42499` — net/mail

### 1.2 Filesystem Scan

```bash
$ docker run --rm -v ${PWD}:/src aquasec/trivy:0.59.1 fs --severity HIGH,CRITICAL /src
```

**Result:**
```
.vagrant/machines/default/virtualbox/private_key (secrets)
Total: 1 (HIGH: 1, CRITICAL: 0)
HIGH: AsymmetricPrivateKey (private-key)
```
One HIGH finding was detected in the Vagrant private key file. This is expected and does not affect the application.

### 1.3 Config Scan

```bash
$ docker run --rm -v ${PWD}:/src aquasec/trivy:0.49.0 config /src/app/Dockerfile
```

**Result:**
```
Dockerfile (dockerfile)
Tests: 27 (SUCCESSES: 27, FAILURES: 0)
```

All Dockerfile best practices are satisfied:
- `USER nonroot:nonroot` present
- `HEALTHCHECK` configured
- `EXPOSE 8080`
- `ENTRYPOINT` in exec form
- Multi-stage build
- Distroless base image

### 1.4 SBOM (CycloneDX)

```bash
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --format cyclonedx quicknotes:lab6
```

**SBOM contains:**
- OS: Debian 13.5
- Packages: base-files, media-types, netbase, tzdata, tzdata-legacy
- Go stdlib v1.24.13
- QuickNotes application binary
- Healthcheck binary

### 1.5 Triage Table

| CVE | Component | Severity | Disposition | Reason |
|-----|-----------|----------|-------------|--------|
| CVE-2026-25679 | net/url | HIGH | ACCEPT | QuickNotes does not parse user-supplied URLs |
| CVE-2026-27145 | crypto/x509 | HIGH | ACCEPT | No TLS/HTTPS in QuickNotes |
| CVE-2026-32280 | crypto/x509 | HIGH | ACCEPT | No TLS/HTTPS in QuickNotes |
| CVE-2026-32281 | crypto/x509 | HIGH | ACCEPT | No TLS/HTTPS in QuickNotes |
| CVE-2026-32283 | crypto/tls | HIGH | ACCEPT | No TLS/HTTPS in QuickNotes |
| CVE-2026-33811 | net | HIGH | WATCH | DNS parsing; re-evaluate with Go update |
| CVE-2026-33814 | net/http | HIGH | WATCH | HTTP/2 DoS; re-evaluate after Go update |
| CVE-2026-39820 | net/mail | HIGH | ACCEPT | QuickNotes does not use net/mail |
| CVE-2026-39836 | stdlib | HIGH | WATCH | General stdlib; update Go version |
| CVE-2026-42499 | net/mail | HIGH | ACCEPT | QuickNotes does not use net/mail |

### 1.6 Design Questions

**a) CVE severity is one input, not the answer. What else matters?**

Reachability (is the vulnerable function actually called?), exploit availability, deployment context (is the service exposed to the internet?), and whether the vulnerability can be triggered by unauthenticated users.

**b) Why is distroless the strongest single security control?**

Distroless images contain only the binary and its dependencies — no shell, no package manager, no OS tools. This drastically reduces the attack surface and eliminates most OS-level CVEs.

**c) When is `.trivyignore` the right move, and when is it security theater?**

`.trivyignore` is legitimate when a finding is a false positive or when the fix is not available (e.g., no upstream patch). It becomes security theater when used to silence warnings without understanding the risk.

**d) What concrete future problem does the SBOM solve?**

The SBOM answers "am I affected by CVE-X?" when a new vulnerability like Log4Shell is discovered. Instead of manually checking every dependency, you can search the SBOM for the affected component and version.

---

## Task 2 — OWASP ZAP Baseline + Fix

### 2.1 ZAP Baseline Scan (Before Fix)

```bash
$ docker run --rm -v ${PWD}/scans:/zap/wrk --network quicknotes-net --entrypoint /zap/zap-baseline.py ghcr.io/zaproxy/zaproxy:2.16.0 -t http://quicknotes:8080/health -r zap-report.html -J zap-report.json
```

**Findings before fix:**

| Plugin ID | Name | Risk | URL |
|-----------|------|------|-----|
| 10021 | X-Content-Type-Options Header Missing | Low | /health |
| 90004 | Insufficient Site Isolation Against Spectre | Low | /health |
| 10116 | ZAP is Out of Date | Low | /health |
| 10049 | Storable and Cacheable Content | Informational | multiple URLs |

### 2.2 Code Fix — Security Headers Middleware

**File:** `app/middleware.go`

```go
package main

import "net/http"

func securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        h := w.Header()
        h.Set("X-Content-Type-Options", "nosniff")
        h.Set("X-Frame-Options", "DENY")
        h.Set("Content-Security-Policy", "default-src 'none'")
        h.Set("Referrer-Policy", "no-referrer")
        h.Set("X-XSS-Protection", "0")
        next.ServeHTTP(w, r)
    })
}
```

**Integration in `main.go`:**

```go
server := NewServer(store)
handler := securityHeaders(server.Routes())
srv := &http.Server{
    Addr:              addr,
    Handler:           handler,
    ReadHeaderTimeout: 5 * time.Second,
}
```

### 2.3 Verification — Headers Present

```bash
$ curl -v http://localhost:8080/health
```

**Response headers:**
```
< Content-Security-Policy: default-src 'none'
< Referrer-Policy: no-referrer
< X-Content-Type-Options: nosniff
< X-Frame-Options: DENY
< X-Xss-Protection: 0
```

### 2.4 ZAP Baseline Scan (After Fix)

```bash
$ docker run --rm -v ${PWD}/scans:/zap/wrk --network quicknotes-net --entrypoint /zap/zap-baseline.py ghcr.io/zaproxy/zaproxy:2.16.0 -t http://quicknotes:8080/health -r zap-report-after.html -J zap-report-after.json
```

**Findings after fix:**

| Plugin ID | Name | Risk | Status |
|-----------|------|------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | **GONE**  |
| 90004 | Insufficient Site Isolation Against Spectre | Low | Still present |
| 10116 | ZAP is Out of Date | Low | Still present |


Plugin 10021 (X-Content-Type-Options) is no longer reported.

### 2.5 Design Questions

**e) Why a middleware and not per-handler header sets?**

Middleware applies to all routes automatically, ensuring consistency and preventing omissions. Per-handler headers would require duplicating code and could easily miss a route.

**f) Why is `default-src 'none'` OK for QuickNotes but not for a website?**

QuickNotes is an API, not a website. It serves no HTML, JavaScript, or CSS. `default-src 'none'` blocks everything — which is fine for an API. A website needs to allow its own scripts, styles, and images.

**g) False positives vs accepted findings — what's the cost of marking them all "accepted" without reading them?**

You might miss a real vulnerability hidden among false positives. This erodes trust in the security tool and creates blind spots. Every finding should be reviewed and understood.

---

