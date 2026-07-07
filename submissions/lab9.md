# Lab 9 

## Task 1 — Trivy: Image + Filesystem + Config + SBOM (6 pts)

Scan date: 2026-07-07

Pinned scanner version:

```text
aquasec/trivy:0.59.1
```

Artifacts saved in `submissions/lab9-artifacts/`:

- `trivy-image.txt`
- `trivy-fs.txt`
- `trivy-config.txt`
- `quicknotes-lab6.cdx.json`

## Commands used

```bash
docker build -t quicknotes:lab6 ./app

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /Users/axxil/Study/Innopolis/DevOps-Intro:/work \
  -v /Users/axxil/.cache/trivy:/root/.cache \
  aquasec/trivy:0.59.1 \
  image --severity HIGH,CRITICAL --format table \
  -o /work/submissions/lab9-artifacts/trivy-image.txt \
  quicknotes:lab6

docker run --rm \
  -v /Users/axxil/Study/Innopolis/DevOps-Intro:/work \
  -v /Users/axxil/.cache/trivy:/root/.cache \
  aquasec/trivy:0.59.1 \
  fs --severity HIGH,CRITICAL --format table \
  -o /work/submissions/lab9-artifacts/trivy-fs.txt \
  /work

docker run --rm \
  -v /Users/axxil/Study/Innopolis/DevOps-Intro:/work \
  -v /Users/axxil/.cache/trivy:/root/.cache \
  aquasec/trivy:0.59.1 \
  config --skip-check-update --format table \
  -o /work/submissions/lab9-artifacts/trivy-config.txt \
  /work

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /Users/axxil/Study/Innopolis/DevOps-Intro:/work \
  -v /Users/axxil/.cache/trivy:/root/.cache \
  aquasec/trivy:0.59.1 \
  image --format cyclonedx \
  -o /work/submissions/lab9-artifacts/quicknotes-lab6.cdx.json \
  quicknotes:lab6
```

## Top of each scan output

### 1. Image scan

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)


quicknotes (gobinary)
=====================
Total: 14 (HIGH: 13, CRITICAL: 1)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬──────────────────────────────┬──────────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │        Fixed Version         │                            Title                             │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ stdlib  │ CVE-2025-68121 │ CRITICAL │ fixed  │ v1.24.0           │ 1.24.13, 1.25.7, 1.26.0-rc.3 │ crypto/tls: crypto/tls: Incorrect certificate validation     │
│         │                │          │        │                   │                              │ during TLS session resumption                                │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2025-68121                   │
│         ├────────────────┼──────────┤        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-22874 │ HIGH     │        │                   │ 1.24.4                       │ crypto/x509: Usage of ExtKeyUsageAny disables policy         │
│         │                │          │        │                   │                              │ validation in crypto/x509                                    │
```

### 2. Filesystem scan

```text
.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
════════════════════════════════════════
Asymmetric Private Key
────────────────────────────────────────
 .vagrant/machines/default/virtualbox/private_key:1
```

### 3. Config scan

```text
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.
```

### 4. SBOM generation

First 30 lines of `quicknotes-lab6.cdx.json`:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:004ff727-a73e-4811-8e0d-08e3e0ebf1ad",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T17:33:25+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3Ad60c10b58753feb3dce466f9d14698958019b01e899bed7a3dde749807154b62?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3Ad60c10b58753feb3dce466f9d14698958019b01e899bed7a3dde749807154b62?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:275a30dd8ce958b21daa9ad962c6fbc09f98306ee2f486b65c9075dc257b1412"
        }
```

## HIGH/CRITICAL triage table

All HIGH/CRITICAL findings came from the image scan and filesystem scan. The config scan had zero HIGH/CRITICAL findings.

| Scan | Finding | Severity | Disposition | Reason | Re-check by |
|------|---------|----------|-------------|--------|-------------|
| image | CVE-2025-68121 | CRITICAL | ACCEPT | QuickNotes serves plain HTTP with `http.ListenAndServe` on `:8080`; no TLS server or outbound TLS session resumption path is configured in the current lab deployment. If this image is reused for HTTPS or internet-facing use, this becomes a FIX immediately. | 2026-10-07 |
| image | CVE-2025-22874 | HIGH | ACCEPT | The app does not validate client certificates, parse trust chains, or perform custom X.509 policy evaluation. In this deployment the vulnerable path is not used. | 2026-10-07 |
| image | CVE-2025-61726 | HIGH | ACCEPT | This is a `net/url` query parsing issue. The lab API is local-only and does not expose query-based business logic. For any shared or public deployment, upgrade the Go toolchain first. | 2026-10-07 |
| image | CVE-2025-61729 | HIGH | ACCEPT | The app does not use TLS certificate validation paths in normal operation, so this `crypto/x509` DoS issue is not reachable in the current lab setup. | 2026-10-07 |
| image | CVE-2026-25679 | HIGH | ACCEPT | The service does not parse attacker-controlled host literals or construct outbound URLs from user input, so this `net/url` parsing issue is not relevant to the current routes. | 2026-10-07 |
| image | CVE-2026-27145 | HIGH | ACCEPT | Another `crypto/x509` DoS issue. QuickNotes neither terminates TLS nor validates remote cert chains in its request path. | 2026-10-07 |
| image | CVE-2026-32280 | HIGH | ACCEPT | Certificate chain building is not part of the app's current runtime behavior, so this path is not exercised by the lab service. | 2026-10-07 |
| image | CVE-2026-32281 | HIGH | ACCEPT | Same X.509 validation surface as above; present in the bundled stdlib, but not used by the app in the current deployment. | 2026-10-07 |
| image | CVE-2026-32283 | HIGH | ACCEPT | This is a TLS 1.3 DoS issue. QuickNotes runs plain HTTP only; no TLS listener or h2/h2c configuration is enabled. | 2026-10-07 |
| image | CVE-2026-33811 | HIGH | ACCEPT | The app does not perform attacker-controlled DNS lookups. The only client-side call is the local healthcheck to `127.0.0.1`. | 2026-10-07 |
| image | CVE-2026-33814 | HIGH | ACCEPT | The HTTP server is started with `ListenAndServe` and no TLS, so HTTP/2 is not part of the current deployment path. | 2026-10-07 |
| image | CVE-2026-39820 | HIGH | ACCEPT | `net/mail` is not used anywhere in the QuickNotes codebase, so the vulnerable parsing path is not reachable. | 2026-10-07 |
| image | CVE-2026-39836 | HIGH | ACCEPT | This is an umbrella Go security advisory surfaced from the bundled stdlib. For the current local lab scope the exposure stays limited, but if the image leaves lab-only use it should be rebuilt on a current Go 1.24 patch release. | 2026-10-07 |
| image | CVE-2026-42499 | HIGH | ACCEPT | Another `net/mail` parser issue; QuickNotes does not accept or parse email address inputs. | 2026-10-07 |
| filesystem | AsymmetricPrivateKey in `.vagrant/machines/default/virtualbox/private_key` | HIGH | ACCEPT | This is a real private key, but it is local Vagrant runtime state, ignored by Git (`.gitignore` excludes `.vagrant/`), not copied into the container image, and would not exist in a clean CI checkout. It is workstation hygiene risk, not a shipped artifact risk. | 2026-10-07 |

## Design answers

### a) CVE severity is one input, not the answer. What else matters?

Severity is only the starting point. It is also worth checking reachability from the actual QuickNotes code, exploit preconditions, internet exposure, and whether the vulnerable component is part of the shipped artifact or only local development state.

Examples from this lab:

- The image scan found many HIGH/CRITICAL issues in the bundled Go stdlib, but most are in TLS, X.509, HTTP/2, or `net/mail` paths that QuickNotes does not use in its current plain-HTTP local deployment.
- The filesystem scan found a real private key, but it lives under ignored `.vagrant/` runtime state and is not part of the image or tracked Git content.

Other useful triage inputs are fixed-version availability, exploit maturity, blast radius, compensating controls, and whether a finding is in a transient lab environment or a production-facing service.

### b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?

Because the best vulnerability is the one you never ship. A minimal runtime removes shells, package managers, and large piles of OS packages that would otherwise add both attack surface and CVEs.

That showed up directly in this scan: the OS layer reported `0` HIGH/CRITICAL findings. The remaining image issues came from the Go binary itself, not from extra runtime packages. Distroless does not fix application bugs, but it sharply reduces everything unrelated to the app.

### c) `.trivyignore` lets you suppress findings. When is that the right move, and when is it security theater?

It is the right move when the finding is understood, documented, time-bounded, and either not reachable yet or not fixable yet. A good suppression has an owner, a reason, and a review date.

It becomes security theater when it is used to make CI green without changing risk, especially for issues that are shipped to users, are reachable, or already have a straightforward fix. A suppression without a reason or date is just a permanent blindfold.

### d) The SBOM is a list of components. What concrete future problem does having it today solve?

This makes it possible to quickly determine whether a recently disclosed vulnerability, such as CVE-X, affects an artefact that has already been compiled.

If an incident like Log4Shell were to recur, thanks to the SBOM, there would be no need to recompile images or search the entire repository using `grep` just to ascertain the extent of the vulnerability. You can check the list of components in the released artefact and, in a matter of minutes, determine whether `quicknotes:lab6` contains the vulnerable package and its version.

## Task 2 — OWASP ZAP Baseline + Fix at Least One Finding (4 pts)

Scan date: 2026-07-07

Pinned scanner version:

```text
ghcr.io/zaproxy/zaproxy:2.16.1
```

Artifacts saved in `submissions/lab9-artifacts/`:

- `zap-pre.html`
- `zap-pre.json`
- `zap-pre.md`
- `zap-pre.txt`
- `zap-post.html`
- `zap-post.json`
- `zap-post.md`
- `zap-post.txt`

Because ZAP was run in a container on macOS, the scan targeted the QuickNotes service on the Compose network at `http://quicknotes:8080` rather than host `localhost`.

## Commands used

```bash
docker compose up -d --build quicknotes

docker run --rm \
  --network devops-intro_default \
  -v "$PWD:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py \
  -t http://quicknotes:8080 \
  -r submissions/lab9-artifacts/zap-pre.html \
  -J submissions/lab9-artifacts/zap-pre.json \
  -w submissions/lab9-artifacts/zap-pre.md

docker compose up -d --build quicknotes

docker run --rm \
  --network devops-intro_default \
  -v "$PWD:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py \
  -t http://quicknotes:8080 \
  -r submissions/lab9-artifacts/zap-post.html \
  -J submissions/lab9-artifacts/zap-post.json \
  -w submissions/lab9-artifacts/zap-post.md
```

## ZAP summary

Pre-fix summary:

```text
FAIL-NEW: 0  FAIL-INPROG: 0  WARN-NEW: 2  WARN-INPROG: 0  INFO: 0  IGNORE: 0  PASS: 65

WARN-NEW: Storable and Cacheable Content [10049] x 2
  http://quicknotes:8080 (404 Not Found)
  http://quicknotes:8080/sitemap.xml (404 Not Found)

WARN-NEW: ZAP is Out of Date [10116] x 1
  http://quicknotes:8080 (404 Not Found)
```

Post-fix summary:

```text
FAIL-NEW: 0  FAIL-INPROG: 0  WARN-NEW: 2  WARN-INPROG: 0  INFO: 0  IGNORE: 0  PASS: 65

WARN-NEW: Non-Storable Content [10049] x 3
  http://quicknotes:8080 (404 Not Found)
  http://quicknotes:8080/robots.txt (404 Not Found)
  http://quicknotes:8080/sitemap.xml (404 Not Found)

WARN-NEW: ZAP is Out of Date [10116] x 1
  http://quicknotes:8080/sitemap.xml (404 Not Found)
```

## Full triage table for ZAP findings

| Scan phase | ID | Name | Risk level | Affected URL / parameter | Disposition | Reason |
|------------|----|------|------------|---------------------------|-------------|--------|
| pre-fix | 10049 | Storable and Cacheable Content | Informational | `http://quicknotes:8080`, `http://quicknotes:8080/sitemap.xml` / none | FIX | Root and 404 responses were cacheable because no explicit cache-control headers were set. I fixed this by adding cache headers in middleware for every response. |
| pre-fix | 10116 | ZAP is Out of Date | Low | `http://quicknotes:8080` / none | SUPPRESS | This is a scanner self-finding, not an application defect. The lab explicitly required a pinned 2.16.x image; for a real CI gate I would update the scanner image when the course no longer requires 2.16.x. |
| post-fix | 10049 | Non-Storable Content | Informational | `http://quicknotes:8080`, `http://quicknotes:8080/robots.txt`, `http://quicknotes:8080/sitemap.xml` / none | ACCEPT | This is the expected result after the fix. The API now intentionally marks responses `no-store` so shared caches do not retain them. |
| post-fix | 10116 | ZAP is Out of Date | Low | `http://quicknotes:8080/sitemap.xml` / none | SUPPRESS | Same reasoning as above: scanner version issue, not QuickNotes behavior. |

## Code fix

Files changed:

- `app/handlers.go`
- `app/handlers_test.go`

Middleware excerpt:

```go
func withSecurityHeaders(next http.Handler) *http.ServeMux {
    mux := http.NewServeMux()
    mux.Handle("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Cache-Control", "no-store, max-age=0")
        w.Header().Set("Content-Security-Policy", "default-src 'none'")
        w.Header().Set("Expires", "0")
        w.Header().Set("Pragma", "no-cache")
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        next.ServeHTTP(w, r)
    }))
    return mux
}
```

The router now returns `withSecurityHeaders(mux)` from `Routes()`, so the middleware applies to all routes, including `404` responses.

Guarding test result:

```text
passed=13 failed=0
```

The tests assert the headers on both `/health` and an unmatched route, so they fail if the middleware is removed or stops wrapping the router globally.

## Before/after proof for the fixed finding

Before:

```text
WARN-NEW: Storable and Cacheable Content [10049] x 2
  http://quicknotes:8080 (404 Not Found)
  http://quicknotes:8080/sitemap.xml (404 Not Found)
```

After:

```text
WARN-NEW: Non-Storable Content [10049] x 3
  http://quicknotes:8080 (404 Not Found)
  http://quicknotes:8080/robots.txt (404 Not Found)
  http://quicknotes:8080/sitemap.xml (404 Not Found)
```

This shows the original cacheability warning is gone. The same ZAP rule now reports the opposite condition, with evidence `no-store`, which is the intended safe outcome of the middleware fix.

Live response header proof after rebuild:

```text
HTTP/1.1 200 OK
Cache-Control: no-store, max-age=0
Content-Security-Policy: default-src 'none'
Expires: 0
Pragma: no-cache
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

## Design answers

### e) Why a middleware and not per-handler header sets?

Middleware fixes the policy once at the HTTP boundary instead of repeating it in every handler. That avoids drift, makes the behavior consistent for success and error responses, and ensures new routes inherit the same security defaults automatically.

This mattered here because the ZAP finding was triggered on `404` responses from `/` and `/sitemap.xml`, not only on the business handlers. Per-handler header sets would miss those paths much more easily.

### f) `Content-Security-Policy: default-src 'none'` is the strictest CSP. What does it break? Why is it OK for QuickNotes but not for a website?

It blocks all scripts, styles, images, fonts, frames, fetches, and other browser-loaded resources unless they are explicitly allowed. A normal website would break immediately because its HTML, JavaScript, CSS, images, and third-party assets would all be denied by default.

QuickNotes is an API that returns JSON and Prometheus text, not a browser UI. For that kind of service, a very strict CSP is acceptable because there is no front-end resource loading behavior to preserve.

### g) False positives vs accepted findings: ZAP often flags informational issues that aren't real problems. What's the cost of marking them all "accepted" without reading them?

The cost is alert fatigue and loss of trust in the scanner. Once everything is blindly marked accepted, real findings disappear into the noise and future reviewers cannot tell whether a decision was thoughtful or lazy.

It also destroys re-evaluation discipline. A finding that is harmless today can become important after an architecture change, but if it was mass-accepted with no reasoning, there is no reliable record of what assumption the acceptance depended on.
