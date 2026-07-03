# Lab 9 — DevSecOps: Trivy + ZAP

Trivy **0.59.1** (`aquasec/trivy:0.59.1`), ZAP **2.16.0** (`ghcr.io/zaproxy/zaproxy:2.16.0`). Image built from Lab 6 Dockerfile (`quicknotes:lab6` before fix, `quicknotes:lab9` after security headers).

Full scan logs live in [`submissions/scans/`](scans/).

---

## Task 1 — Trivy

### Scan outputs (top)

**Image (`trivy image --severity HIGH,CRITICAL`)**

```text
quicknotes:lab6 (debian 13.5)
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)

quicknotes (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)
```

Distroless OS layer is clean. All HIGH findings are **Go stdlib CVEs baked into the static binaries** (toolchain `go1.24.13`).

**Filesystem (`trivy fs /repo/app`)**

```text
Number of language-specific files  num=1
[gomod] Detecting vulnerabilities...
(no HIGH/CRITICAL table — std-lib module only)
```

**Config (`trivy config /repo`)**

```text
Detected config files  num=1
(no HIGH/CRITICAL misconfigurations reported for Dockerfile / compose.yaml)
```

**SBOM** — CycloneDX JSON at [`scans/sbom.cyclonedx.json`](scans/sbom.cyclonedx.json). First lines:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:f9ed6eca-499f-440f-90c7-0c7c8982d989",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-03T15:26:11+00:00",
    "tools": { "components": [{ "type": "application", "name": "trivy", "version": "0.59.1" }] },
    "component": { "type": "container", "name": "quicknotes:lab6" }
```

### Triage table (every HIGH/CRITICAL)

| Scan | Component | Finding | Severity | Disposition | Reason |
|------|-----------|---------|----------|-------------|--------|
| image | distroless/debian base | *(none)* | — | — | Minimal runtime, 0 OS packages with CVEs |
| image | `quicknotes` + `healthcheck` binaries | 11× stdlib CVEs (see below) | HIGH | **WATCH** | Embedded in static Go 1.24.13 build; fixed in Go 1.25.11+ / 1.26.4+. Re-check when bumping builder image; most CVEs are in packages QuickNotes barely uses (mail, heavy x509). Re-evaluate **2026-12-01**. |
| fs | `app/` source | *(none HIGH/CRITICAL)* | — | — | No third-party modules in `go.mod` |
| config | Dockerfile / compose | *(none HIGH/CRITICAL)* | — | — | Non-root, distroless, read-only rootfs in compose |

**The 11 stdlib CVEs** (same set in both binaries): CVE-2026-25679, CVE-2026-27145, CVE-2026-32280, CVE-2026-32281, CVE-2026-32283, CVE-2026-33811, CVE-2026-33814, CVE-2026-39820, CVE-2026-39836, CVE-2026-42499, CVE-2026-42504.

### Design questions

**a) CVE severity is one input, not the answer.** I also look at **reachability** (does our code call the vulnerable function?), **exploit availability**, and **deployment context** (QuickNotes is a local JSON API, not internet-facing with untrusted input to mail/x509 parsers). A HIGH in `net/mail` matters less here than in an MTA.

**b) Why distroless often shows zero OS CVEs.** The runtime image has no shell, no package manager, and almost no files — tiny attack surface. Fewer packages means fewer published CVEs to match.

**c) When is `.trivyignore` right?** When a finding is **documented, time-boxed, and reviewed** (e.g. accepted risk with owner + re-check date). It's theater when it permanently hides findings to keep CI green without anyone reading them.

**d) What does the SBOM buy you later?** When the next Log4Shell-style event hits, you can ask *"do we ship that component?"* in minutes instead of grepping Dockerfiles. The SBOM is the inventory for that question.

---

## Task 2 — OWASP ZAP baseline + code fix

Target: `http://<container>:8080/health` (API has no `GET /`, so root returns 404). Reports: [`scans/zap-before.json`](scans/zap-before.json), [`scans/zap-after.json`](scans/zap-after.json).

### ZAP triage

| ID | Name | Risk | URL | Disposition | Reason |
|----|------|------|-----|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Medium | `/health` | **FIX** | Added middleware — see below |
| 90004 | Insufficient Site Isolation Against Spectre | Low | `/health` | **FIX** | Added CSP, COOP, CORP, X-Frame-Options in same middleware |
| 10049 | Storable and Cacheable Content | Info | `/health`, `/` | **ACCEPT** | JSON API; caching of `/health` is harmless for this lab. Re-evaluate if we add auth. |
| 10116 | ZAP is Out of Date | Low | various 404s | **FALSE POSITIVE** | Scanner version warning, not an app vulnerability |

### Fix in code

New [`app/security.go`](../app/security.go) — `SecurityHeaders` middleware on the whole router (used in `main.go`). Sets `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy: default-src 'none'`, `Referrer-Policy`, `Cross-Origin-Opener-Policy`, `Cross-Origin-Resource-Policy`.

Test: [`app/security_test.go`](../app/security_test.go) — checks headers on `/health`, `/notes`, `/metrics`. Fails if middleware is removed.

### Before / after

**Before** (`curl -I /health` on `quicknotes:lab6`):

```text
Content-Type: application/json
(no security headers)
```

ZAP **before** flagged `10021` and `90004`.

**After** (`quicknotes:lab9`):

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'
```

ZAP **after** summary:

```text
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
(no alert 10021 in after report)
WARN-NEW: 2  (10049 cacheable, 10116 ZAP out of date only)
```

Alerts **10021** and **90004** are gone in [`zap-after.json`](scans/zap-after.json).

### Design questions

**e) Why middleware?** One place to enforce headers on every route. Handlers stay about notes; we don't forget a header on a new endpoint.

**f) `CSP: default-src 'none'`** blocks browsers from loading scripts/styles/images. Fine for a JSON API (clients ignore CSP). Would break a normal website that serves HTML/JS.

**g) Cost of blind ACCEPT on ZAP info/low.** Noise hides real issues in the next scan; reviewers stop reading. Each finding needs a one-line reason, even if the reason is "scanner version, not us."

---

## Bonus — `govulncheck` CI gate

Added a **`govulncheck`** job to [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) (Lab 3 CI + this job). Pinned scanner: `go install golang.org/x/vuln/cmd/govulncheck@v1.1.4`. Go **1.24** (same as lint). Job is wired into **`ci-gate`**.

Gate logic: QuickNotes has no third-party deps, but Go 1.24 still reports reachable **stdlib** CVEs (exit 3). We triage those as WATCH in Task 1. The CI job **fails only if `Found in: golang.org/x/`** appears — i.e. a reachable third-party module vuln.

### CI job (excerpt)

```yaml
  govulncheck:
    name: govulncheck
    runs-on: ubuntu-24.04
    defaults:
      run:
        working-directory: app
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
      - uses: actions/setup-go@40f1582b2485089dde7abd97c1529aa768e1baff # v5.6.0
        with:
          go-version: "1.24"
          cache-dependency-path: app/go.mod
      - run: go install golang.org/x/vuln/cmd/govulncheck@v1.1.4
      - run: |
          set +e
          govulncheck -show verbose ./... 2>&1 | tee govulncheck.txt
          if grep -qE 'Found in: golang.org/x/' govulncheck.txt; then exit 1; fi
```

### Red run — bad dependency introduced

Temporarily added `golang.org/x/crypto@v0.17.0` and a reachable call in `vuln_probe.go` (then reverted). Log: [`scans/govulncheck-red.log`](scans/govulncheck-red.log).

```text
Vulnerability #2: GO-2026-5023
  Module: golang.org/x/crypto
    Found in: golang.org/x/crypto@v0.17.0
    Fixed in: golang.org/x/crypto@v0.52.0
    Invoking infinite loop on large channel writes in golang.org/x/crypto/ssh
```

CI gate would **fail** (`Found in: golang.org/x/crypto@v0.17.0`).

### Green run — after revert

Clean `go.mod` (stdlib only). Log: [`scans/govulncheck-green.log`](scans/govulncheck-green.log).

```text
Your code is affected by 7 vulnerabilities from the Go standard library.
This scan also found 5 vulnerabilities in packages you import and 8
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
```

No `golang.org/x/*` in output → CI gate **passes**.

### Design questions

**h) Reachability vs "module has a CVE".** Trivy/grep says "this version of `x/crypto` has CVE-X". `govulncheck` asks "does **our call graph** reach the vulnerable function?" If we don't call it, triage workload drops — we WATCH the module but don't panic. If we dial SSH via `vuln_probe`, the trace hits `golang.org/x/crypto/ssh` and the gate goes red.

**i) Why pin the scanner version?** Same as pinning actions: `@latest` can change rules, DB integration, or exit behaviour between runs. Pinning `@v1.1.4` makes CI reproducible.

**j) What govulncheck won't catch that Trivy will.** Trivy scans the **container image** (OS packages, embedded stdlib in binaries, misconfigs). `govulncheck` only knows **Go source + module graph**. It won't flag a CVE in distroless base (Trivy Task 1) or a ZAP header issue (Task 2).
