# Lab 9 — DevSecOps: Trivy and OWASP ZAP

I scanned QuickNotes with pinned scanner images, triaged every finding, fixed the actionable findings, and retained machine-readable evidence for review.

## Reproduction

I used:

- `aquasec/trivy:0.59.1`
- `ghcr.io/zaproxy/zaproxy:2.16.1`
- `quicknotes:lab6`

The complete workflow is implemented in [`scripts/lab9-capture.sh`](../scripts/lab9-capture.sh):

```bash
scripts/lab9-capture.sh prepare
scripts/lab9-capture.sh trivy
scripts/lab9-capture.sh zap before
# Apply the security-header middleware and rebuild.
scripts/lab9-capture.sh prepare
scripts/lab9-capture.sh zap after
```

For the repository scans, I excluded only local, git-ignored machine state: `.git`, `.goenv`, `.venv`, and `.vagrant`. These directories are not repository dependencies or deployable content. In particular, excluding `.vagrant` prevents a generated VM private key from being misrepresented as a secret committed to the repository.

## Task 1 — Trivy

### Scan artifacts and output excerpts

The final image scan reports no HIGH or CRITICAL findings:

```text
quicknotes:lab6 (debian 12.15)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

The clean-scope filesystem JSON report contains one scanned target, `app/go.mod`, and no `Vulnerabilities`, `Misconfigurations`, or `Secrets` arrays. Therefore its totals are:

```text
Target: app/go.mod
HIGH: 0
CRITICAL: 0
Secrets: 0
```

The config scan found the Dockerfile and passed all checks:

```json
{
  "Target": "app/Dockerfile",
  "Class": "config",
  "Type": "dockerfile",
  "MisconfSummary": {
    "Successes": 21,
    "Failures": 0
  }
}
```

The reports are available here:

- [Initial image scan (text)](evidence/lab9/trivy-image-before.txt)
- [Initial image scan (JSON)](evidence/lab9/trivy-image-before.json)
- [Final image scan (text)](evidence/lab9/trivy-image.txt)
- [Final image scan (JSON)](evidence/lab9/trivy-image.json)
- [Filesystem scan (text)](evidence/lab9/trivy-filesystem.txt)
- [Filesystem scan (JSON)](evidence/lab9/trivy-filesystem.json)
- [Config scan (text)](evidence/lab9/trivy-config.txt)
- [Config scan (JSON)](evidence/lab9/trivy-config.json)
- [CycloneDX SBOM](evidence/lab9/quicknotes-lab6.cdx.json)

With Trivy 0.59.1, I generated an image SBOM using `trivy image --format cyclonedx`; the `trivy sbom` subcommand consumes an existing SBOM as a scan target rather than generating one.

The first 30 lines of the CycloneDX SBOM are:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:64e42213-d9c5-4727-ab62-546632a3e4fa",
  "version": 1,
  "metadata": {
    "timestamp": "2026-10-01T13:14:01+00:00",
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
      "bom-ref": "cc2c1bc3-93bf-4dea-8135-6f15cd3965af",
      "type": "container",
      "name": "quicknotes:lab6",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:0df798f8a267f401c4361b51ae4440abb4eae919c7f841e8e9b837619246aefd"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:114dde0fefebbca13165d0da9c500a66190e497a82a53dcaabc3172d630be1e9"
```

### HIGH/CRITICAL triage

The initial image contained 19 unique HIGH Go standard-library findings. Each finding occurred in both Go binaries (`quicknotes` and `healthcheck`), so every row below covers both reported occurrences. There were no CRITICAL findings. I fixed all 38 occurrences by updating the builder from Go `1.24.13` to `1.26.6` in [`app/Dockerfile`](../app/Dockerfile). The final image scan proves that no HIGH or CRITICAL finding remains.

| Finding | Affected component and targets | Disposition | Decision |
|---|---|---|---|
| CVE-2026-25679 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the `net/url` IPv6 parsing fix. |
| CVE-2026-27145 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the `crypto/x509` DNS SAN processing fix. |
| CVE-2026-32280 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the certificate-chain DoS fix. |
| CVE-2026-32281 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the certificate validation complexity fix. |
| CVE-2026-32283 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the TLS 1.3 KeyUpdate DoS fix. |
| CVE-2026-33811 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the long-CNAME lookup fix. |
| CVE-2026-33814 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the malformed HTTP/2 SETTINGS fix. |
| CVE-2026-33818 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the ASN.1 recursion fix. |
| CVE-2026-39820 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the crafted `net/mail` input fix. |
| CVE-2026-39821 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the IDNA/Punycode processing fix. |
| CVE-2026-39822 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the `os.Root` symlink traversal fix. |
| CVE-2026-39836 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the NUL-byte network handling fix. |
| CVE-2026-42499 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the pathological email address parsing fix. |
| CVE-2026-42504 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the malicious MIME header fix. |
| CVE-2026-56853 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the unencrypted HTTP/2 DoS fix. |
| CVE-2026-56858 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the `html/template` pathological-input fix. |
| CVE-2026-56859 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the XML recursion-depth fix. |
| CVE-2026-56860 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the quadratic URL path-resolution fix. |
| CVE-2026-56862 | `stdlib v1.24.13`; both binaries | **FIX** | Go 1.26.6 contains the indefinite TLS KeyUpdate fix. |

The clean-scope filesystem and config scans contained no HIGH/CRITICAL finding requiring a disposition.

### Design questions

#### a) What matters beyond CVE severity?

I also consider whether the vulnerable function is reachable, whether a practical exploit exists, which privileges and data the process has, whether the input is attacker-controlled, and which compensating controls exist. An internet-facing parsing flaw is different from the same package in an offline tool. I also consider exploit complexity, blast radius, runtime configuration, and patch availability before choosing a disposition.

#### b) Why is a minimal base image such a strong control?

A minimal or distroless runtime removes shells, package managers, utilities, and libraries that the application does not need. This reduces both the number of components that can contain vulnerabilities and the tools available to an attacker after compromise. It also reduces patching and triage noise, making real application findings easier to see.

#### c) When is `.trivyignore` appropriate?

It is appropriate only for a verified false positive or a documented, time-bounded risk acceptance with an owner, rationale, and review date. It becomes security theater when it is used to make a report green without investigating reachability or remediation. I did not add `.trivyignore`; the actionable image findings were fixed instead.

#### d) What future problem does today's SBOM solve?

When a new incident such as Log4Shell is disclosed, the SBOM lets me quickly query whether the affected component and version were shipped without rebuilding or reverse-engineering an old image. It supports impact analysis, customer responses, targeted patching, and software supply-chain inventory for the exact artifact.

## Task 2 — OWASP ZAP baseline

I used `zap-baseline.py`, which performs passive scanning only. The full reports are:

- [Before report (HTML)](evidence/lab9/zap-before.html)
- [Before report (JSON)](evidence/lab9/zap-before.json)
- [After report (HTML)](evidence/lab9/zap-after.html)
- [After report (JSON)](evidence/lab9/zap-after.json)

### Before triage

| ID and finding | Risk | Affected URL / parameter | Disposition | Decision |
|---|---|---|---|---|
| 10049-3 — Storable and Cacheable Content | Informational (Medium confidence) | `/`, `/robots.txt`, `/sitemap.xml`; response caching policy | **FIX** | Responses had no explicit cache policy. I added `Cache-Control: no-store` in middleware. |
| 10116 — ZAP is Out of Date | Low (High confidence) | `/robots.txt`; no parameter | **ACCEPT** | Lab 9 explicitly requires a pinned ZAP 2.16.x image. I used 2.16.1 for reproducibility and will reassess the pin by 2027-03-31. |

### Code fix and test

[`app/handlers.go`](../app/handlers.go) now wraps the complete router in `securityHeaders`. The middleware applies these headers to registered routes and router-generated errors:

```text
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

[`app/handlers_test.go`](../app/handlers_test.go) checks all five headers on the API root, `/health`, and a router-generated `404`. Removing the middleware makes this test fail. The final Docker build ran `go test ./...` in its builder stage before producing the scanned image.

### After evidence and triage

The original finding is absent after the rebuild:

```text
Before: WARN-NEW: Storable and Cacheable Content [10049] x 3
After:  WARN-NEW: Non-Storable Content [10049] x 3
```

The changed rule name is meaningful: ZAP now observes that the responses cannot be stored. The final baseline scanned the API root successfully with `200 OK` and reported zero failures.

| ID and finding | Risk | Affected URL / parameter | Disposition | Decision |
|---|---|---|---|---|
| 10049-1 — Non-Storable Content | Informational (Medium confidence) | `/`, `/robots.txt`, `/sitemap.xml`; response caching policy | **FALSE POSITIVE** | This is the intended secure result of `Cache-Control: no-store`, not a vulnerability. |
| 10116 — ZAP is Out of Date | Low (High confidence) | `/sitemap.xml`; no parameter | **ACCEPT** | The scanner is intentionally pinned to the required 2.16.x line; reassess by 2027-03-31. |
| 90004-1 — Insufficient Site Isolation Against Spectre Vulnerability | Low (Medium confidence) | `/`; `Cross-Origin-Resource-Policy` | **ACCEPT** | QuickNotes returns JSON and serves no browser UI, scripts, or cross-origin subresources. COOP/COEP/CORP would provide negligible protection here and could unnecessarily restrict future API clients. Reassess if a browser UI is added. |

### Design questions

#### e) Why use middleware instead of setting headers in every handler?

Middleware creates one policy boundary around the router. New routes and framework-generated errors inherit the policy automatically, while per-handler changes are repetitive and easy to forget. A single middleware is also easier to test, review, and update consistently.

#### f) What does `Content-Security-Policy: default-src 'none'` break?

It blocks scripts, styles, images, fonts, frames, network connections, and other browser-loaded resources unless a more specific directive allows them. That would break a normal website or Swagger UI. QuickNotes is a JSON API with no client-side assets, so the strict default does not interfere with its intended behavior.

#### g) What is the cost of accepting informational findings without reading them?

Blind acceptance hides real context, creates alert fatigue, and makes future reviews unable to distinguish harmless observations from exploitable conditions. It can also normalize exceptions until a deployment change makes an old finding dangerous. Each finding still needs evidence, a reason, and a review trigger even when its scanner risk is informational.

## Verification summary

- Trivy image scan: **0 HIGH, 0 CRITICAL** after remediation.
- Trivy filesystem scan: **0 HIGH, 0 CRITICAL, 0 secrets** in repository scope.
- Trivy config scan: **21 passed, 0 failed**.
- CycloneDX SBOM: generated with 12 components.
- ZAP baseline: **0 failures**; the cacheable-content finding was removed.
- Go tests: passed during the final multi-stage Docker build.

## Bonus

I did not attempt the optional `govulncheck` CI bonus. The mandatory 10-point scope is complete.
