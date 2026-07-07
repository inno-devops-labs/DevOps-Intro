# Lab 9 — DevSecOps Security Scan Report

## Task 1 — Trivy Scan Results

## Image Scan

Command:

    trivy image quicknotes:lab6 --severity HIGH,CRITICAL

Result:

    quicknotes:lab6 (debian 13.5)

    Total: 0 (HIGH: 0, CRITICAL: 0)

Go binary scan detected:

- 11 HIGH vulnerabilities in Go stdlib
- 0 CRITICAL vulnerabilities

Disposition:

| Finding | Severity | Decision | Reason |
|---|---|---|---|
| Go stdlib vulnerabilities (CVE-2026-25679, CVE-2026-27145 and others) | HIGH | ACCEPT | The vulnerable code paths are not known to be reachable in QuickNotes. The issue requires a Go runtime update and will be re-evaluated during the next base image update. |


---

## Filesystem Scan

Command:

    trivy fs .

Result:

    .vagrant/machines/default/virtualbox/private_key

    Total: 1 (HIGH: 1, CRITICAL: 0)

Finding:

| Finding | Severity | Decision | Reason |
|---|---|---|---|
| Local Vagrant private key file | HIGH | FALSE POSITIVE | The file is generated locally by Vagrant, excluded by .gitignore, and is not tracked by Git. It is not included in the repository or image. |


---

## Config Scan

Command:

    trivy config .

Result:

    AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile

Finding:

| Finding | Severity | Decision | Reason |
|---|---|---|---|
| Dockerfile missing HEALTHCHECK | LOW | ACCEPT | QuickNotes uses a distroless image without shell utilities. Runtime health checking is implemented in docker compose instead. |


---

## SBOM

Generated using:

    trivy image --format cyclonedx --output reports/sbom.json quicknotes:lab6

First lines:

    {
      "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
      "bomFormat": "CycloneDX",
      "specVersion": "1.6",
      "serialNumber": "urn:uuid:9b1645e1-761e-4d40-99e6-85f54b643a2e",
      "version": 1
    }


---

# Design Questions

## a) CVE severity is one input, not the answer. What else matters when triaging?

CVE severity alone does not show the real risk. We should consider:

- whether the vulnerable code path is reachable;
- whether the application uses the affected functionality;
- whether an exploit exists publicly;
- deployment context and exposure;
- possible impact on confidentiality, integrity, and availability.

A HIGH CVE that cannot be reached by the application may have lower priority than a MEDIUM vulnerability exposed to the internet.


## b) Why are distroless images a strong security control?

Distroless images contain only the application and required runtime libraries. They do not include a shell, package manager, or unnecessary utilities.

This reduces the attack surface because:

- there are fewer packages that can contain vulnerabilities;
- attackers have fewer tools available after compromise;
- the image is smaller and easier to audit.


## c) When is .trivyignore correct and when is it security theater?

.trivyignore is appropriate when:

- the finding is understood;
- there is a documented reason;
- the risk is accepted temporarily;
- there is a review date.

It becomes security theater when developers ignore findings without investigation just to make the scan pass.


## d) What future problem does an SBOM solve?

An SBOM provides an inventory of all software components inside an artifact.

When a new vulnerability appears, such as Log4Shell, the SBOM allows teams to quickly answer:

"Are we using this vulnerable component?"

Without an SBOM, teams must manually search every application and dependency.