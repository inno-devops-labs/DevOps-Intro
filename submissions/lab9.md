# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

Tooling: Trivy `0.72.0` (native CLI, Homebrew — pinned, not `latest`). Full raw outputs are in [`submissions/lab9-scans/`](./lab9-scans/).

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### 1.1 Scans run

1. `trivy image --severity HIGH,CRITICAL quicknotes:lab6` → [`trivy-image.txt`](./lab9-scans/trivy-image.txt)
2. `trivy fs --severity HIGH,CRITICAL .` → [`trivy-fs.txt`](./lab9-scans/trivy-fs.txt)
3. `trivy config .` → [`trivy-config.txt`](./lab9-scans/trivy-config.txt)
4. `trivy image --format cyclonedx quicknotes:lab6` → [`sbom-cyclonedx.json`](./lab9-scans/sbom-cyclonedx.json)

**Image scan (before fix)** — summary:

```
Report Summary
┌────────┬──────────┬─────────────────┬─────────┐
│ Target │   Type   │ Vulnerabilities │ Secrets │
├────────┼──────────┼─────────────────┼─────────┤
│ bin/qn │ gobinary │       14        │    -    │
└────────┴──────────┴─────────────────┴─────────┘

bin/qn (gobinary)
Total: 14 (HIGH: 13, CRITICAL: 1)
```

The image is `scratch` + a single static Go binary (Lab 6). Every finding is in `stdlib`, tied to the `golang:1.24.5` build-stage toolchain — there is no OS package layer to scan, which is exactly the distroless/scratch payoff (see 1.3.b).

**Filesystem scan** — summary:

```
Report Summary
┌──────────────────────────────────────────────────┬───────┬─────────────────┬─────────┐
│                      Target                       │ Type  │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────┼───────┼─────────────────┼─────────┤
│ app/go.mod                                        │ gomod │        0        │    -    │
├──────────────────────────────────────────────────┼───────┼─────────────────┼─────────┤
│ .vagrant/machines/default/virtualbox/private_key  │ text  │        -        │    1    │
└──────────────────────────────────────────────────┴───────┴─────────────────┴─────────┘
```

`app/go.mod` has zero third-party dependencies (QuickNotes only imports Go stdlib), so `gomod` scanning finds nothing — all risk is in the stdlib version, already covered by the image scan. The one HIGH is a secret scanner hit, not a CVE (see triage table).

**Config scan** — summary:

```
Report Summary
┌────────────┬────────────┬───────────────────┐
│   Target   │    Type    │ Misconfigurations │
├────────────┼────────────┼───────────────────┤
│ Dockerfile │ dockerfile │         1         │
└────────────┴────────────┴───────────────────┘

Dockerfile (dockerfile)
Tests: 27 (SUCCESSES: 26, FAILURES: 1)
Failures: 1 (LOW: 1) — DS-0026: Add HEALTHCHECK instruction
```

Only `Dockerfile` was scanned — Trivy's `config` misconfig scanner does not have a check pack for Compose files (only Dockerfile / Terraform / Kubernetes / CloudFormation as of 0.72.0), so `docker-compose.yml` shows `num=0` detected config files when scanned directly. No HIGH/CRITICAL misconfigs found.

**SBOM (first 30 lines):**

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:08cddf6a-9627-4f99-a3d7-2900ea1fbdd3",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T06:59:12+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "manufacturer": {
            "name": "Aqua Security Software Ltd."
          },
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.72.0"
        }
      ]
    },
    "component": {
      "bom-ref": "4ef8bb1e-50c8-40e2-8094-ff6b93e59122",
      "type": "container",
      "name": "quicknotes:lab6",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:70a952b1d983fbc9a4af340c4493196b673e1f6e085e4dcbd5b8fb791f3662ab"
        },
```

### 1.2 Triage — every HIGH/CRITICAL finding

Reachability context used throughout: QuickNotes imports only `net/http`, `encoding/json`, `errors`, `sort`, `strconv`, `sync/atomic`, `context`, `log`, `os`, `os/signal`, `syscall`, `time` (checked via `grep import app/*.go`). It serves **plain HTTP/1.1** on `:8080` — no TLS termination, no outbound DNS/mail/multipart parsing in app code. Trivy's `gobinary` scanner flags a CVE if it's present in the *stdlib version string* embedded in the binary, regardless of whether the vulnerable function is ever called — unlike `govulncheck`, which does call-graph reachability analysis and only reports CVEs actually reachable from the code (see Bonus task, if attempted, for that contrast in practice).

**Fix applied:** bumped the build stage from `golang:1.24.5` → `golang:1.24.13` in [`Dockerfile`](../Dockerfile) (same `go 1.24` line pinned in `go.mod` — a safe patch bump, no toolchain/API risk). Rebuilt and rescanned: CRITICAL and 2 of the 13 HIGH findings disappeared (fixed at ≤1.24.13); 11 HIGH remain, all requiring a Go **1.25/1.26 minor** bump not yet available on the pinned `1.24` line.

| # | Source | Finding | Severity | Disposition | Reason |
|---|--------|---------|----------|--------------|--------|
| 1 | image | CVE-2025-68121 — `crypto/tls` incorrect cert validation on TLS session resumption | CRITICAL | **FIX** | Fixed by bumping build stage to `golang:1.24.13` (this PR, `Dockerfile`). Moot for reachability too — app never terminates TLS — but free to fix, so fixed. |
| 2 | image | CVE-2025-61726 — `net/url` memory exhaustion in query parsing | HIGH | **FIX** | Same bump to `1.24.13` resolves it; `net/url` is reachable (used internally by `net/http` request parsing), so worth fixing regardless. |
| 3 | image | CVE-2025-61729 — `crypto/x509` DoS via crafted cert chain | HIGH | **FIX** | Same bump to `1.24.13` resolves it. |
| 4 | image | CVE-2026-25679 — `net/url` IPv6 host literal parsing | HIGH | **ACCEPT** (re-eval 2026-10-01) | Fix needs Go 1.25.8+, a minor bump outside the pinned `go 1.24` line — bigger change than a patch bump. `net/url` is reachable via request parsing, so this stays a scheduled re-eval, not WATCH. |
| 5 | image | CVE-2026-27145 — `crypto/x509` DoS via DNS name processing | HIGH | **ACCEPT** (re-eval 2026-10-01) | Needs Go 1.25.11+. Not reachable today (app performs no x509 operations — no TLS, no cert parsing) but re-evaluate if that changes. |
| 6 | image | CVE-2026-32280 — `crypto/x509`/`crypto/tls` DoS via cert chain building | HIGH | **ACCEPT** (re-eval 2026-10-01) | Needs Go 1.25.9+. Same reasoning as #5 — no TLS/x509 code path in QuickNotes. |
| 7 | image | CVE-2026-32281 — `crypto/x509` DoS via inefficient chain validation | HIGH | **ACCEPT** (re-eval 2026-10-01) | Needs Go 1.25.9+ (no separate fixed version listed). Same reasoning as #5. |
| 8 | image | CVE-2026-32283 — `crypto/tls` DoS via multiple TLS 1.3 key shares | HIGH | **ACCEPT** (re-eval 2026-10-01) | Needs Go 1.25.9+. QuickNotes never negotiates TLS 1.3 (plain HTTP). |
| 9 | image | CVE-2026-33811 — `net` DoS via long CNAME response | HIGH | **WATCH** | Needs Go 1.25.10+, not yet on the pinned `1.24` line. App does no outbound DNS resolution of untrusted names; effectively unreachable. Re-check: next `go.mod` bump to Go 1.25, or 2026-10-01, whichever comes first. |
| 10 | image | CVE-2026-33814 — `net/http/internal/http2` DoS via malformed SETTINGS frame | HIGH | **ACCEPT** (re-eval 2026-10-01) | Needs Go 1.25.10+. Go's HTTP/2 only activates over TLS ALPN negotiation; QuickNotes serves HTTP/1.1 only, so unreachable today. Re-eval if TLS/h2 is ever added in front of the app. |
| 11 | image | CVE-2026-39820 — `net/mail` DoS via crafted email input | HIGH | **WATCH** | Needs Go 1.25.11+. `net/mail` is not imported anywhere in `app/*.go` — flagged purely because it's part of the linked stdlib version, not because it's reachable. Re-check: next `go.mod` bump to Go 1.25, or 2026-10-01, whichever comes first. |
| 12 | image | CVE-2026-39836 — ELSA-2026-22121 general Go security bundle advisory | HIGH | **WATCH** | Vendor umbrella advisory bundling several of the above; no distinct fixed version given. Re-check: resolves automatically once #4–#11/#13/#14 are fixed by the Go 1.25 bump; re-verify with `trivy image` at that point. |
| 13 | image | CVE-2026-42499 — `net/mail` DoS via pathological address parsing | HIGH | **WATCH** | Same as #11 — `net/mail` unused by QuickNotes. Re-check: next `go.mod` bump to Go 1.25, or 2026-10-01, whichever comes first. |
| 14 | image | CVE-2026-42504 — MIME header decoding DoS (many invalid encoded words) | HIGH | **WATCH** | Needs Go 1.25.11+. QuickNotes does no multipart/MIME parsing (`grep -n multipart app/*.go` empty). Re-check: next `go.mod` bump to Go 1.25, or 2026-10-01, whichever comes first. |
| 15 | fs | `.vagrant/machines/default/virtualbox/private_key` — AsymmetricPrivateKey (Lab 5 Vagrant keypair) | HIGH | **ACCEPT** (re-eval 2026-10-01) | The scanner is correct — a real private key is on disk — so this isn't a false positive; the risk is accepted because it's the per-VM keypair Vagrant auto-generates locally (Lab 5), confirmed gitignored (`git check-ignore -v` matches `.gitignore:27 .vagrant/`), so it's never committed and never leaves this machine. Re-evaluate if `.vagrant/` is ever exempted from `.gitignore` or the repo starts using a shared/remote Vagrant provider. |

Config scan produced only one LOW finding (`DS-0026`, missing `HEALTHCHECK`) — no HIGH/CRITICAL to triage there.

### 1.3 Design questions

**a) CVE severity is one input, not the answer. What else matters when triaging?**
Severity is CVSS-style "how bad if exploited," but it says nothing about whether the vulnerable code path is ever exercised. In this scan, Trivy's `gobinary` mode flags every stdlib CVE for the embedded Go version string, whether or not QuickNotes calls the affected package — `net/mail` shows up as HIGH even though the app never imports it. **Reachability** (is the vulnerable function on any call path from an entry point we expose?), **exploit availability** (is there a public PoC / is it being exploited in the wild, vs. a theoretical DoS requiring a crafted, hard-to-reach input?), and **deployment context** (does QuickNotes terminate TLS itself, or sit behind a proxy that already terminates TLS and only forwards plain HTTP to it? Is it internet-facing or LAN-only?) all determine whether a HIGH finding is "fix tonight" or "watch." That's the whole reason the triage table above splits FIX/ACCEPT/WATCH instead of blanket-patching every HIGH.

**b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?**
Every installed package is attack surface a scanner can report on *and* an attacker can abuse post-compromise (a shell, `curl`, a package manager to pull in more tools). QuickNotes' `FROM scratch` final stage has no OS layer at all — the fs/image scans here found **zero** OS package CVEs; the only findings are in the Go stdlib baked into the one static binary, which is unavoidable no matter how minimal the base is. A `debian:slim` or even `alpine` base would add dozens of packages, each a separate CVE surface, on top of that. Minimal base wins by *subtraction* — it removes the target rather than trying to secure it.

**c) `.trivyignore` — when is suppression the right move vs. security theater?**
Right move: a finding has been triaged with a written reason and a re-evaluation date (i.e., a documented ACCEPT/WATCH/FALSE POSITIVE like the table above), and you want CI to stop failing on a *known, decided* item while still failing on new ones. The ignore entry should reference the CVE and point at where the disposition is recorded. Theater: using `.trivyignore` to make a red pipeline green without writing down *why* — that's just hiding the finding, not deciding on it, and it silently rots (nobody remembers to remove it when a fix ships). The discipline is: no `.trivyignore` entry without a dated, reasoned row in a triage table first.

**d) The SBOM — what future problem does having it today solve?**
An SBOM is a queryable inventory of every component and version in the image, generated once, cheap to keep current. The value shows up the day a **new** CVE drops for something already inside your image — Log4Shell is the canonical case: organizations that had no SBOM spent days grepping filesystems and asking every team "do you use Log4j, and which version?" across their whole fleet. With a CycloneDX SBOM already generated (like `sbom-cyclonedx.json` here), answering "are we affected by CVE-X" becomes a one-line search over existing JSON instead of an emergency inventory exercise. The SBOM doesn't prevent the vulnerability — it collapses the *time-to-know* from days to minutes.

---

## Task 2 — OWASP ZAP Baseline + Fix at Least One Finding

### 2.1 Run ZAP baseline

Tooling: `ghcr.io/zaproxy/zaproxy:2.16.1` (pinned, not `stable`/`latest`). App started via `docker compose up -d quicknotes` (Lab 6/8 image, port 8080).

QuickNotes is a pure JSON API with no HTML/links (`GET /health`, `GET /metrics`, `GET /notes`, `POST /notes`, `GET|DELETE /notes/{id}`) and no root page — pointing `zap-baseline.py` at `http://localhost:8080` directly makes ZAP's spider fail on `/` (404) and it only discovers 3 boilerplate probe URLs (`/`, `/robots.txt`, `/sitemap.xml`), all 404. To actually get ZAP to passively scan real responses, I ran baseline separately against each real endpoint that returns 200 (`/health`, `/metrics`, `/notes`):

```
docker run --rm -v "$(pwd):/zap/wrk:rw" --network host ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py -t http://localhost:8080/health -J zap-health.json -r zap-health.html
# repeated for /metrics and /notes
```

Full HTML + JSON reports for all three runs are in [`submissions/lab9-scans/zap-before/`](./lab9-scans/zap-before/). No active scan (`zap-full-scan.py`) was run — baseline only, per the lab's safety instructions.

### 2.2 Triage — every ZAP finding

Findings were identical across all three real endpoints (same middleware stack), so listed once with the endpoints they applied to:

| ID | Name | Risk | Affected URL(s) | Disposition | Reason |
|----|------|------|------------------|--------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low (Medium confidence) | `/health`, `/metrics`, `/notes` | **FIX** | Fixed in this PR via `SecurityHeaders` middleware (`app/security.go`) — sets `X-Content-Type-Options: nosniff` on every route. See 2.3/2.4 for before/after proof. |
| 90004 | Insufficient Site Isolation Against Spectre Vulnerability | Low (Medium confidence) | `/health`, `/metrics`, `/notes` | **FIX** | Fixed in the same middleware — sets `Cross-Origin-Resource-Policy: same-origin`. See 2.3/2.4. |
| 10049 | Storable and Cacheable Content | Informational | `/`, `/health`, `/metrics`, `/notes`, `/robots.txt`, `/sitemap.xml` | **FIX** (bonus, not required) | The middleware also sets `Cache-Control: no-store`. After the fix ZAP re-labels this alert `Non-Storable Content` (informational, confirms the header worked) rather than removing it outright — informational either way, no action needed beyond what's already fixed. |
| 10116 | ZAP is Out of Date | Low (High confidence) | scanner-internal | **FALSE POSITIVE** | Not a QuickNotes finding — ZAP flagging that its own passive-scan rule pack is older than the latest release. Unrelated to the app; pin the ZAP image version deliberately (2.16.1) rather than chasing "latest". |

Every alert ZAP raised is accounted for above — nothing left untriaged. Design question (g) covers why blanket-accepting informational/false-positive rows without reading them (rather than the reasoned dispositions above) would be the wrong habit.

### 2.3 Fix: `SecurityHeaders` middleware

Implemented in [`app/security.go`](../app/security.go), wired around the whole router (not per-handler) in [`app/main.go`](../app/main.go):

```go
// app/security.go
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}
```

```go
// app/main.go — wraps the router once, applies to every route
srv := &http.Server{
	Addr:              addr,
	Handler:           SecurityHeaders(server.Routes()),
	ReadHeaderTimeout: 5 * time.Second,
}
```

Requirements checklist:
1. ✅ Middleware wraps the router (`SecurityHeaders(server.Routes())`), not scattered `Header().Set` calls in handlers
2. ✅ Applies to all routes — `/health`, `/metrics`, `/notes`, `/notes/{id}` all pass through the same wrapped handler
3. ✅ Unit test asserts headers present: [`app/security_test.go`](../app/security_test.go) (`TestSecurityHeaders_SetOnEveryRoute`, `TestSecurityHeaders_WrapsHandler`)
4. ✅ Test genuinely guards the fix — verified by temporarily gutting `SecurityHeaders` to `return next` and re-running `go test`: both tests failed with explicit header-mismatch errors before the middleware was restored.

### 2.4 Re-scan: before/after proof

**Before** (`submissions/lab9-scans/zap-before/zap-health.json`, and identical for `-metrics`/`-notes`):
```
10021-1 X-Content-Type-Options Header Missing | risk=Low (Medium) | count=1
90004-1 Insufficient Site Isolation Against Spectre Vulnerability | risk=Low (Medium) | count=1
```

**After** (`submissions/lab9-scans/zap-after/zap-health.json`, and identical for `-metrics`/`-notes`), rebuilt image + re-ran the exact same baseline command:
```
10116 ZAP is Out of Date | risk=Low (High) | count=1        <- unrelated to app, see 2.2
10049-1 Non-Storable Content | risk=Informational (Medium)  <- confirms Cache-Control: no-store took effect
```

`10021` and `90004` no longer appear in any of the three re-scanned endpoints — both are fully gone. Raw response headers after the fix (`curl -i http://localhost:8080/health`):
```
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'
Content-Type: application/json
Cross-Origin-Resource-Policy: same-origin
X-Content-Type-Options: nosniff
```

### 2.5 Design questions

**e) Why a middleware and not per-handler header sets?**
A middleware wrapping the router is a single point of enforcement: every current and future route gets the headers automatically, and there's exactly one place to audit or change the policy. Per-handler `Header().Set` calls are copy-paste that *will* drift — someone adds `PATCH /notes/{id}` next sprint, forgets the header lines, and now that one route silently regresses. The unit test in 2.3 tests the middleware itself, not each handler, so the guarantee scales to routes that don't exist yet.

**f) `Content-Security-Policy: default-src 'none'` — what does it break, and why is it fine here but not for a website?**
`default-src 'none'` blocks the browser from loading *anything* by default — no scripts, styles, images, fonts, XHR/fetch targets, unless another directive explicitly allows it. For a real website this breaks inline scripts, external stylesheets, embedded images, analytics beacons, web fonts — basically anything a page normally loads, unless every single resource type is allowlisted directive-by-directive. QuickNotes has zero HTML responses — every route returns JSON or plaintext metrics — so there's no page for a browser to render, no script/style/image to fetch, and thus nothing for the strictest CSP to break. The CSP header only matters here if a browser ever renders a QuickNotes response directly (e.g., an error page), and locking it down costs nothing since there's no legitimate content to allowlist.

**g) False positives vs. accepted findings — cost of blanket-accepting informational ZAP alerts?**
Blanket-marking every informational alert "accepted" without reading it means the one time an informational alert *is* meaningful — a stray comment leaking an internal hostname, a cache header exposing a session token, a version string revealing an unpatched framework — it slides through unnoticed, identical in the report to twenty harmless noise alerts. It also erodes the audit trail: "accepted" should mean "a human read this and decided," not "the scanner said informational so I didn't look." The table in 2.2 reads and reasons about all four alerts (including two purely informational/tooling ones) rather than rubber-stamping them, which is the whole point of the triage discipline this lab is testing.
