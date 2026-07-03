# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

Trivy pinned to **`aquasec/trivy:0.59.1`**, ZAP to **`ghcr.io/zaproxy/zaproxy:2.16.1`**.
Scan artifacts in [`security/`](../security/).

---

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### The four scans

**1. Image** — [`security/trivy-image.txt`](../security/trivy-image.txt)

```text
quicknotes:lab6 (debian 13.5)        Total: 0  (HIGH: 0, CRITICAL: 0)   # OS layer clean (distroless)
quicknotes (gobinary)                Total: 11 (HIGH: 11, CRITICAL: 0)  # all Go 1.24.13 stdlib
```

**2. Filesystem** — [`security/trivy-fs.txt`](../security/trivy-fs.txt)

```text
.vagrant/machines/default/hyperv/private_key (secrets)
Total: 1 (HIGH: 1)  →  HIGH: AsymmetricPrivateKey
```

(Re-scanning the repo with `--skip-dirs .vagrant` is clean — the key is local
Vagrant state, not source.)

**3. Config** — [`security/trivy-config.txt`](../security/trivy-config.txt)

```text
app/Dockerfile (dockerfile)   Tests: 28 (SUCCESSES: 27, FAILURES: 1)
AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

No HIGH/CRITICAL misconfigurations.

**4. SBOM (CycloneDX)** — [`security/sbom.cdx.json`](../security/sbom.cdx.json) — 9 components
(debian 13.5, quicknotes, base-files, media-types, netbase, tzdata, **stdlib v1.24.13**, …).

### Triage — every HIGH/CRITICAL (a decision per finding)

| # | Finding | Scan | Sev | Disposition | Reason |
|---|---------|------|-----|-------------|--------|
| 1 | **11× Go stdlib CVEs** — CVE-2026-25679, -27145, -32280, -32281, -32283, -33811, -33814, -39820, -39836, -42499, -42504 (net/url, crypto/x509, crypto/tls, net, net/http2, net/mail, MIME) | image · gobinary | HIGH | **FIX** | All are Go **1.24 stdlib DoS** bugs fixed in Go 1.25.x. Fixed by bumping the Dockerfile builder `golang:1.24 → golang:1.25` (this branch). Re-scan → **0 HIGH/CRITICAL** ([`trivy-image-after.txt`](../security/trivy-image-after.txt)). |
| 2 | **AsymmetricPrivateKey** — `.vagrant/…/hyperv/private_key` | fs · secret | HIGH | **SUPPRESS (out of scope)** | The Vagrant-generated throwaway SSH key in **gitignored** local machine state (`.vagrant/`); regenerated every `vagrant up`, never committed or shipped in the image. Scanning the actual source (`--skip-dirs .vagrant`) is clean. |
| 3 | **AVD-DS-0026** — no `HEALTHCHECK` in Dockerfile | config | LOW | **ACCEPT** *(re-eval by 2026-12)* | Not HIGH/CRITICAL. The healthcheck is defined in `compose.yaml` — distroless has no shell for a Dockerfile `HEALTHCHECK`, so the binary's self-check runs at the compose layer. Re-evaluate if the image is ever run outside compose. |

The 11 stdlib CVEs are also a **reachability** story: they're DoS in TLS/mail/HTTP2
paths QuickNotes (a plain HTTP/1 JSON API — no TLS server, no mail, no multipart)
barely touches. We fixed them anyway because the fix is a one-line, zero-risk Go
bump — cheaper than justifying each acceptance.

### First 30 lines of the CycloneDX SBOM

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:b68e954b-5628-4bc5-bce0-6b04d68eeaa7",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-03T14:19:59+00:00",
    "tools": {
      "components": [
        { "type": "application", "group": "aquasecurity", "name": "trivy", "version": "0.59.1" }
      ]
    },
    "component": {
      "bom-ref": "7d90f63d-0a13-4be7-b3ec-2207b19e6fb2",
      "type": "container",
      "name": "quicknotes:lab6",
      "properties": [
        { "name": "aquasecurity:trivy:DiffID", "value": "sha256:065706fa87545e68426eb8f984f0f160603009f4ae7a26608bb63e6e587e98e2" },
        { "name": "aquasecurity:trivy:DiffID", "value": "sha256:151e3fc65a977c0d5876bcae809305d01e9a18d2fc52aecb4403096bcfe01799" }
      ]
    }
  }
}
```

### 1.3 Design questions

**a) CVE severity is one input — what else matters when triaging?**
- **Reachability** — do you actually call the vulnerable function? A CVE in a
  stdlib package your code never invokes is far lower risk (this is govulncheck's
  whole point). Most of our 11 were in TLS/mail/HTTP2 paths QuickNotes never hits.
- **Exploit availability** — is there a public PoC or active in-the-wild
  exploitation (CISA KEV)? A weaponized exploit jumps the queue.
- **Deployment context** — internet-facing vs internal-only, behind a WAF, data
  sensitivity. DoS on an internal tool ≠ RCE on a public payments API.
- **Impact class** — DoS vs info-leak vs RCE. All 11 here are availability (DoS),
  not code execution — lower urgency than a remote-code-exec at the same CVSS.
- Plus fix availability/cost and blast radius. CVSS severity is the *starting*
  question, not the answer.

**b) Why is a minimal (distroless) base the strongest single control?**
A vulnerability you don't ship can't be exploited. The vast majority of image
CVEs live in OS packages — shells, libc, package managers, coreutils. Distroless
static contains **none** of them, so there's almost nothing left to be vulnerable
(our OS layer scored 0 HIGH/CRITICAL). Shrinking the software present shrinks the
attack surface *and* the CVE surface at the same time — it eliminates whole
classes of findings at once instead of patching them one CVE at a time, which is
why it's the highest-leverage control.

**c) When is `.trivyignore` right, and when is it theater?**
Right when it records a **triaged, dated decision** — an ACCEPT with a re-eval
date, a documented FALSE POSITIVE, or a WATCH for a not-yet-fixed CVE. The file
keeps the scan green *without losing the signal*, because it points back to a
decision. It's **theater** when you dump findings you never read into it just to
turn CI green — that hides real risk, and an undated "accept forever" entry
becomes a permanent blind spot. The ignore must follow a decision, never replace
one.

**d) What future problem does having the SBOM today solve?**
The next **Log4Shell**. When a critical CVE drops in a ubiquitous component, the
first, time-critical question is *"am I affected — which services ship it, at
what version?"* Without an SBOM you're grepping build systems and guessing while
the clock runs (a big reason Log4Shell/Equifax responses were slow). With an SBOM
generated *today*, "do I ship log4j 2.14?" is an instant lookup against a list you
already have — turning days of frantic inventory into a one-minute query, which
is the difference between patching before and after you're breached.

---

## Task 2 — OWASP ZAP Baseline + Fix at Least One Finding

`zap-baseline.py` (passive only) against the running container. Reports:
[`security/zap-before.*`](../security/) and [`zap-after.*`](../security/).

### Triage — every ZAP finding

| ID | Finding | Risk | URL | Disposition |
|----|---------|------|-----|-------------|
| **10021** | X-Content-Type-Options Header Missing | Low | `/notes` (+ all) | **FIX** — added `X-Content-Type-Options: nosniff` in middleware. Re-scan: **gone**. |
| **10049** | Storable and Cacheable Content | Info | `/`, `/robots.txt`, `/sitemap.xml`, `/notes` | **FIX** — added `Cache-Control: no-store`. Re-scan: now reports *Non-Storable Content* (note data no longer cacheable). |
| **90004** | Insufficient Site Isolation Against Spectre | Low | `/notes` | **ACCEPT** *(re-eval by 2026-12)* — COOP/COEP/CORP are browser *document*-isolation headers; QuickNotes is a JSON API never embedded in a browser document, and COEP `require-corp` risks breaking legitimate cross-origin API clients. Low exposure; revisit if a browser front-end is added. |
| **10116** | ZAP is Out of Date | Low | `/` | **FALSE POSITIVE** — flags that the *ZAP scanner* is outdated, not a QuickNotes defect. Not an app finding. |

### The fix — one middleware, all routes

`Routes()` wraps the mux once with `securityHeaders()` ([`app/handlers.go`](../app/handlers.go)):

```go
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}
```

Guarded by a unit test that fails if the middleware is removed
([`app/handlers_test.go`](../app/handlers_test.go) →
`TestSecurityHeaders_PresentOnEveryResponse`).

### Before / after (finding proven gone)

```text
# BEFORE (zap-before.json)                    # AFTER (zap-after.json)
10021 X-Content-Type-Options Header Missing    ← gone
10049 Storable and Cacheable Content           10049 Non-Storable Content   (fixed)
90004 Spectre site isolation                   90004 Spectre site isolation (accepted)
10116 ZAP is Out of Date                        10116 ZAP is Out of Date     (false positive)

$ curl -sD- -o/dev/null localhost:8080/notes | grep -iE 'x-content|content-security|cache-control'
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'none'
Cache-Control: no-store
```

### 2.5 Design questions

**e) Why a middleware and not per-handler header sets?**
A middleware wraps the router **once**, so the headers land on *every* response —
success, error, 404, and any route added later — with zero duplication. Per-handler
`Header().Set` is error-prone: you forget one handler, a new route ships without
them, or an error path skips them, and the header silently vanishes on some
responses. Middleware makes "miss a route" structurally impossible and gives one
testable source of truth.

**f) `Content-Security-Policy: default-src 'none'` — what breaks, why OK here?**
`default-src 'none'` forbids the page from loading *anything* — no scripts,
styles, images, fonts, frames, or `fetch`/XHR. That **breaks a website**, which
must load its own JS/CSS/assets. QuickNotes is a **JSON API**: it serves no
HTML/JS/CSS and is consumed by API clients, not rendered as a browser document —
so there's nothing for the CSP to break. The strictest policy is free hardening
for an API (it just says "if a browser ever renders this, load nothing"), whereas
a website must allowlist exactly what its pages legitimately load.

**g) Cost of marking all informational findings "accepted" without reading them?**
You lose the signal. Informational findings are mostly noise, but occasionally one
hides a real issue (an info-leak, a cacheable *sensitive* response, a stray debug
endpoint — exactly like 10049 here, which was worth fixing). Rubber-stamping
"accepted" on all of them (1) trains you to ignore the whole category, so you miss
the real one when it comes; (2) creates undated blanket acceptances that bury risk
permanently; (3) destroys the audit trail of *why* each was fine. "Informational,
no action" is a legitimate disposition — but only as a **read** decision, not a
reflex.

---

## Bonus — `govulncheck` as a CI PR Gate

Not attempted (Task 1 + Task 2 completed for 10/10).
