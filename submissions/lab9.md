# Lab 9 - DevSecOps: Trivy + ZAP

## Environment and tools

- Docker Desktop on the Windows host could not start WSL2 (`Wsl/Service/RegisterDistro/CreateVm/HCS/ERROR_NOT_SUPPORTED`), so I ran Docker Engine inside the Lab 5 Vagrant/VirtualBox VM.
- Trivy image: `aquasec/trivy:0.59.1`
- ZAP image: `zaproxy/zap-bare:2.16.1`
- QuickNotes image: `quicknotes:lab6`
- Reports are committed under `security/lab9/`.

ZAP note: the pinned `zaproxy/zap-bare:2.16.1` image contains `zap.sh` and the ZAP engine but does not ship `zap-baseline.py` or Python. I therefore ran the ZAP Automation Framework with the same baseline safety boundary: spider, passive scan wait, and HTML/JSON reports only. I did not run an active scan.

## Commands

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/labwork/lab9:/work \
  -v trivy-cache:/root/.cache \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6

docker run --rm \
  -v /mnt/labwork/lab9:/work \
  -v trivy-cache:/root/.cache \
  aquasec/trivy:0.59.1 fs --severity HIGH,CRITICAL --no-progress /work

docker run --rm \
  -v /mnt/labwork/lab9:/work \
  -v trivy-cache:/root/.cache \
  aquasec/trivy:0.59.1 config --severity HIGH,CRITICAL /work

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/labwork/lab9:/work \
  -v trivy-cache:/root/.cache \
  aquasec/trivy:0.59.1 image --format cyclonedx \
  --output /work/security/lab9/quicknotes.cdx.json quicknotes:lab6

docker run --rm --network host \
  -v /mnt/labwork/lab9/security/lab9:/zap/wrk:rw \
  zaproxy/zap-bare:2.16.1 \
  zap.sh -cmd -silent -port 9091 -autorun /zap/wrk/zap-before.yaml

docker run --rm --network host \
  -v /mnt/labwork/lab9/security/lab9:/zap/wrk:rw \
  zaproxy/zap-bare:2.16.1 \
  zap.sh -cmd -silent -port 9091 -autorun /zap/wrk/zap-after.yaml
```

## Trivy Output

Artifacts:

- `security/lab9/trivy-image.txt`
- `security/lab9/trivy-fs.txt`
- `security/lab9/trivy-config.txt`
- `security/lab9/quicknotes.cdx.json`

Image scan top summary:

```text
quicknotes:lab6 (debian 12.15)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 19 (HIGH: 19, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 19 (HIGH: 19, CRITICAL: 0)
```

Filesystem scan top summary:

```text
2026-09-25T14:49:09Z INFO [vuln] Vulnerability scanning is enabled
2026-09-25T14:49:09Z INFO [secret] Secret scanning is enabled
2026-09-25T14:49:09Z INFO Number of language-specific files num=1
2026-09-25T14:49:09Z INFO [gomod] Detecting vulnerabilities...
No HIGH/CRITICAL findings were emitted.
```

Config scan top summary:

```text
2026-09-25T14:49:18Z INFO [misconfig] Misconfiguration scanning is enabled
2026-09-25T14:49:21Z INFO Detected config files num=1
No HIGH/CRITICAL misconfiguration findings were emitted.
```

The config scan also printed a Trivy check-bundle parser warning for an unrelated built-in AWS EC2 rule (`specify_ami_owners.rego`). The command exited successfully and did not produce any HIGH/CRITICAL rows for this repo.

CycloneDX SBOM first 30 lines:

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:dec4f67a-f41b-4a3d-8ab3-44da956dd01b",
  "version": 1,
  "metadata": {
    "timestamp": "2026-09-25T14:45:48+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3A050afe46cfd7f9e3651e39a2cf9f4fcd75b25fabd6ac32d4c80f9a42737c8525?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A050afe46cfd7f9e3651e39a2cf9f4fcd75b25fabd6ac32d4c80f9a42737c8525?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:114dde0fefebbca13165d0da9c500a66190e497a82a53dcaabc3172d630be1e9"
        },
        {
```

## Trivy Triage

The Debian 12.15 distroless base reported zero HIGH/CRITICAL findings. The filesystem and config scans reported zero HIGH/CRITICAL findings. The image scan reported the following Go `stdlib` HIGH findings twice: once in `/quicknotes` and once in `/healthcheck`. The disposition applies to both affected binaries for each CVE.

| Finding | Component | Affected binaries | Severity | Disposition | Reason |
|---|---|---|---|---|---|
| CVE-2026-25679 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Fixed releases require a newer Go minor than this course repo currently pins (`go 1.24`). QuickNotes is a local lab API and does not terminate TLS or expose a user-supplied URL parsing surface. Re-evaluate by 2026-12-25 or when the course Go line moves. |
| CVE-2026-27145 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Fixed releases require a newer Go minor than this course repo currently pins. QuickNotes does not perform certificate validation against untrusted remote endpoints. Re-evaluate by 2026-12-25. |
| CVE-2026-32280 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the app is HTTP-only behind the lab runtime and does not build external certificate chains. Re-evaluate by 2026-12-25. |
| CVE-2026-32281 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue and certificate-chain reachability is not present in the service. Re-evaluate by 2026-12-25. |
| CVE-2026-32283 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; QuickNotes does not expose TLS 1.3 handling directly. Re-evaluate by 2026-12-25. |
| CVE-2026-33811 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; no untrusted DNS/CNAME resolution path is part of app behavior. Re-evaluate by 2026-12-25. |
| CVE-2026-33814 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; no HTTP/2 endpoint is intentionally exposed by the app server in this lab. Re-evaluate by 2026-12-25. |
| CVE-2026-33818 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the app does not parse ASN.1 input. Re-evaluate by 2026-12-25. |
| CVE-2026-39820 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the app does not parse email addresses. Re-evaluate by 2026-12-25. |
| CVE-2026-39821 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the app does not process IDNA/Punycode host labels from users. Re-evaluate by 2026-12-25. |
| CVE-2026-39822 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the app does not expose `os.Root` or user-controlled filesystem traversal. Re-evaluate by 2026-12-25. |
| CVE-2026-39836 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; no untrusted network-name parsing path is part of app behavior. Re-evaluate by 2026-12-25. |
| CVE-2026-42499 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the app does not parse email addresses. Re-evaluate by 2026-12-25. |
| CVE-2026-42504 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the app does not parse MIME messages from users. Re-evaluate by 2026-12-25. |
| CVE-2026-56853 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the lab deployment does not intentionally serve unencrypted HTTP/2. Re-evaluate by 2026-12-25. |
| CVE-2026-56858 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; QuickNotes returns JSON and does not render `html/template`. Re-evaluate by 2026-12-25. |
| CVE-2026-56859 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; QuickNotes does not decode XML input. Re-evaluate by 2026-12-25. |
| CVE-2026-56860 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; the API does not expose a path that repeatedly parses attacker-controlled URLs. Re-evaluate by 2026-12-25. |
| CVE-2026-56862 | Go `stdlib` v1.24.13 | `quicknotes`, `healthcheck` | HIGH | ACCEPT | Same Go toolchain issue; QuickNotes does not expose TLS KeyUpdate processing directly. Re-evaluate by 2026-12-25. |

No `.trivyignore` entries were added.

## ZAP Triage

Artifacts:

- `security/lab9/zap-before.html`
- `security/lab9/zap-before.json`
- `security/lab9/zap-after.html`
- `security/lab9/zap-after.json`
- `security/lab9/header-evidence.txt`

| Report | ID | Name | Risk | Affected URL / parameter | Disposition | Reason |
|---|---:|---|---|---|---|---|
| Before | 10021 | X-Content-Type-Options Header Missing | Low (Medium confidence) | `GET http://127.0.0.1:8081/health`, parameter `x-content-type-options` | FIX | Added HTTP security-header middleware and a regression test. |
| After | none | none | none | none | FIX VERIFIED | `zap-after.json` contains an empty `alerts` array. |

Before excerpt:

```json
{
  "pluginid": "10021",
  "alert": "X-Content-Type-Options Header Missing",
  "riskdesc": "Low (Medium)",
  "count": "1"
}
```

After excerpt:

```json
"alerts": []
```

Header evidence:

```text
== before http://127.0.0.1:8081/health ==
HTTP/1.1 200 OK
Content-Type: application/json

== after http://127.0.0.1:8080/health ==
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Cross-Origin-Resource-Policy: same-origin
Permissions-Policy: camera=(), geolocation=(), microphone=()
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

## Code Fix

The fix is in `app/handlers.go`: `Routes()` wraps the router with `securityHeaders`. The middleware sets:

- `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Referrer-Policy: no-referrer`
- `Permissions-Policy: camera=(), geolocation=(), microphone=()`
- `Cross-Origin-Resource-Policy: same-origin`

`app/handlers_test.go` includes `TestSecurityHeaders_AppliedToAllRoutes`, which checks `/health` and `/notes/999`. The second path makes sure the middleware also covers error responses.

## Design Questions

a) CVE severity is only a sorting hint. I also need reachability, whether an exploit exists, whether the vulnerable code path is exposed to untrusted input, whether compensating controls exist, and how expensive or risky the fix is.

b) A distroless base removes package managers, shells, and most OS packages. That reduces both the number of CVEs a scanner can find and the tools an attacker could use after a compromise.

c) `.trivyignore` is appropriate when a finding has a documented false-positive or accepted-risk decision with an expiry date. It is security theater if it hides uncomfortable findings just to make a report green.

d) An SBOM lets me answer future exposure questions quickly. If a new Log4Shell-style issue lands, I can query the released artifact inventory instead of reverse-engineering old images under pressure.

e) Middleware is the right place for security headers because it is centralized and wraps every route, including future endpoints and error paths. Per-handler header sets drift as the API grows.

f) `Content-Security-Policy: default-src 'none'` blocks scripts, images, fonts, styles, frames, and network loads unless they are explicitly allowed. That would break a normal website, but QuickNotes is a JSON API with no browser-rendered UI assets.

g) Marking ZAP findings accepted without reading them trains the team to ignore the scanner. It also hides real regressions among informational noise, so the next genuinely exploitable issue is easier to miss.

## Bonus

The `govulncheck` CI bonus was not attempted in this PR.
