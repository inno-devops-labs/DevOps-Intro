# Lab 9 submission

**Host:** Apple Silicon Mac. **Scanner versions:** Trivy `0.59.1`, OWASP ZAP `2.16.1`, govulncheck `v1.1.4`.

---

## Task 1 — Trivy Scans + SBOM + Triage

### Scans run

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL quicknotes:lab6

docker run --rm -v "$PWD:/repo" aquasec/trivy:0.59.1 fs \
  --severity HIGH,CRITICAL --skip-dirs .vagrant --skip-dirs .git /repo

docker run --rm -v "$PWD:/repo" aquasec/trivy:0.59.1 config \
  --severity HIGH,CRITICAL /repo

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/submissions/attachments/lab9/trivy:/out" \
  aquasec/trivy:0.59.1 image --format cyclonedx --output /out/sbom.cdx.json quicknotes:lab6
```

### Scan summaries

| Scan | HIGH | CRITICAL | Artifact |
|------|-----:|---------:|----------|
| Image (OS layer debian) | 0 | 0 | [`trivy/image-scan.txt`](attachments/lab9/trivy/image-scan.txt) |
| Image (Go binary stdlib) | 10 | 0 | same |
| Filesystem (excl. `.vagrant`) | 0 | 0 | [`trivy/fs-scan.txt`](attachments/lab9/trivy/fs-scan.txt) |
| Config (before `USER` fix) | 1 | 0 | [`trivy/config-scan.txt`](attachments/lab9/trivy/config-scan.txt) |
| Config (after `USER` fix) | 0 | 0 | [`trivy/config-scan-after.txt`](attachments/lab9/trivy/config-scan-after.txt) |

### CycloneDX SBOM (first 30 lines)

See [`trivy/sbom-head.txt`](attachments/lab9/trivy/sbom-head.txt) · full file [`trivy/sbom.cdx.json`](attachments/lab9/trivy/sbom.cdx.json)

### Triage table (every HIGH/CRITICAL)

| ID / Finding | Source | Disposition | Reason |
|--------------|--------|-------------|--------|
| CVE-2026-25679 … CVE-2026-42499 (10×) | Image / Go stdlib in binary (`v1.24.13`) | **WATCH** | Embedded toolchain CVEs; distroless OS layer is clean. Re-check when bumping `golang:1.24-alpine` builder to a patched release (by **2026-12-31**). |
| AVD-DS-0002 missing `USER` in Dockerfile | Config scan | **FIX** | Added `USER nonroot:nonroot` to final stage in `app/Dockerfile` — config scan clean after fix. |
| AsymmetricPrivateKey in `.vagrant/.../private_key` | FS scan (without skip) | **FALSE POSITIVE** | Local Vagrant SSH key under `.gitignore`; not shipped in image. FS scan uses `--skip-dirs .vagrant`. |

### Design questions (a–d)

**a) CVE severity is one input, not the answer**

Also consider: **reachability** (is vulnerable code path used?), **exploit availability** (PoC in the wild?), **deployment context** (internal API vs public internet), **compensating controls** (distroless, read-only rootfs, no shell). A HIGH CVE in an unused stdlib package is lower risk than a MEDIUM in code you call on every request.

**b) Why distroless often shows zero OS CVEs**

Minimal base = few packages = tiny attack surface and few NVD entries. No shell, package manager, or libc beyond what a static binary needs — fewer components to patch and fewer paths for container escape.

**c) When is `.trivyignore` right vs theater?**

Right: documented **ACCEPT** with owner, expiry date, and link to risk decision (e.g. dev-only path). Theater: blanket ignores to make CI green without triage, or permanent suppressions with no review date.

**d) What future problem does the SBOM solve?**

When the next **Log4Shell-style** event hits, you query the SBOM (“do we ship `log4j` / `stdlib` at version X?”) in minutes instead of grepping repos. It is the inventory for incident response and license compliance.

---

## Task 2 — ZAP Baseline + Security Header Fix

### ZAP runs

```bash
# Before fix (base URL)
docker run --rm -v "$PWD/submissions/attachments/lab9/zap-before:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py \
  -t http://host.docker.internal:8080 -r zap-report.html -J zap-report.json -I

# After fix (/health)
docker run --rm -v "$PWD/submissions/attachments/lab9/zap-after:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py \
  -t http://host.docker.internal:8080/health -r zap-report.html -J zap-report.json -I
```

### ZAP triage

| ID | Name | Risk | URL | Disposition | Reason |
|----|------|------|-----|-------------|--------|
| 10049 | Storable and Cacheable Content | Info | `/robots.txt`, `/sitemap.xml` | **FIX** | Added `Cache-Control: no-cache, no-store, must-revalidate, private` + `Pragma: no-cache` via middleware. `/health` no longer cacheable. |
| 10116 | ZAP is Out of Date | Low | spider URLs | **ACCEPT** | Scanner metadata, not an app defect. Re-evaluate when upgrading ZAP image. |
| 90004 | Insufficient Site Isolation (Spectre) | Low | `/health` | **ACCEPT** | JSON API without cross-origin documents; COOP/COEP less critical than for HTML apps. Re-evaluate **2026-12-31**. |
| 10020–10038, 10063 | Header rules (CSP, X-Frame, etc.) | — | API JSON | **FIX** (proactive) | ZAP marked PASS on `application/json` responses; middleware adds headers anyway for defense in depth + unit test guard. |

### Code fix — `app/security.go` middleware

```go
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
		h.Set("Cache-Control", "no-cache, no-store, must-revalidate, private")
		h.Set("Pragma", "no-cache")
		next.ServeHTTP(w, r)
	})
}
```

Wired in `main.go` via `server.Handler()`. Test: `TestSecurityHeaders_PresentOnAllRoutes` in `handlers_test.go`.

### Before / after evidence

**Before** (`/health` headers):

```
HTTP/1.1 200 OK
Content-Type: application/json
(no security headers)
```

[`zap-before/headers-health-before.txt`](attachments/lab9/zap-before/headers-health-before.txt)

**After** (`/health` headers):

```
Cache-Control: no-cache, no-store, must-revalidate, private
Content-Security-Policy: default-src 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Permissions-Policy: geolocation=(), microphone=(), camera=()
Referrer-Policy: no-referrer
```

[`zap-after/headers-health-after.txt`](attachments/lab9/zap-after/headers-health-after.txt)

ZAP: before **WARN** `Storable and Cacheable Content` on 404 paths; after `/health` scan shows **Non-Storable Content** (cache headers present). Reports: [`zap-before/`](attachments/lab9/zap-before/) · [`zap-after/`](attachments/lab9/zap-after/)

### Design questions (e–g)

**e) Why middleware, not per-handler headers?**

One place enforces policy on **all** routes; impossible to forget a handler. Tests assert middleware once; removing middleware breaks the test.

**f) `CSP: default-src 'none'` — what breaks?**

Blocks browsers from loading any sub-resource (scripts, styles, images). Fine for a **JSON API** with no HTML. Would break a website with inline JS/CSS unless you allowlist sources.

**g) Cost of blind ACCEPT on ZAP informational findings**

You train reviewers to ignore the report; real issues hide in noise. Each ACCEPT should cite why the risk does not apply to this deployment.

---

## Bonus — `govulncheck` in CI

### Workflow addition (`.github/workflows/ci.yml`)

```yaml
  govulncheck:
    name: govulncheck
    runs-on: ubuntu-24.04
    defaults:
      run:
        working-directory: app
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.2.2
      - uses: actions/setup-go@0aaccfd150d50ccaeb58ebd88d36e91967a5f35b # v5.4.0
        with:
          go-version: '1.25.11'
      - run: go install golang.org/x/vuln/cmd/govulncheck@v1.1.4
      - run: govulncheck ./...
```

`ci-ok` now depends on `govulncheck`.

> **Why Go 1.25.11 for this job?** CI `vet`/`test` stay on Go 1.23/1.24. `govulncheck` on Go **1.24.13** reports **8 reachable stdlib vulnerabilities** (exit code 3) — fixes are in **1.25.11+**, not backported to 1.24. The gate runs on the patched toolchain so a clean app passes; the **red** demo still uses an intentional bad dependency.

### Red / green demonstration

- **Red** (intentional `golang.org/x/crypto@v0.3.0` + `ssh.Dial` in isolated module): [`govulncheck-red.txt`](attachments/lab9/govulncheck-red.txt) — reports reachable `GO-2026-5020` etc.
- **Green** (QuickNotes on Go 1.25.11): [`govulncheck-green.txt`](attachments/lab9/govulncheck-green.txt) — `No vulnerabilities found.`

### Design questions (h–j)

**h) Reachability vs module presence**

Trivy flags “stdlib v1.24.13 contains CVE” if present in the binary. `govulncheck` traces **call paths** — if you do not call the vulnerable function, it may not block. That cuts triage noise but requires keeping the scanner updated.

**i) Why pin govulncheck version?**

Reproducible CI: `@latest` can change vulnerability DB logic or exit behavior between runs without a code change in your repo.

**j) What govulncheck won't catch**

OS packages in the container image, misconfigured `compose.yaml`, secrets in git, and non-Go dependencies — Trivy image/config/fs scans cover those layers.

---

## Artifacts

| Path | Description |
|------|-------------|
| `app/security.go` | Security headers middleware |
| `app/Dockerfile` | `USER nonroot:nonroot` (Trivy config fix) |
| `.github/workflows/ci.yml` | + `govulncheck` job |
| `submissions/attachments/lab9/` | Scan logs, SBOM, ZAP reports |
