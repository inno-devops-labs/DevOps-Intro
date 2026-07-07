# Lab 9 Submission

Branch for this lab:

```text
git checkout feature/lab8
git checkout -b feature/lab9
```

Artifacts saved in:

- `artifacts/lab9/trivy/`
- `artifacts/lab9/zap/`
- `artifacts/lab9/govuln/`

Tool versions used:

- Trivy: `aquasec/trivy:0.59.1`
- ZAP baseline: `ghcr.io/zaproxy/zaproxy:2.16.1`
- govulncheck: `golang.org/x/vuln/cmd/govulncheck@v1.1.4`

## Task 1 - Trivy: image, filesystem, config, SBOM

### 1.1 Image scan

Command:

```text
docker build -t quicknotes:lab6 ./app
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)/.cache/trivy:/root/.cache/" \
  -v "$(pwd):$(pwd)" \
  -w "$(pwd)" \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL quicknotes:lab6
```

Top of output:

```text
quicknotes:lab6 (debian 12.14)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 14 (HIGH: 13, CRITICAL: 1)

quicknotes (gobinary)
=====================
Total: 14 (HIGH: 13, CRITICAL: 1)
```

Analysis:

The base distroless image itself was clean. The real problem was the Go standard library version inside both compiled binaries. The initial image was built with `golang:1.24.5-alpine`, so Trivy reported the same vulnerable stdlib set in both `quicknotes` and `healthcheck`.

### 1.2 Filesystem scan

Command:

```text
docker run --rm \
  -v "$(pwd)/.cache/trivy:/root/.cache/" \
  -v "$(pwd):$(pwd)" \
  -w "$(pwd)" \
  aquasec/trivy:0.59.1 fs --severity HIGH,CRITICAL .
```

Top of output:

```text
.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
```

Analysis:

Trivy found a Vagrant-generated private key inside `.vagrant/`. This is a real secret, but it is a local machine artifact, not project code. It must never be committed. The scan is useful because it shows why repository-root scans can catch dangerous local leftovers too.

### 1.3 Config scan

Command:

```text
docker run --rm \
  -v "$(pwd)/.cache/trivy:/root/.cache/" \
  -v "$(pwd):$(pwd)" \
  -w "$(pwd)" \
  aquasec/trivy:0.59.1 config .
```

Initial result:

```text
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

After fix:

```text
Detected config files    num=1
```

Analysis:

This scan did not produce any HIGH or CRITICAL findings. Still, I fixed the low-severity Dockerfile issue by adding an image-level `HEALTHCHECK`. That makes the image stronger and keeps the Dockerfile consistent with the runtime health check.

### 1.4 SBOM generation

Command:

```text
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)/.cache/trivy:/root/.cache/" \
  -v "$(pwd):$(pwd)" \
  -w "$(pwd)" \
  aquasec/trivy:0.59.1 image --format cyclonedx \
  --output artifacts/lab9/trivy/quicknotes-lab6.cdx.json quicknotes:lab6
```

First 30 lines:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:6ef13561-efe3-4a3f-a988-4f0867993ab4",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T10:52:40+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3A1084306438af7a05ea47907b6995ae7f0d784c4ee109ee8b0115ad1654c62c75?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A1084306438af7a05ea47907b6995ae7f0d784c4ee109ee8b0115ad1654c62c75?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:00848f675cd18be33b3e75e981a6742af6bd9c4467ac23aaf7e748741e72cd59"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
```

Analysis:

The SBOM gives me a component list today, before an incident happens. If a future advisory affects a Go image layer, a distroless base, or a transitive dependency, I can search the SBOM quickly instead of guessing what was deployed months ago.

### 1.5 Triage table for every HIGH or CRITICAL finding

I made one remediation first:

- updated `app/Dockerfile` from `golang:1.24.5-alpine` to `golang:1.25.11-alpine`
- added `HEALTHCHECK` to `app/Dockerfile`

Rebuild result:

```text
quicknotes:lab9 (debian 12.14)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```

The table below covers every unique HIGH or CRITICAL finding seen in the Trivy scans. The same binary findings first appeared in both `quicknotes` and `healthcheck`, then disappeared after the final Go upgrade.

| Finding | Targets | Severity | Disposition | Reason | Re-check / Evidence |
| --- | --- | --- | --- | --- | --- |
| `CVE-2025-68121` | `quicknotes`, `healthcheck` | CRITICAL | FIX | Fixed by upgrading the builder image until the final rebuilt image had zero HIGH or CRITICAL findings. | See `app/Dockerfile` |
| `CVE-2025-61726` | `quicknotes`, `healthcheck` | HIGH | FIX | Fixed by upgrading the builder image from `1.24.5` to `1.25.11`. | See `app/Dockerfile` |
| `CVE-2025-61729` | `quicknotes`, `healthcheck` | HIGH | FIX | Fixed by upgrading the builder image from `1.24.5` to `1.25.11`. | See `app/Dockerfile` |
| `GO-2026-5039` | `quicknotes` runtime path | HIGH | FIX | `govulncheck` on CI showed a reachable stdlib issue in the Go `1.24.13` line. Moving CI and builds to `1.25.11` removed it. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-5037` | `quicknotes` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-4971` | `quicknotes`, `healthcheck` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-4947` | `quicknotes` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-4946` | `quicknotes` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-4918` | `healthcheck` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-4870` | `quicknotes`, `healthcheck` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-4602` | `quicknotes` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `GO-2026-4601` | `quicknotes`, `healthcheck` runtime path | HIGH | FIX | Fixed by upgrading the toolchain to `1.25.11`. | See `.github/workflows/ci.yml` and `app/Dockerfile` |
| `AsymmetricPrivateKey` in `.vagrant/machines/default/virtualbox/private_key` | filesystem scan | HIGH | FALSE POSITIVE | The scanner is correct that the file is a private key, but it is a local Vagrant artifact, not repository content to ship or commit. | Keep `.vagrant/` untracked and re-check before submission |

### 1.6 Design answers

#### a) CVE severity is one input, not the answer

Severity alone is not enough. I also need to ask:

- can my code actually reach the vulnerable function;
- is there public exploit code already;
- is the service internet-facing or only local;
- do I have compensating controls such as distroless, no shell, non-root user, or no TLS feature in use;
- is there a fixed version in the same supported release line.

That is why I did not treat every HIGH as equal.

#### b) Why a minimal base image is the strongest single control

A minimal base removes packages, shells, package managers, and extra libraries. Fewer components mean fewer CVEs, less attack surface, and less work during patching.

This lab showed that clearly: the distroless OS layer had zero HIGH or CRITICAL findings, while the main risk came from the application binary toolchain version.

#### c) When `.trivyignore` is useful and when it is theater

It is valid when:

- the finding is documented;
- the reason is specific;
- there is an owner;
- there is a review date.

It becomes security theater when it is used only to make dashboards green. If nobody can explain why a finding is ignored, the ignore file is just a way to hide debt.

#### d) What future problem the SBOM solves

The SBOM answers a future incident question fast: "Was this component in our deployed image?" That matters in incidents like Log4Shell. Without an SBOM, teams lose time searching repos, images, and old build logs. With an SBOM, the first answer becomes much faster and more reliable.

## Task 2 - ZAP baseline and code fix

### 2.1 Baseline scan before the fix

Command:

```text
docker run --rm \
  --add-host host.docker.internal:host-gateway \
  -v "$(pwd)/artifacts/lab9/zap:/zap/wrk" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py -t http://127.0.0.1:8080/notes \
  -J before-notes.json -r before-notes.html -w before-notes.md
```

Summary:

```text
| Risk Level | Number of Alerts |
| Low        | 3                |
| Info       | 1                |

| Name                                                   | Risk Level |
| Insufficient Site Isolation Against Spectre Vulnerability | Low     |
| X-Content-Type-Options Header Missing                  | Low        |
| ZAP is Out of Date                                     | Low        |
| Storable and Cacheable Content                         | Informational |
```

Analysis:

The meaningful application findings were missing response headers. That is a good fit for a middleware fix, because the issue affects all routes and should not be patched handler by handler.

### 2.2 Code fix

Changed files:

- `app/security.go`
- `app/handlers.go`
- `app/main.go`
- `app/handlers_test.go`

I implemented one global middleware that wraps the router and sets:

- `X-Content-Type-Options: nosniff`
- `Cross-Origin-Resource-Policy: same-origin`
- `Cross-Origin-Opener-Policy: same-origin`
- `X-Frame-Options: DENY`
- `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`
- `Cache-Control: no-store`
- `Pragma: no-cache`

Validation:

```text
cd app
go test -race -count=1 ./...

ok  	quicknotes	1.631s
?   	quicknotes/cmd/healthcheck	[no test files]
```

Runtime proof from the patched app:

```text
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'
Content-Type: application/json
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Pragma: no-cache
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

Analysis:

This is the right shape of fix because it is central, testable, and hard to forget on future routes.

### 2.3 Baseline scan after the fix

Command:

```text
docker run --rm \
  --add-host host.docker.internal:host-gateway \
  -v "$(pwd)/artifacts/lab9/zap:/zap/wrk" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py -t http://host.docker.internal:18083/notes \
  -J after.json -r after.html -w after.md
```

Summary:

```text
| Risk Level | Number of Alerts |
| Low        | 1                |
| Info       | 1                |

| Name                 | Risk Level |
| ZAP is Out of Date   | Low        |
| Non-Storable Content | Informational |
```

Analysis:

The two application header findings are gone. The only remaining low issue is about the scanner version itself, not the app. The informational cache message is expected after intentionally disabling cache storage.

### 2.4 Full ZAP triage table

| ID | Finding | Risk | Affected URL / parameter | Disposition | Reason |
| --- | --- | --- | --- | --- | --- |
| `10021` | X-Content-Type-Options Header Missing | Low | `/notes`, `x-content-type-options` | FIX | Added `X-Content-Type-Options: nosniff` in global middleware. The alert disappears in the final re-scan. |
| `90004` | Insufficient Site Isolation Against Spectre Vulnerability | Low | `/notes`, `Cross-Origin-Resource-Policy` | FIX | Added `Cross-Origin-Resource-Policy: same-origin` in global middleware. The alert disappears in the final re-scan. |
| `10116` | ZAP is Out of Date | Low | scan environment | SUPPRESS | This is about the pinned scanner image, not the QuickNotes app. The lab asked for `2.16.x`, while ZAP reports `2.17.0` as newest. |
| `10049` | Storable and Cacheable Content | Informational | `/notes` and discovered URLs | FIX | Added `Cache-Control: no-store` and `Pragma: no-cache`. After the fix, ZAP reports `Non-Storable Content`, which is expected for intentionally non-cacheable responses. |
| `10049` | Non-Storable Content | Informational | `/notes` and discovered URLs | ACCEPT | This is expected after the cache-control fix. It documents the hardened behavior, not a new weakness. |

### 2.5 Before and after proof

Before:

```text
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
WARN-NEW: Insufficient Site Isolation Against Spectre Vulnerability [90004] x 1
WARN-NEW: ZAP is Out of Date [10116] x 1
WARN-NEW: Storable and Cacheable Content [10049] x 4
```

After:

```text
PASS: X-Content-Type-Options Header Missing [10021]
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
WARN-NEW: ZAP is Out of Date [10116] x 1
WARN-NEW: Non-Storable Content [10049] x 4
```

### 2.6 Design answers

#### e) Why middleware and not per-handler headers

Middleware keeps the security policy in one place. If I set headers inside each handler, I will eventually forget one route or one error path. Middleware makes the default safe and keeps tests simple.

#### f) What `Content-Security-Policy: default-src 'none'` breaks

It blocks scripts, styles, images, fonts, frames, and network requests unless they are allowed explicitly. That would break a normal website very quickly.

For QuickNotes this is fine because it is an API that returns JSON, not an HTML application with browser assets. For a website, I would need a more detailed policy.

#### g) Cost of marking all informational findings as accepted

If I accept everything without reading, I stop learning what the scanner is telling me. That creates alert fatigue and hides real changes. A noisy informational finding today can become an important signal later when the app behavior changes.

## Bonus Task - govulncheck as a CI PR gate

### B.1 Workflow change

I added `.github/workflows/ci.yml` and included a dedicated `govulncheck` job:

```yaml
  govulncheck:
    name: govulncheck
    runs-on: ubuntu-24.04
    defaults:
      run:
        working-directory: app
    steps:
      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10
      - uses: actions/setup-go@4a3601121dd01d1626a1e23e37211e3254c1c06c
        with:
          go-version: ${{ env.GO_VERSION }}
          cache: true
          cache-dependency-path: app/go.mod
      - run: go install golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION}
      - run: '"$(go env GOPATH)/bin/govulncheck" ./...'
```

Analysis:

This job is separate, pinned, and easy to understand in a PR. If it fails, the PR gets a dedicated red check instead of hiding the result inside a bigger test job.

I first tried to keep the gate on Go `1.24`, but the PR checks showed reachable standard-library vulnerabilities with no passing result on that line. The correct engineering response was to upgrade the CI and builder toolchain to Go `1.25.11`, then verify that `govulncheck` and Trivy both passed.

### B.2 Red and green proof

Because a real GitHub Actions run needs a push, I created local proof with the same pinned scanner command.

Red case:

I made a temporary copy of `app/`, added `golang.org/x/text@v0.3.5`, and called `language.Parse` from `vuln_demo.go`.

Output:

```text
=== Symbol Results ===

Vulnerability #1: GO-2021-0113
    Out-of-bounds read in golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2021-0113
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.5
    Fixed in: golang.org/x/text@v0.3.7
    Example traces found:
      #1: vuln_demo.go:6:23: quicknotes.init#1 calls language.Parse

Your code is affected by 1 vulnerability from 1 module.
```

Green case on the real app:

```text
No vulnerabilities found.
```

Analysis:

This is the key difference between simple dependency presence and reachability. The red case fails only after I introduce a vulnerable dependency and a reachable call path.

### B.3 Design answers

#### h) Why reachability matters

If a module has a CVE but my code never calls the vulnerable function, the risk is lower and the triage work is smaller. Reachability helps me focus on what can really execute in my app, instead of treating every transitive dependency as an emergency.

#### i) Why pin the scanner version

I pin the scanner so that CI is reproducible. If I use `@latest`, the rules and behavior can change without any code change in my repo. That makes CI noisy and hard to trust.

#### j) What govulncheck does not catch

`govulncheck` only understands Go vulnerabilities. It will not catch base image CVEs, OS packages, leaked secrets, Docker misconfigurations, or scanner findings from a running HTTP surface. That is why I still need Trivy and ZAP.

## Final notes

Main engineering changes in this lab:

- added security headers middleware with tests;
- updated Docker builder image from Go `1.24.5` to `1.25.11`;
- added Dockerfile `HEALTHCHECK`;
- added CI workflow with a pinned `govulncheck` job;
- saved full scan artifacts under `artifacts/lab9/`.

Manual follow-up after push:

- push `feature/lab9` to GitHub;
- capture GitHub Actions screenshots for the bonus if you want visual evidence in addition to the local logs already saved here.
