# Lab 9 submission

### Trivy scan
#### Image scan
```sh
$ trivy image quicknotes:lab6 --severity HIGH,CRITICAL
2026-07-07T13:16:48+03:00       INFO    [vuln] Vulnerability scanning is enabled
2026-07-07T13:16:48+03:00       INFO    [secret] Secret scanning is enabled
2026-07-07T13:16:48+03:00       INFO    [secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-07-07T13:16:48+03:00       INFO    [secret] Please see https://trivy.dev/docs/v0.70/guide/scanner/secret#recommendation for faster secret detection
2026-07-07T13:16:48+03:00       INFO    Number of language-specific files       num=1
2026-07-07T13:16:48+03:00       INFO    [gobinary] Detecting vulnerabilities...
2026-07-07T13:16:48+03:00       WARN    Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/docs/v0.70/guide/scanner/vulnerability#severity-selection for details.

Report Summary

┌────────────┬──────────┬─────────────────┬─────────┐
│   Target   │   Type   │ Vulnerabilities │ Secrets │
├────────────┼──────────┼─────────────────┼─────────┤
│ app/qn-bin │ gobinary │       14        │    -    │
└────────────┴──────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


app/qn-bin (gobinary)

Total: 14 (HIGH: 13, CRITICAL: 1)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬──────────────────────────────┬──────────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │        Fixed Version         │                            Title                             │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ stdlib  │ CVE-2025-68121 │ CRITICAL │ fixed  │ v1.24.5           │ 1.24.13, 1.25.7, 1.26.0-rc.3 │ crypto/tls: crypto/tls: Incorrect certificate validation     │
│         │                │          │        │                   │                              │ during TLS session resumption                                │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2025-68121                   │
│         ├────────────────┼──────────┤        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-61726 │ HIGH     │        │                   │ 1.24.12, 1.25.6              │ golang: net/url: Memory exhaustion in query parameter        │
│         │                │          │        │                   │                              │ parsing in net/url                                           │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2025-61726                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-61729 │          │        │                   │ 1.24.11, 1.25.5              │ crypto/x509: golang: Denial of Service due to excessive      │
│         │                │          │        │                   │                              │ resource consumption via crafted...                          │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2025-61729                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-25679 │          │        │                   │ 1.25.8, 1.26.1               │ net/url: Incorrect parsing of IPv6 host literals in net/url  │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-25679                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-27145 │          │        │                   │ 1.25.11, 1.26.4              │ crypto/x509: golang: golang crypto/x509: Denial of Service   │
│         │                │          │        │                   │                              │ via excessive processing of DNS...                           │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-27145                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32280 │          │        │                   │ 1.25.9, 1.26.2               │ crypto/x509: crypto/tls: golang: Go: Denial of Service       │
│         │                │          │        │                   │                              │ vulnerability in certificate chain building...               │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32280                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32281 │          │        │                   │                              │ crypto/x509: golang: Go crypto/x509: Denial of Service via   │
│         │                │          │        │                   │                              │ inefficient certificate chain validation...                  │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32281                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32283 │          │        │                   │                              │ crypto/tls: golang: Go crypto/tls: Denial of Service via     │
│         │                │          │        │                   │                              │ multiple TLS 1.3 key...                                      │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32283                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33811 │          │        │                   │ 1.25.10, 1.26.3              │ net: golang: Go net package: Denial of Service via long      │
│         │                │          │        │                   │                              │ CNAME response...                                            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33811                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33814 │          │        │                   │                              │ net/http/internal/http2: golang: golang.org/x/net: Go        │
│         │                │          │        │                   │                              │ HTTP/2: Denial of Service via malformed                      │
│         │                │          │        │                   │                              │ SETTINGS_MAX_FRAME_SIZE frame...                             │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33814                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39820 │          │        │                   │                              │ net/mail: golang: Go net/mail: Denial of Service via crafted │
│         │                │          │        │                   │                              │ email inputs                                                 │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39820                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39836 │          │        │                   │                              │ ELSA-2026-22121: golang security update (IMPORTANT)          │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39836                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-42499 │          │        │                   │                              │ net/mail: golang: net/mail: Denial of Service via            │
│         │                │          │        │                   │                              │ pathological email address parsing                           │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-42499                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-42504 │          │        │                   │ 1.25.11, 1.26.4              │ Decoding a maliciously-crafted MIME header containing many   │
│         │                │          │        │                   │                              │ invalid enc ...                                              │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-42504                   │
└─────────┴────────────────┴──────────┴────────┴───────────────────┴──────────────────────────────┴──────────────────────────────────────────────────────────────┘
```

#### FS Scan
```sh
$ trivy fs . --severity HIGH,CRITICAL
2026-07-07T13:30:21+03:00       INFO    [vuln] Vulnerability scanning is enabled
2026-07-07T13:30:21+03:00       INFO    [secret] Secret scanning is enabled
2026-07-07T13:30:21+03:00       INFO    [secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-07-07T13:30:21+03:00       INFO    [secret] Please see https://trivy.dev/docs/v0.70/guide/scanner/secret#recommendation for faster secret detection
2026-07-07T13:30:21+03:00       INFO    Number of language-specific files       num=1
2026-07-07T13:30:21+03:00       INFO    [gomod] Detecting vulnerabilities...

Report Summary

┌────────────┬───────┬─────────────────┬─────────┐
│   Target   │ Type  │ Vulnerabilities │ Secrets │
├────────────┼───────┼─────────────────┼─────────┤
│ app/go.mod │ gomod │        0        │    -    │
└────────────┴───────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

```

#### Config Scan
```sh
$ trivy config .
2026-07-07T13:55:52+03:00       INFO    [misconfig] Misconfiguration scanning is enabled
2026-07-07T13:55:52+03:00       INFO    [checks-client] Using existing checks from cache        path="/home/arsenez/.cache/trivy/policy/content"
2026-07-07T13:55:53+03:00       INFO    Detected config files   num=1

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

Tests: 27 (SUCCESSES: 26, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.

See https://avd.aquasec.com/misconfig/ds-0026
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────



📣 Notices:
  - Version 0.72.0 of Trivy is now available, current version is 0.70.0

To suppress version checks, run Trivy scans with the --skip-version-check flag
```

#### SBOM
```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:b18abb64-7d14-46f1-9bfe-fdc626586eab",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T10:57:27+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "manufacturer": {
            "name": "Aqua Security Software Ltd."
          },
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.70.0"
        }
      ]
    },
    "component": {
      "bom-ref": "2a76c971-5edb-4106-8e24-cfbe6eb97f1d",
      "type": "container",
      "name": "quicknotes:lab6",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef"
        },
...
```

### Security Triage
| Vulnerability | Label | Reason                                          |
| ------------- | ----- | ----------------------------------------------- |
| CVE-2025-68121| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2025-61726| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2025-61729| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-25679| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-27145| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-32280| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-32281| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-32283| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-33811| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-33814| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-39820| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-39836| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-42499| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |
| CVE-2026-42504| FIX   | Fixed by bumping go version to 1.26.4 (cbf48cd) |