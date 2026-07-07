# Lab 9 submission

### trivy image quicknotes:lab6 --severity HIGH,CRITICAL
```
2026-07-03T23:33:55+03:00       INFO    [vulndb] Need to update DB
2026-07-03T23:33:55+03:00       INFO    [vulndb] Downloading vulnerability DB...
2026-07-03T23:33:55+03:00       INFO    [vulndb] Downloading artifact...        repo="mirror.gcr.io/aquasec/trivy-db:2"
98.92 MiB / 98.92 MiB [--------------------------------------------------------------------------------------------------------------------------------------] 100.00% 12.75 MiB p/s 8.0s
2026-07-03T23:34:05+03:00       INFO    [vulndb] Artifact successfully downloaded       repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-07-03T23:34:05+03:00       INFO    [vuln] Vulnerability scanning is enabled
2026-07-03T23:34:05+03:00       INFO    [secret] Secret scanning is enabled
2026-07-03T23:34:05+03:00       INFO    [secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-07-03T23:34:05+03:00       INFO    [secret] Please see https://trivy.dev/docs/v0.72/guide/scanner/secret#recommendation for faster secret detection
2026-07-03T23:34:05+03:00       INFO    Detected OS     family="debian" version="13.5"
2026-07-03T23:34:05+03:00       INFO    [debian] Detecting vulnerabilities...   os_version="13" pkg_num=5
2026-07-03T23:34:05+03:00       INFO    Number of language-specific files       num=1
2026-07-03T23:34:05+03:00       INFO    [gobinary] Detecting vulnerabilities...
2026-07-03T23:34:05+03:00       WARN    Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/docs/v0.72/guide/scanner/vulnerability#severity-selection for details.

Report Summary

┌───────────────────────────────┬──────────┬─────────────────┬─────────┐
│            Target             │   Type   │ Vulnerabilities │ Secrets │
├───────────────────────────────┼──────────┼─────────────────┼─────────┤
│ quicknotes:lab6 (debian 13.5) │  debian  │        0        │    -    │
├───────────────────────────────┼──────────┼─────────────────┼─────────┤
│ quicknotes                    │ gobinary │       13        │    -    │
└───────────────────────────────┴──────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


quicknotes (gobinary)

Total: 13 (HIGH: 12, CRITICAL: 1)

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
└─────────┴────────────────┴──────────┴────────┴───────────────────┴──────────────────────────────┴──────────────────────────────────────────────────────────────┘
```

```
trivy fs . --severity HIGH,CRITICAL 
2026-07-03T23:41:08+03:00       INFO    [vuln] Vulnerability scanning is enabled
2026-07-03T23:41:08+03:00       INFO    [secret] Secret scanning is enabled
2026-07-03T23:41:08+03:00       INFO    [secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-07-03T23:41:08+03:00       INFO    [secret] Please see https://trivy.dev/docs/v0.72/guide/scanner/secret#recommendation for faster secret detection
2026-07-03T23:41:08+03:00       INFO    Number of language-specific files       num=1
2026-07-03T23:41:08+03:00       INFO    [gomod] Detecting vulnerabilities...

Report Summary

┌──────────────────────────────────────────────────┬───────┬─────────────────┬─────────┐
│                      Target                      │ Type  │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────┼───────┼─────────────────┼─────────┤
│ app/go.mod                                       │ gomod │        0        │    -    │
├──────────────────────────────────────────────────┼───────┼─────────────────┼─────────┤
│ .vagrant/machines/default/virtualbox/private_key │ text  │        -        │    1    │
└──────────────────────────────────────────────────┴───────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


.vagrant/machines/default/virtualbox/private_key (secrets)

Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
Asymmetric Private Key
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 .vagrant/machines/default/virtualbox/private_key:2-7 (offset: 36 bytes)
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1   -----BEGIN OPENSSH PRIVATE KEY-----
   2 ┌ ************************************************************
   3 │ ************************************************************
   4 │ ************************************************************
   5 │ ************************************************************
   6 │ ************************************************************
   7 └ ************************
   8   -----END OPENSSH PRIVATE KEY-----
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

```
trivy config .
2026-07-03T23:43:25+03:00       INFO    [misconfig] Misconfiguration scanning is enabled
2026-07-03T23:43:25+03:00       INFO    [checks-client] Using existing checks from cache        path="/home/long1tail/.cache/trivy/policy/content"
2026-07-03T23:43:26+03:00       INFO    Detected config files   num=1

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
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.

See https://avd.aquasec.com/misconfig/ds-0026
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

```
2026-07-03T23:48:16+03:00       INFO    "--format cyclonedx" disables security scanning. Specify "--scanners vuln" explicitly if you want to include vulnerabilities in the "cyclonedx" report.
2026-07-03T23:48:16+03:00       INFO    Detected OS     family="debian" version="13.5"
2026-07-03T23:48:16+03:00       INFO    Number of language-specific files       num=1
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:5cfb98d0-5b0a-4f53-a8c8-6c125b427428",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-03T20:48:16+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "manufacturer": {
            "name": "Aqua Security Software Ltd."
          },
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.72.0"
        }
      ]
    },
    "component": {
      "bom-ref": "pkg:oci/quicknotes@sha256:7cb3a02c11cf2ff470db3d1a9424b5b504d22a78cf0a33e541054e06c0c383b3?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256:7cb3a02c11cf2ff470db3d1a9424b5b504d22a78cf0a33e541054e06c0c383b3?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:275a30dd8ce958b21daa9ad962c6fbc09f98306ee2f486b65c9075dc257b1412"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:4cde6b0bb6f50a5f255eef7b2a42162c661cf776b803225dcac9a659e396bb6b"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:4d049f83d9cf21d1f5cc0e11deaf36df02790d0e60c1a3829538fb4b61685368"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:5892e2ebce362e40d2093eb8a7e460aa390423bf3a948d509edad0a1d413e508"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:5fd2536c39c0700be8b7b4344e375196da2f126842fd8ede66996a18860a3890"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:621c35e751a51a9a9dc3e80aa0b7fe8be2a93402ea6ccd307d30852cd7776cda"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:6f1cdceb6a3146f0ccb986521156bef8a422cdbb0863396f7f751f575ba308f4"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:92cb9c37b7d3957ac56645a979418f65e6c5bdba00eb99622affae5fc124ac07"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:ad51d0769d16ba578106a177987dfe3d2e02c1668c852b795b2f6b024068242a"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:af5aa97ebe6ce1604747ec1e21af7136ded391bcabe4acef882e718a87c86bcc"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:bd3cdfae1d3fdd83a2231d608969b38b82349777c2fff9a7c12d54f8ac5c9b38"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:bec7e6bb35e05d1284f28b10d2150c259717d91c658c4c10c08424bb9466caba"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:c8b007d0206e4b10ed4d3b3d99dfeab47c2648e82011989fd78a5731baf33fc3"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:f9b720b12c137c381ff66e91fc9d534365b7a7c785f2cc4882d5cbecea93acce"
        },
        {
          "name": "aquasecurity:trivy:ImageID",
          "value": "sha256:7cb3a02c11cf2ff470db3d1a9424b5b504d22a78cf0a33e541054e06c0c383b3"
        },
        {
          "name": "aquasecurity:trivy:Reference",
          "value": "quicknotes:lab6"
        },
        {
          "name": "aquasecurity:trivy:RepoDigest",
          "value": "quicknotes@sha256:7cb3a02c11cf2ff470db3d1a9424b5b504d22a78cf0a33e541054e06c0c383b3"
        },
        {
          "name": "aquasecurity:trivy:RepoTag",
          "value": "quicknotes:lab6"
        },
        {
          "name": "aquasecurity:trivy:SchemaVersion",
          "value": "2"
        },
        {
          "name": "aquasecurity:trivy:Size",
          "value": "9106944"
        }
      ]
    }
  },
  "components": [
    {
      "bom-ref": "ac18a7de-caad-4e7b-8f39-341e712a77fe",
      "type": "operating-system",
      "name": "debian",
      "version": "13.5",
      "properties": [
        {
          "name": "aquasecurity:trivy:Class",
          "value": "os-pkgs"
        },
        {
          "name": "aquasecurity:trivy:Type",
          "value": "debian"
        }
      ]
    },
    {
      "bom-ref": "f46773e4-a1f6-4360-8501-256ecf13d422",
      "type": "application",
      "name": "quicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:Class",
          "value": "lang-pkgs"
        },
        {
          "name": "aquasecurity:trivy:Type",
          "value": "gobinary"
        }
      ]
    },
    {
      "bom-ref": "pkg:deb/debian/base-files@13.8%2Bdeb13u5?arch=amd64&distro=debian-13.5",
      "type": "library",
      "supplier": {
        "name": "Santiago Vila <sanvila@debian.org>"
      },
      "name": "base-files",
      "version": "13.8+deb13u5",
      "licenses": [
        {
          "license": {
            "id": "GPL-2.0-or-later"
          }
        },
        {
          "license": {
            "name": "verbatim"
          }
        }
      ],
      "purl": "pkg:deb/debian/base-files@13.8%2Bdeb13u5?arch=amd64&distro=debian-13.5",
      "properties": [
        {
          "name": "aquasecurity:trivy:LayerDiffID",
          "value": "sha256:92cb9c37b7d3957ac56645a979418f65e6c5bdba00eb99622affae5fc124ac07"
        },
        {
          "name": "aquasecurity:trivy:LayerDigest",
          "value": "sha256:47de5dd0b812c573630914955e26abda537e09b5286a824c96e22e3854d4dd53"
        },
        {
          "name": "aquasecurity:trivy:PkgID",
          "value": "base-files@13.8+deb13u5"
        },
        {
          "name": "aquasecurity:trivy:PkgType",
          "value": "debian"
        },
        {
          "name": "aquasecurity:trivy:SrcName",
          "value": "base-files"
        },
        {
          "name": "aquasecurity:trivy:SrcVersion",
          "value": "13.8+deb13u5"
        }
      ]
    },
    {
      "bom-ref": "pkg:deb/debian/media-types@13.0.0?arch=all&distro=debian-13.5",
      "type": "library",
      "supplier": {
        "name": "Mime-Support Packagers <team+debian-mimesupport-packagers@tracker.debian.org>"
      },
      "name": "media-types",
      "version": "13.0.0",
      "licenses": [
        {
          "license": {
            "name": "ad-hoc"
          }
        }
      ],
      "purl": "pkg:deb/debian/media-types@13.0.0?arch=all&distro=debian-13.5",
      "properties": [
        {
          "name": "aquasecurity:trivy:LayerDiffID",
          "value": "sha256:275a30dd8ce958b21daa9ad962c6fbc09f98306ee2f486b65c9075dc257b1412"
        },
        {
          "name": "aquasecurity:trivy:LayerDigest",
          "value": "sha256:d6b1b89eccacc15c2420b2776d72c1dae334a00805ed9af54bf2f71e4d536f28"
        },
        {
          "name": "aquasecurity:trivy:PkgID",
          "value": "media-types@13.0.0"
        },
        {
          "name": "aquasecurity:trivy:PkgType",
          "value": "debian"
        },
        {
          "name": "aquasecurity:trivy:SrcName",
          "value": "media-types"
        },
        {
          "name": "aquasecurity:trivy:SrcVersion",
          "value": "13.0.0"
        }
      ]
    },
    {
      "bom-ref": "pkg:deb/debian/netbase@6.5?arch=all&distro=debian-13.5",
      "type": "library",
      "supplier": {
        "name": "Marco d'Itri <md@linux.it>"
      },
      "name": "netbase",
      "version": "6.5",
      "licenses": [
        {
          "license": {
            "id": "GPL-2.0-only"
          }
        }
      ],
      "purl": "pkg:deb/debian/netbase@6.5?arch=all&distro=debian-13.5",
      "properties": [
        {
          "name": "aquasecurity:trivy:LayerDiffID",
          "value": "sha256:621c35e751a51a9a9dc3e80aa0b7fe8be2a93402ea6ccd307d30852cd7776cda"
        },
        {
          "name": "aquasecurity:trivy:LayerDigest",
          "value": "sha256:c172f21841dff4c8cf45cde46589c1c2616cefe7e819965e92e6d3475c428aa0"
        },
        {
          "name": "aquasecurity:trivy:PkgID",
          "value": "netbase@6.5"
        },
        {
          "name": "aquasecurity:trivy:PkgType",
          "value": "debian"
        },
        {
          "name": "aquasecurity:trivy:SrcName",
          "value": "netbase"
        },
        {
          "name": "aquasecurity:trivy:SrcVersion",
          "value": "6.5"
        }
      ]
    },
    {
      "bom-ref": "pkg:deb/debian/tzdata-legacy@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5",
      "type": "library",
      "supplier": {
        "name": "GNU Libc Maintainers <debian-glibc@lists.debian.org>"
      },
      "name": "tzdata-legacy",
      "version": "2026b-0+deb13u1",
      "licenses": [
        {
          "license": {
            "name": "public-domain"
          }
        }
      ],
      "purl": "pkg:deb/debian/tzdata-legacy@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5",
      "properties": [
        {
          "name": "aquasecurity:trivy:LayerDiffID",
          "value": "sha256:bec7e6bb35e05d1284f28b10d2150c259717d91c658c4c10c08424bb9466caba"
        },
        {
          "name": "aquasecurity:trivy:LayerDigest",
          "value": "sha256:99ba982a9142213c751a1709dcf088e63d8601f03b3f211bae037be698fef270"
        },
        {
          "name": "aquasecurity:trivy:PkgID",
          "value": "tzdata-legacy@2026b-0+deb13u1"
        },
        {
          "name": "aquasecurity:trivy:PkgType",
          "value": "debian"
        },
        {
          "name": "aquasecurity:trivy:SrcName",
          "value": "tzdata"
        },
        {
          "name": "aquasecurity:trivy:SrcRelease",
          "value": "0+deb13u1"
        },
        {
          "name": "aquasecurity:trivy:SrcVersion",
          "value": "2026b"
        }
      ]
    },
    {
      "bom-ref": "pkg:deb/debian/tzdata@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5",
      "type": "library",
      "supplier": {
        "name": "GNU Libc Maintainers <debian-glibc@lists.debian.org>"
      },
      "name": "tzdata",
      "version": "2026b-0+deb13u1",
      "licenses": [
        {
          "license": {
            "name": "public-domain"
          }
        }
      ],
      "purl": "pkg:deb/debian/tzdata@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5",
      "properties": [
        {
          "name": "aquasecurity:trivy:LayerDiffID",
          "value": "sha256:c8b007d0206e4b10ed4d3b3d99dfeab47c2648e82011989fd78a5731baf33fc3"
        },
        {
          "name": "aquasecurity:trivy:LayerDigest",
          "value": "sha256:99515e7b4d35e0652d3b0fde571b6ec269222ecacc506f026e1758d6261e9109"
        },
        {
          "name": "aquasecurity:trivy:PkgID",
          "value": "tzdata@2026b-0+deb13u1"
        },
        {
          "name": "aquasecurity:trivy:PkgType",
          "value": "debian"
        },
        {
          "name": "aquasecurity:trivy:SrcName",
          "value": "tzdata"
        },
        {
          "name": "aquasecurity:trivy:SrcRelease",
          "value": "0+deb13u1"
        },
        {
          "name": "aquasecurity:trivy:SrcVersion",
          "value": "2026b"
        }
      ]
    },
    {
      "bom-ref": "pkg:golang/quicknotes",
      "type": "library",
      "name": "quicknotes",
      "purl": "pkg:golang/quicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:LayerDiffID",
          "value": "sha256:f9b720b12c137c381ff66e91fc9d534365b7a7c785f2cc4882d5cbecea93acce"
        },
        {
          "name": "aquasecurity:trivy:LayerDigest",
          "value": "sha256:aa0574b2f7185ab28e65d536c216699d8eeb45d74924214e26efae7f53e01e4f"
        },
        {
          "name": "aquasecurity:trivy:PkgID",
          "value": "quicknotes"
        },
        {
          "name": "aquasecurity:trivy:PkgType",
          "value": "gobinary"
        }
      ]
    },
    {
      "bom-ref": "pkg:golang/stdlib@v1.24.5",
      "type": "library",
      "name": "stdlib",
      "version": "v1.24.5",
      "purl": "pkg:golang/stdlib@v1.24.5",
      "properties": [
        {
          "name": "aquasecurity:trivy:LayerDiffID",
          "value": "sha256:f9b720b12c137c381ff66e91fc9d534365b7a7c785f2cc4882d5cbecea93acce"
        },
        {
          "name": "aquasecurity:trivy:LayerDigest",
          "value": "sha256:aa0574b2f7185ab28e65d536c216699d8eeb45d74924214e26efae7f53e01e4f"
        },
        {
          "name": "aquasecurity:trivy:PkgID",
          "value": "stdlib@v1.24.5"
        },
        {
          "name": "aquasecurity:trivy:PkgType",
          "value": "gobinary"
        }
      ]
    }
  ],
  "dependencies": [
    {
      "ref": "ac18a7de-caad-4e7b-8f39-341e712a77fe",
      "dependsOn": [
        "pkg:deb/debian/base-files@13.8%2Bdeb13u5?arch=amd64&distro=debian-13.5",
        "pkg:deb/debian/media-types@13.0.0?arch=all&distro=debian-13.5",
        "pkg:deb/debian/netbase@6.5?arch=all&distro=debian-13.5",
        "pkg:deb/debian/tzdata-legacy@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5",
        "pkg:deb/debian/tzdata@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5"
      ]
    },
    {
      "ref": "f46773e4-a1f6-4360-8501-256ecf13d422",
      "dependsOn": [
        "pkg:golang/quicknotes"
      ]
    },
    {
      "ref": "pkg:deb/debian/base-files@13.8%2Bdeb13u5?arch=amd64&distro=debian-13.5",
      "dependsOn": []
    },
    {
      "ref": "pkg:deb/debian/media-types@13.0.0?arch=all&distro=debian-13.5",
      "dependsOn": []
    },
    {
      "ref": "pkg:deb/debian/netbase@6.5?arch=all&distro=debian-13.5",
      "dependsOn": []
    },
    {
      "ref": "pkg:deb/debian/tzdata-legacy@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5",
      "dependsOn": []
    },
    {
      "ref": "pkg:deb/debian/tzdata@2026b-0%2Bdeb13u1?arch=all&distro=debian-13.5",
      "dependsOn": []
    },
    {
      "ref": "pkg:golang/quicknotes",
      "dependsOn": [
        "pkg:golang/stdlib@v1.24.5"
      ]
    },
    {
      "ref": "pkg:golang/stdlib@v1.24.5",
      "dependsOn": []
    },
    {
      "ref": "pkg:oci/quicknotes@sha256:7cb3a02c11cf2ff470db3d1a9424b5b504d22a78cf0a33e541054e06c0c383b3?arch=amd64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "dependsOn": [
        "ac18a7de-caad-4e7b-8f39-341e712a77fe",
        "f46773e4-a1f6-4360-8501-256ecf13d422"
      ]
    }
  ],
  "vulnerabilities": []
}
```


| vulnerability | label | reason |
|---------------|-------|--------|
| CVE-2025-68121 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2025-61726 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2025-61729 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-25679 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-27145 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-32280 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-32281 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-32283 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-33811 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-33814 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-39820 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-39836 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| CVE-2026-42499 | FALSE POSITIVE | `go run golang.org/x/vuln/cmd/govulncheck@latest ./...` showed `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, therefore I assume that no vulnerable functions were executed |
| HIGH: AsymmetricPrivateKey (private-key) | FALSE POSITIVE | 1. .vagrant folder is totaly local. It is included in .gitignore. Therefore, this key is not exposed. 2. Every `vagrant up` will re-generate this key, so even if it is exposed, next `vagrant up` will fix it (if not already) |

- a. Severity is just the starting point. Reachability (does my code even call the vulnerable function?) is the real filter. Exploit availability (PoC, wormable?) and deployment context (internet-facing vs internal, network isolation) also should be kept in mind before making any desicion
- b. Distroless strips out OS package managers, shells, and tools. Therefore, there’s literally nothing to patch except your own app. No bash, no apt, no curl, no attack surface for dependency confusion or misconfigured package repos. It forces you to ship only what you compiled, making vulnerabilities in the base image a non-issue.
- c. `.trivyignore` is the right move for false positives or local dev artifacts (like the Vagrant key) that never touch prod—saves noise. It becomes security theater when you silence real findings without understanding them, just to pass a CI check. If you can’t justify it, you’re just hiding the problem.
- d. SBOM today means when the next Log4Shell drops, you can instantly `grep` your SBOM for that library across every image and service, instead of manually checking each Dockerfile or trusting memory. It turns an emergency fire drill into a 5-minute query, and you know exactly which versions need upgrading.

### Task 2

I run zap via `docker run --rm --network host -v "$(pwd)/submissions:/zap/wrk" ghcr.io/zaproxy/zaproxy:2.16.1 zap-baseline.py -t http://localhost:8080 -r zap-baseline-before.html -J zap-baseline-before.json`


| Alert ID | Finding Name | Risk Level | Affected URL / Parameter	| Disposition	| Reasoning / Mitigation Strategy |
-------------------------------------------------------------------------------------------------------------------
| 10116 |	ZAP is Out of Date | Low | http://localhost:8080 | SUPPRESS | It just says that I'm using old zap version. I'll rerun with newer one |
| 10049 | Storable and Cacheable Content | Informational | http://localhost:8080, http://localhost:8080/robots.txt, http://localhost:8080/sitemap.xml |  SUPPRESS | Changing dynamic endpoints may cause data leackage. Added `SecurityHeaders` func to headers.go |

#### How patched:


In  `handlers.go`:
```
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Cross-Origin-Resource-Policy", "same-origin")
		w.Header().Set("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
		w.Header().Set("Pragma", "no-cache")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")

		next.ServeHTTP(w, r)
	})
}

func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.wrap(s.handleHealth))
	mux.HandleFunc("GET /metrics", s.wrap(s.handleMetrics))
	mux.HandleFunc("GET /notes", s.wrap(s.handleListNotes))
	mux.HandleFunc("POST /notes", s.wrap(s.handleCreateNote))
	mux.HandleFunc("GET /notes/{id}", s.wrap(s.handleGetNote))
	mux.HandleFunc("DELETE /notes/{id}", s.wrap(s.handleDeleteNote))
	return SecurityHeaders(mux)
}
```

Zap scans:

[before](./artifacts%20lab%209/zap-baseline-before.html)

[after](./artifacts%20lab%209/zap-baseline-after.html)

- e. It's faster, easier and more reliable. You do not violate DRY principlr. You  apply it to every handler and not afraid to forget one
- f. On a regular website, it would block all scripts, styles, and images, turning the page into a blank spot, but for a JSON API, it's ideal, since the API only returns raw data and shouldn't execute any front-end code.
- g. By disabling alerts indiscriminately, you risk accidentally silencing a critical vulnerability (for example, caching a personal account instead of a public file) and turning security into a dangerous illusion.