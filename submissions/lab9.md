# Lab 9 — DevSecOps: Trivy + ZAP + govulncheck

Tooling (pinned, never `:latest`): Trivy `aquasec/trivy:0.59.1`, ZAP `ghcr.io/zaproxy/zaproxy:2.16.1`.
All scan artifacts live in [`submissions/lab9/`](lab9/). Fix commit: `eaa6907`.
Bonus task not attempted.

---

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### 1.1 Scan outputs (tops)

**Image scan** (`trivy image --severity HIGH,CRITICAL quicknotes:lab6`) — full output: [`lab9/trivy-image.txt`](lab9/trivy-image.txt)

```
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 10 (HIGH: 10, CRITICAL: 0)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬─────────────────┬───────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │  Fixed Version  │                     Title                     │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼─────────────────┼───────────────────────────────────────────────┤
│ stdlib  │ CVE-2026-25679 │ HIGH     │ fixed  │ v1.24.13          │ 1.25.8, 1.26.1  │ net/url: Incorrect parsing of IPv6 host ...   │
│         │ CVE-2026-27145 │          │        │                   │ 1.25.11, 1.26.4 │ crypto/x509: DoS via excessive DNS ...        │
│         │ ... (10 HIGH total, all Go stdlib v1.24.13)                                                                               │
```

The distroless base (`gcr.io/distroless/static:nonroot`) is clean — **all** 10 HIGH
findings are in the **Go standard library** compiled into the binary: Go 1.24 left its
support window, fixes only land in 1.25.8+/1.26.x. One root cause → one fix: builder
image bumped `golang:1.24-alpine` → `golang:1.26-alpine` (commit `eaa6907`).

**Re-scan after rebuild** — [`lab9/trivy-image-after.txt`](lab9/trivy-image-after.txt):

```
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```
(gobinary section: no findings — 10 HIGH → **0**.)

**Filesystem scan** (`trivy fs --severity HIGH,CRITICAL /repo`) — [`lab9/trivy-fs.txt`](lab9/trivy-fs.txt)

```
.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
```

**Config scan** (`trivy config /repo`) — before the fix (first run, 2026-07-07):

```
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

After adding `HEALTHCHECK` to the Dockerfile the re-scan is clean —
[`lab9/trivy-config.txt`](lab9/trivy-config.txt) (captured post-fix) reports no failures
for `app/Dockerfile`.

### 1.2 Triage — every HIGH/CRITICAL

| # | Scan | ID | Component | Sev | Disposition | Reason |
|---|------|----|-----------|-----|-------------|--------|
| 1 | image | CVE-2026-25679 | stdlib `net/url` (IPv6 host parsing) | HIGH | **FIX** | Reachable — `net/http` parses request URLs on every call. Fixed by builder bump to Go 1.26, commit `eaa6907`; after-scan: 0 findings |
| 2 | image | CVE-2026-27145 | stdlib `crypto/x509` (DNS names DoS) | HIGH | **FIX** | Not reachable in practice (server is plain HTTP, no TLS), swept up by the same rebuild (`eaa6907`) |
| 3 | image | CVE-2026-32280 | stdlib `crypto/x509`/`tls` (chain building DoS) | HIGH | **FIX** | Same as #2 — unreachable (no TLS), fixed by rebuild |
| 4 | image | CVE-2026-32281 | stdlib `crypto/x509` (chain validation DoS) | HIGH | **FIX** | Same as #2 |
| 5 | image | CVE-2026-32283 | stdlib `crypto/tls` (TLS 1.3 key DoS) | HIGH | **FIX** | Same as #2 |
| 6 | image | CVE-2026-33811 | stdlib `net` (long CNAME DoS) | HIGH | **FIX** | Barely reachable — no outbound DNS except the loopback healthcheck; rebuilt anyway |
| 7 | image | CVE-2026-33814 | stdlib `net/http` HTTP/2 (SETTINGS frame DoS) | HIGH | **FIX** | HTTP/2 requires TLS (no h2c configured) → unreachable, but rebuilt |
| 8 | image | CVE-2026-39820 | stdlib `net/mail` (DoS) | HIGH | **FIX** | `net/mail` never imported → unreachable; rebuilt |
| 9 | image | CVE-2026-39836 | stdlib (ELSA-2026-22121 umbrella) | HIGH | **FIX** | Umbrella advisory for the same stdlib set; rebuilt |
| 10 | image | CVE-2026-42499 | stdlib `net/mail` (address parsing DoS) | HIGH | **FIX** | Same as #8 |
| 11 | fs | AsymmetricPrivateKey (secret) | `.vagrant/.../private_key` | HIGH | **FALSE POSITIVE** | Not a leaked secret: Vagrant auto-generates this key for local VM SSH. Evidence: `git check-ignore -v` → `.gitignore:27:.vagrant/`; `git log --all -- .vagrant` → empty. Never committed, never shipped |
| 12 | config | AVD-DS-0026 | `app/Dockerfile` — no `HEALTHCHECK` | LOW | **FIX** | Below the HIGH/CRIT bar but trivially fixable: exec-form `HEALTHCHECK CMD ["/quicknotes", "healthcheck"]` (the binary self-probes — works in distroless without a shell). Commit `eaa6907`; re-scan clean |

The reachability column on rows 1–10 is deliberate: severity says HIGH for all ten,
reachability says only `net/url` truly matters here. All got FIX anyway because one
Dockerfile line fixes all ten at once — when the fix is cheaper than the analysis, fix.

### SBOM — CycloneDX

Generated with `trivy image --format cyclonedx` → [`lab9/sbom.cdx.json`](lab9/sbom.cdx.json). First 30 lines:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:8fb1e95c-5c52-4c86-bbd6-af5ef27cec11",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T19:07:47+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3A81847428a82d84573bd5f12a9f7781dbda6cd615810a90dd06e9d699f5727e55?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A81847428a82d84573bd5f12a9f7781dbda6cd615810a90dd06e9d699f5727e55?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
```

### 1.3 Design questions

**a) CVE severity is one input.** CVSS scores worst-case exploitability in the abstract; triage needs context: **reachability** (do we ever execute the vulnerable code path? — govulncheck's whole premise), **exploit availability** (a PoC in the wild / KEV-listed beats a theoretical 9.8), **deployment context** (a CVE in a network parser matters less if the port is never exposed; QuickNotes runs as nonroot in distroless, shrinking post-exploit blast radius), and **data at risk** (notes API vs. payment system). A reachable, exploited-in-the-wild MEDIUM outranks an unreachable CRITICAL. Our own image scan illustrates it: 10 identical-severity HIGHs, but only the `net/url` one sits on a code path this app actually executes.

**b) Why distroless is the strongest single control.** Vulnerability count scales with what's installed. Distroless-static ships no shell, no package manager, no libc, no OS packages — whole vulnerability *classes* are absent, not merely patched: nothing for the scanner to flag and nothing for an attacker to live off after initial compromise (no `/bin/sh` to pop). Our scan shows it concretely: the OS layer contributed **zero** findings; every finding came from the one thing distroless can't remove — our own binary and its stdlib. It removes both scanner noise (fewer findings to triage forever) and real attack surface, and it can't regress silently the way "we patch promptly" can.

**c) `.trivyignore` — right vs. theater.** Right: a *documented* FALSE POSITIVE (like our Vagrant key — with the `git check-ignore` evidence attached) or a dated ACCEPT/WATCH where each entry carries a reason, an owner, and a re-evaluation date in review-tracked form. Theater: ignoring findings to make CI green with no reason and no expiry — that's identical to disabling the scanner for those CVEs, permanently and invisibly. Test: if an entry has no explanation and no date, it's theater.

**d) What the SBOM buys you later.** It converts "are we affected by CVE-X?" from a re-scan-everything fire drill into a database lookup. Log4Shell day: orgs with SBOMs grepped their inventory for `log4j-core` and had an affected-list in minutes — including for images built years ago whose build environments no longer exist; orgs without spent weeks rediscovering their own dependency trees. The SBOM is a point-in-time inventory of what actually shipped, queryable against *future* vulnerability knowledge.

---

## Task 2 — OWASP ZAP baseline + fix

### 2.1 Runs

Baseline (passive only, never the active scan), pinned `zaproxy:2.16.1`, two targets —
the API root and `/notes` (a 200 endpoint) — because the first run exposed a DAST blind
spot: the spider only found 404s (`/`, `/robots.txt`, `/sitemap.xml` — a JSON API has no
root page and no links to crawl), so all header rules **PASSed vacuously**. Only the
`/notes`-targeted scan made the passive rules see a real API response.

Reports: [`zap-before.html`](lab9/zap-before.html) / [`.json`](lab9/zap-before.json),
[`zap-before-notes.html`](lab9/zap-before-notes.html) / [`.json`](lab9/zap-before-notes.json),
and the `-after` counterparts.

### 2.2 Triage — every finding

| ID | Name | Risk | Affected URL | Disposition | Reason |
|----|------|------|--------------|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | `/notes` (200 OK) | **FIX** | JSON served without `nosniff` invites MIME-sniffing if a response is ever coerced into a document context. Fixed: `X-Content-Type-Options: nosniff` (middleware, `eaa6907`) |
| 10049 | Storable and Cacheable Content | Informational | `/notes` (200), `/`, `/robots.txt`, `/sitemap.xml` (404s) | **FIX** | No `Cache-Control` → shared caches may store responses; on `/notes` that's user data. Fixed: `Cache-Control: no-store` (middleware, `eaa6907`) |
| 90004 | Insufficient Site Isolation Against Spectre | Low | `/notes` (200 OK) | **FIX** | Missing `Cross-Origin-Resource-Policy` lets cross-origin pages pull API responses into their process (Spectre-class reads). Fixed: `Cross-Origin-Resource-Policy: same-origin` (middleware, `eaa6907`) |
| 10116 | ZAP is Out of Date | Informational | n/a (scanner self-check) | **FALSE POSITIVE** | The alert concerns the *scanner*, not the app — ZAP is deliberately pinned to `2.16.1` per the lab's pinning requirement. Appears flakily across runs |
| 10049 (after) | Non-Storable Content | Informational | all URLs | **ACCEPT** (intended) | Appears only in the after-scans: plugin 10049 now reports the *opposite* condition — responses cannot be cached, which is exactly what `no-store` is for. Confirmation of the fix, not a defect. Re-evaluate if caching is ever wanted (by 2027-01-07) |
| — | Spider warning: `/` returned 404, expected 200 | n/a | `/` | **FALSE POSITIVE** | Not a vulnerability — QuickNotes intentionally has no `/` route; the API surface is `/health`, `/metrics`, `/notes` |

### 2.3 The fix — middleware + guarded test (commit `eaa6907`)

`app/middleware.go` — one middleware wrapping the whole router, applied to **all**
routes (including the mux-generated 404/405 paths no handler owns):

```go
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Cache-Control", "no-store")
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		next.ServeHTTP(w, r)
	})
}

// Handler is the full HTTP stack: router wrapped in security middleware.
// main() and the tests must both use this, so the middleware can't be
// silently dropped from production wiring without a test failing.
func (s *Server) Handler() http.Handler {
	return securityHeaders(s.Routes())
}
```

`main.go` serves `server.Handler()` (was `server.Routes()`). The unit test
`TestSecurityHeaders_PresentOnAllRoutes` (`app/middleware_test.go`) asserts all six
headers on `/health`, `/metrics`, `/notes`, `/notes/{id}` **and** an unknown route
(404), going through the same `Handler()` the server uses.

**Proof the test guards the fix** — middleware removed from `Handler()`, test fails:

```
--- FAIL: TestSecurityHeaders_PresentOnAllRoutes (0.00s)
    middleware_test.go:42: GET /health: header X-Frame-Options = "", want "DENY"
    middleware_test.go:42: GET /health: header Cache-Control = "", want "no-store"
    middleware_test.go:42: GET /notes: header Content-Security-Policy = "", want "default-src 'none'; frame-ancestors 'none'"
    middleware_test.go:42: GET /no-such-route: header X-Frame-Options = "", want "DENY"
    ... (24 assertions fail across 5 routes)
FAIL    quicknotes    0.503s
```
Middleware restored → `ok  quicknotes  0.380s`.

### 2.4 Before / after

Live check after rebuild (`curl -si http://localhost:8080/health`):

```
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Content-Type: application/json
Cross-Origin-Resource-Policy: same-origin
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

ZAP `/notes` target, **before** (4 WARNs):

```
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
WARN-NEW: Storable and Cacheable Content [10049] x 4
WARN-NEW: ZAP is Out of Date [10116] x 1
WARN-NEW: Insufficient Site Isolation Against Spectre Vulnerability [90004] x 1
```

ZAP `/notes` target, **after** (fixed findings gone; 10021 and 90004 in the PASS list):

```
PASS: X-Content-Type-Options Header Missing [10021]
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
WARN-NEW: Non-Storable Content [10049] x 3      <- opposite condition: fix confirmed
WARN-NEW: ZAP is Out of Date [10116] x 1        <- scanner self-check, documented FP
```

### 2.5 Design questions

**e) Why middleware, not per-handler headers.** One enforcement point vs. n copies of a convention. Per-handler `Header().Set` calls fail open: the next handler someone adds — or the 404/405 responses the router generates, which no handler owns — silently ships without headers, and no diff review catches an *absence*. Middleware wraps the whole router, so error paths and future routes are covered by construction, policy lives in one place, and a single test can guard it (our test asserts headers on an unknown route precisely to pin the no-handler path).

**f) `default-src 'none'`.** It forbids the document from loading *any* sub-resource: scripts, styles, images, fonts, XHR/fetch, frames, media. A real website would render as broken unstyled text. QuickNotes only returns JSON — its responses are data consumed by clients, never documents that load sub-resources — so the strictest CSP costs nothing while guaranteeing that if a response were ever coerced into rendering as HTML (content-type confusion, reflected input), the browser would execute none of it. A website instead needs an allowlist of what it actually uses (`default-src 'self'; ...`) — that's why "CSP too strict" is a real pitfall there and a non-issue here.

**g) Cost of rubber-stamping informational findings.** Two costs. (1) A real signal drowns: some "informational" items are context-dependent real issues — our own 10049 is informational, yet on `/notes` it meant user data could sit in shared caches; blanket-accepting means nobody ever made that judgment. (2) It corrodes the process: "accepted" is supposed to mean *a human read this and decided, with a date*; once it means "clicked through", every future triage table is untrustworthy and others must redo the work. Reading them is cheap exactly because they're few — the discipline is the deliverable. The flip side is also real: our 10116 genuinely is noise, and saying *why* (it's about the scanner, which we pin deliberately) is what separates a decision from a shrug.

---

## Summary of changes

| Change | Finding(s) closed | Evidence |
|--------|-------------------|----------|
| Security-headers middleware + guarded test (`app/middleware.go`, `app/middleware_test.go`, `app/main.go`) | ZAP 10021, 10049, 90004 | before/after scans, failing-test proof |
| Builder image `golang:1.24-alpine` → `1.26-alpine` | 10 HIGH stdlib CVEs | `trivy-image.txt` (10 HIGH) → `trivy-image-after.txt` (0) |
| `HEALTHCHECK` instruction in Dockerfile | Trivy AVD-DS-0026 | config scan before (1 LOW) → after (clean) |
