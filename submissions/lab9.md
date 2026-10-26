# Lab 9 — DevSecOps: Trivy + OWASP ZAP

## Scope and result

The mandatory **Task 1 (6 points)** and **Task 2 (4 points)** were completed locally on 2026-10-26. No commit, push, PR creation, or remote repository settings changes were performed, as requested by the repository owner. Submission/PR publication remains a manual step.

The repository started clean on `feature/lab8` at `018641ca642fb30a17a7de1f54825d468da2609b`. A new `feature/lab9` branch was created from that state; the inherited Lab 8 changes were preserved.

The local `labs/lab9.md` and the public [assignment](https://github.com/AlisaRyba/DevOps-Intro/blob/main/labs/lab9.md) had the same SHA-256:

```text
ac4e86a153ca95f83e8411960bfa826ac3074e901471981722e9b786eadf2760
```

Summary of actual results:

| Check | Before | After |
|---|---|---|
| Trivy image, HIGH/CRITICAL | 46 HIGH occurrences: 23 distinct Go stdlib CVEs in each of two binaries; 0 CRITICAL | 0 HIGH/CRITICAL |
| Trivy filesystem, HIGH/CRITICAL | 0 | 0 |
| Trivy configuration | 1 LOW: `DS-0026`, no image HEALTHCHECK; 0 HIGH/CRITICAL | 0 failures, 27 successful checks |
| CycloneDX SBOM | Generated for original image, Go `v1.24.13` | Generated for fixed image, Go `v1.27.3`; re-ingested with `trivy sbom` |
| ZAP baseline | 2 LOW warning types and 2 informational alert variants in JSON; exit 2 | 0 non-informational alerts; exit 0 |
| Regression tests | Middleware removal makes the header test fail | Full race-enabled test suite and `go vet` pass |

Zero findings are limited to the stated scanner scope, severity filter, database snapshot and target. They are not a claim that the application is production-secure.

## Environment and isolation

- Host: macOS Apple Silicon.
- Docker client/server: `29.8.2`; Compose: `v5.6.0`.
- All application, scanner and test images used native `linux/arm64`.
- Trivy: `aquasec/trivy:0.76.1`, digest `sha256:790fd66d1697395d8693d1acaa1ea702406a20f109b6fc7bac8db623eca6c06c`.
- ZAP: `ghcr.io/zaproxy/zaproxy:2.17.0`, digest `sha256:030d3df57735dacbb83464854758e674dd9ad01d79d12a129a8e58b1fd384238`.
- Fixed builder: `golang:1.27.3-alpine`, resolved digest `sha256:b8c9b82affbbb82a020bbcf998dad2ba9516944ac7e883524642a481a9505e9c`.
- Runtime remains distroless Debian 12, non-root; resolved base digest is recorded in [build output](lab9/docker-build.log).

The original Lab 8 stack on host ports 8080/9090/3000 was not stopped, rebuilt or modified. Scans used a dedicated Docker network, `quicknotes-lab9`, with one running application at a time under the alias `quicknotes`. The application listens on port 8080 inside that network; ZAP targets `http://quicknotes:8080`. This is the container-network equivalent of the assignment's local application endpoint, not `localhost` inside the ZAP container.

For host verification, the isolated application is published only on `127.0.0.1:18089`. Its data is seeded from the repository into temporary memory storage, not the user's Lab 8 volume. ZAP's API port is not published. No external target, active scan or AJAX scan was used.

Before image: `quicknotes:lab6`, also retained as `quicknotes:lab9-before`. After image: `quicknotes:lab9`. The original `quicknotes:lab6` tag was not overwritten.

Trivy's image config identifiers (also embedded in the corresponding SBOMs):

```text
before: sha256:804d890a45be678a7a2978eb20e1fd0bdb2e84f78ed880a33deedd8cf30fc05d
after:  sha256:11c8b0f4e2f77186ff2ee84dcfaf0857e6cf06dfa66c4bc6056e8875bd290a5f
```

Docker's manifest/index identifier can differ from this config identifier. Raw [before](lab9/image-before-inspect.json) and [after](lab9/image-after-inspect.json) inspect records are included. The scanner's Git metadata names the unchanged base commit: the fixes are deliberately uncommitted, so that metadata alone must not be interpreted as the complete scanned working tree.

## Reproducible commands

From the repository root, the reusable [scan script](../scripts/lab9/scan.sh) pins both scanner versions and preserves JSON, text, HTML, logs and ZAP exit codes. Trivy receives an exported image archive, **not the Docker socket**.

```bash
# Existing original image; do not rebuild it before the "before" scan.
bash scripts/lab9/scan.sh trivy before

# Network must contain the isolated before image with alias quicknotes.
bash scripts/lab9/scan.sh zap before

docker build --platform linux/arm64 -t quicknotes:lab9 app

# Replace only the isolated lab instance; preserve the Lab 8 stack and data.
bash scripts/lab9/scan.sh trivy after
bash scripts/lab9/scan.sh zap after

ruby scripts/lab9/verify.rb
```

Use the same `LAB9_WORK_DIR` for the Trivy phases to reuse its database cache. If unset, the script creates a temporary directory outside the repository. No scanner cache, image archive or runtime database is a deliverable.

An isolated before instance was created with:

```bash
docker network create --label course.lab=9 quicknotes-lab9
docker image tag quicknotes:lab6 quicknotes:lab9-before

docker run -d --name quicknotes-lab9-before --label course.lab=9 \
  --network quicknotes-lab9 --network-alias quicknotes \
  --publish 127.0.0.1:18089:8080 \
  --env ADDR=:8080 --env DATA_PATH=/data/notes.json \
  --env SEED_PATH=/seed.json \
  --tmpfs /data:rw,uid=65532,gid=65532,mode=0750 \
  quicknotes:lab9-before
```

The before container was stopped before starting `quicknotes-lab9-after` with the same network, alias, port, environment and temporary-data settings, but image `quicknotes:lab9`. These commands change local Docker state; they are a reproduction record, not instructions to run over an existing container with the same name.

# Task 1 — Trivy, triage and SBOM

## Four required outputs

The script runs the equivalent of:

```bash
trivy image --input image-before.tar --scanners vuln \
  --severity HIGH,CRITICAL --format json --output trivy-image-before.json

trivy fs --scanners vuln,secret --severity HIGH,CRITICAL \
  --skip-dirs .git --skip-dirs .vagrant \
  --skip-dirs submissions/lab9 --skip-files .env \
  --format json --output trivy-fs-before.json .

trivy config --skip-dirs .git --skip-dirs .vagrant \
  --skip-dirs submissions/lab9 \
  --format json --output trivy-config-before.json .

trivy image --input image-before.tar \
  --format cyclonedx --output quicknotes-before.sbom.cdx.json
```

Paths above are simplified; the script uses mounted `/work`, `/repo` and `/reports` paths. The archive comes from `docker image save quicknotes:lab6`.

**Assignment syntax clarification:** `trivy sbom` consumes an existing SBOM. Generating an SBOM from an image uses `trivy image --format cyclonedx`, as documented in the [Trivy SBOM guide](https://trivy.dev/docs/latest/guide/supply-chain/sbom/). The generated after SBOM was additionally scanned using `trivy sbom`, with zero HIGH/CRITICAL results in [that JSON](lab9/trivy-sbom-after.json).

Image scan output, top of [complete before text](lab9/trivy-image-before.txt):

```text

Report Summary

┌───────────────────────────────────────┬──────────┬─────────────────┬─────────┬───────────────────┐
│                Target                 │   Type   │ Vulnerabilities │ Secrets │ Misconfigurations │
├───────────────────────────────────────┼──────────┼─────────────────┼─────────┼───────────────────┤
│ /work/image-before.tar (debian 12.15) │  debian  │        0        │    -    │         -         │
├───────────────────────────────────────┼──────────┼─────────────────┼─────────┼───────────────────┤
│ healthcheck                           │ gobinary │       23        │    -    │         -         │
├───────────────────────────────────────┼──────────┼─────────────────┼─────────┼───────────────────┤
│ quicknotes                            │ gobinary │       23        │    -    │         -         │
└───────────────────────────────────────┴──────────┴─────────────────┴─────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


healthcheck (gobinary)
======================
Total: 23 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 23, CRITICAL: 0)
```

Filesystem scan output, top of [complete before text](lab9/trivy-fs-before.txt):

```text

Report Summary

┌────────────┬───────┬─────────────────┬─────────┬───────────────────┐
│   Target   │ Type  │ Vulnerabilities │ Secrets │ Misconfigurations │
├────────────┼───────┼─────────────────┼─────────┼───────────────────┤
│ app/go.mod │ gomod │        0        │    -    │         -         │
└────────────┴───────┴─────────────────┴─────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

Configuration scan output, top of [complete before text](lab9/trivy-config-before.txt):

```text

app/Dockerfile (dockerfile)
===========================
Tests: 1 (SUCCESSES: 0, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.

See https://avd.aquasec.com/misconfig/ds-0026
────────────────────────────────────────
```

SBOM generation output, [complete log](lab9/trivy-sbom-before.log):

```text
2026-10-26T14:37:35Z	INFO	"--format cyclonedx" disables security scanning. Specify "--scanners vuln" explicitly if you want to include vulnerabilities in the "cyclonedx" report.
2026-10-26T14:37:35Z	INFO	Detected OS	family="debian" version="12.15"
2026-10-26T14:37:35Z	INFO	Number of language-specific files	num=2
```

The informational message that CycloneDX generation disables vulnerability scanning is expected: the inventory and the vulnerability report are separate outputs.

## Coverage and limits

The image scan examined five Debian packages plus both `quicknotes` and `healthcheck` Go binaries. Distroless eliminated most OS package surface but did not eliminate vulnerabilities statically linked into the Go executables.

The filesystem scan detected `app/go.mod` and no HIGH/CRITICAL findings or secret findings in scope. It did not inventory a patched Go compiler from the `go 1.24` language directive: there are no external module requirements in that file. Thus a clean filesystem result does **not** contradict the vulnerable image.

The config scan recognized one configuration file, `app/Dockerfile`. This run did **not** analyze Compose as a supported misconfiguration target. `docker compose config --quiet` separately passed; that is model validation, not a substitute for security analysis. Existing Lab 8 port exposure was not silently declared secure or changed in this task.

Excluded paths contain Git internals, VM private runtime state, local credentials and generated reports. Excluding `.env` avoids copying private configuration into scan artifacts. This is not a claim that excluded secrets or the complete workstation were audited. No `.trivyignore` or ZAP suppression file was added.

## Every HIGH/CRITICAL finding: disposition

All 46 occurrences are **FIX**. Each row below applies to **both** named targets, package `stdlib`, installed version `v1.24.13`. All 23 CVEs disappear after rebuilding **both binaries** with Go 1.27.3 via [app/Dockerfile](../app/Dockerfile). The local [code diff](lab9/security-fix.diff) is supplied instead of an invented commit/PR URL; the owner will commit and publish it later.

The deployment notes distinguish exposure from component presence. No exploit was attempted, and absence of an explicit handler is not presented as a formal whole-program reachability proof.

| CVE | Severity | Targets | Disposition | Reason and action |
|---|---|---|---|---|
| CVE-2026-111943 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Certificate validation flaw; the present entrypoints use local HTTP rather than TLS, but future TLS use must not inherit the vulnerable library. Rebuild both binaries with Go 1.27.3. |
| CVE-2026-25679 | HIGH | `healthcheck`, `quicknotes` | **FIX** | URL parsing is relevant to an HTTP program. Replace the vulnerable standard library in both artifacts instead of relying on request-shape assumptions. |
| CVE-2026-27145 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Certificate DNS SAN processing is not a configured local HTTP feature; rebuild both binaries to remove the vulnerable implementation rather than suppress the package finding. |
| CVE-2026-32280 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Certificate-chain construction has limited exposure in the current HTTP-only deployment; nevertheless replace the affected standard library in both binaries. |
| CVE-2026-32281 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Certificate-chain validation is not intentionally exposed by this HTTP-only setup; rebuild both artifacts with the upstream fix rather than permanently accept it. |
| CVE-2026-32283 | HIGH | `healthcheck`, `quicknotes` | **FIX** | No TLS listener is configured, reducing this TLS key-update attack surface. Rebuild both binaries so a later TLS configuration does not reactivate the old implementation. |
| CVE-2026-33811 | HIGH | `healthcheck`, `quicknotes` | **FIX** | The healthcheck connects to a loopback IP and handlers do not explicitly use LookupCNAME. Still rebuild both binaries to eliminate the obsolete resolver implementation. |
| CVE-2026-33814 | HIGH | `healthcheck`, `quicknotes` | **FIX** | No explicit HTTP/2 transport/listener is configured in this lab. Update the bundled HTTP implementation rather than claim package presence proves exploitation. |
| CVE-2026-33818 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Handlers decode JSON, not ASN.1. Reachability through other library paths was not asserted; remove the affected stdlib by rebuilding both binaries. |
| CVE-2026-39820 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Application handlers do not parse email addresses. The tool reports component presence; rebuilding both binaries removes the old mail parser without a suppression. |
| CVE-2026-39821 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Host/IDNA handling can matter to HTTP clients. The healthcheck uses loopback, but update both binaries rather than depend on that restriction forever. |
| CVE-2026-39822 | HIGH | `healthcheck`, `quicknotes` | **FIX** | The application uses ordinary file operations, not an explicitly configured os.Root API. Upgrade the bundled library in both artifacts regardless. |
| CVE-2026-39836 | HIGH | `healthcheck`, `quicknotes` | **FIX** | The advisory title scopes this behavior to Windows while the shipped artifacts are Linux ARM64. Rebuild the shared stdlib anyway; no unsupported global false-positive suppression. |
| CVE-2026-42499 | HIGH | `healthcheck`, `quicknotes` | **FIX** | No application handler calls mail parsing. Upgrade the shared standard library rather than confuse a present package with a proven reachable exploit. |
| CVE-2026-42504 | HIGH | `healthcheck`, `quicknotes` | **FIX** | HTTP uses MIME-related infrastructure; avoid assuming all malformed input paths are unreachable. Replace the standard library in both executables. |
| CVE-2026-56853 | HIGH | `healthcheck`, `quicknotes` | **FIX** | The server has no explicit unencrypted HTTP/2 setup. Replace the vulnerable HTTP library anyway, keeping protocol exposure separate from package-level detection. |
| CVE-2026-56858 | HIGH | `healthcheck`, `quicknotes` | **FIX** | This API has no html/template rendering. Upgrade the bundled library instead of accepting an obsolete toolchain for a feature that may be added later. |
| CVE-2026-56859 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Requests are decoded as JSON rather than XML. Rebuild both artifacts; absence of an explicit XML route is not used as a blanket scanner suppression. |
| CVE-2026-56860 | HIGH | `healthcheck`, `quicknotes` | **FIX** | URL handling is part of HTTP processing. Upgrade both binaries to the fixed toolchain rather than rely on limited current route shapes. |
| CVE-2026-56862 | HIGH | `healthcheck`, `quicknotes` | **FIX** | The local app and healthcheck use plain HTTP, not TLS KeyUpdate. Update both artifacts to prevent future TLS use from inheriting vulnerable code. |
| CVE-2026-78667 | HIGH | `healthcheck`, `quicknotes` | **FIX** | Range headers are untrusted HTTP input even though the API does not serve files. Upgrade the HTTP implementation rather than rely on a narrow current handler set. |
| CVE-2026-78669 | HIGH | `healthcheck`, `quicknotes` | **FIX** | No HTTP/2 service is explicitly enabled in this lab. Rebuild both binaries to remove the vulnerable implementation without claiming end-to-end exploitability. |
| CVE-2026-97031 | HIGH | `healthcheck`, `quicknotes` | **FIX** | ECH/TLS is not configured for the local target. Upgrade both binaries so later encrypted transports use a patched standard library. |

The machine-readable [triage.json](lab9/triage.json) contains a separate decision for **each of the 46 target/CVE occurrences**, including source scan, package, version, reason and fix file. [verify.rb](../scripts/lab9/verify.rb) compares this list with the actual reports, preventing an omitted occurrence.

There were no HIGH/CRITICAL filesystem or configuration findings to leave untriaged.

Additional lower-severity configuration decision:

| ID | Risk | Target | Disposition | Reason and evidence |
|---|---|---|---|---|
| DS-0026 | LOW | `app/Dockerfile` | **FIX** | The image had no HEALTHCHECK even though Compose did. Add the existing `/healthcheck` binary as an exec-form image HEALTHCHECK so standalone runs are covered too. The after report has 27 successes and zero failures. |

No WATCH, ACCEPT or FALSE POSITIVE label was needed for Trivy: a fixed, supported upstream toolchain was available. An unsupported Go 1.24 build was not retained just because some affected features are not configured locally. Go's [release policy and security revisions](https://go.dev/doc/devel/release) support this choice.

## CycloneDX SBOM

Both the [before SBOM](lab9/quicknotes-before.sbom.cdx.json) and the [after SBOM](lab9/quicknotes-after.sbom.cdx.json) are included. The after document is CycloneDX **1.7**, includes two Go stdlib components at `v1.27.3`, both application binaries and the Debian package inventory. The verifier binds its image identity to the image scan.

First **30 lines** of the actual after SBOM:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:a70ab9df-c3c2-4695-90d6-aaadd742f7ed",
  "version": 1,
  "metadata": {
    "timestamp": "2026-10-26T14:59:02+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "manufacturer": {
            "name": "Aqua Security Software Ltd."
          },
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.76.1"
        }
      ]
    },
    "component": {
      "bom-ref": "81b5b65d-4dfd-4789-b3e1-3a90a0ceb4a8",
      "type": "container",
      "name": "/work/image-after.tar",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:114dde0fefebbca13165d0da9c500a66190e497a82a53dcaabc3172d630be1e9"
        },
```

This is intentionally an excerpt, not a standalone JSON document.

## Design answers a–d

**a) Severity is one input.** Also consider the deployed OS/architecture and exact version, attacker-controlled input, whether vulnerable code is reachable, authentication and network boundaries, data sensitivity, plausible impact, exploit maturity, existing mitigations, upstream fixes and the cost of delaying an update. Package presence is evidence to investigate, not automatic proof of exploitation. Here the loopback HTTP healthcheck narrows exposure for TLS findings, but rebuilding both obsolete stdlibs was inexpensive and preferable to permanent exceptions.

**b) Why a minimal base is valuable.** Fewer runtime packages, no shell/package manager/compiler, and non-root execution reduce components to patch and tools available after compromise. Multi-stage builds keep build dependencies out of the final image. However, “strongest single control” is context-dependent, not a universal guarantee. This actual distroless image still contained 46 HIGH occurrences in Go binaries; application logic, authentication, runtime permissions and a maintained compiler remain essential.

**c) When suppression is legitimate.** Use a narrow, documented exception only after checking the exact component and context, with an owner, reason, expiration/review date and compensating control. A verified platform mismatch can justify a false-positive decision; limited exposure can justify dated risk acceptance, not a claim that the scanner is wrong. Blanket ignores, suppressing all HIGH findings, or hiding fixed vulnerabilities to obtain a green screen are security theater. This submission uses no suppression.

**d) The future SBOM problem.** When a new issue appears, inventory the already shipped images without reconstructing every old build environment. Query the affected package/PURL/version, identify deployments using the associated image digest, then prioritize patching and verify replacements. For a Log4Shell-style incident, that turns “do we contain this component?” into an inventory lookup. An SBOM alone does not prove reachability or that every deployed instance was replaced; it must be retained with release/deployment identities.

# Task 2 — Passive ZAP baseline and code fix

## Baseline coverage

[Before HTML](lab9/zap-before.html), [before JSON](lab9/zap-before.json), [after HTML](lab9/zap-after.html) and [after JSON](lab9/zap-after.json) are included.

The pinned baseline used `--autooff -m 1 -T 5`. It performed a time-limited traditional spider and passive analysis, **not an active scan**. Both runs recorded 11 URLs. An API does not expose HTML links to every route, so the [hook](../scripts/lab9/zap_hooks.py) seeds only known **GET** URLs:

```text
/health
/metrics
/notes
/notes/1
/notes/999999
/notes/not-an-int
/does-not-exist
```

The baseline also visited the root and discovery URLs. No POST or DELETE request was generated by the hook. Writes and deletions are covered in isolated unit-test stores instead. This is not exhaustive DAST coverage of every possible input.

Before excerpt from [baseline log](lab9/zap-before.log):

```text
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 4
WARN-NEW: Cross-Origin-Resource-Policy Header Missing or Invalid [90004] x 4
FAIL-NEW: 0  FAIL-INPROG: 0  WARN-NEW: 2  WARN-INPROG: 0  INFO: 0  IGNORE: 0  PASS: 65
```

The saved baseline exit code is `2`, meaning completed with warnings, not an infrastructure failure. The JSON additionally contains informational cacheability variants; these are triaged below even though the warning-oriented console summary does not count them.

## Every ZAP finding: disposition

All URLs are relative to `http://quicknotes:8080`. “Risk (confidence)” follows the report; `Medium` in `Low (Medium)` is **confidence**, not a medium-severity vulnerability.

| Alert reference and name | Risk | Affected URLs / parameter | Disposition | Reason, follow-up and evidence |
|---|---|---|---|---|
| 90004-1 — Cross-Origin-Resource-Policy Header Missing or Invalid | Low (Medium) | `/health`, `/metrics`, `/notes`, `/notes/1`; parameter: Cross-Origin-Resource-Policy | **FIX** | Set Cross-Origin-Resource-Policy: same-origin centrally. This API has no intended cross-origin no-cors embedding; revisit if a cross-origin browser consumer is introduced. Before: 4 instances; after: 0. |
| 10021 — X-Content-Type-Options Header Missing | Low (Medium) | `/health`, `/metrics`, `/notes`, `/notes/1`; parameter: x-content-type-options | **FIX** | Set X-Content-Type-Options: nosniff in outer router middleware, preserving JSON/Prometheus Content-Type values. Before: 4 instances; after: 0. |
| 10049-1 — Non-Storable Content | Informational (Medium) | `/health`, `/notes/999999`, `/notes/not-an-int`; parameter: none | **ACCEPT** | Informational cache-policy observation, not a false scanner claim. Non-storable API/error responses are intentional; no-store protects notes and avoids stale state. Revisit cache requirements on 2027-01-26 or before adding a UI/cache. Before: 1 instances; after: 2. |
| 10049-3 — Storable and Cacheable Content | Informational (Medium) | `/`, `/metrics`, `/notes`, `/notes/1`, `/notes/999999`; parameter: none | **FIX** | The reported responses could be heuristically cached. Add Cache-Control: no-store to all router responses to protect potentially personal notes and fresh state. Before: 5 instances; after: 0. |

The remaining `10049-1` is a real informational observation about intentional non-storage, not a false positive and not an ignored alert. Its review date, **2027-01-26**, is within six months. Review earlier if a UI, proxy cache or performance-driven caching policy is introduced.

## Middleware and tests

Changes:

- [handlers.go](../app/handlers.go): `Routes()` returns `http.Handler` and wraps the entire mux.
- [security.go](../app/security.go): one middleware sets all headers before delegating.
- [security_test.go](../app/security_test.go): production-router tests cover all registered route types, HEAD, successful/invalid requests, missing notes, router 404/405 and canonical-path redirects; another test covers header timing and delegation on a 500 response.
- [Dockerfile](../app/Dockerfile): Go 1.27.3 builder and image-level HEALTHCHECK.

The production wiring is:

```go
func (s *Server) Routes() http.Handler {
    mux := http.NewServeMux()
    // Existing route registrations remain unchanged.
    return securityHeaders(mux)
}
```

The middleware sets:

```text
X-Content-Type-Options: nosniff
Cross-Origin-Resource-Policy: same-origin
Content-Security-Policy: default-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Cache-Control: no-store
```

Only the two missing headers were LOW ZAP findings. CSP, framing/referrer restrictions and explicit non-storage are additional API hardening; a pre-scan PASS for CSP is not falsely presented as a discovered-and-fixed CSP alert.

Wrapping the mux, rather than individual handlers, also covers built-in route errors and redirects. The middleware does not replace the ResponseWriter or rewrite status/body/content type.

Tests were run in an ephemeral Go 1.27.3 ARM64 container; GCC and musl development files were installed **only inside that disposable test container** for the race detector:

```bash
docker run --rm -v "$PWD/app:/src:ro" -w /src \
  golang:1.27.3-alpine sh -ec \
  'apk add --no-cache gcc musl-dev; go version; go test -race -count=1 -v ./...; go vet ./...'
```

Actual [test log](lab9/go-test-container.log):

```text
go version go1.27.3 linux/arm64
--- PASS: TestSecurityHeaders_AllRoutes
--- PASS: TestSecurityHeaders_SetBeforeNextHandler
PASS
ok   quicknotes   1.020s
?    quicknotes/cmd/healthcheck  [no test files]
```

The test uses `srv.Routes().ServeHTTP(...)`, not a manually wrapped test-only handler. A Go overlay replaced **only** `return securityHeaders(mux)` with `return mux` for a separate test build; the real working tree stayed fixed. [Mutation evidence](lab9/mutation-test.log):

```text
--- FAIL: TestSecurityHeaders_AllRoutes/health
X-Content-Type-Options: got "", want "nosniff"
Cross-Origin-Resource-Policy: got "", want "same-origin"
mutation_test_exit=1
```

This demonstrates that removing the middleware causes the regression test to fail on missing headers.

## Re-scan: finding absent

The rebuilt, isolated `quicknotes:lab9` container is healthy. A real host [HTTP response](lab9/http-after.txt) confirms the headers and unchanged `{"notes":4,"status":"ok"}` health payload.

After baseline excerpt:

```text
PASS: X-Content-Type-Options Header Missing [10021]
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
FAIL-NEW: 0  FAIL-INPROG: 0  WARN-NEW: 0  WARN-INPROG: 0  INFO: 0  IGNORE: 0  PASS: 67
```

The after JSON has **no `10021`**, **no `90004-1`** and **no `10049-3`**. Its only alert is informational `10049-1`, with two recorded examples and evidence `no-store`. The baseline exit code is `0`. Counts are scanner-reported examples, not a claim of exhaustive instance coverage.

## Design answers e–g

**e) Why middleware?** One outer wrapper defines policy once, before headers are committed. New routes, errors and router-generated responses inherit it. Per-handler copies are easy to omit and diverge. The production-wiring regression test detects removal of the wrapper.

**f) What strict CSP breaks.** `default-src 'none'` blocks resource loads governed by that fallback, including scripts, styles, images and connections unless explicitly allowed. It would break a normal browser UI or Swagger page that relies on those resources. It is appropriate for a JSON API with no intended UI and does not prevent non-browser API clients from receiving JSON. It is not literally every possible CSP restriction: this middleware also explicitly sets `base-uri`, `frame-ancestors` and `form-action`. Before adding a UI or browser integration, define a reviewed allowlist; do not blindly retain or remove the policy. CORP is not authentication, and CSP is not a substitute for safe JSON handling or authorization.

**g) Why not blindly accept informational findings?** That hides a review backlog, confuses expected behavior with false positives, can miss sensitive caching, and creates permanent exceptions without context. Here `10049-3` was read and addressed with no-store; `10049-1` was read and accepted with a reason and dated review. Labels reflect the individual observation rather than the fact that its risk is informational.

# Bonus — not claimed

No `.github/workflows` directory exists in this starting branch. The bonus requires a separate `govulncheck` status check, blocking policy and actual red/green remote PR runs after introducing/reverting a vulnerable dependency. Those runs were **not** fabricated or replaced with the local middleware mutation test. No workflow or branch-protection settings were changed, and no bonus points are claimed.

Conceptual answers h–j:

- **h:** Component presence and reachable vulnerable functions are different evidence. `govulncheck` uses Go package/symbol and call-graph information to reduce triage noise; that does not prove all other security properties.
- **i:** Pinning the scanner makes its behavior and required toolchain reviewable and repeatable. The vulnerability database still changes, so capture scan time and metadata too.
- **j:** It does not replace inspection of OS packages, container settings, secrets, non-Go components or running HTTP behavior.

See the [official Go vulnerability-management documentation](https://go.dev/doc/security/vuln/). The task's historical Go 1.24 bonus constraint should be reconciled with current support/security requirements before implementing a future shipping pipeline; the actual release image here is built with patched Go 1.27.3.

# Troubleshooting, boundaries and final verification

- A host `go test` attempt could not resolve parts of its standard library and could not write its default cache under the current filesystem permissions. This does not establish that the host installation itself is broken. Testing was completed in a pinned container; no global Go installation or cache configuration was modified.
- Buildx initially lacked permission to write its activity state. After explicit access was granted to its runtime state directory, the ARM64 build completed; no global Docker configuration was edited.
- An extra redirect test initially assumed status 301; the tested Go 1.27.3 router returned 307. The final test accepts the observed supported 301/307 variants and verifies the canonical Location and headers. It does not weaken the header assertions.
- The image lacked a native HEALTHCHECK although Compose defined one. The Dockerfile now reuses the existing executable with the same interval/timeout policy.
- HSTS is deliberately not added to the local plain-HTTP listener. TLS/HSTS belong to a correctly configured HTTPS deployment. Authentication, comprehensive input/resource limits and production network exposure remain outside what these scans certify.
- No private local `.env`, SSH key, Vagrant state, cache or image archive was copied into the submission.

The [verification script](../scripts/lab9/verify.rb) parses the saved reports, checks every HIGH/CRITICAL occurrence and ZAP variant against triage, enforces the acceptance review window, checks that fixed alerts are absent, and binds both SBOMs to their image scan identifiers.

Actual [verification output](lab9/verification.log):

```text
PASS: 46 HIGH/CRITICAL occurrences have decisions (23 unique CVEs).
PASS: 0 HIGH/CRITICAL after fixes; Dockerfile configuration finding fixed.
PASS: 4 ZAP alert variants triaged; 0 non-informational alerts after fixes.
PASS: dated acceptance, CycloneDX/image identity, Go versions, scan exits and mutation guard.
```

Additional checks: `bash -n scripts/lab9/scan.sh`, `docker compose config --quiet`, `go vet ./...`, race-enabled unit tests, healthy isolated container and a real HTTP header check.

The raw reports and logs under `submissions/lab9/` are intentional deliverables. A [full working-tree file list](lab9/changed-files.txt) is included. No files were staged and no commit or push was performed. To review locally:

```bash
git status --short --untracked-files=all
git diff --check
git diff -- app/Dockerfile app/handlers.go
ruby scripts/lab9/verify.rb
curl -i http://127.0.0.1:18089/health
```

After manual review, the owner can stage the explicit Lab 9 files, commit, push `feature/lab9` and open the course PR. The isolated lab container uses temporary fixture data; it is not a replacement for the original Lab 8 environment.
