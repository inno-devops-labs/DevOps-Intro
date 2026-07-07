# Lab 9 - DevSecOps: Trivy + ZAP

## Overview

This lab scans the QuickNotes container image and repository with Trivy, generates a CycloneDX SBOM, runs an OWASP ZAP baseline scan, triages every finding, and fixes one finding in code.

The main code fixes are:

1. Updated the Go builder image from `golang:1.24-alpine` to `golang:1.26.4-alpine`.
2. Added HTTP security/cache headers through middleware.
3. Added a unit test that verifies the middleware adds the headers.

---

# Task 1 - Trivy Scans + SBOM

## Scanner versions

```text
Trivy image: aquasec/trivy:0.59.1
```

---

## 1. Image scan

### Command

```powershell
docker run --rm `
  -v //var/run/docker.sock:/var/run/docker.sock `
  -v "${PWD}\reports\trivy:/reports" `
  aquasec/trivy:0.59.1 `
  image --severity HIGH,CRITICAL quicknotes:lab6 `
  --format table `
  --output /reports/trivy-image-after.txt
```

### Before fix summary

The first image scan found HIGH vulnerabilities in the Go standard library embedded in both Go binaries:

```text
healthcheck (gobinary): Total: 10 (HIGH: 10, CRITICAL: 0)
quicknotes (gobinary): Total: 10 (HIGH: 10, CRITICAL: 0)
```

The findings were caused by building with the older Go toolchain:

```dockerfile
FROM golang:1.24-alpine AS builder
```

### Fix

The Dockerfile builder image was updated:

```diff
-FROM golang:1.24-alpine AS builder
+FROM golang:1.26.4-alpine AS builder
```

After rebuilding with `--no-cache`, the image scan result was:

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

---

## 2. Filesystem scan

### Command

```powershell
docker run --rm `
  -v "${PWD}:/repo" `
  -v "${PWD}\reports\trivy:/reports" `
  aquasec/trivy:0.59.1 `
  fs --severity HIGH,CRITICAL --skip-dirs /repo/.vagrant /repo `
  --format table `
  --output /reports/trivy-fs.txt
```

### Result

```text
No HIGH or CRITICAL filesystem vulnerability or secret findings were reported after excluding local Vagrant state.
```

### Note on initial finding

The first filesystem scan detected:

```text
.vagrant/machines/default/virtualbox/private_key
HIGH: AsymmetricPrivateKey
```

This file is local Vagrant machine state. It is ignored by `.gitignore` and is not tracked by Git:

```text
git ls-files .vagrant/machines/default/virtualbox/private_key
<no output>
```

Disposition: `FALSE POSITIVE` for repository risk, because the file is not part of the submitted project source. The final scan excludes `.vagrant/`.

---

## 3. Config scan

### Command

```powershell
docker run --rm `
  -v "${PWD}:/repo" `
  -v "${PWD}\reports\trivy:/reports" `
  aquasec/trivy:0.59.1 `
  config --severity HIGH,CRITICAL /repo `
  --format json `
  --output /reports/trivy-config.json
```

### Result excerpt

```json
{
  "Target": "app/Dockerfile",
  "Class": "config",
  "Type": "dockerfile",
  "MisconfSummary": {
    "Successes": 21,
    "Failures": 0
  }
}
```

Result: no HIGH or CRITICAL Dockerfile/Compose misconfiguration findings.

---

## 4. CycloneDX SBOM

### Command

```powershell
docker run --rm `
  -v //var/run/docker.sock:/var/run/docker.sock `
  -v "${PWD}\reports\trivy:/reports" `
  aquasec/trivy:0.59.1 `
  image --format cyclonedx quicknotes:lab6 `
  --output /reports/quicknotes-cyclonedx.json
```

### First 30 lines

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:a782fc85-1c0f-4680-9234-12fa4df1117d",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T16:22:55+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.59.1"
        }
      ]
    },
    "component": {
      "bom-ref": "pkg:oci/quicknotes@sha256%3A72e01af9d2867f6074a1f3f2d2ff2428a4734d5eec2bf2c2898c271f4e268812?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A72e01af9d2867f6074a1f3f2d2ff2428a4734d5eec2bf2c2898c271f4e268812?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
```

---

## Trivy triage table

| Scan | Target | Finding | Severity | Disposition | Reason |
|---|---|---:|---|---|---|
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-25679 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-27145 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-32280 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-32281 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-32283 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-33811 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-33814 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-39820 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-39836 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Image | `healthcheck`, `quicknotes` Go binaries | CVE-2026-42499 | HIGH | FIX | Fixed by rebuilding binaries with `golang:1.26.4-alpine`; after scan reports 0 HIGH/CRITICAL. |
| Filesystem | `.vagrant/machines/default/virtualbox/private_key` | AsymmetricPrivateKey | HIGH | FALSE POSITIVE | Local Vagrant-generated machine state, ignored by `.gitignore`, not tracked by Git, and excluded from final repo scan. |
| Config | `app/Dockerfile` | No HIGH/CRITICAL misconfigurations | N/A | ACCEPT | Trivy config scan reported 21 successes and 0 failures. |

---

## Task 1 design questions

### a) CVE severity is one input, not the answer. What else matters?

Severity matters, but it does not prove exploitability in this application. I also considered reachability, whether the vulnerable code path is actually used, whether a public exploit exists, whether the service is internet-facing, and whether the vulnerable package is present only in a build stage or in the runtime image.

For example, a HIGH CVE in a package that is never called by the application may be less urgent than a MEDIUM CVE in a public request parser. Deployment context also matters: a local-only lab service has different risk from a public production API.

### b) Why is a minimal base image the strongest single security control?

A minimal base image removes unnecessary packages, shells, package managers, and tools from the runtime container. This reduces the attack surface and gives scanners fewer packages to find vulnerabilities in.

The distroless runtime image helped here because the OS package scan reported zero HIGH/CRITICAL findings. The only initial image findings came from the compiled Go binaries, not from a large runtime OS layer.

### c) When is `.trivyignore` the right move, and when is it security theater?

`.trivyignore` is appropriate when a finding is documented, reviewed, time-bounded, and genuinely not actionable. For example, it may be valid if there is no upstream fix yet, the vulnerable code is not reachable, or the finding is a scanner false positive.

It becomes security theater when it is used just to make the report green without a reason, owner, or re-evaluation date. Suppression without triage hides risk instead of managing it.

### d) What future problem does having an SBOM solve?

An SBOM lets the team answer “are we affected?” quickly when a new vulnerability appears. During incidents like Log4Shell, teams needed to know whether they used a specific component and where it was deployed. Without an SBOM, that becomes a slow manual search.

Having the CycloneDX SBOM today means future vulnerability response can start from an inventory instead of guessing what is inside the image.

---

# Task 2 - OWASP ZAP Baseline + Fix

## Scanner version

```text
ZAP image: zaproxy/zap-stable:2.16.1
```

---

## ZAP baseline before fix

### Command

```powershell
docker run --rm `
  -v "${PWD}\reports\zap:/zap/wrk" `
  zaproxy/zap-stable:2.16.1 `
  zap-baseline.py `
  -t http://host.docker.internal:8080 `
  -r zap-before.html `
  -J zap-before.json `
  -m 1 `
  -I
```

### Before result excerpt

```text
WARN-NEW: Storable and Cacheable Content [10049] x 1
        http://host.docker.internal:8080 (404 Not Found)
WARN-NEW: ZAP is Out of Date [10116] x 1
        http://host.docker.internal:8080 (404 Not Found)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 2     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 65
```

---

## Code fix

### `app/security.go`

```go
package main

import "net/http"

func securityHeaders(next http.Handler) http.Handler {
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
w.Header().Set("Cache-Control", "no-store")
w.Header().Set("Content-Security-Policy", "default-src 'none'")
w.Header().Set("X-Content-Type-Options", "nosniff")
w.Header().Set("Referrer-Policy", "no-referrer")
w.Header().Set("X-Frame-Options", "DENY")

next.ServeHTTP(w, r)
})
}
```

### `app/main.go` diff

```diff
 server := NewServer(store)
 srv := &http.Server{
         Addr:              addr,
-        Handler:           server.Routes(),
+        Handler:           securityHeaders(server.Routes()),
         ReadHeaderTimeout: 5 * time.Second,
 }
```

This wraps the full router, so the headers apply to all routes.

---

## Unit test

### `app/security_test.go`

```go
package main

import (
"net/http"
"net/http/httptest"
"testing"
)

func TestSecurityHeadersMiddleware(t *testing.T) {
next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
w.WriteHeader(http.StatusOK)
})

handler := securityHeaders(next)

req := httptest.NewRequest(http.MethodGet, "/health", nil)
rr := httptest.NewRecorder()

handler.ServeHTTP(rr, req)

tests := map[string]string{
"Cache-Control":           "no-store",
"Content-Security-Policy": "default-src 'none'",
"X-Content-Type-Options":  "nosniff",
"Referrer-Policy":         "no-referrer",
"X-Frame-Options":         "DENY",
}

for header, want := range tests {
if got := rr.Header().Get(header); got != want {
t.Fatalf("%s = %q, want %q", header, got, want)
}
}
}
```

### Test result

```text
ok      quicknotes      0.014s
```

---

## Header verification

### Command

```powershell
curl.exe -I http://localhost:8080/health
```

### Output

```text
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'
Content-Type: application/json
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Date: Tue, 07 Jul 2026 16:37:15 GMT
Content-Length: 26
```

---

## ZAP baseline after fix

### Command

```powershell
docker run --rm `
  -v "${PWD}\reports\zap:/zap/wrk" `
  zaproxy/zap-stable:2.16.1 `
  zap-baseline.py `
  -t http://host.docker.internal:8080 `
  -r zap-after.html `
  -J zap-after.json `
  -m 1 `
  -I
```

### After result excerpt

```text
WARN-NEW: Non-Storable Content [10049] x 2
        http://host.docker.internal:8080/robots.txt (404 Not Found)
        http://host.docker.internal:8080/sitemap.xml (404 Not Found)
WARN-NEW: ZAP is Out of Date [10116] x 1
        http://host.docker.internal:8080/sitemap.xml (404 Not Found)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 2     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 65
```

### Proof the fixed finding is gone

Command:

```powershell
Get-Content .\reports\zap\zap-after.json | Select-String "Storable and Cacheable Content"
```

Output:

```text
<no output>
```

The original `Storable and Cacheable Content` finding no longer appears after adding `Cache-Control: no-store`.

---

## ZAP triage table

| ID | Name | Risk | Affected URL / parameter | Disposition | Reason |
|---|---|---|---|---|---|
| 10049 | Storable and Cacheable Content | WARN before fix | `http://host.docker.internal:8080` | FIX | Fixed by adding `securityHeaders` middleware with `Cache-Control: no-store` applied to all routes. The after report no longer contains `Storable and Cacheable Content`. |
| 10049 | Non-Storable Content | Informational | `/robots.txt`, `/sitemap.xml` | ACCEPT | These are ZAP-generated requests to static SEO files that QuickNotes does not serve. QuickNotes is an API, and the responses are intentionally non-storable after the middleware fix. Re-evaluate by 2027-01-07 if browser/static content is added. |
| 10116 | ZAP is Out of Date | Low | `/sitemap.xml` | ACCEPT | This finding is about the scanner image, not the QuickNotes application. The lab requires a pinned ZAP image, and `zaproxy/zap-stable:2.16.1` was intentionally pinned. Re-evaluate by 2027-01-07 when updating scanner versions. |

---

## Task 2 design questions

### e) Why middleware and not per-handler header sets?

Middleware applies the headers consistently to every route. If headers are set inside each handler, it is easy to forget one route and create inconsistent security behavior.

Middleware also gives one place to test and update the policy. The unit test guards the middleware directly, so removing it or changing a required header causes a test failure.

### f) What does `Content-Security-Policy: default-src 'none'` break? Why is it OK for QuickNotes?

`default-src 'none'` blocks loading scripts, stylesheets, images, fonts, frames, and most other browser resources unless they are explicitly allowed. That would break a normal website unless the site carefully allowlisted its frontend assets.

For QuickNotes, this is acceptable because it is an API that returns JSON, not a browser application. There are no scripts, styles, or images that need to load. If QuickNotes later adds Swagger UI or a real frontend, the CSP would need to be relaxed with explicit allowed sources.

### g) What is the cost of marking all ZAP informational findings as accepted without reading them?

The cost is that real problems can be hidden inside low-risk or informational output. Not every informational finding is dangerous, but some can reveal bad assumptions, unexpected endpoints, metadata leaks, or configuration mistakes.

If everything is blindly accepted, the triage table becomes meaningless. The useful practice is to read each finding, decide whether it affects the actual app, and document a reason.

---

# Bonus Task - govulncheck CI Gate

Bonus was not attempted.

---

# Final artifact list

```text
reports/trivy/trivy-image.txt
reports/trivy/trivy-image-after.txt
reports/trivy/trivy-fs.txt
reports/trivy/trivy-config.txt
reports/trivy/trivy-config.json
reports/trivy/quicknotes-cyclonedx.json
reports/zap/zap-before.html
reports/zap/zap-before.json
reports/zap/zap-after.html
reports/zap/zap-after.json
app/security.go
app/security_test.go
submissions/lab9.md
```

# Final result

Task 1 is complete:

```text
Image scan: 0 HIGH / 0 CRITICAL after Go builder update
Filesystem scan: 0 HIGH / 0 CRITICAL after excluding ignored local Vagrant state
Config scan: 0 HIGH / 0 CRITICAL misconfiguration failures
SBOM: generated CycloneDX JSON
```

Task 2 is complete:

```text
ZAP before: Storable and Cacheable Content finding present
Fix: security headers middleware + unit test
ZAP after: Storable and Cacheable Content finding gone
```