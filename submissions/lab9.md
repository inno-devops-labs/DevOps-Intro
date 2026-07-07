# Lab 9: DevSecOps: Scan QuickNotes with Trivy + ZAP

All scans use **Trivy `aquasec/trivy:0.59.1`**, run as a Docker container with a persistent cache volume so the vulnerability database is downloaded only once

```bash
# Build the Lab 6 image
docker compose build

# Image scan
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 image quicknotes:lab6 --severity HIGH,CRITICAL

# Filesystem scan (vulnerabilities and secrets)
docker run --rm \
  -v "$PWD:/repo" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 fs /repo \
  --severity HIGH,CRITICAL --scanners vuln,secret

# Configuration scan
docker run --rm \
  -v "$PWD:/repo" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 config /repo

# Generate a CycloneDX SBOM
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 image quicknotes:lab6 \
  --format cyclonedx --output quicknotes-lab6.sbom.cdx.json
```

## Task 1: Trivy: Image + Filesystem + Config + SBOM

### 1.1 Required scans

#### Image scan

```text
quicknotes:lab6 (debian 12.14)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 11 (HIGH: 11, CRITICAL: 0)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬─────────────────┬─────────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version   │ Title                                                       │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼─────────────────┼─────────────────────────────────────────────────────────────┤
│ stdlib  │ CVE-2026-25679 │ HIGH     │ fixed  │ v1.24.13          │ 1.25.8, 1.26.1  │ net/url: Incorrect parsing of IPv6 host literals            │
│ ...     │ ...            │ ...      │ ...    │ ...               │ ...             │ ...                                                         │
└─────────┴────────────────┴──────────┴────────┴───────────────────┴─────────────────┴─────────────────────────────────────────────────────────────┘
```

The Debian base image has **no HIGH or CRITICAL vulnerabilities**. All 11 HIGH findings come from the **Go standard library** in the application binary, which was built with **Go 1.24.13**. These vulnerabilities are fixed in newer Go releases, so updating the Go toolchain resolves them.

#### Filesystem scan

```text
Number of language-specific files: 1
[gomod] Detecting vulnerabilities... → 0

.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
  Asymmetric Private Key
  .vagrant/machines/default/virtualbox/private_key:1
```

The project has **no vulnerable Go dependencies**. The only finding is a Vagrant SSH private key used for local development. It is already `.gitignore`d, not tracked by Git, and is not included in the Docker image.

#### Config scan

```text
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

The Dockerfile passes **27 of 28 checks**. The only issue is a **LOW** severity recommendation to add a `HEALTHCHECK`. No configuration issues were reported for `compose.yaml`.

#### SBOM

A CycloneDX 1.6 SBOM was generated containing **6 components**:

- 4 Debian packages
- QuickNotes binary
- Go standard library

### 1.2 Triage

| Finding | Scan | Severity | Disposition | Reason |
|---------|------|----------|-------------|--------|
| 11 Go standard library CVEs | Image | HIGH | **FIX** | Update the Go toolchain and rebuild the application. |
| Vagrant private key | Filesystem | HIGH | **ACCEPT** | Local development key, `.gitignore`d, never shipped. |
| Missing `HEALTHCHECK` | Config | LOW | **FIX** | Added a `HEALTHCHECK` instruction to the Dockerfile. |

### 1.3 Design questions

**a) CVE severity is one input, not the answer. What else matters?**

CVSS measures the severity of a vulnerability, but the actual risk depends on the application.

- **Reachability** – Is the vulnerable code actually used?
- **Exploitability** – Is there a public exploit or active exploitation?
- **Deployment context** – Is the service internet-facing or internal? What data does it handle?
- **Compensating controls** – Protections such as running as a non-root user, a read-only filesystem, and dropped Linux capabilities reduce risk.
- **Fix availability** – If a simple update fixes the issue, it should usually be applied.

For QuickNotes, the 11 HIGH findings were all fixed by updating the Go toolchain.

**b) Why are distroless images more secure?**

Distroless images contain only the files needed to run the application. Fewer packages mean:

- Smaller attack surface
- Fewer vulnerabilities
- No shell or package manager for attackers
- Smaller SBOM and lower maintenance

In this project, the distroless base image had **0 HIGH/CRITICAL vulnerabilities**, so nearly all findings came from the application itself.

**c) When should `.trivyignore` be used?**

Use `.trivyignore` only after a documented risk assessment, such as for:

- False positives
- Unfixable vulnerabilities
- Development-only files that are never deployed

Each ignored finding should include a reason and be reviewed regularly. It should never be used simply to hide real security issues.

**d) Why is an SBOM useful?**

An SBOM records every software component included in an application. If a new vulnerability (such as Log4Shell) is announced, the SBOM makes it easy to determine whether the affected component is present and which version is in use. This speeds up incident response and patching.

### 1.5 CycloneDX SBOM — first 30 lines

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:40a1b320-efbd-4cd8-8d8f-e6361206ade8",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T13:40:49+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3Ae626f5267a1ff84d353f8d62a74d3c3d1fd1d78877db71ccaca14942b0c77950?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3Ae626f5267a1ff84d353f8d62a74d3c3d1fd1d78877db71ccaca14942b0c77950?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:114dde0fefebbca13165d0da9c500a66190e497a82a53dcaabc3172d630be1e9"
        },
        {
```

The generated SBOM contains **6 components**: four Debian packages, the **QuickNotes** application, and the **Go standard library**

## Task 2: OWASP ZAP Baseline + Fix at Least One Finding

### 2.1 Run ZAP baseline

ZAP was run in **baseline (passive) mode** using the pinned image
`ghcr.io/zaproxy/zaproxy:2.16.1`. Since QuickNotes has no `/` endpoint, the scan targeted `/notes`, which returns a `200 OK` response.

```bash
# QuickNotes running on :8080
docker run --rm -v "$PWD/submissions/lab9:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py -t http://host.docker.internal:8080/notes \
  -r zap-baseline-before.html -J zap-baseline-before.json
```

Reports were saved as:

- `zap-baseline-before.html`
- `zap-baseline-before.json`
- `zap-baseline-after.html`
- `zap-baseline-after.json`

### 2.2 Triage

| ID | Finding | Risk | URL | Disposition | Reason |
|----|---------|------|-----|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | `/notes` | **FIX** | Added `X-Content-Type-Options: nosniff` in middleware. |
| 90004 | Insufficient Site Isolation Against Spectre | Low | `/notes` | **ACCEPT** | QuickNotes serves JSON, not HTML. Re-evaluate if a web UI is added. |
| 10049 | Storable and Cacheable Content | Info | `/` | **ACCEPT** | Responses contain public, non-sensitive data. Re-evaluate if private data is served. |
| 10116 | ZAP is Out of Date | Low | `/` | **FALSE POSITIVE** | Reports the scanner version, not an application issue. |

The CSP, anti-clickjacking, and Permissions-Policy checks passed because they apply only to HTML responses, while QuickNotes serves JSON.

### 2.3 Fix: Security Headers Middleware

A `securityHeaders` middleware wraps the router so all routes automatically include the required security headers.

```go
func (s *Server) Routes() http.Handler {
 mux := http.NewServeMux()
 // ... routes ...
 return securityHeaders(mux)
}

func securityHeaders(next http.Handler) http.Handler {
 return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
  h := w.Header()
  h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
  h.Set("X-Content-Type-Options", "nosniff")
  h.Set("X-Frame-Options", "DENY")
  h.Set("Referrer-Policy", "no-referrer")
  next.ServeHTTP(w, r)
 })
}
```

The following unit test verifies that every route receives the security headers. It fails if the middleware is removed.

```go
func TestSecurityHeaders_SetOnEveryRoute(t *testing.T) {
 srv := newTestServer(t)

 for _, target := range []string{"/health", "/notes", "/metrics"} {
  rec := do(t, srv, http.MethodGet, target, nil)

  if got := rec.Header().Get("Content-Security-Policy"); got != "default-src 'none'; frame-ancestors 'none'" {
   t.Errorf("%s: Content-Security-Policy = %q", target, got)
  }

  if got := rec.Header().Get("X-Content-Type-Options"); got != "nosniff" {
   t.Errorf("%s: X-Content-Type-Options = %q, want nosniff", target, got)
  }
 }
}
```

```text
ok  quicknotes  0.8s
```

### 2.4 Before / After

After rebuilding the image and rerunning ZAP, the missing `X-Content-Type-Options` finding no longer appeared.

```text
BEFORE: WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1 (PASS: 63)
AFTER:  PASS:     X-Content-Type-Options Header Missing [10021]     (PASS: 64)
```

`curl -i http://localhost:8080/notes` after the fix:

```text
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

### 2.5 Design questions

**e) Why use middleware instead of setting headers in every handler?**

Middleware applies the headers in one place, ensuring every route is protected. This avoids duplicated code and ensures new routes automatically receive the same security headers.

**f) What does `Content-Security-Policy: default-src 'none'` do, and why is it appropriate here?**

It blocks loading scripts, styles, images, fonts, and other resources. This would break a normal website, but QuickNotes is a JSON API, so the policy has no negative effect.

**g) What is the cost of accepting informational findings without reviewing them?**

Accepting findings without review creates alert fatigue and can hide real security issues. Each accepted finding should have a documented reason so future scans remain useful.
