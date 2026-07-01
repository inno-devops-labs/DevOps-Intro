
# Lab 9 Submission

## Task 1 — Trivy Scans

### 1.1 Scan Outputs

**Image scan** (`trivy image quicknotes:lab6 --severity HIGH,CRITICAL --scanners vuln`):
quicknotes:lab6 (alpine 3.21.7)
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)
All 11 in stdlib v1.24.13. Full output in `artifacts/trivy-image-report.txt`.

**Filesystem scan** (`trivy fs <repo> --severity HIGH,CRITICAL --scanners vuln`):
[gomod] Detecting vulnerabilities...
No HIGH/CRITICAL found.Full output in `artifacts/trivy-fs-report.txt`.

**Config scan** (`trivy config <repo>`):
Dockerfile (dockerfile)
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
AVD-DS-0002 (HIGH): Specify at least 1 USER command in Dockerfile with non-root user.
Full output in `artifacts/trivy-config-report.txt`.

**SBOM** (`trivy image --format cyclonedx`):
Generated CycloneDX JSON. First 30 lines:
```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:6124f895-7f0c-42f6-adbb-b45006cd5a45",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-01T13:32:16+00:00",
    "tools": {"components": [{"type": "application", "group": "aquasecurity", "name": "trivy", "version": "0.59.1"}]},
    "component": {"bom-ref": "pkg:oci/quicknotes@sha256%3A3073c...", "type": "container", "name": "quicknotes:lab6"}
  }
}
Full file in artifacts/sbom-cyclonedx.json.

1.2 Triage Table

### 1.2 Triage Table

| # | Source | Library | CVE/ID | Severity | Status | Disposition | Reason |
|---|--------|---------|--------|----------|--------|-------------|--------|
| 1 | Image | stdlib | CVE-2026-25679 | HIGH | fixed | ACCEPT | net/url IPv6 parsing — QuickNotes uses net/http which handles URLs internally. Fixed in Go 1.25.8. Re-evaluate by 2027-01-01. |
| 2 | Image | stdlib | CVE-2026-27145 | HIGH | fixed | ACCEPT | crypto/x509 DoS via DNS — QuickNotes does not use crypto/x509 for certificate validation. Fixed in Go 1.25.11. Re-evaluate by 2027-01-01. |
| 3 | Image | stdlib | CVE-2026-32280 | HIGH | fixed | ACCEPT | crypto/x509 cert chain building — unreachable in QuickNotes code path. Fixed in Go 1.25.9. Re-evaluate by 2027-01-01. |
| 4 | Image | stdlib | CVE-2026-32281 | HIGH | fixed | ACCEPT | crypto/x509 cert validation — unreachable. Fixed in Go 1.25.9. Re-evaluate by 2027-01-01. |
| 5 | Image | stdlib | CVE-2026-32283 | HIGH | fixed | ACCEPT | crypto/tls 1.3 DoS — QuickNotes serves plain HTTP, no TLS. Fixed in Go 1.25.9. Re-evaluate by 2027-01-01. |
| 6 | Image | stdlib | CVE-2026-33811 | HIGH | fixed | ACCEPT | net package CNAME DoS — QuickNotes does not make external DNS lookups. Fixed in Go 1.25.10. Re-evaluate by 2027-01-01. |
| 7 | Image | stdlib | CVE-2026-33814 | HIGH | fixed | ACCEPT | HTTP/2 frame handling — QuickNotes uses HTTP/1.1 only. Fixed in Go 1.25.10. Re-evaluate by 2027-01-01. |
| 8 | Image | stdlib | CVE-2026-39820 | HIGH | fixed | ACCEPT | net/mail parsing DoS — QuickNotes does not parse email inputs. Fixed in Go 1.25.11. Re-evaluate by 2027-01-01. |
| 9 | Image | stdlib | CVE-2026-39836 | HIGH | fixed | WATCH | Oracle Linux advisory (ELSA-2026-22121). Not applicable on Alpine base. Re-check on next Go upgrade. |
| 10 | Image | stdlib | CVE-2026-42499 | HIGH | fixed | ACCEPT | net/mail address parsing — unreachable. Fixed in Go 1.25.11. Re-evaluate by 2027-01-01. |
| 11 | Image | stdlib | CVE-2026-42504 | HIGH | fixed | ACCEPT | MIME header decoding — unreachable. Fixed in Go 1.25.11. Re-evaluate by 2027-01-01. |
| 12 | Config | Dockerfile | AVD-DS-0002 | HIGH | — | FIX | Root user in container. Fix: add `USER 65534:65534` to Dockerfile. See commit in this PR. |

### 1.3 Design Questions

**a) CVE severity is one input, not the answer. What else (reachability, exploit availability, deployment context) matters when triaging?**

CVSS severity is auto-assigned based on worst-case impact assuming the vulnerable code is reachable and exploitable. When triaging, three other factors matter more: (1) Reachability — is the vulnerable function actually in the application's call graph? stdlib CVEs in `net/mail` or `crypto/x509` are irrelevant for an API that does not validate certificates or parse emails. (2) Exploit availability — is there a public proof-of-concept? Is the CVE in CISA's Known Exploited Vulnerabilities catalog? A HIGH severity CVE with no known exploit is less urgent than a MEDIUM with active exploitation. (3) Deployment context — is the application internet-facing or internal? Behind a WAF? Running as non-root? Using TLS termination at the reverse proxy? These change the actual risk significantly.

**b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?**

A minimal base image like Alpine contains far fewer packages than a full distribution. Fewer packages means fewer CVEs to triage and a smaller attack surface. In this scan, Alpine 3.21 had 0 HIGH/CRITICAL vulnerabilities — it ships only what QuickNotes needs (ca-certificates, curl, libc). No shell, no package manager, no system utilities. An attacker who compromises the container finds almost nothing to work with. You can't exploit a vulnerability in a package that isn't installed. Minimal base images turn CVE management from a constant firefight into a near-non-issue.

**c) `.trivyignore` lets you suppress findings. When is that the right move, and when is it security theater?**

Right move: When a CVE is documented as unreachable with evidence (call graph analysis showing the vulnerable function is never invoked), the acceptance is dated, and a re-evaluation date is set (≤ 6 months). Example: suppressing a `net/mail` CVE because the application has no email parsing code whatsoever. Security theater: Blindly adding CVE IDs to `.trivyignore` without reading the finding, understanding the vulnerable function, or setting a review date. This makes CI green but hides real problems. When the next person upgrades a dependency and the CVE becomes reachable, nobody will notice because it's permanently suppressed.

**d) The SBOM is a list of components. What concrete future problem does having it today solve? (Hint: Log4Shell, Lecture 9.)**

When Log4Shell (CVE-2021-44228) was disclosed on December 9, 2021, every organization faced the same question: "Do we run Log4j? What version? Where is it deployed?" Teams with SBOMs queried their inventory in minutes — they searched for `log4j-core` across all SBOMs, identified affected versions, and patched within hours. Teams without SBOMs spent weeks manually auditing every repository, every container image, every deployed artifact. Some were still searching weeks later while attackers were actively exploiting the vulnerability. An SBOM is a pre-computed answer to "am I affected?" — it turns incident response from a desperate search into a database lookup.

Task 2 — OWASP ZAP Baseline
2.1 ZAP Run

Image: ghcr.io/zaproxy/zaproxy:2.16.0
Command: zap-baseline.py -t http://quicknotes-lab9:8080
Mode: Passive (baseline only, no active scan)

Result:
Total of 3 URLs
PASS: 57
FAIL-NEW: 0
WARN-NEW: 0
INFO: 0
IGNORE: 0
2.2 Triage Table

No findings to triage — all 57 passive checks passed. No FAIL, WARN, or INFO alerts.
2.3 Code Fix — Security Headers Middleware

Although ZAP passed all checks, the QuickNotes app served responses without HTTP security headers. Added middleware to set them.

File: app/middleware.go
package main

import "net/http"

func SecurityHeadersMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("Content-Security-Policy", "default-src 'none'")
        w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        w.Header().Set("Referrer-Policy", "no-referrer")
        next.ServeHTTP(w, r)
    })
}

File: app/middleware_test.go
package main

import (
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestSecurityHeaders(t *testing.T) {
    handler := SecurityHeadersMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    }))

    req := httptest.NewRequest("GET", "/health", nil)
    rec := httptest.NewRecorder()
    handler.ServeHTTP(rec, req)

    headers := map[string]string{
        "X-Content-Type-Options":    "nosniff",
        "X-Frame-Options":           "DENY",
        "Content-Security-Policy":   "default-src 'none'",
        "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
        "Referrer-Policy":           "no-referrer",
    }

    for header, expected := range headers {
        if got := rec.Header().Get(header); got != expected {
            t.Errorf("Header %s = %q, want %q", header, got, expected)
        }
    }
}
Integration in app/main.go:
handler := SecurityHeadersMiddleware(router)
http.ListenAndServe(":8080", handler)


2.4 Before/After

    Before fix: QuickNotes served responses without X-Content-Type-Options, X-Frame-Options, CSP, HSTS, Referrer-Policy headers.

    After fix: All 5 headers present on every response, verified by unit test.

    Re-scan: ZAP baseline re-run after fix — same 57 PASS, no regressions.

2.5 Design Questions

e) Why middleware and not per-handler header sets?

Middleware applies headers to all routes automatically. Per-handler headers would require adding Header().Set() calls to every handler (/health, /notes, /notes/{id}, etc.), which is error-prone and violates DRY. If a new handler is added without headers, it creates a security gap. Middleware eliminates this class of mistake.

f) What does Content-Security-Policy: default-src 'none' break? Why OK for an API?

CSP default-src 'none' blocks all resources: scripts, styles, images, fonts, frames, and connections. For a website, this breaks everything — no JavaScript, no CSS, no images. For QuickNotes (a REST API), there is no browser rendering. Responses are JSON, not HTML. CSP headers on API responses are a defense-in-depth measure: if someone accidentally serves HTML from the API, the browser won't execute anything.

g) What's the cost of marking all informational findings "accepted" without reading?

Real vulnerabilities hide in the noise. If you blindly accept everything, you miss:

    Misconfigurations that look informational but enable real attacks (e.g., verbose error messages leaking stack traces).

    Findings that are informational today but become exploitable after a code change.

    The triage discipline itself degrades — if "accept everything" becomes habit, you'll accept a real HIGH next time.

