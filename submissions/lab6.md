# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### Trivy Version

Trivy version: 0.59.1

---

## Image Scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  $TRIVY_IMG image --severity HIGH,CRITICAL quicknotes:lab6 \
  | tee trivy-image.txt
```

Top of output:

```text
quicknotes:lab6 (debian 13.5)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 10 (HIGH: 10, CRITICAL: 0)
```

### Findings

| CVE            | Severity | Component           | Disposition | Reason                                                                                |
| -------------- | -------- | ------------------- | ----------- | ------------------------------------------------------------------------------------- |
| CVE-2026-25679 | HIGH     | stdlib net/url      | WATCH       | DoS-class (IPv6 host parsing), no fix available in Go 1.24.x. Re-check by 2026-09-01. |
| CVE-2026-27145 | HIGH     | stdlib crypto/x509  | WATCH       | DoS via excessive DNS processing. No upstream fix in Go 1.24.x.                       |
| CVE-2026-32280 | HIGH     | stdlib crypto/x509  | WATCH       | DoS via certificate chain building. Await upstream patch.                             |
| CVE-2026-32281 | HIGH     | stdlib crypto/x509  | WATCH       | DoS via inefficient certificate validation. Await upstream patch.                     |
| CVE-2026-32283 | HIGH     | stdlib crypto/tls   | WATCH       | TLS 1.3 DoS vulnerability. No supported fix available yet.                            |
| CVE-2026-33811 | HIGH     | stdlib net          | WATCH       | Long CNAME response DoS. Monitor future Go releases.                                  |
| CVE-2026-33814 | HIGH     | stdlib net/http2    | WATCH       | Malformed HTTP/2 SETTINGS frame DoS. Monitor upstream fix.                            |
| CVE-2026-39820 | HIGH     | stdlib net/mail     | WATCH       | Crafted email parsing DoS. QuickNotes does not parse email, reducing exposure.        |
| CVE-2026-39836 | HIGH     | Go standard library | WATCH       | Bundled Go security advisory. Await supported Go patch.                               |
| CVE-2026-42499 | HIGH     | stdlib net/mail     | WATCH       | Pathological email parsing DoS. Low exposure for this application.                    |

---

## Filesystem Scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/repo $TRIVY_IMG fs --severity HIGH,CRITICAL /repo \
  | tee trivy-fs.txt
```

Top of output:

```text

.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
════════════════════════════════════════
Asymmetric Private Key
────────────────────────────────────────
 .vagrant/machines/default/virtualbox/private_key:1
────────────────────────────────────────
   1 [ BEGIN OPENSSH PRIVATE KEY-----*******************************************************************************************************************************************************************************************************************************************************************************************************************************************-----END OPENSSH PRI
   2   
────────────────────────────────────────
```

---

## Configuration Scan

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/repo $TRIVY_IMG config /repo \
  | tee trivy-config.txt
```

Output:

```text

app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.

See https://avd.aquasec.com/misconfig/ds026
────────────────────────────────────────
```

### Findings

| Finding     | Severity | File           | Disposition | Reason                                                                                                                                                                                                                                                                                                                                                                                                         |
| ----------- | -------- | -------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AVD-DS-0026 | LOW      | app/Dockerfile | ACCEPT      | Attempted a HEALTHCHECK using `/quicknotes -healthcheck` (exec form because Distroless has no shell). During testing, a pre-existing volume ownership issue caused restart loops. The ownership issue was fixed (`chown 65532:65532`), but the HEALTHCHECK was reverted to keep the application stable for Lab 9 scanning. Re-evaluate by 2026-08-01 and reintroduce the HEALTHCHECK after additional testing. |

---

## CycloneDX SBOM

Command:

```bash
tMSYS_NO_PATHCONV=1 docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/out \
  $TRIVY_IMG image --format cyclonedx --output /out/sbom.json quicknotes:lab6
```

First 30 lines:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:5b317199-5644-4ac1-a6af-b467e1c109bf",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T17:10:16+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3A6d7e12f625c1dc9b727167936fe4a07317722d40fdf13cd69724550174b87f2b?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A6d7e12f625c1dc9b727167936fe4a07317722d40fdf13cd69724550174b87f2b?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
```

---

# Design Questions

## a) CVE severity is one input, not the answer. What else matters?

Severity alone does not determine risk. Reachability, exploit availability, deployment context, internet exposure, compensating controls, and whether the vulnerable code is actually used are all important. A HIGH severity vulnerability in unused code may present less practical risk than a MEDIUM vulnerability in an exposed API endpoint.

---

## b) Why do Distroless images often show fewer vulnerabilities?

Distroless images include only the files required to run the application. They omit shells, package managers, and unnecessary system utilities, greatly reducing the number of installed packages. Fewer components mean a smaller attack surface and fewer opportunities for known vulnerabilities.

---

## c) When should `.trivyignore` be used?

`.trivyignore` should only suppress findings after they have been reviewed and documented. Appropriate reasons include confirmed false positives or accepted risks with a planned review date. Ignoring findings simply to produce a cleaner scan report hides real security issues and provides no security benefit.

---

## d) Why is an SBOM useful?

An SBOM records every software component included in the application. If a new vulnerability such as Log4Shell is disclosed, the SBOM allows teams to quickly determine whether the affected component is present without rebuilding or manually inspecting the application.

---

# Task 2 — OWASP ZAP Baseline

## Run ZAP

Command:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/zap/wrk/:rw \
  ghcr.io/zaproxy/zaproxy:2.16.0 \
  zap-baseline.py -t http://host.docker.internal:8080/health \
  -r zap-report-after.html -J zap-report-after.json
```

Reports generated:

* `zap-report.html`
* `zap-report.json`

---

## ZAP Findings

Original ZAP report showing the finding:

```text
Name	Risk Level	Number of Instances
Insufficient Site Isolation Against Spectre Vulnerability	Low	1
X-Content-Type-Options Header Missing	Low	1
ZAP is Out of Date	Low	1
Storable and Cacheable Content	Informational	4
```

---

## Code Fix

The selected finding was fixed by implementing HTTP security headers as middleware rather than setting headers inside individual handlers.

Files changed:

* `app/middleware.go`
* `app/main.go`
* `app/middleware_test.go`

A unit test was added to verify that the security headers are included on every response. Removing the middleware causes the test to fail, ensuring the fix remains protected.

---

## After Re-scan

New ZAP report showing that the finding no longer appears:

```text
Name	Risk Level	Number of Instances
ZAP is Out of Date	Low	1
Storable and Cacheable Content	Informational	3
```

---

# Design Questions

## e) Why implement security headers as middleware?

Middleware applies security headers consistently to every request. This avoids duplicated code, reduces maintenance effort, and prevents handlers from accidentally omitting required headers.

---

## f) Why would `Content-Security-Policy: default-src 'none'` break a website but not QuickNotes?

A strict CSP blocks all external resources unless explicitly allowed. Traditional websites require JavaScript, CSS, images, and fonts, so such a policy would prevent the site from functioning. QuickNotes is a JSON API without browser-rendered content, making a strict CSP appropriate.

---

## g) Why shouldn't informational findings simply be marked "accepted"?

Automatically accepting findings increases the risk of overlooking genuine security problems. Each finding should be reviewed individually because scanners can report informational items that reveal configuration weaknesses or indicate future security risks.

---

# Files Included

* `trivy-image.txt`
* `trivy-image-final.txt`
* `trivy-fs.txt`
* `trivy-config.txt`
* `trivy-config-final.txt`
* `sbom.json`
* `zap-report.html`
* `zap-report.json`
* `zap-report-after.html`
* `zap-report-after.json`
* `zap.yaml`

These artifacts provide evidence of the scans, the implemented security fix, and the verification that the selected ZAP finding was resolved.
