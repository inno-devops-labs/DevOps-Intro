# Lab 9 — DevSecOps: QuickNotes Trivy and ZAP scans

## Environment and method

- Date: 2026-09-26.
- Docker: 29.8.1; Compose: v5.5.1.
- Host Go: 1.22.2; tests used `golang:1.24-alpine` because `app/go.mod` requires Go 1.23.
- Trivy: verified image `aquasec/trivy:0.59.1`.
- ZAP: pulled and checked `ghcr.io/zaproxy/zaproxy:2.16.1` (`zap.sh -version` returned 2.16.1).
- Baseline image: `quicknotes:lab6` built with `golang:1.24-alpine`; final image uses `golang:1.26.6-alpine` and the same distroless runtime.
- QuickNotes ran locally on `127.0.0.1:18080` because port 8080 was occupied by an existing Docker proxy. Both ZAP runs targeted `http://127.0.0.1:18080/notes` with `zap-baseline.py -m 1` and Docker host networking. `/health` and `/notes` returned HTTP 200 before and after.

## Task 1 — Trivy

### 1.1 Image scan

[Complete baseline output](../security/lab9/trivy-image.txt): `quicknotes:lab6`, `--severity HIGH,CRITICAL`.

```text
quicknotes:lab6 (debian 13.7): Total: 0 (HIGH: 0, CRITICAL: 0)
healthcheck (gobinary): Total: 19 (HIGH: 19, CRITICAL: 0)
quicknotes (gobinary): Total: 19 (HIGH: 19, CRITICAL: 0)
```

The 19 distinct Go standard library CVEs appeared once in each binary, so there are 38 image findings. I verified and used `golang:1.26.6-alpine` for the builder, rebuilt both binaries, then ran the [same Trivy scan](../security/lab9/trivy-image-after.txt): **0 HIGH, 0 CRITICAL**. The final image SBOM identifies `stdlib v1.26.6` in both binaries. Trivy 0.59.1 reported two Go binaries in the repeat scan.

### 1.2 Filesystem scan

[Complete output](../security/lab9/trivy-fs.txt): `trivy fs --severity HIGH,CRITICAL --skip-dirs /work/.vagrant /work`. The current application module yielded **0 HIGH, 0 CRITICAL**. `.vagrant` is ignored machine runtime state containing a local private key, so it was excluded from the publishable source scan. The initial unrestricted local check detected that key; its output was kept out of Git. The command still scans the repository source, not the home directory.

### 1.3 Config scan

[Complete output](../security/lab9/trivy-config.txt): `trivy config /work` inspected `app/Dockerfile`: 28 checks, 27 passed, one LOW, zero HIGH/CRITICAL. `AVD-DS-0026` asks for a Dockerfile `HEALTHCHECK`. Compose already defines a health check using `/healthcheck`, so this LOW finding is accepted for this Compose deployment; image users outside Compose should add an equivalent health check. Review by **2027-03-26**.

### 1.4 CycloneDX SBOM

[Full generated SBOM](../security/lab9/quicknotes-sbom.cdx.json): CycloneDX 1.6, created by Trivy 0.59.1 for final `quicknotes:lab6`; 13 components. The first 30 lines of the generated file are:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:dc5ecf8a-30c8-4158-a292-be2e28aab1dd",
  "version": 1,
  "metadata": {
    "timestamp": "2026-09-26T11:26:33+00:00",
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
      "bom-ref": "563f8db3-1f6e-466b-a854-a49609774e2a",
      "type": "container",
      "name": "quicknotes:lab6",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:0d59ed0ffbea65e577e84b4d165771d95659393a1b0961e6161b27a33af17f86"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
```

### 1.5 Complete HIGH/CRITICAL triage

Every row covers both occurrences of one CVE, one in `healthcheck` and one in `quicknotes`. All 38 findings have disposition **FIX**; no HIGH/CRITICAL risk was accepted, watched, or suppressed. The exact affected package and fixed version per finding are in the unmodified baseline output.

| Source / affected binaries | Finding | Severity | Component | Disposition | Reason and verification |
|---|---|---|---|---|---|
| Image: `healthcheck`, `quicknotes` | CVE-2026-25679 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-27145 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-32280 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-32281 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-32283 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-33811 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-33814 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-33818 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-39820 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-39821 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-39822 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-39836 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-42499 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-42504 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-56853 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-56858 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-56859 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-56860 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |
| Image: `healthcheck`, `quicknotes` | CVE-2026-56862 | HIGH | `stdlib v1.24.13` | FIX | Rebuilt both binaries with Go 1.26.6; [repeat scan](../security/lab9/trivy-image-after.txt) reports 0 HIGH/CRITICAL. |

### 1.6 Design questions

**a) Triage beyond severity.** Severity alone cannot tell whether a vulnerable function is called, whether an exploit exists, whether the service is public, what privileges it has, or which controls surround it. Patch availability and deployment context also matter. These Go standard library findings affected embedded binaries rather than OS packages; the image runs as a nonroot user in a small runtime and Compose drops capabilities, but rebuilding with a fixed Go compiler was available and removed the findings.

**b) Minimal runtime images.** A distroless runtime has fewer packages and command-line tools, shrinking attack surface, scanner noise, and patch work. The baseline OS layer had zero HIGH/CRITICAL while embedded Go binaries had 38 findings. Minimal images do not eliminate application or language-runtime vulnerabilities.

**c) `.trivyignore`.** It can document a validated false positive or a consciously accepted risk with an owner, reason, date, and review plan. It should not conceal real findings to make a check pass. No `.trivyignore` was added here; the HIGH findings were fixed.

**d) SBOM value.** A retained image SBOM answers whether a deployed build contained an affected component and version during a future supply-chain incident, such as Log4Shell, without reconstructing an old image. This SBOM records both Go binaries and their standard library version.

## Task 2 — OWASP ZAP

### 2.1 Baseline scan

[Before HTML](../security/lab9/zap-before.html) · [Before JSON](../security/lab9/zap-before.json). The passive baseline visited five URLs and reported four distinct alerts (three LOW, one informational); no active scan was run. Starting at `/notes` gave a successful seed response. ZAP also noted that its spider expected HTTP 200 at `/`, where this API returns 404; this did not prevent the `/notes` findings.

### 2.2 Complete finding triage

| ID | Finding | Risk | URL / parameter | Disposition | Reason |
|---|---|---|---|---|---|
| 10021 | X-Content-Type-Options Header Missing | Low | `/notes`; `x-content-type-options` | FIX | Add `nosniff` globally; browser MIME sniffing is unnecessary for JSON. |
| 90004 | Insufficient Site Isolation Against Spectre Vulnerability | Low | `/notes`; `Cross-Origin-Resource-Policy` | FIX | Add `Cross-Origin-Resource-Policy: same-origin` globally. The API does not serve cross-origin browser assets. |
| 10116 | ZAP is Out of Date | Low | `/`; none | ACCEPT | This concerns the pinned local scanner, not a QuickNotes response. Recheck scanner version by 2027-03-26; retain the pinned version for reproducible before/after comparison. |
| 10049 | Storable and Cacheable Content | Informational | `/`, `/notes`, `/robots.txt`, `/sitemap.xml`; none | FIX | Set `Cache-Control: no-store` globally because note data may be user-specific. The after report changes the alert to `Non-Storable Content` under the same ID; this informational observation is expected. |

### 2.3 Selected finding and middleware

The selected real finding was **10021** on `/notes`; **90004** was also fixed. `securityHeaders` in `app/handlers.go` wraps the complete mux returned by `Server.Routes()`, including 404 responses. It sets `X-Content-Type-Options: nosniff`, `Cross-Origin-Resource-Policy: same-origin`, and `Cache-Control: no-store`. No handler-specific header edits were needed.

### 2.4 Regression test

`TestSecurityHeadersOnAllRoutes` in `app/handlers_test.go` sends requests through the actual wrapped router for `/health`, `/notes`, `/metrics`, and an unknown route. It checks each header and value. `go test ./...` with Go 1.24 passed for the application and healthcheck command; output was captured locally in `/tmp/lab9-go-test.txt`. A removed wrapper would fail the test.

### 2.5 Before/after evidence

[After HTML](../security/lab9/zap-after.html) · [After JSON](../security/lab9/zap-after.json). Both reports used the same pinned image, target, and passive baseline method. Alert IDs **10021** and **90004** are present in the before JSON and absent in the after JSON. `curl -i` on `/health` and `/notes` shows the new headers. The after scan reports two alerts: `10116` and informational `10049 Non-Storable Content`; the latter describes the new cache policy rather than cacheable data.

### 2.6 Design questions

**e) Middleware.** One wrapper applies to existing and future routes, avoids repeated header code, makes review simpler, and lets a single test check the complete request path.

**f) Strict CSP.** `Content-Security-Policy: default-src 'none'` blocks browser resource loading unless permitted. It can fit a JSON-only API, but would break a normal page with scripts, styles, images, or fonts unless those are explicitly allowed. ZAP did not report missing CSP for this API, so no CSP change was made.

**g) Informational findings.** Blind acceptance can hide genuine data exposure and make the accepted-risk list useless. Each informational alert needs its own context and disposition; here cacheability of notes was addressed, and the after report was checked for the changed behavior.

## Bonus — govulncheck CI Gate

### B.1 Standalone CI job

The existing [Lab 3 workflow](../.github/workflows/ci.yml) now runs on `feature/lab9` pushes as well as its existing `main` push and PR events. Its separate `govulncheck` job runs in `app/`; `ci-ok` requires it alongside vet, test, and lint. The job installs Go 1.24 as specified. Because Go 1.24.13 has reachable standard-library findings in this codebase (15 in the local trial), the job explicitly pins `GOTOOLCHAIN=go1.26.6` for the scanner. This matches the patched compiler used to build the shipped image. The local Go 1.24 trial exited 3 on clean application source, while the Go 1.26.6 trial reported no vulnerabilities. This toolchain choice is explicit in the workflow rather than hiding those baseline findings.

### B.2 Pinned scanner

The job installs `golang.org/x/vuln/cmd/govulncheck@v1.8.0`, a verified published module version, and runs `govulncheck ./...`. Local and Actions version output identified `govulncheck@v1.8.0`. The scanner version and Go toolchain are pinned separately. The vulnerability database at `https://vuln.go.dev` still updates; pinning the binary does not freeze its intelligence.

### B.3 Clean baseline

Locally, the final source passed `go test ./...` and `govulncheck ./...` with `golang:1.26.6-alpine`: `No vulnerabilities found.` The first fully green branch run after fixing the pre-existing healthcheck lint issue was [CI run 36239247767](https://github.com/SanyaLikeIT/DevOps-Intro/actions/runs/36239247767) at commit `c74bc0cd1be73caa35621779d0ca0cc62b035fae`; its `govulncheck` job succeeded. The healthcheck fix checks the `resp.Body.Close()` return value and was a separate signed commit.

### B.4 RED demonstration

- Vulnerable module: `golang.org/x/net@v0.33.0`, temporarily called through `html.Parse` from `quicknotes.main` using a constant harmless HTML string.
- Representative advisory: [GO-2026-5030](https://pkg.go.dev/vuln/GO-2026-5030). The local scan found eight reachable advisories in that module and exited 3; `go test ./...` passed.
- Vulnerable signed commit: `ab2b999e87786f0568813f1246b846c3fb594cdc`.
- [GitHub Actions run 36239333675](https://github.com/SanyaLikeIT/DevOps-Intro/actions/runs/36239333675), workflow `CI`, job `govulncheck`: **failure**. All vet, test, and lint jobs succeeded, isolating the security gate as the cause.

Relevant run log:

```text
Vulnerability #1: GO-2026-5030
Found in: golang.org/x/net@v0.33.0
#1: main.go:22:25: quicknotes.main calls html.Parse
Your code is affected by 8 vulnerabilities from 1 module.
Process completed with exit code 3.
```

### B.5 GREEN demonstration

The temporary call, import, module requirement, and generated `go.sum` were removed by a new commit; RED remains in branch history. After `go mod tidy`, local tests and `govulncheck` passed.

- Repair signed commit: `571d3a696afd8091068ae92be790145d690bda85`.
- [GitHub Actions run 36239427141](https://github.com/SanyaLikeIT/DevOps-Intro/actions/runs/36239427141), workflow `CI`, job `govulncheck`: **success**. All other jobs and `ci-ok` also succeeded.

Relevant run log:

```text
Go: go1.26.6
Scanner: govulncheck@v1.8.0
No vulnerabilities found.
```

The final `app/go.mod` contains only `module quicknotes` and `go 1.23`; no `golang.org/x/net` import or temporary call remains in final source.

### B.6 Design questions

**h) Reachability.** A module version can contain a vulnerable function without QuickNotes invoking it. `govulncheck` follows calls from application entry points and reports reachable vulnerable symbols, which narrows triage compared with a version-only list. In RED, the temporary `quicknotes.main` call reached `html.Parse`, and the log included that exact call trace. Removing the call and module restored GREEN.

**i) Scanner pinning.** A fixed scanner release makes tool behavior easier to reproduce, audit, and debug, and avoids surprise CI changes. The scanner version, Go compiler, and vulnerability data source are different inputs: the job pins the first two while the database can gain new advisories over time.

**j) Coverage limits.** `govulncheck` focuses on Go source, modules, vulnerable symbols, and their call reachability. It does not assess OS or base-image packages, non-Go runtime components, Docker/IaC configuration, filesystem secrets, or the complete container image. Trivy remains necessary for those layers.
