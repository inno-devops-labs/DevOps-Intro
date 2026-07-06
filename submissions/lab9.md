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
