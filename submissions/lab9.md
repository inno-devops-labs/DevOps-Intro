# Lab 9 — DevSecOps: Trivy + ZAP

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + WSL2 + Docker Desktop + `quicknotes:lab6` image

---

## Task 1 — Trivy scans + SBOM + triage

### Scan commands

```bash
bash security/scripts/run-trivy.sh
```

Reports: [`security/reports/`](../security/reports/)

Pinned scanner: `aquasec/trivy:0.59.1`

### Scan output (top)

#### Image (`trivy-image.txt`)

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 12 (HIGH: 12, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 12 (HIGH: 12, CRITICAL: 0)
```

(Full report in repo. Image rebuilt with `golang:1.24.13-alpine`; original `1.24.5` scan had 15 HIGH + 1 CRITICAL per binary.)

#### Filesystem (`trivy-fs.txt`)

```text
2026-06-25T23:41:37Z	INFO	Number of language-specific files	num=1
2026-06-25T23:41:37Z	INFO	[gomod] Detecting vulnerabilities...
```

No HIGH/CRITICAL findings in `app/go.mod` / repo source.

#### Config (`trivy-config.txt`)

```text
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

No HIGH/CRITICAL misconfigurations. Health probing is handled via Compose `healthcheck` + `/healthcheck` binary.

#### SBOM (first 30 lines of `quicknotes-sbom.json`)

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:458eae96-8901-4a3e-a318-8aff125ca714",
  "version": 1,
  "metadata": {
    "timestamp": "2026-06-25T23:57:16+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3A98f4e47b07633d15a9b3b3c0b94f98e9c8dcde8746d8416eaf1fd4ef270088dc?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A98f4e47b07633d15a9b3b3c0b94f98e9c8dcde8746d8416eaf1fd4ef270088dc?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:144f9b8d282198cfbafeb0783d0901985d16ec0e2103b12b57616fe520373590"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
```

### Triage table (every HIGH/CRITICAL)

Image scan findings are Go `stdlib` CVEs in both compiled binaries (`/quicknotes` and `/healthcheck`). Each CVE appears twice; disposition is the same for both.

| ID / Package | Severity | Source | Disposition | Reason |
|--------------|----------|--------|-------------|--------|
| CVE-2026-25679 (stdlib) | HIGH | image (both binaries) | WATCH | Fixed in Go 1.25.8+; no 1.24.x backport yet. Re-check when Go 1.24.14+ or 1.25 patch is released (by 2026-12-01). |
| CVE-2026-27145 (stdlib) | HIGH | image | WATCH | x509 hostname verification; fixed in 1.25.11+. App serves plain HTTP only; monitor Go release notes. |
| CVE-2026-32280 (stdlib) | HIGH | image | ACCEPT | TLS cert-chain DoS; QuickNotes does not terminate TLS or accept client certs. Re-evaluate 2026-12-01 if HTTPS is added. |
| CVE-2026-32281 (stdlib) | HIGH | image | ACCEPT | Same as above — x509 chain validation not on attack surface for this API. |
| CVE-2026-32283 (stdlib) | HIGH | image | ACCEPT | TLS 1.3 DoS in `crypto/tls`; service listens HTTP :8080 only. |
| CVE-2026-33811 (stdlib) | HIGH | image | WATCH | DNS CNAME DoS in `net`; outbound DNS from container is minimal. Watch for 1.24 backport. |
| CVE-2026-33814 (stdlib) | HIGH | image | ACCEPT | HTTP/2 SETTINGS DoS; QuickNotes uses HTTP/1.1 only. |
| CVE-2026-39820 (stdlib) | HIGH | image | WATCH | mail address parsing DoS; no mail parsing in QuickNotes — likely unreachable, re-check with `govulncheck`. |
| CVE-2026-39823 (stdlib) | HIGH | image | WATCH | URL parsing fix follow-up; limited URL parsing in app. |
| CVE-2026-39836 (stdlib) | HIGH | image | FIX | Patched by upgrading builder `golang:1.24.5` → `1.24.13` in `app/Dockerfile` (commit on `feature/lab9`). |
| CVE-2026-42499 (stdlib) | HIGH | image | WATCH | MIME phrase parsing DoS; no MIME header decoding in handlers. |
| CVE-2026-42504 (stdlib) | HIGH | image | WATCH | MIME header decoding DoS; fixed in 1.25.11+. Re-check 2026-12-01. |

**Config / filesystem:** no HIGH or CRITICAL findings to triage.

### Design questions (Task 1)

**a) CVE severity is one input — what else matters?**

Severity alone does not say whether we are exposed. I also consider **reachability** (is the vulnerable code path used?), **exploit availability**, **network exposure** (internal API vs public), **compensating controls** (distroless, read-only rootfs, dropped caps), and **blast radius** if exploited.

**b) Why distroless → fewer HIGH/CRITICAL?**

Distroless removes the OS package manager, shell, and most packages. Trivy finds fewer OS-level CVEs because the attack surface is tiny — only what you copy in (our static Go binaries + seed file). The minimal base is the strongest single control because it eliminates entire vulnerability classes (no `apt`, no `curl`, no accidental packages).

**c) When is `.trivyignore` right vs theater?**

Right when a finding is **documented**, **time-boxed**, and **approved** — e.g. a CVE with no reachable path, with a ticket and re-review date. Theater when it permanently hides findings to get a green scan without analysis, or suppresses without an owner or expiry.

**d) What future problem does the SBOM solve?**

When a new CVE drops (e.g. Log4Shell-style), the SBOM lets you answer in minutes: *“Do we ship that component, which version, and where?”* without re-scanning or guessing. It enables targeted incident response and compliance audits.

---

## Task 2 — ZAP baseline + code fix

### Security headers fix

Middleware: [`app/middleware.go`](../app/middleware.go) — `SecurityHeaders` wraps all routes via `server.Handler()` in `main.go`.

Headers set on every response:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Content-Security-Policy: default-src 'none'`
- `Referrer-Policy: no-referrer`

Tests: `TestSecurityHeaders_PresentOnResponses`, `TestSecurityHeaders_AbsentWithoutMiddleware` in `handlers_test.go`.

### ZAP baseline

```bash
docker compose up -d quicknotes
bash security/scripts/run-zap-baseline.sh   # targets /health
```

Pinned: `ghcr.io/zaproxy/zaproxy:2.16.1`

Before scan saved as `zap-baseline-before-health.json` (against image **without** middleware). After scan: `zap-baseline.json`.

### ZAP triage table

| ID | Name | Risk | URL | Disposition | Reason |
|----|------|------|-----|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | `/health` | **FIX** | Added `SecurityHeaders` middleware + unit tests. Gone in post-fix scan. |
| 90004 | Insufficient Site Isolation Against Spectre | Low | `/health` | ACCEPT | Missing `Cross-Origin-Resource-Policy` / COOP. JSON API not loaded in browsers cross-origin; re-evaluate if UI is added (2026-12-01). |
| 10116 | ZAP is Out of Date | Low | various | FALSE POSITIVE | Finding is about the **scanner** version (2.16.1 vs 2.17.0), not the app. Pin kept per lab requirement. |
| 10049 | Storable and Cacheable Content | Informational | `/`, `/health`, `/sitemap.xml` | ACCEPT | `/health` returns static JSON; notes are not highly sensitive in lab. Could add `Cache-Control: no-store` later. Re-evaluate 2026-12-01. |

### Before / after

**Before** (`zap-baseline-before-health.json`):

```json
{
  "pluginid": "10021",
  "alert": "X-Content-Type-Options Header Missing",
  "riskdesc": "Low (Medium)",
  "instances": [{ "uri": "http://host.docker.internal:8080/health", "method": "GET" }]
}
```

**After** (`zap-baseline.json`): alert `10021` is **absent**. ZAP summary dropped from `WARN-NEW: 4` to `WARN-NEW: 3`; `X-Content-Type-Options Header Missing` appears under PASS rules in CLI output.

Live verification:

```http
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
```

### Design questions (Task 2)

**e) Why middleware vs per-handler headers?**

One middleware guarantees **every** route (including future handlers and error paths) gets the same headers. Per-handler sets are easy to forget, inconsistent, and untested when new endpoints are added.

**f) CSP `default-src 'none'` — what breaks, why OK for API?**

It blocks browsers from loading scripts, styles, images, or fonts from any origin. That breaks normal websites. QuickNotes is a JSON REST API with no HTML UI — browsers should not execute content from our responses, so denying all resource loads is appropriate.

**g) Cost of accepting all informational ZAP findings unread?**

You accumulate **unknown real risk** (alert fatigue in reverse), miss patterns that indicate misconfiguration, and lose audit credibility. Informational does not mean harmless — bulk-accepting without review is security theater.

---

## Bonus — govulncheck CI gate

### CI job

Added to [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) (from Lab 3 + new job):

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
          go-version: '1.24'
          cache: true
          cache-dependency-path: app/go.mod
      - name: Install govulncheck
        run: go install golang.org/x/vuln/cmd/govulncheck@v1.1.4
      - name: Run govulncheck
        run: govulncheck ./...
```

`ci-ok` now depends on `govulncheck` — a failing scan blocks the PR.

Pinned scanner: `golang.org/x/vuln/cmd/govulncheck@v1.1.4` (not `@latest`).

### Red / green demo

**Red** — temporarily added `golang.org/x/text@v0.3.5` and `vuln_demo.go` calling `language.Parse` (GO-2021-0113). Local run (`security/reports/govulncheck-red.txt`):

```text
Vulnerability #1: GO-2021-0113
    Out-of-bounds read in golang.org/x/text/language
  Module: golang.org/x/text@v0.3.5  Fixed in: v0.3.7
  Example traces: vuln_demo.go calls language.Parse
Your code is affected by 1 vulnerability from 1 module.
(exit code 3)
```

**Green** — removed `vuln_demo.go` and ran `go mod tidy` (`security/reports/govulncheck-green.txt`):

```text
No vulnerabilities found.
(exit code 0)
```

### Design questions (Bonus)

**h) Reachability vs “module has a CVE” — triage workload?**

`govulncheck` only fails when your call graph reaches the vulnerable symbol. A module can list 10 CVEs, but if you never call the affected functions, there is nothing to patch urgently. That cuts triage from “every CVE in go.sum” to “CVEs we can actually trigger,” which is far less noise — but you still need Trivy/image scans for non-Go components.

**i) Why pin the scanner version?**

`@latest` can change DB logic, output format, or detection rules between CI runs, causing flaky or unexplained red builds. Pinning `govulncheck@v1.1.4` makes CI reproducible and upgrades deliberate.

**j) What does govulncheck *not* catch that Trivy would?**

Go stdlib/binary CVEs in the **container image** (distroless OS layer, embedded Go version in compiled binaries), misconfigurations (Dockerfile/compose), secrets in repo, and vulnerabilities in **non-Go** dependencies. Trivy is broader; govulncheck is deeper on Go reachability.

---

## Lab 9 completion checklist

### Task 1 (6 pts)

- [x] Four Trivy scans + SBOM captured
- [x] Every HIGH/CRITICAL triaged
- [x] Design questions a–d answered

### Task 2 (4 pts)

- [x] Security headers middleware + unit tests
- [x] ZAP baseline run + triage
- [x] Before/after re-scan evidence
- [x] Design questions e–g answered

### Bonus (2 pts)

- [x] govulncheck in CI + demo red/green

### Submission

- [ ] Course PR (`feature/lab9` → `inno-devops-labs/main`)
- [ ] Fork PR
- [ ] Moodle URL
