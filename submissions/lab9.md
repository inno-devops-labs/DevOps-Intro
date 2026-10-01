# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

- Student: Arina Nikolaeva (Nik-ari-ai)
- Fork: https://github.com/Nik-ari-ai/DevOps-Intro
- Branch: feature/lab9

Scan artifacts are committed under `security/` (trivy-image.txt, trivy-fs.txt, trivy-config.txt, sbom.cdx.json, zap-before.{html,json}, zap-after.{html,json}). Trivy pinned to 0.74.0.

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### Scan results (top lines)

**1) Image** — `trivy image --severity HIGH,CRITICAL quicknotes:lab6`
```
Detected OS family="debian" version="13.6"  (base pkgs: 6)  -> 0 vulnerabilities
gobinary /quicknotes    -> 19 (HIGH: 19, CRITICAL: 0)
gobinary /healthcheck   -> 19 (HIGH: 19, CRITICAL: 0)
```
All HIGH findings are Go **stdlib** CVEs (built on go1.24.13); the distroless base itself is clean (0).

**2) Filesystem** — `trivy fs --severity HIGH,CRITICAL .`
```
app/go.mod (gomod)  ->  0 vulnerabilities, 0 secrets
```

**3) Config** — `trivy config .`
```
app/Dockerfile (dockerfile): 27 tests, 26 pass, 1 fail
DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

**4) SBOM** — `trivy image --format cyclonedx` → `security/sbom.cdx.json` (CycloneDX 1.7). First lines:
```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "metadata": { "component": { "type": "container", "name": "quicknotes:lab6" } }
}
```

### Triage — every HIGH/CRITICAL (+ the config LOW)

| Finding | Severity | Disposition | Reason |
|---|---|---|---|
| 19× Go stdlib CVEs in `/quicknotes` and `/healthcheck` (CVE-2026-25679, -27145, -32280/1/3, -33811/4/8, -39820/1/2/6, -42499, -42504, -56853/8/9/60/62) | HIGH (0 CRITICAL) | **ACCEPT** (re-eval by 2026-12-12) | All are Go stdlib DoS/XSS bugs, fixed in later Go patch releases (1.25.x / 1.26.x). Reachability is low for QuickNotes — it is a small plaintext HTTP/1.1 JSON API that does not use `html/template`, `net/mail`, `encoding/xml`, `mime`, or HTTP/2 (where most of these live). A single Go-toolchain bump clears all 19; `govulncheck` (bonus) is the right tool to confirm which are actually reachable. |
| debian base packages | — | — | 0 findings (value of the distroless base). |
| `app/go.mod` (fs) | — | — | 0 findings (no third-party deps, no `go.sum`). |
| DS-0026 no HEALTHCHECK in Dockerfile | LOW | **ACCEPT** | The health check is defined at the orchestration layer (`compose.yaml` runs the `/healthcheck` binary), which is where it belongs for this deployment; a Dockerfile `HEALTHCHECK` would duplicate it. |

### 1.3 Design questions

**a) What besides CVE severity matters when triaging?**
Reachability (is the vulnerable function actually called from our code path — the `govulncheck` idea), exploit availability (is there a public PoC / is it in CISA's KEV / actively exploited), deployment context (is the component exposed to untrusted input, its network position, and whether we even use the affected feature), and the asset's value / blast radius. A CRITICAL in code we never call is less urgent than a HIGH on a directly-exposed, reachable path.

**b) Why is the minimal base the strongest single security control?**
Most image CVEs come from OS packages, a shell, and utilities that a full base image ships. A distroless/scratch base has none of them — no shell, no package manager, no libc (for static) — so the entire class of package CVEs and the shell-pivot attack surface disappear at once. One decision removes whole categories of findings; you cannot be vulnerable to a package you do not ship.

**c) When is `.trivyignore` right vs security theater?**
Right: a documented, **dated** acceptance of a specific finding you have actually analysed — a genuine false positive, an unreachable path, or an accepted risk with a re-evaluation date. That keeps the signal clean. Theater: blanket-silencing findings you have not read just to turn the scan green — it hides real risk. The difference is whether each entry has a reasoned, dated decision behind it.

**d) What future problem does having the SBOM today solve?**
When the next Log4Shell-class CVE drops, the first question under pressure is "are we affected, and where?" With an SBOM already generated you answer in seconds by querying your component inventory across every build, instead of grepping every repo and image during an incident. It turns "do we ship component X?" from a multi-day scramble into a lookup.

## Task 2 — OWASP ZAP Baseline + Fix

ZAP pinned to `ghcr.io/zaproxy/zaproxy:2.16.0`, `zap-baseline.py` (passive only) against a real 200 endpoint (`/notes`).

### Triage — every ZAP finding (before)

| ID | Name | Risk | URL | Disposition | Reason |
|---|---|---|---|---|---|
| 10021 | X-Content-Type-Options Header Missing | Low | /notes | **FIX** | Fixed in code (middleware); proven gone in the after-scan. |
| 10049 | Storable and Cacheable Content | Info | /notes, 404s | **ACCEPT** | `GET /notes` is public, non-sensitive data; caching it is acceptable. Would add `Cache-Control: no-store` if it ever served per-user data. |
| 10116 | ZAP is Out of Date | Low | — | **FALSE POSITIVE** | This is about the ZAP scanner's own version, not QuickNotes — not an application finding. |
| 90004 | Insufficient Site Isolation Against Spectre | Low | /notes | **ACCEPT** (re-eval by 2026-12-12) | Wants cross-origin isolation headers (COOP/COEP/CORP). Low value for a plaintext JSON API not embedded in a browser context with secrets; candidate for a future `Cross-Origin-Resource-Policy` addition. |

X-Frame-Options and CSP were **not** flagged because ZAP only applies those rules to `text/html` responses; `/notes` returns JSON, so they are correctly not raised for an API (the middleware still sets them defensively).

### The fix (middleware + test)

`app/handlers.go` — `Routes()` now returns `securityHeaders(mux)`:
```go
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		h.Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}
```

`app/handlers_test.go` — `TestSecurityHeaders_PresentOnAllRoutes` asserts all four headers on `/health` and `/notes`. Guard check: with the middleware bypassed the test fails (`X-Content-Type-Options = "", want "nosniff"`), so the fix is genuinely tested, not decorative.

### Before / after evidence

Headers on `/notes` after rebuild:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer
```

ZAP alert list:
```
before:  Low — X-Content-Type-Options Header Missing   <-- present
         Info — Storable and Cacheable Content
         Low — Insufficient Site Isolation (Spectre)
         Low — ZAP is Out of Date
after:   (X-Content-Type-Options Header Missing GONE)   <-- fixed
         Info — Storable and Cacheable Content
         Low — Insufficient Site Isolation (Spectre)
         Low — ZAP is Out of Date
```
WARN-NEW dropped 4 → 3, PASS 63 → 64. Full reports: `security/zap-before.html`, `security/zap-after.html`.

### 2.5 Design questions

**e) Why a middleware, not per-handler header sets?**
A middleware wraps the whole router, so the headers apply uniformly to every route — existing and future — from one place. There is one thing to test, no route can silently miss the headers, and adding a route doesn't require remembering to set them. Per-handler `Header().Set` is duplicated, drift-prone, and can't be guaranteed by a single test.

**f) `Content-Security-Policy: default-src 'none'` — what it breaks; why OK for the API but not a website.**
`default-src 'none'` blocks the page from loading any resource — scripts, styles, images, fonts, frames, fetch/XHR — so a browser rendering it as a page gets a blank, non-functional page. That's fine for QuickNotes: it's a JSON API consumed by programs, not rendered as a web page, so there are no resources to load. A website needs its own scripts/styles/images, so `'none'` would break it; a real site must allowlist the origins it actually uses.

**g) Cost of marking all informational findings "accepted" without reading them.**
You can bury a real issue in the noise — an actual finding gets rubber-stamped along with the truly-informational ones, so triage stops being a control and becomes a checkbox. Accepting without reading also leaves no understanding and no re-eval date, so the risk quietly persists. The value of triage is the reading, not the label.

## Bonus — `govulncheck` CI gate

Not attempted in this submission.
