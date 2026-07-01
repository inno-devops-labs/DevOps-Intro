# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### 1.1 Required scans

All Trivy scans were run with pinned Trivy image `aquasec/trivy:0.59.1`, not `latest`.

#### Trivy version

Command:

```bash
docker run --rm aquasec/trivy:0.59.1 --version | tee submissions/lab9-trivy-version.txt
```

Output:

```text
Version: 0.59.1
```

---

#### Image scan

Command:

```bash
docker save quicknotes:lab6 -o lab9-quicknotes-lab6.tar

MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W):/work" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 image \
  --input /work/lab9-quicknotes-lab6.tar \
  --severity HIGH,CRITICAL \
  --format table \
  --output /work/submissions/lab9-trivy-image.txt
```

Top of output:

```text
/work/lab9-quicknotes-lab6.tar (debian 13.5)
============================================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 11 (HIGH: 11, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 11 (HIGH: 11, CRITICAL: 0)
```

Summary:

The Debian base image itself had zero HIGH/CRITICAL findings. Trivy reported Go `stdlib` HIGH findings in the two Go binaries inside the image: `healthcheck` and `quicknotes`.

Raw artifact: `submissions/lab9-trivy-image.txt`

---

#### Filesystem scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W):/work" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 fs \
  /work \
  --severity HIGH,CRITICAL \
  --skip-files /work/lab9-quicknotes-lab6.tar \
  --format table \
  --output /work/submissions/lab9-trivy-fs.txt
```

First run finding:

```text
.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
Asymmetric Private Key
.vagrant/machines/default/virtualbox/private_key:1
```

Fix applied before final filesystem scan:

```bash
mkdir -p "/f/Innopolis 3 year/Devops/Lab work/devops-local-backups"
mv .vagrant "/f/Innopolis 3 year/Devops/Lab work/devops-local-backups/.vagrant-lab9-backup-$(date +%Y%m%d-%H%M%S)"
```

Top of final filesystem scan output after fix:

```text
```

Summary:

The initial filesystem scan found a local Vagrant SSH private key under `.vagrant/`. This was local VM state, not application source code. I moved `.vagrant/` outside the repo tree and reran the filesystem scan. The final filesystem scan produced no HIGH/CRITICAL findings.

Raw artifact: `submissions/lab9-trivy-fs.txt`

---

#### Config scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W):/work" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 config \
  /work \
  --severity HIGH,CRITICAL \
  --format table \
  --output /work/submissions/lab9-trivy-config.txt
```

Top of output:

```text
```

Summary:

Trivy reported `Detected config files num=0`, so the config scan produced no HIGH/CRITICAL findings.

Raw artifact: `submissions/lab9-trivy-config.txt`

---

#### CycloneDX SBOM generation

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W):/work" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 image \
  --input /work/lab9-quicknotes-lab6.tar \
  --format cyclonedx \
  --output /work/submissions/lab9-sbom.cdx.json
```

First 30 lines of SBOM:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:128dd52f-af18-43e9-96a0-7555d1994921",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-01T10:26:40+00:00",
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
      "bom-ref": "9600b740-2df3-49eb-88cc-89144aef2258",
      "type": "container",
      "name": "/work/lab9-quicknotes-lab6.tar",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:275a30dd8ce958b21daa9ad962c6fbc09f98306ee2f486b65c9075dc257b1412"
```

Raw artifact: `submissions/lab9-sbom.cdx.json`

---

### 1.2 HIGH/CRITICAL triage table

| Scan | Finding ID | Package / Target | Severity | Installed Version | Fixed Version | Disposition | Reason |
|---|---|---|---|---|---|---|---|
| Image | CVE-2026-25679 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.8, 1.26.1 | ACCEPT | This is a Go stdlib parsing issue. The lab/CI baseline uses Go 1.24, and QuickNotes is a small lab API running locally. No direct custom URL parsing exposure was identified. Re-evaluate by 2026-10-01 or upgrade the image builder/runtime to a fixed Go release before production use. |
| Image | CVE-2026-27145 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.11, 1.26.4 | ACCEPT | This is a Go `crypto/x509` denial-of-service class issue. QuickNotes does not terminate external TLS itself in this lab setup. Accepted temporarily for the lab baseline; re-evaluate by 2026-10-01 or rebuild with a fixed Go toolchain before production. |
| Image | CVE-2026-32280 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.9, 1.26.2 | ACCEPT | This affects certificate-chain handling. The app is deployed as a local HTTP lab service and does not perform certificate-chain validation in its own business logic. Re-evaluate by 2026-10-01. |
| Image | CVE-2026-32281 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.9, 1.26.2 | ACCEPT | Same Go `crypto/x509` denial-of-service family. No direct certificate-chain validation path was identified in QuickNotes. Re-evaluate by 2026-10-01. |
| Image | CVE-2026-32283 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.9, 1.26.2 | ACCEPT | This is a Go TLS denial-of-service class finding. QuickNotes is not acting as a public TLS terminator in this lab deployment. Re-evaluate by 2026-10-01. |
| Image | CVE-2026-33811 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.10, 1.26.3 | ACCEPT | This is a DNS/CNAME denial-of-service class issue. QuickNotes does not depend on untrusted DNS resolution in request handling. Accepted for lab context; re-evaluate by 2026-10-01. |
| Image | CVE-2026-33814 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.10, 1.26.3 | ACCEPT | This is an HTTP/2 denial-of-service class issue. QuickNotes is a simple local HTTP API for the lab. Rebuild with a fixed Go release before exposing publicly; re-evaluate by 2026-10-01. |
| Image | CVE-2026-39820 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.10, 1.26.3 | ACCEPT | This affects `net/mail`. QuickNotes does not parse email input, so the affected functionality is not reachable in the app. Re-evaluate by 2026-10-01. |
| Image | CVE-2026-39836 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.10, 1.26.3 | ACCEPT | Generic Go security update reported through the stdlib. Accepted temporarily only because this is a lab image and Go 1.24 is the course baseline. Re-evaluate by 2026-10-01. |
| Image | CVE-2026-42499 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.10, 1.26.3 | ACCEPT | This affects `net/mail` email address parsing. QuickNotes does not process email addresses with `net/mail`, so the vulnerable code path is not expected to be reachable. Re-evaluate by 2026-10-01. |
| Image | CVE-2026-42504 | Go stdlib in `healthcheck` and `quicknotes` | HIGH | v1.24.13 | 1.25.11, 1.26.4 | ACCEPT | This is a MIME-header parsing denial-of-service finding. QuickNotes does not parse untrusted MIME headers in app logic. Accepted temporarily for lab context; re-evaluate by 2026-10-01. |
| Filesystem | AsymmetricPrivateKey | `.vagrant/machines/default/virtualbox/private_key` | HIGH | n/a | n/a | FIX | The scanner correctly detected a local Vagrant SSH private key. I moved `.vagrant/` outside the repo tree and reran the filesystem scan. The final filesystem scan output is clean. This was local VM state and is not part of the submitted source. |
| Config | None | n/a | n/a | n/a | n/a | n/a | Trivy reported no config files and no HIGH/CRITICAL config findings. |

---

### 1.3 Design questions

#### a) CVE severity is one input, not the answer. What else matters when triaging?

Severity is only the starting point. Triage should also consider reachability, exploit availability, deployment context, exposure, compensating controls, and business impact. For example, a HIGH CVE in a library is less urgent if the vulnerable function is not called, the service is not public, and there is no known exploit. The same CVE becomes much more urgent if the vulnerable code path is reachable from unauthenticated internet traffic.

#### b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?

A minimal base image removes unnecessary packages, shells, package managers, and utilities. This reduces the attack surface and leaves fewer components for scanners to flag. It also makes post-exploitation harder because an attacker has fewer tools available inside the container. In this scan, the Debian image layer had zero HIGH/CRITICAL findings, while the Go binaries were the only vulnerable targets reported.

#### c) `.trivyignore` lets you suppress findings. When is that the right move, and when is it security theater?

`.trivyignore` is appropriate when a finding has been read, understood, documented, and intentionally accepted with a re-evaluation date. It is also useful for true false positives. It becomes security theater when it is used only to make the pipeline green without explaining the risk, owner, expiration date, or reason the finding is safe to ignore.

#### d) The SBOM is a list of components. What concrete future problem does having it today solve?

An SBOM lets the team quickly answer “are we affected by CVE-X?” when a new vulnerability is announced. Instead of manually searching every image and dependency, the team can query the SBOM to check whether the vulnerable component and version are present. This is exactly the kind of visibility that helps during Log4Shell-style incidents.

---

## Task 2 - OWASP ZAP Baseline + Fix

### 2.1 ZAP baseline before fix

QuickNotes was running on `http://localhost:8080`. I first captured the before-fix response headers:

```bash
curl -i http://localhost:8080/health | tee submissions/lab9-headers-before.txt
```

Before-fix header excerpt:

```text
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 01 Jul 2026 10:42:51 GMT
Content-Length: 26

{"notes":7,"status":"ok"}
```

The response did not include cache-control or security headers such as `Cache-Control`, `Content-Security-Policy`, `X-Content-Type-Options`, `X-Frame-Options`, or `Referrer-Policy`.

ZAP baseline command, using pinned ZAP image `ghcr.io/zaproxy/zaproxy:2.16.1`:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -t \
  -v "$(pwd -W)/submissions:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py \
  -t http://host.docker.internal:8080 \
  -r lab9-zap-before.html \
  -J lab9-zap-before.json \
  2>&1 | tee submissions/lab9-zap-before.txt
```

Before-fix ZAP summary:

```text
WARN-NEW: Storable and Cacheable Content [10049] x 3
        http://host.docker.internal:8080 (404 Not Found)
        http://host.docker.internal:8080/robots.txt (404 Not Found)
        http://host.docker.internal:8080/sitemap.xml (404 Not Found)
WARN-NEW: ZAP is Out of Date [10116] x 1
        http://host.docker.internal:8080/robots.txt (404 Not Found)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 2     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 65
```

Raw artifacts:

- `submissions/lab9-headers-before.txt`
- `submissions/lab9-zap-before.html`
- `submissions/lab9-zap-before.json`
- `submissions/lab9-zap-before.txt`

---

### 2.2 ZAP triage table

| ID | Name | Risk | Affected URL / Parameter | Disposition | Reason |
|---|---|---|---|---|---|
| 10049 | Storable and Cacheable Content | WARN | `http://host.docker.internal:8080`, `/robots.txt`, `/sitemap.xml`; no parameter | FIX | ZAP reported that 404 responses were cacheable/storable. I fixed this by adding middleware that applies `Cache-Control: no-store`, `Pragma: no-cache`, and `Expires: 0` to every response. |
| 10116 | ZAP is Out of Date | WARN | `http://host.docker.internal:8080/robots.txt`; no parameter | ACCEPT | This is about the scanner container version, not the QuickNotes application. The lab requires a pinned ZAP image instead of `latest`, so I intentionally used `ghcr.io/zaproxy/zaproxy:2.16.1`. Re-evaluate by 2026-10-01 and update the pinned scanner version after checking compatibility. |
| 10049 | Non-Storable Content | WARN after fix | `http://host.docker.internal:8080`, `/robots.txt`, `/sitemap.xml`; no parameter | ACCEPT | This appeared after the fix because the app now intentionally marks responses as non-storable. It confirms the cache-control behavior changed. For this small API, non-storable responses are acceptable because responses are small and avoiding stale cached API/error responses is preferred. Re-evaluate by 2026-10-01 if caching becomes a performance requirement. |

---

### 2.3 Code fix

Finding fixed:

```text
Storable and Cacheable Content [10049]
```

Files changed:

```text
app/handlers.go
app/security.go
app/security_test.go
```

Implementation summary:

I added `securityHeadersMiddleware(next http.Handler) http.Handler` in `app/security.go`. The middleware sets cache-control and security headers before passing the request to the wrapped router.

Headers added:

```text
Cache-Control: no-store
Pragma: no-cache
Expires: 0
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'
Referrer-Policy: no-referrer
```

The router now returns the middleware-wrapped mux:

```go
func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.wrap(s.handleHealth))
	mux.HandleFunc("GET /metrics", s.wrap(s.handleMetrics))
	mux.HandleFunc("GET /notes", s.wrap(s.handleListNotes))
	mux.HandleFunc("POST /notes", s.wrap(s.handleCreateNote))
	mux.HandleFunc("GET /notes/{id}", s.wrap(s.handleGetNote))
	mux.HandleFunc("DELETE /notes/{id}", s.wrap(s.handleDeleteNote))
	return securityHeadersMiddleware(mux)
}
```

Unit test added:

```go
func TestSecurityHeaders_AppliedToAllRoutes(t *testing.T) {
	srv := newTestServer(t)

	tests := []struct {
		name   string
		method string
		path   string
	}{
		{name: "existing route", method: http.MethodGet, path: "/health"},
		{name: "not found route", method: http.MethodGet, path: "/does-not-exist"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rec := do(t, srv, tc.method, tc.path, nil)

			wantHeaders := map[string]string{
				"Cache-Control":           "no-store",
				"Pragma":                  "no-cache",
				"Expires":                 "0",
				"X-Content-Type-Options":  "nosniff",
				"X-Frame-Options":         "DENY",
				"Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
				"Referrer-Policy":         "no-referrer",
			}

			for name, want := range wantHeaders {
				if got := rec.Header().Get(name); got != want {
					t.Fatalf("%s header = %q, want %q", name, got, want)
				}
			}
		})
	}
}
```

Test result:

```text
ok      quicknotes      1.552s
```

The test checks both an existing route and a missing route. This means the headers are applied to the whole router, not only to a single handler. If `securityHeadersMiddleware(mux)` is removed, the test fails.

---

### 2.4 ZAP baseline after fix

I rebuilt the fixed image locally as `quicknotes:lab9` and ran it on port `8080`.

Build command:

```bash
MSYS_NO_PATHCONV=1 docker build -t quicknotes:lab9 -f - . <<'EOF'
FROM golang:1.24-bookworm AS build
WORKDIR /src

COPY app/go.mod ./
RUN go mod download

COPY app/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /
COPY --from=build /out/quicknotes /quicknotes
COPY app/seed.json /seed.json
USER nonroot:nonroot
EXPOSE 8080
ENV ADDR=:8080
ENV DATA_PATH=/tmp/notes.json
ENV SEED_PATH=/seed.json
ENTRYPOINT ["/quicknotes"]
EOF
```

Run command:

```bash
docker run -d \
  --name quicknotes-lab9-after \
  -p 8080:8080 \
  quicknotes:lab9
```

After-fix header evidence:

```text
HTTP/1.1 200 OK
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'
Content-Type: application/json
Expires: 0
Pragma: no-cache
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Date: Wed, 01 Jul 2026 11:28:17 GMT
Content-Length: 26

{"notes":4,"status":"ok"}
```

After-fix ZAP command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -t \
  -v "$(pwd -W)/submissions:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py \
  -t http://host.docker.internal:8080 \
  -r lab9-zap-after.html \
  -J lab9-zap-after.json \
  2>&1 | tee submissions/lab9-zap-after.txt
```

After-fix ZAP summary:

```text
WARN-NEW: Non-Storable Content [10049] x 3
        http://host.docker.internal:8080 (404 Not Found)
        http://host.docker.internal:8080/robots.txt (404 Not Found)
        http://host.docker.internal:8080/sitemap.xml (404 Not Found)
WARN-NEW: ZAP is Out of Date [10116] x 1
        http://host.docker.internal:8080 (404 Not Found)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 2     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 65
```

Before/after proof that the fixed finding is gone:

```text
Before:
WARN-NEW: Storable and Cacheable Content [10049] x 3

After:
No "Storable and Cacheable Content" finding appears in submissions/lab9-zap-after.txt.
```

Raw artifacts:

- `submissions/lab9-headers-after.txt`
- `submissions/lab9-zap-after.html`
- `submissions/lab9-zap-after.json`
- `submissions/lab9-zap-after.txt`

---

### 2.5 Design questions

#### e) Why a middleware and not per-handler header sets?

Middleware is better because it applies the policy consistently to every route. If headers are added manually inside each handler, it is easy to forget one endpoint or miss generated responses such as 404s. Wrapping the router makes the behavior centralized, easier to test, and easier to maintain.

#### f) `Content-Security-Policy: default-src 'none'` is the strictest CSP. What does it break? Why is it OK for QuickNotes API but not for a website?

`default-src 'none'` blocks loading scripts, styles, images, fonts, frames, and other external resources unless they are explicitly allowlisted. This can break normal websites because pages often need CSS, JavaScript, images, analytics, fonts, or embedded content. It is acceptable for QuickNotes because QuickNotes is a JSON API, not a browser-rendered website. Its endpoints return JSON or Prometheus text, so it does not need to load front-end resources.

#### g) False positives vs accepted findings: what is the cost of marking them all accepted without reading them?

Marking everything accepted without reading destroys the value of security scanning. Real vulnerabilities can be hidden among low-risk findings, and the team loses the chance to understand exposure, reachability, and impact. It also creates poor audit evidence because there is no reason, owner, or re-evaluation date. A finding should only be accepted after it is understood and documented.

---

## Bonus Task - govulncheck as a CI PR Gate

### B.1 CI workflow job

I added a separate GitHub Actions job named `govulncheck` in `.github/workflows/ci.yml`. It runs independently from `Go vet` and `Go test`, uses Go `1.24`, installs a pinned scanner version, and runs inside the `app/` module directory.

Workflow excerpt:

```yaml
  govulncheck:
    name: govulncheck
    runs-on: ubuntu-24.04
    defaults:
      run:
        working-directory: app
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.24"
          cache: false

      - name: Install pinned govulncheck
        run: go install golang.org/x/vuln/cmd/govulncheck@v1.5.0

      - name: Run govulncheck with accepted baseline
        shell: bash
        run: |
          set +e
          govulncheck ./... 2>&1 | tee govulncheck.txt
          GOVULN_EXIT=${PIPESTATUS[0]}
          set -e

          python - <<'PY'
          import pathlib
          import re
          import sys

          output = pathlib.Path("govulncheck.txt").read_text(encoding="utf-8", errors="replace")
          accepted_path = pathlib.Path("../.github/govulncheck-accepted.txt")
          accepted = {
              line.strip()
              for line in accepted_path.read_text(encoding="utf-8").splitlines()
              if line.strip() and not line.strip().startswith("#")
          }

          found = set(re.findall(r"\bGO-\d{4}-\d+\b", output))
          unaccepted = sorted(found - accepted)

          print("govulncheck finding IDs:", ", ".join(sorted(found)) or "none")
          print("accepted baseline IDs:", ", ".join(sorted(accepted)) or "none")

          if unaccepted:
              print("Unaccepted reachable vulnerabilities found:")
              for vuln_id in unaccepted:
                  print(f"- {vuln_id}")
              sys.exit(1)

          if found:
              print("Only accepted baseline vulnerabilities were found. Passing CI, but keep the baseline review date.")
          else:
              print("No reachable vulnerabilities found.")
          PY
```

I also added `.github/govulncheck-accepted.txt` to document the accepted current Go 1.24 standard-library baseline findings:

```text
GO-2026-5039
GO-2026-5037
GO-2026-4971
GO-2026-4947
GO-2026-4946
GO-2026-4870
GO-2026-4602
GO-2026-4601
```

Reason for this baseline:

The GitHub Actions Go `1.24` environment reported reachable standard-library findings even without the deliberately vulnerable dependency. Following the normal rollout strategy from the lecture, I documented the existing findings and configured the CI gate to fail only on new unaccepted vulnerabilities.

Green baseline evidence:

```text
Commit: c3bf625
Workflow run: lab9 baseline govulncheck stdlib findings #16
Status: Success
Go vet: green
Go test: green
govulncheck: green
```

---

### B.2 Red CI evidence with deliberately vulnerable dependency

For the red CI proof, I temporarily added a deliberately vulnerable dependency:

```text
golang.org/x/text v0.3.5
```

Temporary file added:

```go
package main

import "golang.org/x/text/language"

// This file is intentionally temporary for Lab 9 bonus evidence.
// It makes a known-vulnerable dependency reachable so govulncheck can prove
// the CI gate catches a new unaccepted vulnerability.
func init() {
	_, _ = language.Parse("en-US")
}
```

Local `govulncheck` evidence before pushing:

```text
Vulnerability #1: GO-2021-0113
    Out-of-bounds read in golang.org/x/text/language
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.5
    Fixed in: golang.org/x/text@v0.3.7
    Example traces found:
      #1: vuln_demo.go:9:23: quicknotes.init#1 calls language.Parse

Your code is affected by 1 vulnerability from 1 module.
```

Red CI evidence:

```text
Commit: 988fd87
Workflow run: temp lab9 reachable vulnerable dependency demo #17
Status: Failure
Go vet: green
Go test: green
govulncheck: red
```

The `govulncheck` job failed because the dependency introduced a new reachable vulnerability that was not in the accepted baseline:

```text
govulncheck finding IDs: GO-2021-0113, GO-2026-4601, GO-2026-4602, GO-2026-4870, GO-2026-4946, GO-2026-4947, GO-2026-4971, GO-2026-5037, GO-2026-5039
accepted baseline IDs: GO-2026-4601, GO-2026-4602, GO-2026-4870, GO-2026-4946, GO-2026-4947, GO-2026-4971, GO-2026-5037, GO-2026-5039
Unaccepted reachable vulnerabilities found:
- GO-2021-0113
Error: Process completed with exit code 1.
```

This proves the CI gate catches a new reachable vulnerability while allowing the documented baseline.

---

### B.3 Green CI evidence after revert

After capturing the red CI proof, I reverted the temporary vulnerable dependency commit. This removed:

```text
app/vuln_demo.go
app/go.sum
golang.org/x/text v0.3.5 from app/go.mod
```

Revert evidence:

```text
Commit: 4cdddda
Workflow run: Revert "temp lab9 reachable vulnerable dependency..." #18
Status: Success
Go vet: green
Go test: green
govulncheck: green
```

This confirms the final branch does not contain the temporary vulnerable dependency and the CI gate passes again.

---

### B.4 Design questions

#### h) How is “this module has a CVE but we do not call the affected function” different from “this module has a CVE”?

A module-level CVE only says the vulnerable code exists somewhere in the dependency. A reachable vulnerability means the application actually calls, directly or indirectly, the affected function. `govulncheck` is useful because it reduces noise by showing whether the vulnerable symbol is reachable from the program. A dependency can contain a CVE, but if the affected function is never called, the immediate application risk is lower than a reachable vulnerability.

#### i) Why pin the scanner version instead of using `@latest`?

Pinning the scanner version makes CI reproducible. If the workflow uses `@latest`, a new scanner release can change output, rules, exit behavior, or formatting without any repository change. That can break CI unexpectedly or make old evidence hard to reproduce. A pinned version lets the team update the scanner intentionally, review changes, and document why the update is safe.

#### j) What will govulncheck not catch that Trivy image scan would?

`govulncheck` focuses on Go code and Go vulnerabilities. It does not scan the full container image filesystem. It will not catch vulnerable OS packages, vulnerable non-Go binaries, Dockerfile or image misconfigurations, leaked secrets in image layers, or packages installed in the base image. Trivy image scanning covers those container and filesystem-level risks, so both tools are useful together.

