# Lab 9 Submission

## Task 1. Trivy Image, Filesystem, Config Scan and SBOM

### Trivy Version

Trivy was executed using the pinned Docker image:

```text
aquasec/trivy:0.59.1
```

This satisfies the requirement to pin the scanner version instead of using `latest`.

---

### Image Scan

Source file:

```text
submissions/src/lab09/trivy_image.txt
```

Command:

```powershell
docker run --rm `
  -v //var/run/docker.sock:/var/run/docker.sock `
  -v "${PWD}:/work" `
  aquasec/trivy:0.59.1 `
  image `
  --severity HIGH,CRITICAL `
  quicknotes:lab6
```

Summary:

```text
quicknotes:lab6 (debian 12.14)

Total:
HIGH: 0
CRITICAL: 0

Go binary:
HIGH: 10
CRITICAL: 0
```

---

### Filesystem Scan

Source file:

```text
submissions/src/lab09/trivy_fs.txt
```

Command:

```powershell
docker run --rm `
  -v "${PWD}:/work" `
  -w /work `
  aquasec/trivy:0.59.1 `
  fs `
  --severity HIGH,CRITICAL `
  .
```

Summary:

```text
HIGH: 1
CRITICAL: 0
```

Finding:

```text
Asymmetric Private Key

.vagrant/machines/default/virtualbox/private_key
```

---

### Configuration Scan

Source file:

```text
submissions/src/lab09/trivy_config.txt
```

Command:

```powershell
docker run --rm `
  -v "${PWD}:/work" `
  -w /work `
  aquasec/trivy:0.59.1 `
  config `
  .
```

Summary:

```text
No HIGH or CRITICAL configuration issues were detected.
```

---

### CycloneDX SBOM

Source files:

```text
submissions/src/lab09/sbom.json
```

Command:

```powershell
docker run --rm `
  -v //var/run/docker.sock:/var/run/docker.sock `
  -v "${PWD}:/work" `
  aquasec/trivy:0.59.1 `
  sbom `
  --format cyclonedx `
  --output /work/submissions/src/lab09/sbom.json `
  quicknotes:lab6
```

First lines of the generated SBOM:

```text
See:

submissions/src/lab09/sbom.json
```

---

## HIGH / CRITICAL Triage

| Finding | Severity | Disposition | Reason |
|----------|---------|-------------|--------|
| Go standard library CVEs inside application binary | HIGH | FIX | The vulnerabilities originate from the Go runtime bundled into the application binary. They should be resolved by rebuilding the application with a newer Go release once patched versions become available. |
| `.vagrant/machines/default/virtualbox/private_key` | HIGH | FALSE POSITIVE | This file is located inside `.vagrant/`, is ignored by Git (`.gitignore`), and is not shipped in the application image. It is a local development artifact rather than a production secret. |

---

## Task 1 Design Questions

### Question a. Why is CVE severity only one part of triage?

Severity alone is not enough. Reachability, exploit availability, deployment context, and whether the vulnerable code is actually used are also important. A HIGH vulnerability in unreachable code may present less real risk than a MEDIUM vulnerability that is easily exploitable.

### Question b. Why are distroless images such an effective security control?

Distroless images contain only the application and the minimum runtime components. They do not include a shell, package manager, compiler, or many operating system packages. Fewer installed components mean fewer potential vulnerabilities and a much smaller attack surface.

### Question c. When should `.trivyignore` be used?

`.trivyignore` should only be used for documented and justified exceptions, such as confirmed false positives or accepted risks with a planned review date. It should not be used simply to hide unresolved vulnerabilities from scan results.

### Question d. Why is an SBOM useful?

An SBOM provides a complete inventory of software components included in the application. When a new vulnerability such as Log4Shell is disclosed, the SBOM makes it possible to quickly determine whether the affected component is present without rebuilding or manually inspecting the application.

---


# Task 2. OWASP ZAP Baseline Scan

### ZAP Version

OWASP ZAP was executed using the pinned Docker image:

```text
ghcr.io/zaproxy/zaproxy:2.16.1
```

---

### Initial Baseline Scan

Reports:

```text
submissions/src/lab09/zap/report_before.html
submissions/src/lab09/zap/report_before.json
```

Command:

```powershell
docker run --rm `
  -v "${PWD}\submissions\src\lab09\zap:/zap/wrk" `
  ghcr.io/zaproxy/zaproxy:2.16.1 `
  zap-baseline.py `
  -t http://host.docker.internal:8080/health `
  -z "-configfile /zap/wrk/urls.txt" `
  -r report_before.html `
  -J report_before.json
```

The baseline scan completed successfully.

Summary:

- High: **0**
- Medium: **0**
- Low: **2**
- Informational: **1**

Screenshot:

![](screenshots/lab09/zap_report_before.png)

---

## ZAP Findings Triage

| Finding | Risk | URL | Disposition | Reason |
|----------|------|-----|-------------|--------|
| Insufficient Site Isolation Against Spectre Vulnerability | Low | `/health` | ACCEPT | The application is a small local API without browser-delivered sensitive content. The missing `Cross-Origin-Resource-Policy` header presents negligible practical risk in this deployment. |
| Storable / Non-Storable Content | Informational | `/`, `/robots.txt`, `/sitemap.xml`, `/health` | ACCEPT | The application intentionally exposes only API endpoints and does not implement a website. Missing cache directives on nonexistent pages are acceptable. |
| ZAP is Out of Date | Low | Scanner | ACCEPT | This warning refers to the scanner version itself rather than the application being tested. The lab explicitly required using the pinned version `2.16.1`. |

---

## Security Header Fix

A middleware was added to apply security headers to every HTTP response.

Instead of modifying each handler individually, a single middleware wraps the router and automatically injects security headers.

Implemented headers include:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Referrer-Policy: no-referrer`
- `Content-Security-Policy: default-src 'none'`

The implementation ensures that every endpoint receives the same protection automatically.

---

## Unit Test

A unit test was added to verify that the middleware injects the expected security headers.

Output:

```text
submissions/src/lab09/go_test_security_headers.txt
```

Command:

```powershell
go test ./...
```

Result:

```text
PASS
```

The test would fail if the middleware were removed, ensuring that the security fix remains protected against future regressions.

---

## Header Verification

Headers were verified manually after rebuilding the application.

Output:

```text
submissions/src/lab09/headers_after_fix.txt
```

Example:

```text
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Content-Security-Policy: default-src 'none'
```

---

## Re-scan After the Fix

Reports:

```text
submissions/src/lab09/zap/report_after.html
submissions/src/lab09/zap/report_after.json
```

Command:

```powershell
docker run --rm `
  -v "${PWD}\submissions\src\lab09\zap:/zap/wrk" `
  ghcr.io/zaproxy/zaproxy:2.16.1 `
  zap-baseline.py `
  -t http://host.docker.internal:8080/health `
  -z "-configfile /zap/wrk/urls.txt" `
  -r report_after.html `
  -J report_after.json
```

Summary:

- High: **0**
- Medium: **0**
- Low: **2**
- Informational: **1**

Screenshot:

![](screenshots/lab09/zap_report_after.png)

The re-scan confirmed that no High or Medium findings were introduced after the security changes. The remaining findings are accepted according to the triage decisions above.

---

## Tsk 2 Design Questions

### Question e. Why implement security headers using middleware?

Middleware guarantees that every request passes through the same security logic. It avoids duplicated code, prevents accidental omissions when adding new handlers, and centralizes future security changes in a single place.

### Question f. Why is `Content-Security-Policy: default-src 'none'` acceptable for QuickNotes but not for a website?

This policy blocks loading of scripts, styles, fonts, images, and other browser resources. That would completely break a traditional website. QuickNotes is a JSON API rather than a browser application, so clients do not require those resources and the strict policy is appropriate.

### Question g. Why is blindly accepting all ZAP findings dangerous?

Ignoring findings without reviewing them defeats the purpose of security scanning. A real vulnerability may be overlooked among informational warnings, leading to exploitable issues remaining in production. Proper triage ensures that each finding is consciously evaluated and documented.

---

## Observations

- Trivy successfully scanned the image, repository filesystem, and project configuration.
- A CycloneDX SBOM was generated successfully.
- The Debian distroless runtime contained no HIGH or CRITICAL operating-system vulnerabilities.
- HIGH findings detected inside the Go binary originate from the bundled Go runtime and should be resolved by upgrading to patched Go releases.
- The filesystem HIGH finding corresponds to a local Vagrant private key excluded from Git and production artifacts.
- OWASP ZAP baseline completed successfully and reported no High or Medium application vulnerabilities.
- Security headers were implemented using middleware and verified with automated tests.
- The application was rescanned after the fix, and only accepted Low/Informational findings remained.