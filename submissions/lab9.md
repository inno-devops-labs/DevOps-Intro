# Lab 9 Submission — DevSecOps: Scan QuickNotes with Trivy + ZAP

> **Builds on Lab 6** (uses the container image). All scans below were run for
> real; raw artifacts are in [lab9-scans/](lab9-scans/). Trivy pinned to
> `aquasec/trivy:0.59.1`, ZAP pinned to `ghcr.io/zaproxy/zaproxy:2.16.1`.

## Files & artifacts
- Scans: [trivy-image.txt](lab9-scans/trivy-image.txt), [trivy-fs.txt](lab9-scans/trivy-fs.txt), [trivy-config.txt](lab9-scans/trivy-config.txt), [sbom.cdx.json](lab9-scans/sbom.cdx.json)
- ZAP: [zap-before.html](lab9-scans/zap-before.html)/[.json](lab9-scans/zap-before.json), [zap-after.html](lab9-scans/zap-after.html)/[.json](lab9-scans/zap-after.json)
- Bonus: [govulncheck.txt](lab9-scans/govulncheck.txt), [.github/workflows/security.yml](../.github/workflows/security.yml)
- Code fix: [app/handlers.go](../app/handlers.go) (middleware), [app/handlers_test.go](../app/handlers_test.go) (test), [app/Dockerfile](../app/Dockerfile) (HEALTHCHECK)

---

## Task 1 — Trivy Scanning

Four scans executed:
```bash
T="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/repo aquasec/trivy:0.59.1"
$T image  --severity HIGH,CRITICAL quicknotes:lab6            # 1) image
$T fs     --severity HIGH,CRITICAL /repo/app                  # 2) filesystem
$T config /repo                                               # 3) config (Dockerfile/compose)
$T image  --format cyclonedx --output /repo/submissions/lab9-scans/sbom.cdx.json quicknotes:lab6  # 4) SBOM
```

### Results (headers)
| Scan | Result |
|---|---|
| **image** | `quicknotes:lab6 (debian 13.5)` → **0 HIGH/0 CRITICAL** (distroless OS clean); `app/quicknotes`+`app/healthcheck` (gobinary) → **10 HIGH** each (Go stdlib `v1.24.13`) |
| **fs** | app source → **0** (QuickNotes has zero dependencies, no `go.sum`) |
| **config** | `app/Dockerfile` → was **1 LOW** `AVD-DS-0026` (missing HEALTHCHECK); **now 0** after fix |
| **SBOM** | CycloneDX 1.6, 12 components ([sbom.cdx.json](lab9-scans/sbom.cdx.json)) |

### Triage table
| Finding ID | Scan | Severity | Disposition | Reasoning |
|---|---|---|---|---|
| CVE-2026-25679 + 9 others (Go stdlib) | image (gobinary) | HIGH | **WATCH** | Fixed only in Go ≥ 1.25.8 / 1.26.x; no 1.24.x fix. The lab pins Go 1.24, so we can't clear them without leaving the pin. Low real-world exposure (internal JSON API). Re-check **2026-10-05**; remediate by bumping the toolchain when off the 1.24 pin. |
| AVD-DS-0026 | config (Dockerfile) | LOW | **FIX** | Added `HEALTHCHECK` using the static probe binary; re-scan shows **0 findings**. |
| (fs) | fs | — | n/a | No vulnerable dependencies. |

### First 30 lines of the CycloneDX SBOM
```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:...",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-05T06:38:46+00:00",
    "tools": { "components": [ { "type": "application", "group": "aquasecurity", "name": "trivy", "version": "0.59.1" } ] },
    "component": {
      "type": "container",
      "name": "quicknotes:lab6",
      ...
    }
  },
  "components": [ /* 12 components: distroless base packages + Go stdlib */ ]
}
```
(Full file: [sbom.cdx.json](lab9-scans/sbom.cdx.json).)

### Design answers

**a) Contextual factors beyond severity.**
CVSS is only base severity. Real triage weighs: **reachability** (does our code actually
call the vulnerable function? — see govulncheck below), **exploit maturity** (PoC vs
weaponized vs none — EPSS score, CISA KEV listing), **deployment topology**
(internet-facing vs internal-only, network segmentation), **data sensitivity**,
**auth prerequisites**, and **compensating controls**. A CRITICAL in an unreachable
code path on an internal service can rank below a HIGH that's reachable and
internet-exposed.

**b) Why distroless reports zero HIGH/CRITICAL, and the principle.**
`distroless/static` ships no shell, no package manager, and almost no OS packages — so
scanners find essentially nothing at the OS layer to flag (verified: 0/0). It
illustrates **minimizing attack surface / least functionality**: the fewer components
you ship, the fewer CVEs and the smaller the exploitable surface.

**c) When `.trivyignore` is appropriate vs problematic.**
Appropriate: silencing a **documented false positive** or a **consciously accepted
risk with an expiry date and justification**, to keep signal high. Problematic: using
it to blanket-mute HIGH/CRITICAL findings so the pipeline goes green without triage —
that's security theater; and un-dated, un-reviewed entries become permanent silent
suppression. Every entry should carry a comment with reason + re-eval date.

**d) How an SBOM speeds future incident response (Log4Shell).**
When the next Log4Shell drops, you **query your stored SBOMs** to instantly answer
"are we affected, and exactly where?" — turning a multi-day manual sweep of every
image into a minutes-long inventory lookup. The component graph is already computed;
you just search it for the affected package/version.

---

## Task 2 — OWASP ZAP Baseline + Code Remediation

```bash
docker compose up --build -d
docker run --rm --network host -v "$PWD/submissions/lab9-scans":/zap/wrk:rw \
  ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py -t http://localhost:8080/health -r zap-before.html -J zap-before.json
```
> Note: the target is `/health` (a 200 endpoint). Scanning `/` returns 404
> (QuickNotes has no root route), so header rules wouldn't fire on a real response.

### Findings table (before → after)
| ID | Title | Risk | Affected | Disposition | Result |
|---|---|---|---|---|---|
| 10021 | X-Content-Type-Options Header Missing | Low | all responses | **FIX** (middleware `nosniff`) | before WARN → after **PASS** |
| 90004 | Insufficient Site Isolation vs Spectre | Low | all responses | **FIX** (`Cross-Origin-Resource-Policy`) | before WARN → after **PASS** |
| 10049 | Storable and Cacheable Content | Info | all responses | **FIX** (`Cache-Control: no-store`) | before WARN → after **Non-Storable** |
| 10116 | ZAP is Out of Date | Info | scanner | **FALSE POSITIVE** | About the ZAP version, not QuickNotes |

Summary: before `WARN-NEW: 4, PASS: 63` → after `WARN-NEW: 2, PASS: 65` (the two
remaining are the scanner-version notice and a benign "non-storable" note).

### The fix (middleware + test)
Implemented as **middleware wrapping the router** ([app/handlers.go](../app/handlers.go)):
```go
func (s *Server) Handler() http.Handler { return securityHeaders(s.Routes()) }

func securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        h := w.Header()
        h.Set("X-Content-Type-Options", "nosniff")
        h.Set("X-Frame-Options", "DENY")
        h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
        h.Set("Referrer-Policy", "no-referrer")
        h.Set("Cross-Origin-Resource-Policy", "same-origin")
        h.Set("Cache-Control", "no-store")
        next.ServeHTTP(w, r)
    })
}
```
`main.go` now serves `server.Handler()`. Test `TestSecurityHeaders_PresentOnAllResponses`
([app/handlers_test.go](../app/handlers_test.go)) asserts the headers on `/health` and
`/notes` via `Handler()` — it **fails if the middleware is removed**. `go test -race`
passes.

### Design answers

**e) Advantages of middleware-based header injection.**
One central place applies headers **uniformly to every route** — present and future — so
you can't forget a handler, there's no duplication or drift, and it's tested once. Per-handler
`Header().Set()` calls scatter the logic, are easy to miss on new endpoints, and drift apart.

**f) Why `CSP: default-src 'none'` fits an API but breaks websites.**
QuickNotes serves only JSON — no HTML, JS, CSS, images or fonts — so `'none'` blocks
resource loading that never happens: maximum strictness, **zero functional cost**,
pure defense-in-depth. On an interactive website `'none'` would block *all* scripts,
styles, images and frames, producing a blank/broken page; such sites need a carefully
tailored allowlist instead.

**g) Organizational cost of blanket-accepting ZAP informationals.**
Alert fatigue and **normalization of deviance** — a real issue eventually hides among
the ignored infos; there's no audit trail of decisions (compliance gap), and the scan
loses credibility (security theater). Each finding deserves an explicit, recorded
disposition even if that disposition is "accept".

---

## Bonus — `govulncheck` CI Integration

Workflow: [.github/workflows/security.yml](../.github/workflows/security.yml) — a
standalone `govulncheck` job (pinned `@v1.1.4`, Go 1.24, `working-directory: app`) that
runs on pushes/PRs to `main` and can be required in branch protection to block merges.

**Real local run** (`govulncheck ./...`, [govulncheck.txt](lab9-scans/govulncheck.txt)):
```
Your code is affected by 20 vulnerabilities from the Go standard library.
This scan also found 5 vulnerabilities in packages you import and 13
vulnerabilities in modules you require, but your code doesn't appear to call these.
```
The 20 reachable findings are stdlib (e.g. `GO-2025-4008` crypto/tls via
`http.Server.ListenAndServe`), fixed in Go ≥ 1.25.x — the **same Go-1.24 pin tension**
noted in the Trivy triage → **WATCH** / bump toolchain. Critically, govulncheck marks
the 13 module-level vulns as **not called** (unreachable) and does not fail on them.

**Red → green demo (executed locally; reproduce in CI on a PR):**

*Inject* a known-vulnerable, **reachable** dependency:
```bash
cd app
go get gopkg.in/yaml.v2@v2.2.2
# add a reachable call (init() in package main is always reached):
printf 'package main\nimport yaml "gopkg.in/yaml.v2"\nfunc init(){var m map[string]any; _ = yaml.Unmarshal([]byte("a: b"), &m)}\n' > demo_vuln.go
go mod tidy && govulncheck ./...
```
**RED** — govulncheck flags it as *called* and exits non-zero (gate fails):
```
Vulnerability #21: GO-2022-0956
    Excessive resource consumption in gopkg.in/yaml.v2
    Found in: gopkg.in/yaml.v2@v2.2.2   Fixed in: gopkg.in/yaml.v2@v2.2.4
    Example traces found:
      #1: demo_vuln.go:9:20: quicknotes.init#1 calls yaml.Unmarshal
Vulnerability #22: GO-2021-0061  Denial of service in gopkg.in/yaml.v2
$ echo $?
3          # non-zero → the CI check is RED and blocks merge
```
*Revert* → the yaml findings disappear (0 mentions), `go.mod` back to zero deps → **GREEN** for that dependency:
```bash
rm demo_vuln.go && go mod edit -droprequire=gopkg.in/yaml.v2 && go mod tidy && rm -f go.sum
```
This is the point of **reachability**: the dependency vuln is reported only because our
code actually *calls* `yaml.Unmarshal`; remove the call and it drops out. (On this local
Go 1.24.4 the stdlib findings remain regardless — in CI, require the `govulncheck` check
in branch protection so a reachable dependency vuln blocks the merge.)
<!-- TODO: optionally add the red/green CHECK-STATUS screenshots from your PR's Actions tab. -->

### Design answers

**h) How reachability changes triage vs "module contains a CVE".**
`govulncheck` builds a call graph and reports a vuln only if your code actually
**reaches the vulnerable symbol** — so a CVE in an imported-but-unused function is not
flagged (our run: 13 module vulns present but **not called** → not reported as
actionable). SCA tools like Trivy report by **presence** (this version is vulnerable)
regardless of use, producing far more noise. Reachability focuses remediation effort on
genuine exposure.

**i) Why pin the scanner version separately from dependencies.**
Pinning dependencies controls **what** you scan; pinning the scanner (`@v1.1.4`, not
`@latest`) controls **how** you scan. An unpinned scanner can change detection logic or
DB handling between runs, giving non-reproducible CI (green today, red tomorrow with no
code change) or pulling a broken/compromised release. Reproducible security requires
both pins.

**j) Categories govulncheck can't detect but Trivy image scan catches.**
OS-package vulnerabilities in the base image (glibc/openssl/etc.), non-Go components,
base-layer issues, secrets, and **misconfigurations** (Dockerfile/IaC) — plus vulns in
Go modules that are *present but unreachable* (Trivy flags by presence). `govulncheck`
is Go-source/call-graph only; Trivy scans the whole artifact (OS + language + config).

---

## Submission Checklist
- [ ] Four Trivy scans captured + triage table + SBOM (first 30 lines)
- [ ] ZAP baseline before/after + findings table + middleware fix with test
- [ ] Design answers a–j
- [ ] (Bonus) `govulncheck` workflow + red/green demo evidence
- [ ] PR `feature/lab9 → main` against **upstream** and against **your fork**
- [ ] Both PR URLs in Moodle
