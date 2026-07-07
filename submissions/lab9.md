# Lab 9 Submission

Host used for the run: Ubuntu 24.04.3 LTS x86_64 cloud server with Docker 29.4.2. Scanners: Trivy `0.59.1`, ZAP `2.16.1`.

## Task 1 - Trivy Scans + SBOM

### Image scan (`trivy image quicknotes:lab6`)

```text
quicknotes:lab6 (debian 12.14)
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)

quicknotes (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)
```

Full output: `lab9-artifacts/trivy-image.txt`.

### Filesystem scan (`trivy fs`)

```text
$ trivy fs --severity HIGH,CRITICAL /repo
(no HIGH/CRITICAL findings)
```

Full output: `lab9-artifacts/trivy-fs.txt`.

### Config scan (`trivy config`)

```text
$ trivy config --severity HIGH,CRITICAL /repo
(no HIGH/CRITICAL misconfigurations)
```

Full output: `lab9-artifacts/trivy-config.txt`.

### SBOM (`trivy image --format cyclonedx`)

First lines of `lab9-artifacts/quicknotes.sbom.cdx.json`:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:4ee1a9b4-26cd-47e7-a4ef-d586c2403124",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T20:15:26+00:00",
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
      "type": "container",
      "name": "quicknotes:lab6"
    }
  }
}
```

### Trivy triage (HIGH/CRITICAL)

| Finding | Severity | Disposition | Reason |
|---------|----------|-------------|--------|
| Debian 12.14 OS packages in `quicknotes:lab6` image | HIGH/CRITICAL | N/A | Trivy reported `0` OS-layer HIGH/CRITICAL on distroless runtime |
| Go stdlib CVEs in `quicknotes` binary (11 HIGH, e.g. CVE-2026-33811, CVE-2026-42504) | HIGH | WATCH | Findings are in the compiled stdlib inside the static binary; Trivy marks several as `fixed` in newer Go releases. Re-check on next image rebuild after bumping builder Go patch version |
| Go stdlib CVEs in `healthcheck` binary (11 HIGH) | HIGH | ACCEPT | Auxiliary probe binary is not exposed as a service; same stdlib scanner noise as main binary. Re-evaluate by 2026-12-31 |

### Design answers

a) CVE severity alone is not enough. I also consider reachability (is the vulnerable code path used?), exploit availability, deployment exposure (internal API vs public internet), and blast radius if compromised.

b) Distroless removes shells, package managers, and most OS packages, so the runtime image has almost nothing left to patch. That is the strongest single control here because it eliminates whole classes of OS CVEs before triage even starts.

c) `.trivyignore` is right for documented, time-bounded risk acceptance with an owner and re-check date. It is theater when it permanently hides findings that should be fixed or upgraded.

d) The SBOM answers "are we affected by CVE-X?" without rebuilding or guessing. During incidents like Log4Shell, you can query the SBOM for the component name/version instead of auditing every image by hand.

## Task 2 - ZAP Baseline + Security Header Fix

ZAP command:

```bash
docker run --rm --network host \
  -v "$PWD/lab9-artifacts:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py -t http://127.0.0.1:8080/ \
  -r zap-baseline-before.html -J zap-baseline-before.json -I
```

### ZAP triage

| ID | Name | Risk | Disposition | Reason |
|----|------|------|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | FIX | Added `securityHeaders` middleware |
| 90004 | Insufficient Site Isolation Against Spectre Vulnerability | Low | FIX | Added `Cross-Origin-Opener-Policy` and `Cross-Origin-Resource-Policy` |
| 10049 | Storable and Cacheable Content | Informational | ACCEPT | JSON API responses without sensitive session state; acceptable for this lab API. Re-evaluate by 2026-12-31 |
| 10116 | ZAP is Out of Date | Low | FALSE POSITIVE | Scanner container version warning, not a QuickNotes application defect |

### Code fix

Added `app/security.go` middleware and wrapped the router in `app/main.go`:

```go
Handler: securityHeaders(server.Routes()),
```

Headers set on every route: `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`, `Referrer-Policy`, `Permissions-Policy`, `Cross-Origin-Opener-Policy`, `Cross-Origin-Resource-Policy`.

Unit test `TestSecurityHeaders_OnAllRoutes` in `app/security_test.go` asserts the headers on `/`, `/health`, `/notes`, and `/metrics`.

### Before / after evidence

Headers before fix:

```text
$ curl -sI http://127.0.0.1:8080/
HTTP/1.1 200 OK
Content-Type: application/json
Date: Tue, 07 Jul 2026 20:08:57 GMT
```

Headers after fix:

```text
$ curl -sI http://127.0.0.1:8080/
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
```

ZAP summary:

| Report | Plugin 10021 | Plugin 90004 | Other warnings |
|--------|--------------|--------------|----------------|
| `zap-baseline-before.json` | present | present | 10049, 10116 |
| `zap-baseline-after.json` | absent | absent | 10049, 10116 |

Artifacts: `lab9-artifacts/zap-baseline-before.{html,json}`, `lab9-artifacts/zap-baseline-after.{html,json}`.

### Design answers

e) Middleware applies one policy to every handler in a single place. Per-handler header code drifts quickly and is easy to forget on new endpoints.

f) `Content-Security-Policy: default-src 'none'` blocks browsers from loading scripts, styles, or images. That is fine for a JSON API with no HTML UI, but it would break a normal website that needs assets from its own origin or a CDN.

g) Marking every informational ZAP alert as accepted without reading them creates alert fatigue and hides real regressions later. You lose the signal that something actually changed.

## Bonus - govulncheck CI Gate

Added a `govulncheck` job to `.github/workflows/ci.yml`:

```yaml
  govulncheck:
    name: govulncheck
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: actions/setup-go@d35c59abb061a4a6fb18e82ac0862c26744d6ab5
        with:
          go-version: "1.24"
          cache: true
          cache-dependency-path: app/go.mod
      - run: go install golang.org/x/vuln/cmd/govulncheck@v1.1.4
      - run: govulncheck ./...
        working-directory: app
```

### Red / green demonstration

Green run on the submitted code (`lab9-artifacts/govulncheck-green.txt`):

```text
No vulnerabilities found.
```

Red demonstration: temporarily added `golang.org/x/crypto@v0.12.0` and a probe import, then ran `govulncheck -show verbose ./...` (`lab9-artifacts/govulncheck-red-verbose.txt`):

```text
=== Module Results ===

Vulnerability #1: GO-2026-5033
  Module: golang.org/x/crypto
    Found in: golang.org/x/crypto@v0.12.0
    Fixed in: golang.org/x/crypto@v0.52.0

Vulnerability #2: GO-2026-5023
  Module: golang.org/x/crypto
    Found in: golang.org/x/crypto@v0.12.0
    Fixed in: golang.org/x/crypto@v0.52.0
```

The vulnerable dependency was not committed; the final tree stays clean while the CI job blocks reachable Go vulnerabilities on every PR.

### Design answers

h) `govulncheck` distinguishes "module has a CVE" from "our code can reach the vulnerable symbol." That cuts triage noise: a vulnerable test dependency you never call is a different decision than a reachable TLS parser bug.

i) Pinning the scanner version keeps CI reproducible. `@latest` can change rules or vulnerability data between runs and create false red/green flapping.

j) `govulncheck` does not see OS packages, container base layers, or misconfigurations in `Dockerfile` / `compose.yaml`. Trivy image/config scans cover those layers.
