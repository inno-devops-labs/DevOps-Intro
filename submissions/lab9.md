# Lab 9 - DevSecOps: Trivy + ZAP

## Implemented files

- [`app/handlers.go`](../app/handlers.go)
- [`app/handlers_test.go`](../app/handlers_test.go)
- [`app/Dockerfile`](../app/Dockerfile)
- [`app/.dockerignore`](../app/.dockerignore)
- [`compose.yaml`](../compose.yaml)
- [`security/lab9/trivy-image.txt`](../security/lab9/trivy-image.txt)
- [`security/lab9/trivy-fs.json`](../security/lab9/trivy-fs.json)
- [`security/lab9/trivy-config.txt`](../security/lab9/trivy-config.txt)
- [`security/lab9/quicknotes-image.cdx.json`](../security/lab9/quicknotes-image.cdx.json)
- [`security/lab9/zap-before.html`](../security/lab9/zap-before.html)
- [`security/lab9/zap-before.json`](../security/lab9/zap-before.json)
- [`security/lab9/zap-after.html`](../security/lab9/zap-after.html)
- [`security/lab9/zap-after.json`](../security/lab9/zap-after.json)

The branch is based on `upstream/main` and only contains Lab 9 deliverables. The Dockerfile and Compose file are included so the Lab 9 scanners have a buildable `quicknotes:lab6` image and a running API target.

## Commands run

```powershell
go test ./...
docker build -t quicknotes:lab6 app
$reports = (Resolve-Path security\lab9).Path
docker run --rm --mount type=bind,src="$reports",dst=/reports `
  -v /var/run/docker.sock:/var/run/docker.sock `
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL `
  --no-progress --output /reports/trivy-image.txt quicknotes:lab6
docker run --rm --mount type=bind,src="$PWD",dst=/workspace,readonly `
  --mount type=bind,src="$reports",dst=/reports `
  aquasec/trivy:0.59.1 fs --severity HIGH,CRITICAL `
  --skip-dirs /workspace/.git,/workspace/.vagrant `
  --format json --output /reports/trivy-fs.json /workspace
docker run --rm --mount type=bind,src="$PWD",dst=/workspace,readonly `
  --mount type=bind,src="$reports",dst=/reports `
  aquasec/trivy:0.59.1 config --output /reports/trivy-config.txt /workspace
docker run --rm --mount type=bind,src="$reports",dst=/reports `
  -v /var/run/docker.sock:/var/run/docker.sock `
  aquasec/trivy:0.59.1 image --format cyclonedx `
  --output /reports/quicknotes-image.cdx.json quicknotes:lab6
docker compose up -d --build
docker run --rm --mount type=bind,src="$reports",dst=/zap/wrk `
  ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py `
  -t http://host.docker.internal:18080/health -J zap-before.json -r zap-before.html -I
docker run --rm --mount type=bind,src="$reports",dst=/zap/wrk `
  ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py `
  -t http://host.docker.internal:8080/health -J zap-after.json -r zap-after.html -I
```

For Docker Desktop on Windows, ZAP ran in a container and reached host `localhost:8080` through `host.docker.internal`.
The before report used a temporary `quicknotes:lab9-before` image built from `upstream/main` with the same Dockerfile, exposed on host port `18080`.

## Trivy image scan

Top of [`trivy-image.txt`](../security/lab9/trivy-image.txt):

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 11 (HIGH: 11, CRITICAL: 0)
```

## Trivy filesystem scan

[`trivy-fs.json`](../security/lab9/trivy-fs.json) shows the repository filesystem scan completed with no HIGH/CRITICAL vulnerabilities:

```json
{
  "SchemaVersion": 2,
  "ArtifactName": "/workspace",
  "ArtifactType": "filesystem",
  "Results": [
    {
      "Target": "app/go.mod",
      "Class": "lang-pkgs",
      "Type": "gomod"
    }
  ]
}
```

I skipped `.git` and `.vagrant` because they are local runtime metadata, not files submitted in this branch.

## Trivy config scan

Top of [`trivy-config.txt`](../security/lab9/trivy-config.txt):

```text
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

There are no HIGH or CRITICAL config findings. The LOW healthcheck recommendation is not a paging risk for this lab branch; Compose still starts QuickNotes directly for ZAP.

## CycloneDX SBOM

First 30 lines of [`quicknotes-image.cdx.json`](../security/lab9/quicknotes-image.cdx.json):

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:5d840114-690a-469c-a67e-c1e306be5e2b",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-01T20:35:35+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3Aa40d68236e7bb473be36760ad5005ee8cabaeeff91d2a7151d67e9ad885abb35?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3Aa40d68236e7bb473be36760ad5005ee8cabaeeff91d2a7151d67e9ad885abb35?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
```

## Trivy HIGH/CRITICAL triage

| Source | Finding | Severity | Disposition | Reason |
|---|---|---:|---|---|
| Image, Go stdlib | CVE-2026-25679 `net/url` IPv6 host literal parsing | HIGH | ACCEPT, re-evaluate by 2026-10-01 | QuickNotes does not parse user-supplied URLs, proxy requests, or redirect to caller-controlled URLs. Upgrade when the course runtime moves beyond Go 1.24. |
| Image, Go stdlib | CVE-2026-27145 `crypto/x509` DNS-name processing DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | The app serves plain HTTP in Compose and does not validate client certificates or remote certificate chains. |
| Image, Go stdlib | CVE-2026-32280 `crypto/x509` / `crypto/tls` certificate chain DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | No TLS listener or outbound TLS certificate validation exists in QuickNotes. |
| Image, Go stdlib | CVE-2026-32281 `crypto/x509` certificate validation DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | Same reachability decision as the other `crypto/x509` findings: no certificate chain processing is exposed. |
| Image, Go stdlib | CVE-2026-32283 `crypto/tls` TLS 1.3 key update DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | QuickNotes is exposed as HTTP on port 8080, not TLS, so this path is not reachable in the lab deployment. |
| Image, Go stdlib | CVE-2026-33811 `net` long CNAME DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | Request handlers do not perform attacker-controlled DNS lookups. |
| Image, Go stdlib | CVE-2026-33814 HTTP/2 SETTINGS frame DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | The lab container exposes a plain HTTP/1.1 service; there is no TLS-enabled HTTP/2 entry point. |
| Image, Go stdlib | CVE-2026-39820 `net/mail` crafted email input DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | QuickNotes does not parse email addresses or email messages. |
| Image, Go stdlib | CVE-2026-39836 Go security update | HIGH | ACCEPT, re-evaluate by 2026-10-01 | Scanner reports the Go 1.24 stdlib in the static binary. The app has no direct reachable path identified for this umbrella update; upgrade when course/runtime constraints allow Go 1.25 or 1.26. |
| Image, Go stdlib | CVE-2026-42499 `net/mail` pathological email address parsing | HIGH | ACCEPT, re-evaluate by 2026-10-01 | No QuickNotes endpoint accepts or parses email addresses. |
| Image, Go stdlib | CVE-2026-42504 MIME header decoding DoS | HIGH | ACCEPT, re-evaluate by 2026-10-01 | The service accepts JSON over HTTP and does not call MIME decoding APIs directly. Keep watching because Go stdlib fixes require a runtime upgrade. |

Filesystem scan: no HIGH/CRITICAL findings. Config scan: no HIGH/CRITICAL findings.

## Task 1 design questions

### a) CVE severity is one input

Severity says how bad the vulnerability can be in the abstract. Triage also needs reachability, whether exploit code exists, whether the affected function is called with attacker-controlled input, whether the service is internet-facing, whether compensating controls exist, and how expensive the fix is.

### b) Distroless minimal base

A minimal base removes shells, package managers, compilers, and most OS packages. That shrinks both the vulnerability inventory and the post-exploitation toolkit available to an attacker. It is strong because it reduces attack surface before any scanner-specific triage begins.

### c) `.trivyignore`

Suppressions are appropriate for documented false positives or time-bounded accepted risks with an owner and review date. They are security theater when used to make a report green without explaining reachability, impact, or when the team will revisit the decision.

### d) SBOM future value

The SBOM lets us answer quickly whether QuickNotes contains a newly disclosed vulnerable component. During an event like Log4Shell, the team can query the SBOM instead of rebuilding tribal knowledge from Dockerfiles and binaries while an incident is already moving.

## ZAP baseline

Pinned image: `ghcr.io/zaproxy/zaproxy:2.16.1`.

Before fix, [`zap-before.json`](../security/lab9/zap-before.json) and [`zap-before.html`](../security/lab9/zap-before.html) reported:

```text
High: 0
Medium: 0
Low: 3
Informational: 1

Insufficient Site Isolation Against Spectre Vulnerability
X-Content-Type-Options Header Missing
ZAP is Out of Date
Storable and Cacheable Content
```

After fix, [`zap-after.json`](../security/lab9/zap-after.json) and [`zap-after.html`](../security/lab9/zap-after.html) reported:

```text
High: 0
Medium: 0
Low: 1
Informational: 1

ZAP is Out of Date
Non-Storable Content
```

The fixed findings no longer appear in the after report:

```text
PASS: X-Content-Type-Options Header Missing [10021]
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
```

Direct header evidence from the fixed app:

```text
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Permissions-Policy: camera=(), geolocation=(), microphone=()
Pragma: no-cache
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

## ZAP finding triage

| Report | ID | Name | Risk | Affected URL / parameter | Disposition | Reason |
|---|---:|---|---|---|---|---|
| Before | 90004 | Insufficient Site Isolation Against Spectre Vulnerability | Low | `/health`, missing `Cross-Origin-Resource-Policy` | FIX | Added `Cross-Origin-Embedder-Policy`, `Cross-Origin-Opener-Policy`, and `Cross-Origin-Resource-Policy` in router middleware. Gone in after report. |
| Before | 10021 | X-Content-Type-Options Header Missing | Low | `/health`, missing `x-content-type-options` | FIX | Added `X-Content-Type-Options: nosniff` in router middleware. Gone in after report. |
| Before | 10049 | Storable and Cacheable Content | Informational | `/`, `/health`, `/robots.txt`, `/sitemap.xml` | FIX | Added `Cache-Control: no-store` and `Pragma: no-cache`. After report changed this to an informational non-storable-content note. |
| Before | 10116 | ZAP is Out of Date | Low | Scanner metadata on `/sitemap.xml` | ACCEPT, re-evaluate by 2026-08-01 | This is about the pinned scanner image, not QuickNotes. The lab requires a pinned image; update the pin during the next security-tooling maintenance pass. |
| After | 10049 | Non-Storable Content | Informational | `/`, `/health`, `/robots.txt` | ACCEPT, re-evaluate by 2026-10-01 | This is expected after intentionally setting `Cache-Control: no-store` on an API. It does not indicate user impact. |
| After | 10116 | ZAP is Out of Date | Low | Scanner metadata on `/` | ACCEPT, re-evaluate by 2026-08-01 | Same scanner-version note as before; it remains documented and time-bounded. |

## Code fix

The fix is implemented as middleware in [`app/handlers.go`](../app/handlers.go):

```go
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("Cache-Control", "no-store")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Cross-Origin-Embedder-Policy", "require-corp")
		h.Set("Cross-Origin-Opener-Policy", "same-origin")
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		h.Set("Pragma", "no-cache")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Permissions-Policy", "camera=(), geolocation=(), microphone=()")
		next.ServeHTTP(w, r)
	})
}
```

The router returns `securityHeaders(mux)`, so every route goes through the same policy. [`app/handlers_test.go`](../app/handlers_test.go) includes `TestRoutes_AddSecurityHeaders`, which fails if the middleware is removed.

## Task 2 design questions

### e) Why middleware

Middleware keeps the security policy in one place and wraps the whole router, including future routes. Per-handler header calls are easy to forget and create inconsistent behavior across endpoints.

### f) Strict CSP for an API

`Content-Security-Policy: default-src 'none'` blocks loading scripts, styles, images, frames, fonts, and network subresources unless explicitly allowed. That would break a normal website or Swagger UI unless it had a tailored allowlist. QuickNotes is a JSON API, so responses are data, not browser-rendered pages that need subresources.

### g) False positives vs accepted findings

Marking every informational finding as accepted without reading it trains the team to ignore scanner output. The cost is missed signal: a real exposure can hide among noisy findings, and future reviewers cannot tell whether a risk was understood or simply waved through.

## Bonus task

Not attempted. No `govulncheck` CI job or bonus evidence is included in this Lab 9 branch.
