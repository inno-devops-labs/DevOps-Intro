# Lab 9 - DevSecOps: Scan QuickNotes with Trivy and ZAP

## Objective

Scan the Lab 6 QuickNotes image with Trivy (image, filesystem, config) and
generate a CycloneDX SBOM, run an OWASP ZAP baseline against the running app,
triage every finding with an explicit disposition, fix at least one finding in
code, and (bonus) add govulncheck to the Lab 3 CI as a blocking PR gate.

## Environment

- Host: Apple M4 (arm64), macOS; Docker 29.2.1
- Scanners pinned, not `latest`: `aquasec/trivy:0.59.1`,
  `ghcr.io/zaproxy/zaproxy:2.16.1`
- Scan target: `quicknotes:lab6` (distroless static, nonroot, built from
  `app/Dockerfile`); fixed image built as `quicknotes:lab9`
- This branch starts from the Lab 6 container substrate and carries the Lab 3
  `ci.yml` for the bonus gate

All raw scan outputs are committed under `security/`:

```text
security/
  trivy-image.txt            # image scan, before fixes
  trivy-image-after.txt      # image scan, after fixes (0 findings)
  trivy-fs.txt               # filesystem scan of the repo
  trivy-config.txt           # config scan (Dockerfile, compose.yaml)
  quicknotes.sbom.cdx.json   # CycloneDX SBOM of the image
  zap-hooks.py               # endpoint seeding hook for zap-baseline.py
  zap-before.html / .json    # ZAP baseline, before the fix
  zap-after.html / .json     # ZAP baseline, after the fix
```

---

## Task 1 - Trivy: image + filesystem + config + SBOM

### How the scans were run

Trivy runs from its pinned container with a named cache volume, so the vuln DB
(about 200 MB) downloads once and is reused by every scan:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache aquasec/trivy:0.59.1 \
  image --severity HIGH,CRITICAL quicknotes:lab6        # > trivy-image.txt

docker run --rm -v "$PWD":/repo:ro -v trivy-cache:/root/.cache \
  aquasec/trivy:0.59.1 fs --severity HIGH,CRITICAL /repo # > trivy-fs.txt

docker run --rm -v "$PWD":/repo:ro -v trivy-cache:/root/.cache \
  aquasec/trivy:0.59.1 config /repo                      # > trivy-config.txt

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/security":/out -v trivy-cache:/root/.cache aquasec/trivy:0.59.1 \
  image --format cyclonedx --output /out/quicknotes.sbom.cdx.json quicknotes:lab6
```

### Scan 1: image (top of output)

```text
quicknotes:lab6 (debian 13.5)
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)

quicknotes (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)
```

The distroless OS layer contributes zero HIGH/CRITICAL findings. Every finding
is the same set of 11 Go standard library CVEs, once per shipped binary,
because both binaries were built with Go 1.24.13 and the 1.24 line is EOL (the
fixed versions Trivy lists are all 1.25.x/1.26.x).

### Scan 2: filesystem (full output is short)

```text
.vagrant/machines/default/vmware_desktop/private_key (secrets)
Total: 1 (HIGH: 1, CRITICAL: 0)
HIGH: AsymmetricPrivateKey (private-key)
```

No dependency findings: `app/go.mod` has zero third party requirements, and
the fs scanner has no compiled binary to inspect, so the stdlib CVEs from the
image scan do not appear here.

### Scan 3: config (top of output)

```text
app/Dockerfile (dockerfile)
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

Zero HIGH/CRITICAL misconfigurations. The one LOW is discussed in the triage
table for completeness.

### SBOM (first 30 lines of `security/quicknotes.sbom.cdx.json`)

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:829d4a39-6de1-4dc6-8639-9ed28cad3a89",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-03T11:16:01+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3A249c641fd80a8df0c2905996b587a8fb98697d621ac61d94f77f64de576b048e?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A249c641fd80a8df0c2905996b587a8fb98697d621ac61d94f77f64de576b048e?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
```

### Triage: every HIGH/CRITICAL finding

The 11 stdlib CVEs appear twice each (in `quicknotes` and in `healthcheck`),
so the table lists the CVE once with both locations implied. All 11 share one
root cause (EOL Go 1.24.13 stdlib compiled into the binaries) and one fix.

| # | Finding | Where | Severity | Disposition | Reason and evidence |
|---|---------|-------|----------|-------------|---------------------|
| 1 | CVE-2026-25679 (net/url IPv6 parsing) | both gobinaries | HIGH | FIX | Fixed in commit `94e6aae`: builder bumped `golang:1.24.13` to `golang:1.26.4` (first supported patch containing every fix below). Rebuilt as `quicknotes:lab9`; re-scan `security/trivy-image-after.txt` shows Total: 0. |
| 2 | CVE-2026-27145 (crypto/x509 DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 3 | CVE-2026-32280 (crypto/x509/tls chain building DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 4 | CVE-2026-32281 (crypto/x509 chain validation DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 5 | CVE-2026-32283 (crypto/tls TLS 1.3 DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 6 | CVE-2026-33811 (net long CNAME DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 7 | CVE-2026-33814 (net/http HTTP/2 SETTINGS DoS) | both gobinaries | HIGH | FIX | Same fix as #1. This one is the most likely to be reachable (we serve net/http), which pushed the decision to FIX now rather than triage each CVE separately. |
| 8 | CVE-2026-39820 (net/mail DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 9 | CVE-2026-39836 (golang security update) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 10 | CVE-2026-42499 (net/mail address parsing DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 11 | CVE-2026-42504 (MIME header decoding DoS) | both gobinaries | HIGH | FIX | Same fix as #1. |
| 12 | AsymmetricPrivateKey in `.vagrant/.../private_key` | fs scan | HIGH | ACCEPT (re-evaluate by 2026-12-31) | This is the auto-generated SSH key for the local Lab 5 Vagrant VM. The `.vagrant/` directory is gitignored upstream and `git log --all` confirms the key was never committed; it only grants SSH to a VM on this laptop that is no longer running. Will be deleted together with the retired VM state; if the directory still exists at re-evaluation time, delete it then. |

Not required in this table but triaged anyway: AVD-DS-0026 (LOW, no
HEALTHCHECK in Dockerfile). Accepted as designed: the image is distroless with
no shell, so the healthcheck is the shipped `/healthcheck` probe binary wired
up in `compose.yaml` (Lab 6 decision). Orchestrators like Kubernetes ignore
Dockerfile HEALTHCHECK anyway.

A note on why FIX for all 11 CVEs instead of per-CVE reachability analysis:
most of these packages (net/mail, crypto/tls on a plain-HTTP service) are
probably not reachable from QuickNotes. But the stdlib version is a property
of the whole binary, the fix is one line in the Dockerfile, and arguing
"unreachable" 11 times costs more than rebuilding once. Severity said HIGH;
the cheap complete fix beat the per-finding debate.

### Re-scan after the fix

```text
quicknotes:lab9 (debian 13.5)
Total: 0 (HIGH: 0, CRITICAL: 0)
```

The gobinary sections are gone entirely (no findings to print). Full output in
`security/trivy-image-after.txt`.

### Design questions

**a) CVE severity is one input, not the answer. What else matters?**
Reachability (does our code ever call the vulnerable function; the bonus shows
govulncheck automating exactly this), exploit maturity (public PoC, active
exploitation in the wild), exposure (internet-facing endpoint vs internal
tool), what an attacker gains (RCE vs DoS on a stateless service that
restarts), compensating controls (distroless, nonroot, read-only fs), and the
cost of the fix. In this lab the deciding factor was fix cost: one Dockerfile
line cleared all 11 HIGHs, so reachability arguments became irrelevant.

**b) Why is the minimal base the strongest single security control?**
Because the base contributes nothing to attack surface or to the patch
treadmill. Our scan shows it directly: the distroless layer produced 0
findings; every finding came from our own binaries. There is no shell to pop,
no package manager to abuse for lateral movement, no libc or coreutils
accumulating CVEs that we would have to track and patch on someone else's
schedule. The remaining vulnerability surface is code we build and can fix
ourselves.

**c) When is `.trivyignore` legitimate, and when is it security theater?**
Legitimate when each entry is the recorded outcome of a real triage decision:
a documented false positive, or an accepted/watched finding with an owner and
a re-evaluation date, reviewed like code. Theater when it exists to make CI
green: blanket ignores with no reason, no date, no owner, or ignores of
findings that have an available fix someone did not want to apply. The test:
every line in `.trivyignore` should trace back to a written disposition like
the table above. We ship none because nothing needed suppressing.

**d) What concrete future problem does having the SBOM today solve?**
The Log4Shell scenario: a critical CVE lands in some component at 2 a.m. and
the question is "are we affected, and where". With stored SBOMs you grep an
inventory you already have and answer in minutes, for every image version you
ever shipped, including ones you can no longer rebuild. Without them you are
rebuilding and rescanning every artifact at incident time, or worse, guessing.
It also lets new CVE feeds be matched against old releases continuously
instead of only at build time.

---

## Task 2 - OWASP ZAP baseline + fix in code

### How the scan was run

QuickNotes has no HTML pages and `GET /` is 404, so a stock baseline spider
sees nothing but robots.txt/sitemap.xml probes and the passive rules never
examine real API responses. The packaged scan scripts support hooks for
exactly this, so `security/zap-hooks.py` seeds the real endpoints with plain
GETs before the passive phase (`zap.core.access_url`). The scan stays fully
passive; no active scan was run.

```bash
docker network create lab9-scan
docker run -d --name quicknotes --network lab9-scan quicknotes:lab6
docker run --rm --network lab9-scan -v "$PWD/security":/zap/wrk \
  ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py -t http://quicknotes:8080 \
  --hook /zap/wrk/zap-hooks.py -r zap-before.html -J zap-before.json
```

Console summary (before):

```text
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 4
WARN-NEW: ZAP is Out of Date [10116] x 1
WARN-NEW: Insufficient Site Isolation Against Spectre Vulnerability [90004] x 4
FAIL-NEW: 0  WARN-NEW: 3  INFO: 0  PASS: 63
```

### Triage: every ZAP finding

| ID | Name | Risk (confidence) | Affected URLs | Disposition | Reason |
|----|------|-------------------|---------------|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low (Medium) | /health, /notes, /notes/1, /metrics | FIX | Real gap: without `nosniff` a browser may MIME-sniff responses. Fixed in commit `77d4cba` via the security headers middleware; gone in the after scan. |
| 90004 | Insufficient Site Isolation Against Spectre | Low (Medium) | /health, /notes, /notes/1, /metrics | FIX | Missing `Cross-Origin-Resource-Policy` means any site could pull our responses into its process and expose them to speculative side channels. Fixed in the same middleware; gone in the after scan. |
| 10116 | ZAP is Out of Date | Low (High) | scanner self-report | ACCEPT (re-evaluate each lab, next 2026-12-31) | Not a finding about QuickNotes at all: the scanner reports that 2.16.1 is not the newest ZAP. The pin is deliberate (the lab requires a pinned scanner version for reproducibility); the pinned version gets bumped consciously, not silently. |
| 10049 | Storable and Cacheable Content | Informational (Medium) | all seeded URLs plus robots.txt/sitemap.xml probes | ACCEPT (re-evaluate by 2026-12-31) | QuickNotes sends no Cache-Control, so a shared cache may store responses. There is no per-user or authenticated data (every client sees the same notes), so cache poisoning/leakage value is nil today. Re-evaluate if auth or per-user data ever lands; then `Cache-Control: no-store` becomes a FIX. |

### The fix: security headers middleware

Requirements: middleware that wraps the router (not per-handler `Header().Set`
calls), applied to all routes, guarded by a unit test that fails if the
middleware is removed. Commit `77d4cba`:

`app/middleware.go` (new):

```go
func securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        h := w.Header()
        h.Set("X-Content-Type-Options", "nosniff")
        h.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
        h.Set("Cross-Origin-Resource-Policy", "same-origin")
        next.ServeHTTP(w, r)
    })
}
```

`app/handlers.go`: `Routes()` now returns `http.Handler` and its last line is
`return securityHeaders(mux)` instead of `return mux`. Every route (and the
mux's own 404/405 responses) passes through the middleware; `main.go` and the
test helper already build the server via `Routes()`, so nothing else changed.

`app/middleware_test.go` (new) asserts all three headers on `GET /health` and
`GET /notes`. Proof the guard is real, with the wrap temporarily removed:

```text
--- FAIL: TestSecurityHeaders_OnAllRoutes (0.00s)
    middleware_test.go:24: GET /health header X-Content-Type-Options: got "", want "nosniff"
    middleware_test.go:24: GET /health header Content-Security-Policy: got "", want "default-src 'none'; frame-ancestors 'none'"
    middleware_test.go:24: GET /health header Cross-Origin-Resource-Policy: got "", want "same-origin"
    ...
FAIL    quicknotes      0.445s
```

With the wrap in place: `go vet ./...` clean, `go test -race -count=1 ./...`
passes.

### Re-scan: the findings are gone

Rebuilt the image as `quicknotes:lab9`, re-ran the identical baseline command
(`zap-after.html` / `zap-after.json`):

```text
WARN-NEW: ZAP is Out of Date [10116] x 1
FAIL-NEW: 0  WARN-NEW: 1  INFO: 0  PASS: 65
```

10021 and 90004 no longer appear (their rules now count among the 65 passes).
Live header check on the fixed container:

```text
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Content-Type: application/json
Cross-Origin-Resource-Policy: same-origin
X-Content-Type-Options: nosniff
```

### Design questions

**e) Why a middleware and not per-handler header sets?**
One enforcement point with a fail-safe default: a route added next month gets
the headers automatically, while per-handler calls rely on every future author
remembering boilerplate, and drift silently (the mux's own 404/405 error
responses would never get them at all). It is also testable as a whole: one
unit test guards the entire surface, instead of one assertion per handler.

**f) What does `Content-Security-Policy: default-src 'none'` break, and why is
it OK for QuickNotes but not for a website?**
It forbids a rendered document from loading anything: scripts, styles, images,
fonts, XHR/fetch, frames. Any real website would be completely broken by it.
QuickNotes only ever emits JSON; browsers apply CSP when rendering documents,
so API responses lose nothing, and if some error path ever did render in a
browser, the strictest policy is exactly what we want. A website instead needs
an allowlist of what it actually loads (and that takes testing, because a too
strict CSP breaks things like embedded docs UIs).

**g) What is the cost of marking all informational findings "accepted" without
reading them?**
"Accepted" is a risk decision; making it without reading means the decision
never happened, and the label lies about it. Practically it trains rubber
stamping: once bulk-accepting is normal, the one informational finding that
actually matters (10049 would become real the day auth lands) sails through
with the noise. An unread accept is worse than an honest "not reviewed",
because it removes the finding from every future review's attention.

---

## Bonus - govulncheck as a blocking CI gate

### The job

Added to the Lab 3 `.github/workflows/ci.yml` (commit `56e5be0`), wired into
the existing `ci-ok` aggregation gate so a failure blocks the PR:

```yaml
  govulncheck:
    needs: changes
    if: needs.changes.outputs.app == 'true'
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
      - uses: actions/setup-go@4a3601121dd01d1626a1e23e37211e3254c1c06c # v6.4.0
        with:
          # Matches the Dockerfile builder, not the 1.23/1.24 test matrix: the
          # gate checks the stdlib that the released binary actually ships
          # with. Go 1.24 is EOL, so running the gate on it would leave the
          # job permanently red on stdlib CVEs no code change can fix.
          go-version: '1.26.4'
          cache-dependency-path: app/go.mod
      - name: Install govulncheck (pinned)
        run: go install golang.org/x/vuln/cmd/govulncheck@v1.5.0
      - name: govulncheck
        working-directory: app
        run: govulncheck ./...
```

One deliberate deviation from the task text: the task says the Go version
should match the rest of CI (1.24). The vet/test matrix still runs 1.23/1.24
for compatibility, but the gate itself runs 1.26.4, the same toolchain the
Dockerfile builds the released binary with. Running govulncheck on EOL 1.24
would report the Task 1 stdlib CVEs forever (no 1.24 fix exists), making the
gate permanently red and teaching everyone to ignore it. The gate must be able
to go green on a healthy tree to be a gate at all.

`ci-ok` now needs `[changes, vet, test, lint, govulncheck]`.

### Red demo: the gate catches a vulnerable dependency

Branch `lab9-vuln-demo` adds `golang.org/x/text v0.3.5` and a reachable call
(`language.Parse` of an env var in an `init` function), then opens a fork PR
so the pull_request pipeline runs:
https://github.com/Dekart-hub/DevOps-Intro/pull/7 (red run:
https://github.com/Dekart-hub/DevOps-Intro/actions/runs/28660438729)

govulncheck output from the red run:

```text
Vulnerability #1: GO-2021-0113
    Out-of-bounds read in golang.org/x/text/language
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.5
    Fixed in: golang.org/x/text@v0.3.7
    Example traces found:
      #1: lang.go:12:29: quicknotes.init#1 calls language.Parse

Your code is affected by 1 vulnerability from 1 module.
This scan also found 1 vulnerability in packages you import and 0
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
```

The job exits with code 3, `ci-ok` turns red, and the PR is blocked; the
other jobs (vet, test, lint) stay green, so it is specifically the security
gate that catches it:

```text
ci-ok        fail   govulncheck  fail
changes      pass   lint         pass
test (1.23)  pass   test (1.24)  pass
vet (1.23)   pass   vet (1.24)   pass
```

The demo branch is never merged (the "revert" is that the dependency never
lands).

### Green run on the lab branch

The same pipeline on `feature/lab9` (evidence PR:
https://github.com/Dekart-hub/DevOps-Intro/pull/8) passes all jobs including
govulncheck: https://github.com/Dekart-hub/DevOps-Intro/actions/runs/28660441693

### Design questions

**h) How is "this module has a CVE" different from "we call the affected
function", and what does reachability mean for triage workload?**
Module-level matching (what Trivy does) answers an inventory question: a
vulnerable version is present. Reachability (govulncheck's call graph
analysis) answers the risk question: can our code actually execute the
vulnerable path. The red demo shows both in one output: x/text v0.3.5 carries
two vulnerabilities, govulncheck reports exactly one as affecting us (the one
`language.Parse` reaches) and files the other under "you import it but never
call it". Triage workload shrinks to findings that can actually fire; with
module-level results a human does that reachability reasoning by hand for
every finding, which is precisely the part that does not scale.

**i) Why pin the version of the scanner itself, not just use `@latest`?**
Same reason we pin any tool in CI: determinism and reviewable change. With
`@latest`, a new govulncheck release (new flags, changed exit behavior,
different analysis) can flip a PR red with zero changes in the repo, and
nobody can reproduce yesterday's green locally. Pinned, the scanner upgrade is
a visible diff that gets reviewed and rolled back like any other change. The
vulnerability database stays fresh independently of the binary version, so
pinning does not mean scanning against stale vulns.

**j) What will govulncheck not catch that the Trivy image scan would?**
Everything that is not Go code: CVEs in OS packages of the base image (libc,
openssl, ca-certificates in a fatter base), other-language dependencies,
Dockerfile and compose misconfigurations, leaked secrets, and license issues.
It also cannot see what is only in the final image (binaries copied in from
elsewhere). The two are complements: govulncheck gives precision on our own
code paths, Trivy gives breadth across the entire shipped artifact.

---

## How this was verified

- `go vet ./...` and `go test -race -count=1 ./...` pass on `feature/lab9`;
  the header test was additionally shown to fail with the middleware wrap
  removed (output above)
- Trivy re-scan of the fixed image: 0 HIGH/CRITICAL (was 22)
- ZAP re-scan of the fixed image: both header findings gone, no new findings
- The govulncheck gate demonstrably fails on a PR introducing a reachable
  vulnerable dependency and passes on the clean lab branch
