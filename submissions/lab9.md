# Lab 9 — DevSecOps: Trivy + ZAP

## Overview

This lab scans the QuickNotes image and repository with Trivy, generates a CycloneDX SBOM, runs OWASP ZAP baseline against the running API, triages findings, fixes one ZAP finding in code, and proves the fix with a unit test and a re-scan.

---

## Task 1 — Trivy Scans

### Trivy image scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd -W)/.trivy-cache:/root/.cache/trivy" \
  -v "$(pwd -W)/reports/trivy:/reports" \
  aquasec/trivy:0.59.1 image \
  --severity HIGH,CRITICAL \
  --timeout 20m \
  --no-progress \
  quicknotes:lab6 | tee reports/trivy/trivy-image.txt
```

Result excerpt:

```text
quicknotes:lab6 (debian 13.5)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

### Trivy filesystem scan

The first filesystem scan found a local Vagrant private key under `.vagrant/`. This was a local VM state artifact, not application source code.

Initial finding:

```text
.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
```

Fix:

```bash
rm -rf .vagrant
```

Added to `.gitignore`:

```gitignore
# Local VM / scanner state
.vagrant/
.trivy-cache/
```

Final scan command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W):/work" \
  -v "$(pwd -W)/.trivy-cache:/root/.cache/trivy" \
  -w /work \
  aquasec/trivy:0.59.1 fs \
  --severity HIGH,CRITICAL \
  --timeout 20m \
  --no-progress \
  . 2>&1 | tee reports/trivy/trivy-fs.txt
```

Final result:

```text
Result after removing .vagrant/: 0 HIGH / 0 CRITICAL findings.
```

### Trivy config scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W):/work" \
  -w /work \
  aquasec/trivy:0.59.1 config \
  . | tee reports/trivy/trivy-config.txt
```

Result excerpt:

```text
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

This was not a required HIGH/CRITICAL triage item. The risk is acceptable for this lab because the runtime healthcheck is already defined in `compose.yaml`, and Docker Compose verifies the QuickNotes container as healthy.

### CycloneDX SBOM

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd -W)/.trivy-cache:/root/.cache/trivy" \
  -v "$(pwd -W)/reports/trivy:/reports" \
  aquasec/trivy:0.59.1 image \
  --format cyclonedx \
  --output /reports/quicknotes-sbom.cdx.json \
  quicknotes:lab6
```

Artifact:

```text
reports/trivy/quicknotes-sbom.cdx.json
```

First lines of the SBOM were saved in the report artifact and can be inspected with:

```bash
head -30 reports/trivy/quicknotes-sbom.cdx.json
```

---

## Trivy HIGH/CRITICAL Triage Table

| Scan            | Finding                                                                            | Severity | Disposition | Reason                                                                                                                                                               |
| --------------- | ---------------------------------------------------------------------------------- | -------: | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Image scan      | None                                                                               |      N/A | N/A         | `quicknotes:lab6` had 0 HIGH and 0 CRITICAL findings.                                                                                                                |
| Filesystem scan | Local Vagrant private key under `.vagrant/machines/default/virtualbox/private_key` |     HIGH | FIX         | Removed local `.vagrant/` state from the workspace, added `.vagrant/` to `.gitignore`, and reran the filesystem scan. The finding disappeared from the final report. |
| Config scan     | None HIGH/CRITICAL                                                                 |      N/A | N/A         | Config scan only reported one LOW Dockerfile healthcheck finding. Runtime healthcheck is already provided by Compose.                                                |

---

## Task 1 — Design Questions

### a) CVE severity is one input, not the answer. What else matters when triaging?

Severity is only a starting point. I also need to check whether the vulnerable code is reachable from the application, whether a public exploit exists, whether the vulnerable component is exposed to untrusted users, and whether the deployment context makes exploitation realistic. A HIGH CVE in unused code can be lower priority than a MEDIUM issue in an internet-facing endpoint. I also consider whether a fix is available, how risky the upgrade is, and whether there are compensating controls such as a minimal base image or non-root runtime.

### b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?

A minimal image reduces the attack surface by removing shells, package managers, and unnecessary OS utilities. Fewer packages means fewer CVEs, fewer tools available to an attacker after compromise, and less patching work. Distroless is especially useful because the runtime image contains only what the application needs to run. This is stronger than suppressing findings because it prevents many findings from existing in the first place.

### c) `.trivyignore`: when is it right, and when is it security theater?

`.trivyignore` is acceptable when a finding has been reviewed, documented, dated, and there is a clear reason why it cannot or should not be fixed immediately. For example, a false positive or an upstream issue with no available patch can be temporarily ignored with a re-evaluation date. It becomes security theater when teams use it to hide real vulnerabilities without understanding reachability, impact, or remediation. Ignoring without documentation only makes the report look clean while the risk remains.

### d) What future problem does an SBOM solve?

An SBOM lets the team quickly answer whether the application contains a vulnerable component after a new incident is announced. For example, during an incident like Log4Shell, teams with SBOMs can search their deployed software inventory instead of manually inspecting every repository and image. The SBOM also helps with audits, incident response, and dependency tracking. Having it before an incident reduces response time when a new CVE becomes urgent.

---

## Task 2 — OWASP ZAP Baseline

### ZAP before scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W)/reports/zap:/zap/wrk" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py \
  -t http://host.docker.internal:8080 \
  -J zap-before.json \
  -r zap-before.html
```

Artifacts:

```text
reports/zap/zap-before.json
reports/zap/zap-before.html
```

Before scan finding:

```text
WARN-NEW: Storable and Cacheable Content [10049] x 2
http://host.docker.internal:8080/robots.txt (404 Not Found)
http://host.docker.internal:8080/sitemap.xml (404 Not Found)
```

### ZAP findings triage

| ID    | Name                           | Risk | Affected URL / parameter      | Disposition | Reason                                                                                                                                      |
| ----- | ------------------------------ | ---- | ----------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 10049 | Storable and Cacheable Content | WARN | `/robots.txt`, `/sitemap.xml` | FIX         | Added HTTP middleware that sets cache-control and security headers for all responses, then reran ZAP and confirmed the finding disappeared. |
| 90033 | Loosely Scoped Cookie          | PASS | N/A                           | N/A         | ZAP reported this as PASS, not an active warning. No action required.                                                                       |

---

## Code Fix — Security Headers Middleware

The fix was implemented as middleware in `app/handlers.go`, not as per-handler header code.

Middleware:

```go
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("Pragma", "no-cache")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Content-Security-Policy", "default-src 'none'")
		next.ServeHTTP(w, r)
	})
}
```

Router wrapping:

```go
func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.wrap(s.handleHealth))
	mux.HandleFunc("GET /metrics", s.wrap(s.handleMetrics))
	mux.HandleFunc("GET /notes", s.wrap(s.handleListNotes))
	mux.HandleFunc("POST /notes", s.wrap(s.handleCreateNote))
	mux.HandleFunc("GET /notes/{id}", s.wrap(s.handleGetNote))
	mux.HandleFunc("DELETE /notes/{id}", s.wrap(s.handleDeleteNote))
	return securityHeaders(mux)
}
```

Unit test added in `app/security_headers_test.go`:

```go
func TestSecurityHeadersAreAppliedToAllRoutes(t *testing.T) {
	handler := securityHeaders(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	expected := map[string]string{
		"Cache-Control":           "no-store",
		"Pragma":                  "no-cache",
		"X-Content-Type-Options":  "nosniff",
		"Content-Security-Policy": "default-src 'none'",
	}

	for header, want := range expected {
		if got := rec.Header().Get(header); got != want {
			t.Fatalf("%s = %q, want %q", header, got, want)
		}
	}
}
```

Test result:

```text
go test ./...
```

The test passed successfully.

Header verification:

```bash
curl -i http://localhost:8080/health | head -20
```

Output excerpt:

```text
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'
Content-Type: application/json
Pragma: no-cache
X-Content-Type-Options: nosniff

{"notes":4,"status":"ok"}
```

---

## ZAP After Scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W)/reports/zap:/zap/wrk" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py \
  -t http://host.docker.internal:8080 \
  -J zap-after.json \
  -r zap-after.html
```

Artifacts:

```text
reports/zap/zap-after.json
reports/zap/zap-after.html
```

Before/after evidence:

```bash
grep -i "Storable and Cacheable" reports/zap/zap-before.json
grep -i "Storable and Cacheable" reports/zap/zap-after.json || echo "Finding removed in after scan"
```

Output:

```text
"alert": "Storable and Cacheable Content",
"name": "Storable and Cacheable Content",
Finding removed in after scan
```

This proves the selected ZAP finding disappeared after the middleware fix.

---

## Task 2 — Design Questions

### e) Why middleware and not per-handler header sets?

Middleware applies the security policy consistently to every route. If headers are set manually in each handler, it is easy to forget a new route or accidentally create inconsistent behavior. Middleware also keeps security policy separate from business logic, which makes it easier to test and maintain. In this lab, removing the middleware would remove the headers and the unit test would fail.

### f) `Content-Security-Policy: default-src 'none'` is strict. What does it break? Why is it OK for QuickNotes but not for a website?

`default-src 'none'` blocks loading scripts, styles, images, fonts, frames, and other external resources unless they are explicitly allowed. That would break most normal websites because they need CSS, JavaScript, images, and possibly API calls. QuickNotes is an API that returns JSON, so it does not need browser-rendered resources. For this API, the strict CSP is acceptable because there is no frontend content that needs to load assets.

### g) What is the cost of marking all informational ZAP findings as accepted without reading them?

Accepting all findings without reading them trains the team to ignore security tools. Some informational findings can still reveal useful context, such as unexpected headers, caching behavior, or endpoint exposure. If everything is blindly accepted, real issues can hide among low-risk findings and the scan becomes compliance theater. Proper triage keeps the signal useful and makes future alerts more trustworthy.

---

## Artifacts

```text
reports/trivy/trivy-image.txt
reports/trivy/trivy-fs.txt
reports/trivy/trivy-config.txt
reports/trivy/quicknotes-sbom.cdx.json
reports/zap/zap-before.json
reports/zap/zap-before.html
reports/zap/zap-after.json
reports/zap/zap-after.html
```
