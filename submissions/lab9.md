# Lab 9 — DevSecOps: Trivy, ZAP and govulncheck

## Task 1 — Trivy: Image, Filesystem, Configuration and SBOM

### Tool version

Trivy version used for the scans:

```text
Trivy 0.74.0
```

The scanner version is fixed and recorded instead of using an unpinned `latest` version.

---

## 1.1 Container image scan

Command:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --format table \
  --output submissions/lab9-assets/trivy-image.txt \
  quicknotes:lab6
```

Summary:

```text
┌────────────────────────────────┬──────────┬─────────────────┬─────────┐
│             Target             │   Type   │ Vulnerabilities │ Secrets │
├────────────────────────────────┼──────────┼─────────────────┼─────────┤
│ quicknotes:lab6 (debian 12.15) │ debian   │        0        │    -    │
│ app/healthcheck                │ gobinary │       19        │    -    │
│ app/quicknotes                 │ gobinary │       19        │    -    │
└────────────────────────────────┴──────────┴─────────────────┴─────────┘
```

The Debian runtime layer itself contained no HIGH or CRITICAL vulnerabilities.
The 19 unique HIGH findings came from Go standard library v1.24.13 embedded in
both compiled Go binaries, so the same CVEs appear for `quicknotes` and
`healthcheck`.

Full output: `submissions/lab9-assets/trivy-image.txt`.

### Image vulnerability triage

All findings below affect both `app/quicknotes` and `app/healthcheck`.

| CVE | Severity | Fixed version | Disposition | Reason |
|---|---|---|---|---|
| CVE-2026-25679 | HIGH | Go 1.25.8 / 1.26.1 | ACCEPT | IPv6 URL parsing issue. The lab image is currently constrained to the Go 1.24 toolchain. Upgrade the builder when the course baseline allows it. Re-evaluate by 2026-12-31. |
| CVE-2026-27145 | HIGH | Go 1.25.11 / 1.26.4 | ACCEPT | `crypto/x509` DoS. The vulnerable stdlib is embedded in the Go 1.24 binaries; no patched Go 1.24 version is listed. Re-evaluate by 2026-12-31. |
| CVE-2026-32280 | HIGH | Go 1.25.9 / 1.26.2 | ACCEPT | Certificate-chain-building DoS. A fix requires moving away from the current Go 1.24 build baseline. Re-evaluate by 2026-12-31. |
| CVE-2026-32281 | HIGH | Go 1.25.9 / 1.26.2 | ACCEPT | Certificate-chain validation DoS. No fixed 1.24 release is available in the scan result. Re-evaluate by 2026-12-31. |
| CVE-2026-32283 | HIGH | Go 1.25.9 / 1.26.2 | ACCEPT | TLS 1.3 DoS. Current lab runtime is primarily a local HTTP service, reducing exposure, but the vulnerable stdlib remains present. Re-evaluate by 2026-12-31. |
| CVE-2026-33811 | HIGH | Go 1.25.10 / 1.26.3 | ACCEPT | Network/DNS DoS. Fix requires a newer Go toolchain than the Lab 3/6 baseline. Re-evaluate by 2026-12-31. |
| CVE-2026-33814 | HIGH | Go 1.25.10 / 1.26.3 | ACCEPT | Malformed HTTP/2 SETTINGS DoS. Current QuickNotes deployment uses local HTTP and has limited exposure, but the library is present. Re-evaluate by 2026-12-31. |
| CVE-2026-33818 | HIGH | Go 1.25.13 / 1.26.6 | ACCEPT | ASN.1 recursion DoS. The affected stdlib is embedded in the Go 1.24 binary and requires a toolchain upgrade. Re-evaluate by 2026-12-31. |
| CVE-2026-39820 | HIGH | Go 1.25.10 / 1.26.3 | ACCEPT | `net/mail` crafted-input DoS. QuickNotes does not expose mail-processing functionality, so practical reachability is low. Re-evaluate by 2026-12-31. |
| CVE-2026-39821 | HIGH | Go 1.25.13 / 1.26.6 | ACCEPT | Punycode/IDNA processing issue. QuickNotes has no user-facing hostname-processing feature, reducing practical exposure. Re-evaluate by 2026-12-31. |
| CVE-2026-39822 | HIGH | Go 1.25.12 / 1.26.5 | ACCEPT | `os.Root` symlink traversal issue. QuickNotes does not expose an `os.Root` based file-browsing interface. Re-evaluate by 2026-12-31. |
| CVE-2026-39836 | HIGH | Go 1.25.10 / 1.26.3 | ACCEPT | Network parsing DoS involving NUL bytes. The current lab deployment has limited network surface. Re-evaluate by 2026-12-31. |
| CVE-2026-42499 | HIGH | Go 1.25.10 / 1.26.3 | ACCEPT | Pathological email-address parsing DoS. QuickNotes does not process email addresses with `net/mail`, reducing reachability. Re-evaluate by 2026-12-31. |
| CVE-2026-42504 | HIGH | Go 1.25.11 / 1.26.4 | ACCEPT | Malicious MIME-header DoS. QuickNotes has no MIME-processing feature exposed to users. Re-evaluate by 2026-12-31. |
| CVE-2026-56853 | HIGH | Go 1.25.13 / 1.26.6 | ACCEPT | Unencrypted HTTP/2 DoS. The application is a small local lab API, but the vulnerable implementation is still present. Re-evaluate by 2026-12-31. |
| CVE-2026-56858 | HIGH | Go 1.25.13 / 1.26.6 | ACCEPT | `html/template` XSS issue. QuickNotes is a JSON API and does not render HTML templates, so this path is not exposed by the application. Re-evaluate by 2026-12-31. |
| CVE-2026-56859 | HIGH | Go 1.25.13 / 1.26.6 | ACCEPT | XML recursion DoS. QuickNotes uses JSON rather than XML input, so practical reachability is low. Re-evaluate by 2026-12-31. |
| CVE-2026-56860 | HIGH | Go 1.25.13 / 1.26.6 | ACCEPT | `net/url` quadratic-complexity DoS. URL handling exists in the standard HTTP stack, so this is more relevant than unused packages, but fixing requires a newer Go toolchain. Re-evaluate by 2026-12-31. |
| CVE-2026-56862 | HIGH | Go 1.25.13 / 1.26.6 | ACCEPT | TLS KeyUpdate DoS. The local lab deployment does not terminate TLS itself, reducing direct exposure. Re-evaluate by 2026-12-31. |

These findings demonstrate why severity alone is not enough for triage. The same
HIGH severity can correspond to a directly reachable HTTP path or to an unused
feature such as XML or HTML template processing.

---

## 1.2 Filesystem scan

Command:

```bash
trivy fs \
  --severity HIGH,CRITICAL \
  --format table \
  --output submissions/lab9-assets/trivy-fs.txt \
  .
```

Summary:

```text
┌──────────────────────────────────────────────────┬───────┬─────────────────┬─────────┐
│ Target                                           │ Type  │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────┼───────┼─────────────────┼─────────┤
│ app/go.mod                                       │ gomod │        0        │    -    │
│ .vagrant/machines/default/virtualbox/private_key │ text  │        -        │    1    │
└──────────────────────────────────────────────────┴───────┴─────────────────┴─────────┘
```

### Filesystem finding triage

| Finding | Severity | Disposition | Reason |
|---|---|---|---|
| Vagrant-generated asymmetric private key | HIGH | ACCEPT | The scanner correctly detected a private key, so this is not a false positive. It is generated locally inside `.vagrant/`, which is gitignored and is not copied into the QuickNotes image or committed to the repository. Re-evaluate by 2026-12-31. |

The private key itself is intentionally not included in this report.

Full output: `submissions/lab9-assets/trivy-fs.txt`.

---

## 1.3 Configuration scan

Command:

```bash
trivy config \
  --severity HIGH,CRITICAL \
  --format table \
  --output submissions/lab9-assets/trivy-config.txt \
  .
```

Result:

```text
┌────────────────┬────────────┬───────────────────┐
│ Target         │ Type       │ Misconfigurations │
├────────────────┼────────────┼───────────────────┤
│ app/Dockerfile │ dockerfile │         0         │
└────────────────┴────────────┴───────────────────┘
```

No HIGH or CRITICAL Dockerfile misconfigurations were detected.

Full output: `submissions/lab9-assets/trivy-config.txt`.

---

## 1.4 CycloneDX SBOM

Command:

```bash
trivy image \
  --format cyclonedx \
  --output submissions/lab9-assets/quicknotes.sbom.cdx.json \
  quicknotes:lab6
```

With Trivy 0.74.0, CycloneDX generation for an image is performed through
`trivy image --format cyclonedx`.

First 30 lines:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:e852f550-7309-4a78-87d9-1689fd56badd",
  "version": 1,
  "metadata": {
    "timestamp": "2026-09-30T08:18:50+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "manufacturer": {
            "name": "Aqua Security Software Ltd."
          },
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.74.0"
        }
      ]
    },
    "component": {
      "bom-ref": "pkg:oci/quicknotes@sha256:09d5afe3a8a8544ffa6572c722cd2d228dcb5436d3b48aa071d39375dfbb072f?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256:09d5afe3a8a8544ffa6572c722cd2d228dcb5436d3b48aa071d39375dfbb072f?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:114dde0fefebbca13165d0da9c500a66190e497a82a53dcaabc3172d630be1e9"
```

Full SBOM: `submissions/lab9-assets/quicknotes.sbom.cdx.json`.

---

## 1.5 Design questions

### a. Severity vs reachability, exploitability and deployment context

Severity describes the potential impact of a vulnerability, but it does not
prove that the vulnerable code can actually be reached in this application.
Triage should therefore combine severity with reachability, attacker-controlled
input, exploit prerequisites and deployment context.

For example, an XML vulnerability can be HIGH but have low practical risk for
QuickNotes if the API never parses XML. In contrast, a vulnerability reachable
through `net/http` deserves more attention because the application exposes an
HTTP server. `govulncheck` complements an image scanner here because it can
trace vulnerable symbols to calls from application code.

### b. Why a distroless/minimal base image is a strong security control

A minimal or distroless runtime image removes software that the application
does not need, such as shells, package managers and many operating-system
utilities. This reduces both the number of packages that can contain
vulnerabilities and the tools available to an attacker after a compromise.

The QuickNotes runtime uses `gcr.io/distroless/static-debian12:nonroot`, while
compilation happens in a separate Go builder stage. Therefore the compiler and
other build tools are not included in the final runtime image.

### c. When `.trivyignore` is legitimate and when it becomes security theater

`.trivyignore` is legitimate when a finding has been investigated and there is
a documented reason why it cannot currently be fixed or is not applicable.
The exception should have an owner/reason and a review or expiration date.

It becomes security theater when findings are ignored only to make the scanner
green, without investigating reachability or documenting why the risk is
acceptable. Broad or permanent suppressions can hide new real vulnerabilities.

### d. Concrete future problem solved by the SBOM

An SBOM provides an inventory of the components and versions shipped in an
artifact. If a major vulnerability such as Log4Shell is announced, teams can
search SBOMs to determine which deployed artifacts contain the affected
component instead of manually inspecting every repository and image.

For QuickNotes, the CycloneDX SBOM records the container and its Go components,
so a newly disclosed vulnerability can be mapped back to the exact shipped
artifact and dependency version.

---

# Task 2 — OWASP ZAP Baseline and Security Header Fix

## 2.1 ZAP version and baseline scan

Pinned ZAP image:

```text
ghcr.io/zaproxy/zaproxy:2.16.1
```

Before-fix command:

```bash
docker run --rm \
  -v "$(pwd)/submissions/lab9-assets/zap-before:/zap/wrk/:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py \
  -t http://host.docker.internal:8080/notes \
  -r zap-before.html \
  -J zap-before.json
```

The baseline scan produced four types of findings.

### ZAP finding triage

| ID | Finding | Risk | URL / parameter | Disposition | Reason |
|---|---|---|---|---|---|
| 90004 | Insufficient Site Isolation Against Spectre Vulnerability | Low (Medium confidence) | `/notes`, `Cross-Origin-Resource-Policy` | ACCEPT | QuickNotes is a JSON API rather than a browser-rendered application. The missing isolation header has limited impact in the current local lab deployment. Re-evaluate by 2026-12-31. |
| 10021 | X-Content-Type-Options Header Missing | Low (Medium confidence) | `/notes`, `x-content-type-options` | FIX | The header can be applied centrally with middleware at very low cost and prevents MIME sniffing. |
| 10116 | ZAP is Out of Date | Low (High confidence) | `/robots.txt` | FALSE POSITIVE | This describes the scanner environment/version rather than a vulnerability in QuickNotes. ZAP 2.16.1 is deliberately pinned for reproducibility. |
| 10049 | Storable and Cacheable Content | Informational (Medium confidence) | `/`, `/notes`, `/robots.txt`, `/sitemap.xml` | ACCEPT | The lab API has no authentication or per-user private content. Caching therefore has low security impact in the current deployment. Re-evaluate by 2026-12-31. |

Full before-scan artifacts:

- `submissions/lab9-assets/zap-before/zap-before.html`
- `submissions/lab9-assets/zap-before/zap-before.json`

---

## 2.2 Fix: X-Content-Type-Options

A security middleware was added around the complete router rather than to an
individual handler:

```go
func (s *Server) Routes() http.Handler {
    mux := http.NewServeMux()
    mux.HandleFunc("GET /health", s.wrap(s.handleHealth))
    mux.HandleFunc("GET /metrics", s.wrap(s.handleMetrics))
    mux.HandleFunc("GET /notes", s.wrap(s.handleListNotes))
    mux.HandleFunc("POST /notes", s.wrap(s.handleCreateNote))
    mux.HandleFunc("GET /notes/{id}", s.wrap(s.handleGetNote))
    mux.HandleFunc("DELETE /notes/{id}", s.wrap(s.handleDeleteNote))

    return securityHeaders(mux)
}

func securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("X-Content-Type-Options", "nosniff")
        next.ServeHTTP(w, r)
    })
}
```

This wraps the router itself, so the security header is applied to all
QuickNotes routes.

A unit test verifies the header:

```go
func TestSecurityHeaders_XContentTypeOptions(t *testing.T) {
    srv := newTestServer(t)
    rec := do(t, srv, http.MethodGet, "/health", nil)

    if got := rec.Header().Get("X-Content-Type-Options"); got != "nosniff" {
        t.Errorf("X-Content-Type-Options = %q, want %q", got, "nosniff")
    }
}
```

The test passes with the middleware present and would fail if
`securityHeaders(mux)` were replaced with the unwrapped `mux`.

`curl -i http://localhost:8080/notes` after rebuilding the container showed:

```text
X-Content-Type-Options: nosniff
```

---

## 2.3 ZAP rescan

After rebuilding QuickNotes, the same pinned ZAP image was used again.

The original finding:

```text
10021 | X-Content-Type-Options Header Missing
```

is absent from `zap-after.json`.

The ZAP output reports it as a passed check:

```text
PASS: X-Content-Type-Options Header Missing [10021]
```

Remaining findings are:

```text
90004  Insufficient Site Isolation Against Spectre Vulnerability
10116  ZAP is Out of Date
10049  Storable and Cacheable Content
```

This demonstrates that the application change removed finding `10021` while
the other explicitly triaged findings remained.

Full after-scan artifacts:

- `submissions/lab9-assets/zap-after/zap-after.html`
- `submissions/lab9-assets/zap-after/zap-after.json`

---

## 2.4 Design questions

### e. Why middleware instead of adding the header to each handler?

Security headers are a cross-cutting concern and should be applied
consistently. Middleware provides one enforcement point for every route.
Adding the header manually to individual handlers is easy to forget when a new
endpoint is introduced and creates duplicated security logic.

Wrapping the router also makes the policy easier to review and test.

### f. What would `Content-Security-Policy: default-src 'none'` break?

`default-src 'none'` denies loading resources unless another CSP directive
explicitly permits them. A normal website could therefore lose JavaScript,
stylesheets, images, fonts and other resources.

For a JSON-only API such as QuickNotes, responses are data rather than rendered
web pages, so these browser resources are not required. Such a restrictive
policy can therefore be reasonable for an API while being too restrictive for
a normal frontend website without additional CSP directives.

### g. Cost of blindly accepting informational or false-positive findings

Even low-severity or informational findings can reveal configuration mistakes
or become important after the application changes. Blindly accepting them
creates alert fatigue and can hide real regressions among ignored findings.

Each finding should therefore have a concrete reason for acceptance or
suppression and should be reviewed when the deployment model changes.

---

# Bonus — govulncheck CI Gate

## CI integration

A dedicated `Govulncheck` job was added to `.github/workflows/ci.yml`.

The scanner itself is pinned:

```yaml
- name: Install govulncheck
  run: go install golang.org/x/vuln/cmd/govulncheck@v1.8.0

- name: Run govulncheck
  working-directory: ./app
  run: govulncheck ./...
```

The job is included in the aggregate `CI OK` gate:

```yaml
ci-ok:
  name: CI OK
  if: always()
  needs:
    - vet
    - test
    - lint
    - govulncheck
```

Therefore a failing `Govulncheck` job also makes `CI OK` fail and blocks the
security gate.

### Go toolchain note

The original Lab 3 CI baseline uses Go 1.24. When the new security gate was
first executed with Go 1.24.13, the current Go vulnerability database reported
15 reachable vulnerabilities in the Go standard library. Their listed fixes
start in Go 1.25.x, so there was no patched Go 1.24 version available in the
scanner results.

Suppressing the findings or forcing `govulncheck` to return success would make
the security gate ineffective. Therefore the dedicated security scan uses
Go 1.25.13, while the existing Vet/Test matrix continues to test Go 1.23 and
Go 1.24. This deviation is documented rather than hiding the findings.

---

## Vulnerability gate demonstration

A clean baseline run passed all CI jobs, including `Govulncheck`.

For the negative test, the known vulnerable dependency was temporarily added:

```text
golang.org/x/text v0.3.5
```

and the healthcheck executable made a reachable call:

```go
_, _ = language.Parse("en-US")
```

Local `govulncheck` detected:

```text
Vulnerability #1: GO-2021-0113
Out-of-bounds read in golang.org/x/text/language

Found in: golang.org/x/text@v0.3.5
Fixed in: golang.org/x/text@v0.3.7

cmd/healthcheck/main.go:11:23:
healthcheck.main calls language.Parse
```

The scanner exited with status 3.

The temporary vulnerable change was pushed in commit:

```text
6fac4da test(lab9): demonstrate govulncheck gate
```

GitHub Actions then showed:

```text
Vet / Go 1.23     PASS
Vet / Go 1.24     PASS
Test / Go 1.23    PASS
Test / Go 1.24    PASS
Lint              PASS
Govulncheck        FAIL
CI OK              FAIL
```

This proves that a reachable vulnerability blocks the CI gate rather than only
being logged as a warning.

The vulnerable commit was then reverted:

```text
497d8c9 Revert "test(lab9): demonstrate govulncheck gate"
```

The next GitHub Actions run returned to:

```text
Vet / Go 1.23     PASS
Vet / Go 1.24     PASS
Test / Go 1.23    PASS
Test / Go 1.24    PASS
Lint              PASS
Govulncheck        PASS
CI OK              PASS
```

The final repository therefore does not contain the intentionally vulnerable
dependency.

---

## Bonus design questions

### h. What does reachability mean and how does it reduce triage workload?

A dependency scanner can report a vulnerability simply because a vulnerable
package/version exists in the dependency graph. Reachability analysis goes
further and determines whether application code can actually reach the
vulnerable function.

For example, during the demonstration `govulncheck` did not only identify
`golang.org/x/text v0.3.5`; it produced a call trace from
`healthcheck.main` to `language.Parse`. This gives higher-priority evidence
than a vulnerable package that is installed but whose affected symbols are
never called, reducing the number of findings that require immediate manual
investigation.

### i. Why pin the scanner version?

Pinning the scanner makes CI reproducible. If `@latest` were used, a new
scanner release could unexpectedly change detection behaviour, output format
or compatibility and break CI without any repository change.

Using `govulncheck@v1.8.0`, Trivy 0.74.0 and ZAP 2.16.1 makes it clear which
tool versions produced the recorded results.

### j. What can Trivy image scanning detect that govulncheck misses?

`govulncheck` focuses on vulnerabilities in Go code and dependencies and uses
call-graph reachability.

A Trivy image scan examines the complete container artifact. It can detect
operating-system packages, libraries and other components included in the
image that are outside the Go module dependency graph. Trivy can also inspect
the final binary/container composition.

Therefore the tools are complementary: `govulncheck` provides Go-specific
reachability information, while Trivy checks the broader software supply chain
contained in the final image.