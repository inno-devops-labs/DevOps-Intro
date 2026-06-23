# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

Ran for real with Docker 29 (WSL engine). Trivy pinned to `aquasec/trivy:0.59.1`,
ZAP to `ghcr.io/zaproxy/zaproxy:2.16.1`, govulncheck to `@v1.1.4`. Scan artifacts in
[`submissions/lab9-artifacts/`](lab9-artifacts/).

---

## Task 1 — Trivy: image + filesystem + config + SBOM

| Scan | Command | Result |
|------|---------|--------|
| Image | `trivy image --severity HIGH,CRITICAL quicknotes:lab6` | OS (debian): **0**; Go binaries `qn` + `healthcheck`: **14 unique HIGH** (0 CRITICAL) |
| Filesystem | `trivy fs --severity HIGH,CRITICAL .` | **1 HIGH** — a private key secret |
| Config | `trivy config .` | **0 HIGH/CRITICAL** misconfigs |
| SBOM | `trivy image --format cyclonedx` | CycloneDX JSON, 12 components |

### Triage — every HIGH/CRITICAL

| Finding | Scan | Disposition | Reasoning / evidence |
|---------|------|-------------|----------------------|
| 14× Go **stdlib** HIGH in `qn` + `healthcheck` (`CVE-2026-25679/27142/27145/32280/32281/32283/33811/33814/39820/39823/39825/39836`, `CVE-2026-42499/42504`) | image | **FIX** | Confirmed *reachable* by govulncheck (QuickNotes calls `net/http`, `encoding/json`, …). Fixed by bumping the builder `golang:1.24 → 1.26` in [`app/Dockerfile`](../app/Dockerfile). Re-scan → `Total: 0 (HIGH:0, CRITICAL:0)` (see `trivy-image-after.txt`). |
| `AsymmetricPrivateKey` — `.vagrant/machines/default/virtualbox/private_key` | fs | **FALSE POSITIVE** | This is the Vagrant-generated *insecure* local key; `.vagrant/` is gitignored and never committed or shipped in the image. Not a secret leak. |
| (no HIGH/CRITICAL misconfigs) | config | — | Dockerfile already sets `USER nonroot`; compose has `cap_drop: [ALL]`, `read_only`, `no-new-privileges`. |

**Before → after the FIX (image scan):**
```
golang:1.24 build:  qn 14 HIGH, healthcheck 14 HIGH   (Go stdlib)
golang:1.26 build:  Total: 0 (HIGH: 0, CRITICAL: 0)   ← all cleared
```

SBOM head (`quicknotes.sbom.cdx.json`): CycloneDX 1.x, `metadata.component =
quicknotes:lab6`, 12 components (the image layers + the Go stdlib + the app).

### Design questions

**a) CVE severity is one input — what else matters?** Reachability (is the
vulnerable function actually called — govulncheck answers this), exploit
availability (public PoC / is it in CISA KEV), and deployment context
(internet-facing vs internal, authenticated, behind a WAF, what data it touches,
network vs local attack vector). A CRITICAL in dead code on an internal service is
lower real risk than a reachable HIGH on an internet-facing one.

**b) Why is the minimal base the strongest single control?** Most image CVEs come
from OS packages you don't even use — libc, openssl, a shell, a package manager.
Distroless removes them, so the vulnerabilities are *gone*, not just patched: you
can't be vulnerable to what isn't installed, and there's no shell for an attacker
to pivot with. That's prevention, and it's why the OS scan shows 0.

**c) When is `.trivyignore` right vs theater?** Right: a *documented, dated*
accepted risk or a confirmed false positive, with the reason in version control
and a re-evaluation date. Theater: silencing findings you don't want to deal with,
with no reason or date — it just hides risk and rots into a permanent blind spot.

**d) What future problem does the SBOM solve?** Inventory *before* the incident.
When the next Log4Shell drops, you answer "are we affected, and where?" in seconds
by querying the SBOM for the component+version across the fleet — instead of
frantically re-inspecting every image under pressure. You can't grep an inventory
you don't have.

---

## Task 2 — OWASP ZAP baseline + fix one finding

`zap-baseline.py` (passive) against a running QuickNotes container.

**Before:** `FAIL-NEW: 0, WARN-NEW: 2` — `Storable and Cacheable Content [10049]`
(no `Cache-Control`) and `ZAP is Out of Date [10116]`. (The CSP / X-Frame /
clickjacking rules *passed* because QuickNotes serves `application/json`, not HTML,
so those rules don't apply.)

| ZAP finding | Risk | Where | Disposition |
|-------------|------|-------|-------------|
| Storable and Cacheable Content [10049] | Low/Info | all responses | **FIX** — add `Cache-Control: no-store` (below) |
| ZAP is Out of Date [10116] | Info | scanner itself | **ACCEPT** — about the ZAP version, not QuickNotes; not an app issue |

### The fix — security-headers middleware (+ test)

Added `securityHeaders` middleware in [`app/handlers.go`](../app/handlers.go) that
wraps the whole router in `Routes()` (one place, every route), setting
`Cache-Control: no-store`, `X-Content-Type-Options: nosniff`, `X-Frame-Options:
DENY`, `Content-Security-Policy: default-src 'none'`, `Referrer-Policy:
no-referrer`. Guarded by `TestSecurityHeaders_PresentOnAllRoutes` in
[`app/handlers_test.go`](../app/handlers_test.go), which goes through `Routes()` so
it fails if the middleware is removed. `go test ./...` passes.

**After (re-scan of the rebuilt image):** `[10049]` flips from *"Storable and
Cacheable Content"* to *"Non-Storable Content"* (riskcode 0, informational) — i.e.
the cacheable-content finding is **gone**; only the scanner-version note remains.
Headers verified live on `/health`:
```
Cache-Control: no-store
Content-Security-Policy: default-src 'none'
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

### Design questions

**e) Why middleware, not per-handler?** One place that applies uniformly to every
route — you can't forget a handler, values can't drift, and it's trivial to test
and audit. Sprinkling `Header().Set` across handlers guarantees one gets missed.

**f) `Content-Security-Policy: default-src 'none'` — what breaks, why OK here?**
It blocks loading *all* sub-resources (scripts, styles, images, fonts, frames,
XHR), so a real **website** would render blank. QuickNotes is a JSON **API**:
browsers don't execute its responses as documents and it loads nothing, so `'none'`
is free defense-in-depth (if a response were ever mis-rendered as HTML, nothing
runs). A website needs an allowlist of the sources it actually uses.

**g) Cost of "accept all" on informational findings?** A real issue can hide in
the noise — an info-level finding that's exploitable in your context, or a genuine
problem mislabeled. Rubber-stamping them all also trains you to ignore the whole
report, so next time you miss the one that mattered. Triage = read each once.

---

## Bonus — `govulncheck` as a CI PR gate

Added a pinned `vuln` job to the Lab 3 workflow ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)):
`go install golang.org/x/vuln/cmd/govulncheck@v1.1.4` then `govulncheck ./...` in
`app/`, on Go 1.24, its own required status check.

**Clean run:** `No vulnerabilities found.` (matches the fixed, Trivy-0 image.)

**Catches a bad dep (demonstrated locally):** added `gopkg.in/yaml.v2@v2.2.2` with
a reachable call, govulncheck flagged it and pointed at the call site, then I
reverted:
```
Vulnerability #1: GO-2022-0956  Excessive resource consumption in gopkg.in/yaml.v2
    Found in: gopkg.in/yaml.v2@v2.2.2   Fixed in: v2.2.4
      vuln_demo.go:7:20: quicknotes.init#1 calls yaml.Unmarshal
Vulnerability #2: GO-2021-0061  Denial of service in gopkg.in/yaml.v2
```

### Design questions

**h) Reachability vs presence.** "Module has a CVE" = the vulnerable package is
somewhere in your dependency tree (Trivy/SCA). "We don't call the affected
function" = govulncheck's call-graph analysis proves the vulnerable symbol is never
reached from your code, so it isn't exploitable in your binary. Effect on workload:
govulncheck filters out the large majority of present-but-unreachable CVEs, so you
triage a handful of real ones instead of hundreds. (Here: 14 stdlib CVEs *present*
in the 1.24 build, all reachable; after the toolchain bump, govulncheck = 0.)

**i) Why pin the scanner version?** Determinism and supply chain. `@latest` lets
the tool change under you — a gate that's green today could fail tomorrow with no
code change (flaky), and a compromised `@latest` would run untrusted code in CI.
Pinning makes the gate reproducible and auditable; you upgrade on purpose.

**j) What govulncheck won't catch.** It only understands Go. It misses OS-package
and system-library CVEs in the image (libc, openssl, CA bundles), non-Go
components, base-image issues, and misconfigurations — exactly what Trivy's image
and config scans cover. They're complementary: govulncheck = reachable Go-code
vulns; Trivy = everything in the image + config.

---

## Summary

| Task | Result |
|------|--------|
| 1 — Trivy ×4 + SBOM + triage | image 14 stdlib HIGH → **FIX (Go 1.26) → 0**; fs secret = false positive; config clean; CycloneDX SBOM |
| 2 — ZAP + code fix | cacheable-content finding fixed via tested security-headers middleware; before/after proven |
| Bonus — govulncheck gate | pinned CI job; clean = no vulns; demonstrated catching a reachable bad dep |
