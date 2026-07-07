# Lab 9: DevSecOps: Scan QuickNotes with Trivy + ZAP

All scans use **Trivy `aquasec/trivy:0.59.1`**, run as a Docker container with a persistent cache volume so the vulnerability database is downloaded only once

```bash
# Build the Lab 6 image
docker compose build

# Image scan
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 image quicknotes:lab6 --severity HIGH,CRITICAL

# Filesystem scan (vulnerabilities and secrets)
docker run --rm \
  -v "$PWD:/repo" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 fs /repo \
  --severity HIGH,CRITICAL --scanners vuln,secret

# Configuration scan
docker run --rm \
  -v "$PWD:/repo" \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 config /repo

# Generate a CycloneDX SBOM
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy:0.59.1 image quicknotes:lab6 \
  --format cyclonedx --output quicknotes-lab6.sbom.cdx.json
```

## Task 1: Trivy: Image + Filesystem + Config + SBOM

### 1.1 Required scans

#### Image scan

```text
quicknotes:lab6 (debian 12.14)
==============================
Total: 0 (HIGH: 0, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 11 (HIGH: 11, CRITICAL: 0)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬─────────────────┬─────────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version   │ Title                                                       │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼─────────────────┼─────────────────────────────────────────────────────────────┤
│ stdlib  │ CVE-2026-25679 │ HIGH     │ fixed  │ v1.24.13          │ 1.25.8, 1.26.1  │ net/url: Incorrect parsing of IPv6 host literals            │
│ ...     │ ...            │ ...      │ ...    │ ...               │ ...             │ ...                                                         │
└─────────┴────────────────┴──────────┴────────┴───────────────────┴─────────────────┴─────────────────────────────────────────────────────────────┘
```

The Debian base image has **no HIGH or CRITICAL vulnerabilities**. All 11 HIGH findings come from the **Go standard library** in the application binary, which was built with **Go 1.24.13**. These vulnerabilities are fixed in newer Go releases, so updating the Go toolchain resolves them.

#### Filesystem scan

```text
Number of language-specific files: 1
[gomod] Detecting vulnerabilities... → 0

.vagrant/machines/default/virtualbox/private_key (secrets)
==========================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
  Asymmetric Private Key
  .vagrant/machines/default/virtualbox/private_key:1
```

The project has **no vulnerable Go dependencies**. The only finding is a Vagrant SSH private key used for local development. It is already `.gitignore`d, not tracked by Git, and is not included in the Docker image.

#### Config scan

```text
app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

The Dockerfile passes **27 of 28 checks**. The only issue is a **LOW** severity recommendation to add a `HEALTHCHECK`. No configuration issues were reported for `compose.yaml`.

#### SBOM

A CycloneDX 1.6 SBOM was generated containing **6 components**:

- 4 Debian packages
- QuickNotes binary
- Go standard library

### 1.2 Triage

| Finding | Scan | Severity | Disposition | Reason |
|---------|------|----------|-------------|--------|
| 11 Go standard library CVEs | Image | HIGH | **FIX** | Update the Go toolchain and rebuild the application. |
| Vagrant private key | Filesystem | HIGH | **ACCEPT** | Local development key, `.gitignore`d, never shipped. |
| Missing `HEALTHCHECK` | Config | LOW | **FIX** | Added a `HEALTHCHECK` instruction to the Dockerfile. |

### 1.3 Design questions

**a) CVE severity is one input, not the answer. What else matters?**

CVSS measures the severity of a vulnerability, but the actual risk depends on the application.

- **Reachability** – Is the vulnerable code actually used?
- **Exploitability** – Is there a public exploit or active exploitation?
- **Deployment context** – Is the service internet-facing or internal? What data does it handle?
- **Compensating controls** – Protections such as running as a non-root user, a read-only filesystem, and dropped Linux capabilities reduce risk.
- **Fix availability** – If a simple update fixes the issue, it should usually be applied.

For QuickNotes, the 11 HIGH findings were all fixed by updating the Go toolchain.

**b) Why are distroless images more secure?**

Distroless images contain only the files needed to run the application. Fewer packages mean:

- Smaller attack surface
- Fewer vulnerabilities
- No shell or package manager for attackers
- Smaller SBOM and lower maintenance

In this project, the distroless base image had **0 HIGH/CRITICAL vulnerabilities**, so nearly all findings came from the application itself.

**c) When should `.trivyignore` be used?**

Use `.trivyignore` only after a documented risk assessment, such as for:

- False positives
- Unfixable vulnerabilities
- Development-only files that are never deployed

Each ignored finding should include a reason and be reviewed regularly. It should never be used simply to hide real security issues.

**d) Why is an SBOM useful?**

An SBOM records every software component included in an application. If a new vulnerability (such as Log4Shell) is announced, the SBOM makes it easy to determine whether the affected component is present and which version is in use. This speeds up incident response and patching.

### 1.5 CycloneDX SBOM — first 30 lines

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:40a1b320-efbd-4cd8-8d8f-e6361206ade8",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T13:40:49+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3Ae626f5267a1ff84d353f8d62a74d3c3d1fd1d78877db71ccaca14942b0c77950?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3Ae626f5267a1ff84d353f8d62a74d3c3d1fd1d78877db71ccaca14942b0c77950?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:114dde0fefebbca13165d0da9c500a66190e497a82a53dcaabc3172d630be1e9"
        },
        {
```

The generated SBOM contains **6 components**: four Debian packages, the **QuickNotes** application, and the **Go standard library**
