# Lab 9 — QuickNotes security review

Date: 2026-11-04. Scope: the local Lab 6 image and this repository; ZAP used
passive baseline scanning only. No active scan was run.

## Results and reproducibility

| Check | Before | After |
|---|---:|---:|
| Image HIGH/CRITICAL | 23 (Go standard library) | 0 |
| Filesystem HIGH/CRITICAL | 0 | 0 |
| Config HIGH/CRITICAL | 0 | 0 |
| ZAP rule 10021, missing nosniff | Present | Absent |
| ZAP rule 90004, CORP | Present | Present; accepted below |

Tools are pinned: Trivy **0.71.1**; ZAP **2.17.0**, image
`ghcr.io/zaproxy/zaproxy@sha256:7c2f8afc893e4e4000be8ad3fd22013fc36e5cce59359349f5a2d45626e2ccb9`;
govulncheck **v1.9.0**. The vulnerability database is time-dependent; the saved
JSON reports preserve the results of this run. Image identities are in
[image-identities.txt](evidence/lab9/image-identities.txt).

Commands (run from the repo; Windows output redirection uses equivalent paths):

```sh
trivy image --severity HIGH,CRITICAL --scanners vuln --format json --output trivy-image-before.json quicknotes:lab6
trivy fs --severity HIGH,CRITICAL --scanners vuln --format json --output trivy-filesystem-before.json .
trivy config --format json --output trivy-config-before.json .
trivy image --format cyclonedx --output quicknotes-before.cdx.json quicknotes:lab6
```

The handout's `trivy sbom --format cyclonedx` wording needs correction:
`trivy sbom` scans an existing SBOM. Generating one from an image uses
`trivy image --format cyclonedx` ([Trivy SBOM documentation](https://trivy.dev/docs/latest/supply-chain/sbom/)).
Both before and after CycloneDX documents are committed.

For ZAP, start an isolated container from the target image and use
`--network container:quicknotes-lab9-before` (or `quicknotes-lab9-after`), so the
scanner really targets `http://localhost:8080`. The application is separately
mapped to host 8080/8081. Mount `submissions/evidence/lab9` at `/zap/wrk` and
`scripts/lab9` at `/hooks`, then run the pinned image with:

```sh
zap-baseline.py -t http://localhost:8080 --hook /hooks/zap_seed.py -r zap-before.html -J zap-before.json -m 1 -T 5
```

The hook visits `/health`, `/notes`, `/notes/1`, and `/metrics` with GET only;
JSON API responses have no links for a spider to discover. After rebuilding,
repeat with `zap-after.html`/`zap-after.json`. Exit code 2 means baseline warnings,
not a scanner crash. Full [before HTML](evidence/lab9/zap-before.html),
[before JSON](evidence/lab9/zap-before.json),
[after HTML](evidence/lab9/zap-after.html), and
[after JSON](evidence/lab9/zap-after.json) are retained.

### Tops of the four scan outputs

Image:
```text

Report Summary

┌───────────────────────────────┬──────────┬─────────────────┐
│            Target             │   Type   │ Vulnerabilities │
├───────────────────────────────┼──────────┼─────────────────┤
│ quicknotes:lab6 (debian 13.7) │  debian  │        0        │
├───────────────────────────────┼──────────┼─────────────────┤
│ quicknotes                    │ gobinary │       23        │
└───────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


quicknotes (gobinary)
=====================
Total: 23 (HIGH: 23, CRITICAL: 0)

┌─────────┬─────────────────┬──────────┬────────┬───────────────────┬──────────────────────────────┬──────────────────────────────────────────────────────────────┐
```

Filesystem:
```text

Report Summary

┌────────────┬───────┬─────────────────┐
│   Target   │ Type  │ Vulnerabilities │
├────────────┼───────┼─────────────────┤
│ app/go.mod │ gomod │        0        │
└────────────┴───────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

```

Configuration:
```text

Report Summary

┌────────────────┬────────────┬───────────────────┐
│     Target     │    Type    │ Misconfigurations │
├────────────────┼────────────┼───────────────────┤
│ app/Dockerfile │ dockerfile │         1         │
└────────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


app/Dockerfile (dockerfile)
===========================
Tests: 27 (SUCCESSES: 26, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.

See https://avd.aquasec.com/misconfig/ds-0026
────────────────────────────────────────
```

SBOM generation:
```text
2026-11-04T15:27:20+05:00	INFO	"--format cyclonedx" disables security scanning. Specify "--scanners vuln" explicitly if you want to include vulnerabilities in the "cyclonedx" report.
2026-11-04T15:27:21+05:00	INFO	Detected OS	family="debian" version="13.7"
2026-11-04T15:27:21+05:00	INFO	Number of language-specific files	num=1
```

First 30 lines of the generated CycloneDX SBOM:
```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:eb26936c-30cd-45bb-92cc-b5e8edcdbbd9",
  "version": 1,
  "metadata": {
    "timestamp": "2026-11-04T10:27:21+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "manufacturer": {
            "name": "Aqua Security Software Ltd."
          },
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.71.1"
        }
      ]
    },
    "component": {
      "bom-ref": "pkg:oci/quicknotes@sha256:6b3c09b8833b8d03d9141d47bcac9af029b68619e0d3d8a54c00bf828ec09991?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256:6b3c09b8833b8d03d9141d47bcac9af029b68619e0d3d8a54c00bf828ec09991?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
```

## Per-finding Trivy triage

All 23 HIGH/CRITICAL image findings are in the Go 1.24.13 binary, not OS
packages. A minimal base does not remove statically linked Go vulnerabilities.
These are module-presence findings; actual reachability and exploit context
still matter. Rebuilding with patched Go addresses them without suppression.

| Finding | Severity | Component | Disposition | Reason / fix |
|---|---|---|---|---|
| CVE-2026-111943 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.26.10, 1.27.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-25679 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.8, 1.26.1); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-27145 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.11, 1.26.4); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-32280 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.9, 1.26.2); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-32281 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.9, 1.26.2); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-32283 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.9, 1.26.2); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-33811 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.10, 1.26.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-33814 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.10, 1.26.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-33818 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.13, 1.26.6, 1.27.0-rc.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-39820 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.10, 1.26.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-39821 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.13, 1.26.6, 1.27.0-rc.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-39822 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.12, 1.26.5, 1.27.0-rc.2); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-39836 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.10, 1.26.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-42499 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.10, 1.26.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-42504 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.11, 1.26.4); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-56853 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.13, 1.26.6, 1.27.0-rc.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-56858 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.13, 1.26.6, 1.27.0-rc.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-56859 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.13, 1.26.6, 1.27.0-rc.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-56860 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.13, 1.26.6, 1.27.0-rc.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-56862 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.25.13, 1.26.6, 1.27.0-rc.3); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-78667 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.26.9, 1.27.2); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-78669 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.26.9, 1.27.2); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |
| CVE-2026-97031 | HIGH | stdlib v1.24.13 | FIX | Rebuild with Go 1.27.3, which is at or above the listed fixed versions (1.26.9, 1.27.2); [toolchain change](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed). |

The filesystem scan reports zero HIGH/CRITICAL findings and no third-party
dependencies in the final app. The temporary bad dependency used below is
reverted. Config scanning reports no HIGH/CRITICAL. The one LOW finding,
`DS-0026` (no Dockerfile HEALTHCHECK), is **ACCEPT**: Compose already runs
`/quicknotes healthcheck`, and Render will probe `/health`; a minimal runtime
has no shell/curl. Re-evaluate by **2027-02-04**, especially before running the
image without an orchestrator health check. Trivy reported one supported
configuration file (the Dockerfile); this does not prove full Compose coverage.

A final filesystem scan with the default vulnerability **and secret** scanners
also reports zero HIGH/CRITICAL findings:
[JSON](evidence/lab9/trivy-filesystem-final.json),
[scanner log](evidence/lab9/trivy-filesystem-final.log).

## Every ZAP finding, including informational results

The JSON contains informational findings not listed in the default WARN-only
summary, so the decisions below use the full reports.

| Rule / name | Risk | Affected URLs / parameter | Disposition and reason |
|---|---|---|---|
| 10021 — X-Content-Type-Options Header Missing | Low | Before JSON: `/metrics`, `/notes/1`; baseline log also lists `/health`, `/notes`. Parameter `x-content-type-options`. | **FIX**: router-wide `X-Content-Type-Options: nosniff`; rule absent in the after JSON. |
| 90004 — Cross-Origin-Resource-Policy Header Missing or Invalid | Low | `/health`, `/metrics`, `/notes`, `/notes/1`; parameter `Cross-Origin-Resource-Policy` | **ACCEPT** until **2027-02-04**: this public demo API contains disposable, non-sensitive notes, no cookies or authenticated resources. CORP controls cross-origin no-cors embedding; it is not API authorization. No CORS credentials are enabled. Reassess before adding authenticated/private data; prefer `same-origin` then. |
| 10049 — Storable and Cacheable Content (before) | Informational | `/`, `/health`, `/metrics`, `/notes`, `/notes/1`; no parameter | **FIX**: middleware sets `Cache-Control: no-store`, avoiding caching of note responses. |
| 10049 — Non-Storable Content (after) | Informational | `/`, `/notes/1`, `/metrics`; no parameter | **ACCEPT** until **2027-02-04**: informational confirmation of the intentional no-store policy. Forgoing caching is appropriate for mutable notes; review if performance requirements change. |

## Code fix and proof

[security.go](../app/security.go) wraps the entire router returned from
`Server.Routes()`, including mux-generated 404 and 405 responses. It supplies
nosniff, CSP, frame denial, referrer policy and no-store in one place.
[security_test.go](../app/security_test.go) checks all six route/method
combinations, invalid IDs, missing notes, unknown routes, and wrong methods.
It invokes the production `Routes()` path, so removing its middleware wrapper
makes the test fail.

- [Failing test before middleware](evidence/lab9/headers-test-before.txt): missing headers, exit 1.
- [Passing Go 1.24 compatibility test with race detector and vet](evidence/lab9/tests-after.txt).
- [Implementation commit](https://github.com/4rni4ka/DevOps-Intro/commit/5dafed679c8a6c0643a722ed724c84c27230c9ed).
- Before baseline: `WARN-NEW: X-Content-Type-Options Header Missing [10021]`.
- After baseline: rule 10021 absent; `WARN-NEW: 1`, only rule 90004 remains.
- In JSON, rule 10049 changes from `Storable and Cacheable Content` to
  `Non-Storable Content`; these are two meanings of the same informational rule.

## Design questions a–g

**a)** Besides severity, check whether the affected function is reachable from
untrusted input, exploit availability/KEV status, exposure, authentication,
required privileges, data at risk, mitigating controls and patch availability.
A public request parser is different from an unused build-time utility.

**b)** Fewer packages mean fewer vulnerable components, fewer tools an attacker
can reuse and fewer patch obligations. This is a strong reduction of attack
surface, not a guarantee: this scan found 23 issues in the Go binary despite
zero HIGH/CRITICAL OS package findings.

**c)** Suppress only a reviewed false positive or a specific accepted risk with
owner, evidence, expiry and compensating controls. Suppressing real, reachable
bugs merely to turn a dashboard green hides risk. No `.trivyignore` was added.

**d)** A versioned SBOM tied to an image lets us search already-deployed releases
when a new Log4Shell-like advisory appears, identify affected components and
prioritize rebuilds without rediscovering dependencies from source or servers.
An SBOM is inventory, not proof of exploitability or absence of vulnerabilities.

**e)** Middleware covers existing/future routes and router errors consistently;
per-handler sets drift and often miss error paths. Tests exercise the real
router integration, not an isolated header-setting helper.

**f)** `default-src 'none'` blocks scripts, styles, images, fonts and fetches
unless more specific directives allow them. That breaks a typical website or
Swagger UI. QuickNotes serves JSON/text and needs none of those browser assets.
`frame-ancestors`, `base-uri`, and `form-action` are set separately because they
do not inherit all desired restrictions from default-src.

**g)** Blindly accepting informational alerts can miss private-response caching,
technology disclosure or a changed deployment assumption; it also creates noisy,
unreviewed permanent exceptions. Read the affected URLs and distinguish expected
behavior from a false positive or a risk deliberately retained.

## Bonus — reachable-vulnerability PR gate

[CI workflow](../.github/workflows/ci.yml) adds a dedicated `govulncheck` job and
includes it in the fork's protected `ci-ok` aggregate. Both checks are required
([settings](evidence/lab9/required-checks.json)). The job runs
`go install golang.org/x/vuln/cmd/govulncheck@v1.9.0`, then `govulncheck ./...`
from `app/`; failure is not ignored. All actions use full 40-character SHAs.

**Toolchain:** compatibility jobs retain Go 1.23/1.24. The saved
[Go 1.24.13 scan](evidence/lab9/govulncheck-go1.24.txt) reports 25 reachable
standard-library vulnerabilities with fixes in newer Go branches. The container
build and security job therefore use patched Go 1.27.3 rather than the handout's
1.24; no findings are filtered.

Positive control: commit
[`2051e68`](https://github.com/4rni4ka/DevOps-Intro/commit/2051e68)
temporarily adds `golang.org/x/text v0.3.7` and an actual call to
`language.ParseAcceptLanguage("en")`. No exploit payload is needed.
[Red CI run](https://github.com/4rni4ka/DevOps-Intro/actions/runs/41815151362)
reports **GO-2022-1059**, traces it to `quicknotes.init#1`, and exits 3.
All vet/test/lint jobs pass, but `govulncheck` and `ci-ok` fail.
[Saved red log](evidence/lab9/ci-red.txt).
Commit [`5794b4b`](https://github.com/4rni4ka/DevOps-Intro/commit/5794b4b)
reverts the dependency and call. The final tree contains neither.

[Green CI after revert](https://github.com/4rni4ka/DevOps-Intro/actions/runs/41815458829); [saved log](evidence/lab9/ci-green.txt). The protected aggregate and dedicated security job both pass.

**h)** A module-presence alert says vulnerable code is in the dependency graph;
a reachability alert identifies a call path into an affected symbol. The latter
cuts unused-code triage noise, though a call path alone does not prove an
attacker controls the required input. Review both the path and deployment.

**i)** Pinning makes scanner behavior, installation requirements and CI changes
reviewable and repeatable. `@latest` can unexpectedly change output, exit
behavior or minimum Go. The advisory database must still be refreshed.

**j)** govulncheck does not assess Debian/Alpine libraries, shell tools, foreign
language packages, Docker misconfiguration or image secrets. Trivy's image and
configuration scans complement source call-graph analysis.
