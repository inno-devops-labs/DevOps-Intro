# Lab 9 Submission — DevSecOps: Trivy + ZAP

> Built on the Lab 6 image (`quicknotes:lab6`, distroless-static). All scans
> run with **Trivy pinned to `aquasec/trivy:0.59.1`** (not `:latest`). Raw outputs are
> in [`submissions/lab9-artifacts/`](/submissions/lab9-artifacts/).

## Task 1: Trivy — Image + Filesystem + Config + SBOM

### 1.1 Scan outputs (tops)

All four scans share a cached vuln DB (`trivy-cache` named volume) so the ~200 MB DB
downloads once. On Windows/Git-Bash the repo-target scans need `MSYS_NO_PATHCONV=1` so
the `/repo` argument isn't rewritten to a Windows path.

**1. Image scan**: `trivy image --severity HIGH,CRITICAL quicknotes:lab6`
([full](/submissions/lab9-artifacts/trivy-image.txt))

```
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/ \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
```

```
Detected OS  family="debian" version="13.5"
[debian] Detecting vulnerabilities...  os_version="13" pkg_num=5
[gobinary] Detecting vulnerabilities...

quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 10 (HIGH: 10, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 10 (HIGH: 10, CRITICAL: 0)
```

The **OS layer is clean** (distroless-static ships only 5 packages, none vulnerable).
Every HIGH lives in the two compiled Go binaries, all of them **Go standard-library**
CVEs against `stdlib v1.24.13`, the same 10 in both `/quicknotes` and `/healthcheck`.
These are fixed in §1.2, so the shipped image and the SBOM in §1.3 are the rebuilt,
patched build.

**2. Filesystem scan** — `trivy fs --severity HIGH,CRITICAL /repo`
([full](/submissions/lab9-artifacts/trivy-fs.txt))

```
MSYS_NO_PATHCONV=1 docker run --rm -v trivy-cache:/root/.cache/ \
  -v "/d/VSCodeProjects/DevOps-Intro":/repo:ro \
  aquasec/trivy:0.59.1 fs --severity HIGH,CRITICAL --no-progress /repo
```

```
.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
 .vagrant/machines/default/virtualbox/private_key:1
```

`go.mod` has no third-party dependencies, so the dependency scan is clean. The only
finding is a secret: Vagrant's per-VM SSH key (triaged below).

**3. Config scan**: `trivy config /repo`
([full](/submissions/lab9-artifacts/trivy-config-full.txt))

```
MSYS_NO_PATHCONV=1 docker run --rm -v trivy-cache:/root/.cache/ \
  -v "/d/VSCodeProjects/DevOps-Intro":/repo:ro \
  aquasec/trivy:0.59.1 config /repo
```

```
Detected config files  num=1

app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

**0 HIGH/CRITICAL misconfigs.** Only `app/Dockerfile` is scanned — Trivy's default
misconfig scanners don't include a `docker-compose` check, so `compose.yaml` isn't
inspected. The single LOW (`AVD-DS-0026`, missing `HEALTHCHECK`) is expected: our
health probe lives in `compose.yaml`, which the Dockerfile scanner can't see.

**4. SBOM generation**: CycloneDX (`trivy image --format cyclonedx`)
([full](/submissions/lab9-artifacts/sbom.cyclonedx.json))

```
MSYS_NO_PATHCONV=1 docker run --rm -v //var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/ \
  -v "/d/VSCodeProjects/DevOps-Intro/submissions/lab9-artifacts":/out \
  aquasec/trivy:0.59.1 image --format cyclonedx --output /out/sbom.cyclonedx.json quicknotes:lab6
```

> Note: the lab text says `trivy sbom --format cyclonedx`, but in Trivy the `sbom`
> subcommand *scans* an existing SBOM file; you *generate* one with
> `image --format cyclonedx`. First 30 lines are in §1.3.

### 1.2 Triage (every HIGH/CRITICAL)

11 HIGH findings, 0 CRITICAL. Ten are the same Go standard library CVEs compiled into
both binaries (`/quicknotes` and `/healthcheck`), so they share one disposition; the
eleventh is a secret from the filesystem scan.

**The stdlib batch was fixed, not accepted.** Every listed *Fixed Version* lands in Go
1.25.x/1.26.x, so a single change clears all ten: bump the builder from
`golang:1.24-alpine` to `golang:1.26-alpine` (go1.26.4, which covers the highest
required fix) in [`app/Dockerfile`](/app/Dockerfile) and rebuild. Re-scanning the
rebuilt image returns `Total: 0 (HIGH: 0, CRITICAL: 0)`
([`trivy-image-after.txt`](/submissions/lab9-artifacts/trivy-image-after.txt)), and the
SBOM now records `stdlib v1.26.4`. When a patch is this cheap, fixing beats writing a
reachability case for keeping it.

| # | Finding (all `stdlib v1.24.13`, all DoS) | Scan | Sev | Disposition |
|---|------------------------------------------|------|-----|-------------|
| 1 | CVE-2026-25679 `net/url` IPv6 host literal parsing | image (gobinary) | HIGH | **FIX** |
| 2 | CVE-2026-27145 `crypto/x509` DNS processing | image | HIGH | **FIX** |
| 3 | CVE-2026-32280 `crypto/tls` cert chain building | image | HIGH | **FIX** |
| 4 | CVE-2026-32281 `crypto/x509` cert chain validation | image | HIGH | **FIX** |
| 5 | CVE-2026-32283 `crypto/tls` TLS 1.3 keys | image | HIGH | **FIX** |
| 6 | CVE-2026-33811 `net` long CNAME response | image | HIGH | **FIX** |
| 7 | CVE-2026-33814 `net/http2` SETTINGS_MAX_FRAME_SIZE | image | HIGH | **FIX** |
| 8 | CVE-2026-39820 `net/mail` crafted email input | image | HIGH | **FIX** |
| 9 | CVE-2026-39836 golang security update (`net/mail`) | image | HIGH | **FIX** |
| 10 | CVE-2026-42499 `net/mail` address parsing | image | HIGH | **FIX** |
| 11 | AsymmetricPrivateKey `.vagrant/.../private_key` | fs (secret) | HIGH | **FALSE POSITIVE** |

Rows 1 to 10 are all cleared by the one builder bump above (evidence:
`trivy-image-after.txt`). Row 11 is Vagrant's auto-generated per-VM insecure key:
`git ls-files` shows it untracked and `.gitignore:27` excludes `.vagrant/`, so it is
never committed, stays on localhost, and is regenerated on each `vagrant up`. It is a
real private key but not a leaked secret; scope future filesystem scans with
`--skip-dirs .vagrant` to drop the noise.

The config scan contributed no HIGH/CRITICAL (one LOW, noted in §1.1).

### 1.3 CycloneDX SBOM (first 30 lines)

Full file: [`submissions/lab9-artifacts/sbom.cyclonedx.json`](/submissions/lab9-artifacts/sbom.cyclonedx.json)
(518 lines, CycloneDX spec 1.6). Generated from the rebuilt, patched image, so it records
`stdlib v1.26.4`.

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:d2f61380-9db2-4f24-bbf7-461562795885",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T16:23:07+00:00",
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
      "bom-ref": "fd432e26-c95e-4349-bdea-423a8215fc39",
      "type": "container",
      "name": "quicknotes:lab6",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:0c00cc2757035b04838d1de3ea183591ba9ee9671d4034921de7eff2cd302393"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
```

### 1.4 Design questions

**a) CVE severity is one input, not the answer. What else matters?**

CVSS scores a vulnerability in isolation; triage requires the context that turns it into actual risk. The main additional inputs are reachability (whether the affected function lies on the application's call path), exploit availability (a public proof of concept or active exploitation in the wild), impact class (denial of service versus remote code execution versus data exposure), and deployment context (internet-facing versus internal, authentication, data sensitivity). A reachable RCE on a public endpoint and an unreachable DoS on an internal service can carry the same score yet warrant very different priority.

**b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the
strongest single security control?**

Most image CVEs originate in OS packages the application never required: a shell, libc, a package manager, coreutils. Distroless-static ships almost none of them, so the OS layer scans at zero HIGH/CRITICAL across only five packages. A package that is absent cannot be vulnerable, so a single base-image choice eliminates entire classes of findings at once, and it also removes the post-exploitation toolkit (no shell, no package manager), making even a genuine code bug far harder to escalate. It is the highest-leverage control because it subtracts attack surface permanently rather than patching reactively.

**c) `.trivyignore`: when is it right, and when is it security theater?**

Suppression is legitimate when it records a specific, dated, reasoned acceptance in version control: a confirmed false positive, or a vulnerability demonstrated to be unreachable, with an owner and a review date. It becomes security theater when it silences findings only to turn the pipeline green, with no justification and no expiry, because that also hides the reachable vulnerability sitting in the same list. The test is whether each entry could be defended to an auditor months later. In this lab the stdlib findings were fixed outright rather than suppressed, so no `.trivyignore` entry was required.

**d) What future problem does having the SBOM today solve?**

The SBOM's value is incident-response speed during the next zero-day. When Log4Shell was disclosed, the costly question was not how to patch but whether an organization was affected at all, and where; teams without an inventory spent days rebuilding and rescanning images just to find out. A committed CycloneDX SBOM reduces that to a lookup: a newly disclosed CVE names a component and version, and the SBOM immediately shows whether it is present and which artifact ships it. The inventory work is done once, in advance, rather than under incident pressure.

### 1.5 Task 1 outputs

- [`trivy-image.txt`](/submissions/lab9-artifacts/trivy-image.txt) — image scan (before fix, 10 HIGH)
- [`trivy-image-after.txt`](/submissions/lab9-artifacts/trivy-image-after.txt) — image scan (after Go 1.26 bump, 0 HIGH)
- [`trivy-fs.txt`](/submissions/lab9-artifacts/trivy-fs.txt) — filesystem scan
- [`trivy-config-full.txt`](/submissions/lab9-artifacts/trivy-config-full.txt) — config/misconfig scan
- [`sbom.cyclonedx.json`](/submissions/lab9-artifacts/sbom.cyclonedx.json) — CycloneDX SBOM

---

## Task 2: OWASP ZAP Baseline + Header Fix

### 2.1 Run ZAP baseline

QuickNotes (the Lab 6 stack) runs on `:8080`; ZAP is pinned to
`ghcr.io/zaproxy/zaproxy:2.16.1`. The scan is the passive `zap-baseline.py` only, never
the active `zap-full-scan.py`. On Docker Desktop the ZAP container reaches the host app
via `host.docker.internal`, and reports are written to a bind-mounted `/zap/wrk`.

```
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "/d/VSCodeProjects/DevOps-Intro/submissions/lab9-artifacts:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py \
  -t http://host.docker.internal:8080/notes \
  -J zap-before.json -r zap-before.html
```

The target is `/notes` rather than `/`: QuickNotes has no root route, so pointing ZAP at
`http://host.docker.internal:8080` makes its spider hit a `404` on the base URL and it
never reaches a real endpoint (that run is kept as evidence but is uninformative). `/notes`
returns a `200` JSON body, so ZAP actually evaluates response headers.

```
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
WARN-NEW: Storable and Cacheable Content [10049] x 2
WARN-NEW: ZAP is Out of Date [10116] x 1
WARN-NEW: Insufficient Site Isolation Against Spectre Vulnerability [90004] x 1
FAIL-NEW: 0   WARN-NEW: 4   INFO: 0   IGNORE: 0   PASS: 63
```

Note that on a JSON API the `Anti-clickjacking Header [10020]` and
`Content Security Policy (CSP) Header Not Set [10038]` rules **pass**: they only alert on
`text/html` responses, so a pure API is not flagged for a missing CSP or `X-Frame-Options`.
The one missing-header finding that applies to JSON is `X-Content-Type-Options [10021]`.

Reports: [`zap-before.html`](/submissions/lab9-artifacts/zap-before.html),
[`zap-before.json`](/submissions/lab9-artifacts/zap-before.json).

### 2.2 ZAP Triage every finding

| ID | Name | Risk (confidence) | Affected URL | Disposition | Reason / evidence |
|----|------|-------------------|--------------|-------------|-------------------|
| 10021 | X-Content-Type-Options Header Missing | Low (Medium) | `/notes` | **FIX** | `securityHeaders` middleware sets `X-Content-Type-Options: nosniff` on every response; after-scan re-classifies it as PASS (§2.4). |
| 90004 | Insufficient Site Isolation Against Spectre | Low (Medium) | `/notes` | **ACCEPT** | The rule wants `Cross-Origin-Opener/Embedder/Resource-Policy`, which isolate cross-origin *document* loads in a browser. QuickNotes serves JSON to API clients, not an HTML browsing context, so the Spectre vector does not apply. Re-eval **2026-10-07**; would set `Cross-Origin-Resource-Policy: same-origin` if the API is ever embedded. |
| 10049 | Storable and Cacheable Content | Informational (Medium) | `/`, `/notes` | **ACCEPT** | Notes are non-sensitive, unauthenticated data, so default cacheability is acceptable. If authentication is added later, set `Cache-Control: no-store`. Re-eval **2026-10-07**. |
| 10116 | ZAP is Out of Date | Low (High) | `/` | **FALSE POSITIVE** | Concerns the scanner's own version, not QuickNotes. ZAP is pinned to 2.16.1 deliberately; not an application finding. |

### 2.3 Fix in code: security-headers middleware + test

The fix is a single middleware that wraps the whole router, so every route (and every
error response, including the mux's own `404`) carries the headers. It is not repeated
inside handlers, so a new route cannot forget them. `main.go` serves `server.Handler()`
instead of `server.Routes()`, and the test asserts all four headers across a real route,
a handler `404`, and a mux `404` through `Server.Handler()`; if the wrap is removed (i.e.
`Handler` returns `s.Routes()`), none of the headers are present and the test fails.

Full diff of the fix, new files [`app/middleware.go`](/app/middleware.go) and
[`app/middleware_test.go`](/app/middleware_test.go), plus the one-line change to
[`app/main.go`](/app/main.go):

```diff
diff --git a/app/main.go b/app/main.go
index e258ffc..aa3dd9e 100644
--- a/app/main.go
+++ b/app/main.go
@@ -28,7 +28,7 @@ func main() {
 	server := NewServer(store)
 	srv := &http.Server{
 		Addr:              addr,
-		Handler:           server.Routes(),
+		Handler:           server.Handler(),
 		ReadHeaderTimeout: 5 * time.Second,
 	}
 
diff --git a/app/middleware.go b/app/middleware.go
new file mode 100644
--- /dev/null
+++ b/app/middleware.go
@@ -0,0 +1,18 @@
+package main
+
+import "net/http"
+
+func securityHeaders(next http.Handler) http.Handler {
+	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
+		h := w.Header()
+		h.Set("X-Content-Type-Options", "nosniff")
+		h.Set("X-Frame-Options", "DENY")
+		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
+		h.Set("Referrer-Policy", "no-referrer")
+		next.ServeHTTP(w, r)
+	})
+}
+
+func (s *Server) Handler() http.Handler {
+	return securityHeaders(s.Routes())
+}
diff --git a/app/middleware_test.go b/app/middleware_test.go
new file mode 100644
--- /dev/null
+++ b/app/middleware_test.go
@@ -0,0 +1,42 @@
+package main
+
+import (
+	"net/http"
+	"net/http/httptest"
+	"testing"
+)
+
+// wantSecurityHeaders is the exact set the securityHeaders middleware must apply to
+// every response. If the middleware is removed from Server.Handler, none of these are
+// present and this test fails.
+var wantSecurityHeaders = map[string]string{
+	"X-Content-Type-Options":  "nosniff",
+	"X-Frame-Options":         "DENY",
+	"Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
+	"Referrer-Policy":         "no-referrer",
+}
+
+func TestSecurityHeaders_PresentOnAllRoutes(t *testing.T) {
+	srv := newTestServer(t)
+	handler := srv.Handler()
+
+	// Exercise a real route, an error route, and an unregistered path to prove the
+	// middleware wraps the whole router and not just the happy path.
+	routes := []struct{ method, target string }{
+		{http.MethodGet, "/health"},
+		{http.MethodGet, "/notes"},
+		{http.MethodGet, "/notes/999"},     // 404 from a handler
+		{http.MethodGet, "/does-not-exist"}, // 404 from the mux itself
+	}
+
+	for _, rt := range routes {
+		req := httptest.NewRequest(rt.method, rt.target, nil)
+		rec := httptest.NewRecorder()
+		handler.ServeHTTP(rec, req)
+		for name, want := range wantSecurityHeaders {
+			if got := rec.Header().Get(name); got != want {
+				t.Errorf("%s %s: header %q = %q, want %q", rt.method, rt.target, name, got, want)
+			}
+		}
+	}
+}
```

```
$ go test ./...
ok      quicknotes      1.562s
?       quicknotes/healthcheck  [no test files]
```

### 2.4 Re-scan (the finding is gone)

After rebuilding the image (`docker compose up --build -d`) the response carries the
headers:

```
$ curl -s -D - -o /dev/null http://localhost:8080/notes
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Type: application/json
```

Re-running the identical baseline against `/notes`:

```
PASS: X-Content-Type-Options Header Missing [10021]
WARN-NEW: Storable and Cacheable Content [10049] x 3
WARN-NEW: ZAP is Out of Date [10116] x 1
WARN-NEW: Insufficient Site Isolation Against Spectre Vulnerability [90004] x 1
FAIL-NEW: 0   WARN-NEW: 3   INFO: 0   IGNORE: 0   PASS: 64
```

`X-Content-Type-Options [10021]` moved from **WARN to PASS** (WARN count 4 → 3, PASS 63 →
64); the after-scan alert set is `[10049, 10116, 90004]`, with `10021` absent. The three
remaining warnings are the accepted / false-positive findings from §2.2. Reports:
[`zap-after.html`](/submissions/lab9-artifacts/zap-after.html),
[`zap-after.json`](/submissions/lab9-artifacts/zap-after.json).

### 2.5 Design questions

**e) Why a middleware and not per-handler header sets?**

One middleware wrapping the router applies the headers to every response in a single place, including error paths and any route added later, whereas per-handler `Header().Set` calls duplicate the policy and are one forgotten line away from a gap. Centralising it also makes the policy auditable and lets a single unit test guard the whole surface rather than testing each handler.

**f) `Content-Security-Policy: default-src 'none'` is the strictest CSP. What does it break, and why is it OK for QuickNotes but not a website?**

`default-src 'none'` forbids the document from loading any script, style, image, font, or frame and from making any fetch/XHR, so it breaks essentially any real website, which needs at least its own scripts and styles. QuickNotes returns only JSON and serves no HTML document, so a browser never executes it as a page; the policy therefore constrains nothing the API actually does while still hardening the case where a response is mistakenly rendered. A website instead allowlists the specific sources it uses (`'self'`, a CDN, and so on) rather than denying everything.

**g) What is the cost of marking informational findings "accepted" without reading them?**

Blanket-accepting the informational noise trains the reviewer to rubber-stamp the entire list, so the day a genuine Medium or High lands in the same report it is waved through with everything else. Each acceptance should be a read decision with a recorded reason; otherwise triage becomes theater and the scanner loses its whole value, which is catching the one finding that matters. Reading them also occasionally surfaces a real issue hiding among the informational entries.

### 2.6 Task 2 artifacts

- [`zap-before.html`](/submissions/lab9-artifacts/zap-before.html) / [`zap-before.json`](/submissions/lab9-artifacts/zap-before.json) — baseline before the fix (4 warnings)
- [`zap-after.html`](/submissions/lab9-artifacts/zap-after.html) / [`zap-after.json`](/submissions/lab9-artifacts/zap-after.json) — baseline after the fix (`10021` gone)
- [`app/middleware.go`](/app/middleware.go), [`app/middleware_test.go`](/app/middleware_test.go) — the fix and its guard test