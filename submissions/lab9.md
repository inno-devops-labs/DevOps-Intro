# Lab 9 Submission

## Task 1 - Trivy Image, Filesystem, Config, and SBOM

### Trivy version

Pinned Trivy image:

```text
aquasec/trivy:0.59.1
```

### Artifact files

- `submissions/lab9-artifacts/trivy-image.txt`
- `submissions/lab9-artifacts/trivy-fs.txt`
- `submissions/lab9-artifacts/trivy-config.txt`
- `submissions/lab9-artifacts/quicknotes-lab6.cyclonedx.json`

### Image scan

Command:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache \
  "$TRIVY_IMAGE" \
  image --severity HIGH,CRITICAL --no-progress quicknotes:lab6 \
  | tee submissions/lab9-artifacts/trivy-image.txt
```

Top of output:

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)


healthcheck (gobinary)
======================
Total: 11 (HIGH: 11, CRITICAL: 0)

Library: stdlib
Installed Version: v1.24.13
Findings: CVE-2026-25679, CVE-2026-27145, CVE-2026-32280,
CVE-2026-32281, CVE-2026-32283, CVE-2026-33811, CVE-2026-33814,
CVE-2026-39820, CVE-2026-39836, CVE-2026-42499, CVE-2026-42504

quicknotes (gobinary)
=====================
Total: 11 (HIGH: 11, CRITICAL: 0)

Library: stdlib
Installed Version: v1.24.13
Findings: same 11 Go stdlib findings as healthcheck
```

Summary:

- The Debian runtime packages in `quicknotes:lab6` have `0` HIGH and `0` CRITICAL findings.
- Trivy reported `11` HIGH findings in the `healthcheck` Go binary.
- Trivy reported the same `11` HIGH findings in the `quicknotes` Go binary.
- No CRITICAL findings were reported.

### Filesystem scan

Command:

```bash
docker run --rm \
  -v "$PWD:/repo" \
  -v trivy-cache:/root/.cache \
  -w /repo \
  "$TRIVY_IMAGE" \
  fs --severity HIGH,CRITICAL --no-progress . \
  | tee submissions/lab9-artifacts/trivy-fs.txt
```

Top of output:

```text
2026-07-06T10:42:09Z    INFO    [vuln] Vulnerability scanning is enabled
2026-07-06T10:42:09Z    INFO    [secret] Secret scanning is enabled
2026-07-06T10:42:09Z    INFO    Number of language-specific files       num=1
2026-07-06T10:42:09Z    INFO    [gomod] Detecting vulnerabilities...
```

Summary:

- No HIGH or CRITICAL filesystem vulnerability table was emitted.
- The repository Go module currently has no external Go dependencies in `app/go.mod`.

### Config scan

command:

```bash
docker run --rm \
  -v "$PWD:/repo" \
  -v trivy-cache:/root/.cache \
  -w /repo \
  "$TRIVY_IMAGE" \
  config --severity HIGH,CRITICAL . \
  | tee submissions/lab9-artifacts/trivy-config.txt
```

Top of output:

```text
2026-07-06T10:45:28Z    INFO    [misconfig] Misconfiguration scanning is enabled
2026-07-06T10:45:28Z    INFO    [misconfig] Need to update the built-in checks
2026-07-06T10:45:28Z    INFO    [misconfig] Downloading the built-in checks...
2026-07-06T10:45:31Z    ERROR   [rego] Error occurred while parsing. Trying to fallback to embedded check
file_path="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego"
2026-07-06T10:45:32Z    INFO    Detected config files   num=1
```

Summary:

- Trivy detected `1` config file.
- No HIGH or CRITICAL config finding table was emitted.
- Trivy printed Rego parsing errors for a built-in AWS EC2 policy check. This repository does not contain AWS EC2 configuration, so no project-specific HIGH or CRITICAL config finding was produced from that policy.

### CycloneDX SBOM

Command:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/submissions/lab9-artifacts:/artifacts" \
  -v trivy-cache:/root/.cache \
  "$TRIVY_IMAGE" \
  image --format cyclonedx --output /artifacts/quicknotes-lab6.cyclonedx.json quicknotes:lab6
```

First 30 lines:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:4fe6aa31-f4c5-47c2-aeb1-faa0d83e4f4f",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-06T10:42:30+00:00",
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
      "bom-ref": "5e31af06-be94-4c30-82f2-cdb15f854081",
      "type": "container",
      "name": "quicknotes:lab6",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:275a30dd8ce958b21daa9ad962c6fbc09f98306ee2f486b65c9075dc257b1412"
```

## HIGH/CRITICAL Triage

Each row below covers the duplicate finding in both Go binaries reported by the image scan: `healthcheck` and `quicknotes`. The filesystem and config scans did not emit additional HIGH or CRITICAL findings.

| Scan  | Finding ID     | Target/package                             | Severity | Installed version | Fixed version   | Disposition | Reason                                                                                                                                                                                                                                                          |
| ----- | -------------- | ------------------------------------------ | -------- | ----------------- | --------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Image | CVE-2026-25679 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.8, 1.26.1  | ACCEPT      | Fixed Go versions require moving from the course Go 1.24 baseline to Go 1.25 or 1.26. QuickNotes is a small local HTTP API and does not intentionally parse untrusted IPv6 URL host literals. Re-evaluate by 2026-12-06 or when the course Go baseline changes. |
| Image | CVE-2026-27145 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.11, 1.26.4 | ACCEPT      | This is a `crypto/x509` denial-of-service issue. The app is served over plain HTTP in the lab setup and does not process user-supplied certificate chains. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                    |
| Image | CVE-2026-32280 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.9, 1.26.2  | ACCEPT      | This is a certificate chain validation denial-of-service issue. QuickNotes does not validate client-provided certificates in the current lab deployment. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                      |
| Image | CVE-2026-32281 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.9, 1.26.2  | ACCEPT      | This is another `crypto/x509` certificate validation denial-of-service issue. The vulnerable functionality is not part of the current QuickNotes request flow. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                |
| Image | CVE-2026-32283 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.9, 1.26.2  | ACCEPT      | This affects TLS 1.3 key processing. The lab app listens over HTTP on port 8080 and does not terminate TLS itself. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                                                            |
| Image | CVE-2026-33811 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.10, 1.26.3 | ACCEPT      | This is a Go `net` package denial-of-service issue involving long CNAME responses. QuickNotes does not perform DNS lookups based on user input in the current code. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                           |
| Image | CVE-2026-33814 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.10, 1.26.3 | ACCEPT      | This is an HTTP/2 denial-of-service issue. The current lab deployment exposes plain HTTP through the Go server and does not intentionally enable TLS-based HTTP/2. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                            |
| Image | CVE-2026-39820 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.10, 1.26.3 | ACCEPT      | This affects crafted email parsing in `net/mail`. QuickNotes does not parse email addresses or MIME email content. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                                                            |
| Image | CVE-2026-39836 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.10, 1.26.3 | ACCEPT      | Trivy reports this as a Go security update. The practical fix is rebuilding with a fixed Go toolchain, but the current lab baseline is Go 1.24. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                               |
| Image | CVE-2026-42499 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.10, 1.26.3 | ACCEPT      | This affects pathological email address parsing in `net/mail`. QuickNotes does not accept or parse email addresses. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                                                           |
| Image | CVE-2026-42504 | `stdlib` in `healthcheck` and `quicknotes` | HIGH     | v1.24.13          | 1.25.11, 1.26.4 | ACCEPT      | This affects decoding malicious MIME headers. QuickNotes accepts JSON note data and does not parse MIME email headers. Re-evaluate by 2026-12-06 or when the course Go baseline changes.                                                                        |

## Design Questions

### a. CVE severity is one input, not the answer. What else matters?

Severity is only the starting point. Triage also needs reachability, whether the vulnerable package or function is actually used, whether an exploit exists, whether the service is internet-facing, what privileges the process has, whether compensating controls exist, and how easy the dependency is to patch safely. In this case, the findings are in the Go standard library embedded in the binaries, but several affected areas such as `net/mail`, TLS certificate processing, and DNS resolution are not part of the normal QuickNotes request path.

### b. Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?

A minimal base image removes unnecessary operating system packages, shells, package managers, debugging tools, and extra libraries. That reduces both the number of CVEs that can exist in the image and the tools an attacker could use after gaining code execution. The scan shows this clearly: the Debian runtime package layer has `0` HIGH and `0` CRITICAL findings, while the remaining findings come from the Go binaries themselves.

### c. `.trivyignore` lets you suppress findings. When is that the right move, and when is it security theater?

`.trivyignore` is appropriate when a finding has been reviewed, documented, assigned an owner or re-check date, and there is a clear reason it is not actionable now, such as no reachable code path or no available safe upgrade. It becomes security theater when it is used only to make reports green without understanding the finding, recording the risk, or planning to revisit it.

### d. The SBOM is a list of components. What concrete future problem does having it today solve?

The SBOM lets the team quickly answer whether QuickNotes contains a newly vulnerable component when a future CVE is announced. For example, during an incident like Log4Shell, teams with SBOMs can search known shipped components immediately instead of rebuilding dependency knowledge from memory or manually inspecting every image after the fact.

## Task 2 - OWASP ZAP Baseline and Security Header Fix

### ZAP version

Pinned ZAP image:

```text
ghcr.io/zaproxy/zaproxy:2.16.1
```

### Artifact files

- `submissions/lab9-artifacts/zap-before-console.txt`
- `submissions/lab9-artifacts/zap-before.html`
- `submissions/lab9-artifacts/zap-before.json`
- `submissions/lab9-artifacts/zap-after-console.txt`
- `submissions/lab9-artifacts/zap-after.html`
- `submissions/lab9-artifacts/zap-after.json`

### Before scan

Command:

```bash
docker run --rm --network host \
  -v "$PWD/submissions/lab9-artifacts:/zap/wrk:rw" \
  "$ZAP_IMAGE" \
  zap-baseline.py \
  -t http://127.0.0.1:8080/health \
  -r zap-before.html \
  -J zap-before.json \
  -I \
  2>&1 | tee submissions/lab9-artifacts/zap-before-console.txt
```

Before scan summary:

```text
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
        http://127.0.0.1:8080/health (200 OK)
WARN-NEW: Storable and Cacheable Content [10049] x 4
        http://127.0.0.1:8080/ (404 Not Found)
        http://127.0.0.1:8080/health (200 OK)
        http://127.0.0.1:8080/robots.txt (404 Not Found)
        http://127.0.0.1:8080/sitemap.xml (404 Not Found)
WARN-NEW: ZAP is Out of Date [10116] x 1
        http://127.0.0.1:8080/sitemap.xml (404 Not Found)
WARN-NEW: Insufficient Site Isolation Against Spectre Vulnerability [90004] x 1
        http://127.0.0.1:8080/health (200 OK)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 4     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 63
```

### ZAP findings triage

| ID | Name | Risk | Affected URL / parameter | Disposition | Reason |
| --- | --- | --- | --- | --- | --- |
| 10021 | X-Content-Type-Options Header Missing | Low (Medium) | `http://127.0.0.1:8080/health`, parameter `x-content-type-options` | FIX | Added security headers middleware that sets `X-Content-Type-Options: nosniff` on all routes. The after scan reports this check as `PASS`. |
| 90004 | Insufficient Site Isolation Against Spectre Vulnerability | Low (Medium) | `http://127.0.0.1:8080/health`, parameter `Cross-Origin-Resource-Policy` | FIX | Added `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Resource-Policy: same-origin` in the same middleware. The after scan reports this check as `PASS`. |
| 10049 | Storable and Cacheable Content | Informational (Medium) | `http://127.0.0.1:8080/`, `/health`, `/robots.txt`, `/sitemap.xml` | ACCEPT | Added `Cache-Control: no-store`. The after scan changed this to `Non-Storable Content`, which is acceptable for this API because the response is explicitly marked non-cacheable. Re-check if QuickNotes later serves browser assets. |
| 10116 | ZAP is Out of Date | Low (High) | `http://127.0.0.1:8080/sitemap.xml` before scan, `http://127.0.0.1:8080/` after scan | ACCEPT | The lab requires a pinned ZAP image instead of `latest`; `ghcr.io/zaproxy/zaproxy:2.16.1` was used for reproducibility. This finding is about the scanner image, not a QuickNotes runtime vulnerability. Re-check when updating the pinned scanner version. |

### Code fix

Files changed:

- `app/handlers.go`
- `app/handlers_test.go`

Summary:

- Changed `Routes()` to return `http.Handler`.
- Added `securityHeaders` middleware around the router.
- Applied security headers to all routes, not only `/health`.
- Added `TestSecurityHeaders_AppliesToResponses` to verify the headers are present.

Relevant code diff:

```diff
-func (s *Server) Routes() *http.ServeMux {
+func (s *Server) Routes() http.Handler {
        mux := http.NewServeMux()
        mux.HandleFunc("GET /health", s.wrap(s.handleHealth))
        mux.HandleFunc("GET /metrics", s.wrap(s.handleMetrics))
        mux.HandleFunc("GET /notes", s.wrap(s.handleListNotes))
        mux.HandleFunc("POST /notes", s.wrap(s.handleCreateNote))
        mux.HandleFunc("GET /notes/{id}", s.wrap(s.handleGetNote))
        mux.HandleFunc("DELETE /notes/{id}", s.wrap(s.handleDeleteNote))
-       return mux
+       return securityHeaders(mux)
 }
+
+func securityHeaders(next http.Handler) http.Handler {
+       return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
+               w.Header().Set("X-Content-Type-Options", "nosniff")
+               w.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; base-uri 'none'")
+               w.Header().Set("X-Frame-Options", "DENY")
+               w.Header().Set("Referrer-Policy", "no-referrer")
+               w.Header().Set("Cache-Control", "no-store")
+               w.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
+               w.Header().Set("Cross-Origin-Resource-Policy", "same-origin")
+               next.ServeHTTP(w, r)
+       })
+}
```

### Validation

Unit tests:

```bash
cd app
gofmt -w handlers.go handlers_test.go
go test ./...
cd ..
```

Result:

```text
ok      quicknotes      0.005s
?       quicknotes/cmd/healthcheck      [no test files]
```

Rebuild:

```bash
docker compose up -d --build quicknotes
```

Manual header check:

```bash
curl -i http://localhost:8080/health
```

Relevant output:

```text
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'
Content-Type: application/json
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

### After scan

Command:

```bash
docker run --rm --network host \
  -v "$PWD/submissions/lab9-artifacts:/zap/wrk:rw" \
  "$ZAP_IMAGE" \
  zap-baseline.py \
  -t http://127.0.0.1:8080/health \
  -r zap-after.html \
  -J zap-after.json \
  -I \
  2>&1 | tee submissions/lab9-artifacts/zap-after-console.txt
```

After scan summary:

```text
PASS: X-Content-Type-Options Header Missing [10021]
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
WARN-NEW: Non-Storable Content [10049] x 3
        http://127.0.0.1:8080/ (404 Not Found)
        http://127.0.0.1:8080/health (200 OK)
        http://127.0.0.1:8080/sitemap.xml (404 Not Found)
WARN-NEW: ZAP is Out of Date [10116] x 1
        http://127.0.0.1:8080/ (404 Not Found)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 2     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 65
```

Before/after evidence:

- Before: `X-Content-Type-Options Header Missing [10021]` was reported as `WARN-NEW`.
- After: `X-Content-Type-Options Header Missing [10021]` was reported as `PASS`.
- Before: `Insufficient Site Isolation Against Spectre Vulnerability [90004]` was reported as `WARN-NEW`.
- After: `Insufficient Site Isolation Against Spectre Vulnerability [90004]` was reported as `PASS`.

## Task 2 Design Questions

### e. Why a middleware and not per-handler header sets?

Middleware puts the security policy in one place and applies it consistently to every route. Per-handler header calls are easy to forget when adding a new endpoint, and they create duplicated security behavior that can drift over time. Wrapping the router means `/health`, `/metrics`, `/notes`, and future routes get the same baseline headers.

### f. `Content-Security-Policy: default-src 'none'` is the strictest CSP. What does it break? Why is it OK for QuickNotes (an API) but not for a website?

`default-src 'none'` blocks scripts, stylesheets, images, fonts, frames, connections, and other browser-loaded resources unless they are explicitly allowed. That would break a normal website that needs JavaScript, CSS, images, analytics, or API calls from browser code. It is acceptable for QuickNotes because this service is a JSON API, not a browser-rendered web application.

### g. False positives vs accepted findings: ZAP often flags informational issues that are not real problems. What is the cost of marking them all accepted without reading them?

Marking all informational findings as accepted without review creates blind spots. Some findings are harmless in the current deployment, but others may reveal weak defaults, missing headers, excessive caching, or useful reconnaissance for attackers. Reading each finding keeps the acceptance decision intentional and makes it easier to notice when a future change turns a low-risk warning into a real issue.

## Bonus Task - govulncheck CI PR Gate

### CI job

The workflow file is `.github/workflows/ci.yml`. The `govulncheck` job runs against the Go module in `app/`, uses Go `1.24`, installs a pinned scanner version, and exposes its own `govulncheck` status check.

```yaml
govulncheck:
  name: govulncheck
  runs-on: ubuntu-24.04
  defaults:
    run:
      working-directory: app

  steps:
    - name: Checkout
      uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

    - name: Set up Go
      uses: actions/setup-go@d35c59abb061a4a6fb18e82ac0862c26744d6ab5 # v5.5.0
      with:
        go-version: "1.24"
        cache-dependency-path: app/go.mod

    - name: Install govulncheck
      run: go install golang.org/x/vuln/cmd/govulncheck@v1.5.0

    - name: Run govulncheck
      run: |
        "$(go env GOPATH)/bin/govulncheck" -format=json ./... > govulncheck.json

        non_stdlib_findings="$(
          jq -r 'select(.finding != null)
            | select((.finding.trace[0].module // "") != "stdlib")
            | .finding.osv' govulncheck.json \
            | sort -u
        )"

        if [ -n "$non_stdlib_findings" ]; then
          echo "Reachable non-standard-library vulnerabilities found:"
          echo "$non_stdlib_findings"
          jq 'select(.finding != null)
            | select((.finding.trace[0].module // "") != "stdlib")' govulncheck.json
          exit 1
        fi

        echo "No reachable non-standard-library vulnerabilities found."
        if jq -e 'select(.finding != null)
          | select((.finding.trace[0].module // "") == "stdlib")' govulncheck.json >/dev/null; then
          echo "Standard-library findings are ignored here because this lab pins CI to Go 1.24."
        fi
```

Note: the job runs `govulncheck` for `./...` under `app/`. JSON output is used so the workflow can keep the gate focused on reachable non-standard-library vulnerabilities. Current Go `1.24` standard-library findings were already triaged in Task 1 and are not used to fail this bonus gate.

### Red CI evidence

Red CI run:

```text
https://github.com/software-engineering-toolkit/DevOps-Intro/actions/runs/28791129189/job/85369786010?pr=9
```

The red run was produced by temporarily adding a known vulnerable dependency and making it reachable from the QuickNotes call graph:

- Added `golang.org/x/text v0.3.7`
- Added temporary `app/vuln_demo.go`
- Called `language.ParseAcceptLanguage` from `handleHealth`
- Commit: `f7e9139` - `Reapply "test(lab9): demonstrate govulncheck failure"`

This made `govulncheck` report a reachable non-standard-library vulnerability and fail the PR gate.

### Green CI evidence after revert

Green CI run:

```text
https://github.com/software-engineering-toolkit/DevOps-Intro/actions/runs/28791446091/job/85370884879?pr=9
```

The temporary vulnerable dependency and call path were reverted:

- Removed `app/vuln_demo.go`
- Removed `golang.org/x/text v0.3.7` from `app/go.mod`
- Removed the temporary call from `handleHealth`
- Commit: `0c2dea3` - `Revert "Reapply "test(lab9): demonstrate govulncheck failure""`

After the revert, the `govulncheck` status check passed again.

## Bonus Design Questions

### h. Reachability is govulncheck's key idea. How is "this module has a CVE but we do not call the affected function" different from "this module has a CVE"?

A module-level CVE means a vulnerable version is present somewhere in the dependency graph. A reachable vulnerability means the application actually imports and calls code that can reach the affected function. That distinction reduces triage noise: an unused vulnerable function still matters for dependency hygiene, but a reachable vulnerable function is more urgent because it is part of the application's executable behavior.

### i. Why pin the version of the scanner, not just use `@latest`?

Pinning `govulncheck` makes CI reproducible. If the job used `@latest`, a new scanner release could change output format, vulnerability matching, exit behavior, or analysis precision without any repository change. A pinned scanner version means a red or green CI result is tied to a known tool version and can be re-run consistently.

### j. govulncheck only knows about Go. What is it not going to catch that Trivy image scan would?

`govulncheck` will not catch operating system package CVEs, base image vulnerabilities, Dockerfile or container misconfigurations, shell utilities, C libraries, package-manager-installed tools, or non-Go binaries in the image. Trivy image scanning covers the shipped container contents, while `govulncheck` focuses on Go source, modules, and reachable Go call paths.
