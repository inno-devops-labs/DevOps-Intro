# Lab 9 Submission

## Task 1
### Image Scan
```
quicknotes.tar (debian 13.5)
Total: 0 (HIGH: 0, CRITICAL: 0)
```
```
quicknotes (gobinary)
Total: 11 (HIGH: 11, CRITICAL: 0)
```

### Filesystem Scan
```
.vagrant/machines/default/virtualbox/private_key (secrets)
Total: 1 (HIGH: 1, CRITICAL: 0)
```

### Config Scan
```
2026-06-28T16:31:05Z INFO  Detected config files   num=0
```
### SBOM Generation Scan
```Plaintext
2026-06-28T16:36:39Z    INFO    "--format cyclonedx" disables security scanning.
2026-06-28T16:36:40Z    INFO    Detected OS     family="debian" version="13.5"
2026-06-28T16:36:40Z    INFO    Number of language-specific files       num=1
```

### Triage Table

| Component | Vulnerability / Secret | Severity | Disposition | Reason / Action Plan                                                                                                                                                        |
| :--- | :--- | :--- | :--- |:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `fs` | `.vagrant/.../private_key` | HIGH | **FALSE POSITIVE** | It is a default Vagrant SSH key generated for local dev VMs only. It is not deployed to production and poses no risk to the application.                                    |
| `stdlib` | `CVE-2026-25679` (net/url) | HIGH | **WATCH** | Application does not actively parse untrusted IPv6 host literals. Will upgrade Go version in the next major release cycle.                                                  |
| `stdlib` | `CVE-2026-33811` (net) | HIGH | **ACCEPT** | DoS via long CNAME response. Our app operates behind a cloud load balancer which handles DNS resolution natively. Risk is minimal.                                          |
| `stdlib` | `CVE-2026-33814` (HTTP/2) | HIGH | **WATCH** | DoS via SETTINGS_MAX_FRAME_SIZE. We terminate HTTP/2 at the reverse proxy/ingress level; the Go app only speaks HTTP/1.1 internally.                                        |
| `stdlib` | `CVE-2026-32280` (crypto/x509) | HIGH | **WATCH** | Certificate chain validation DoS. Application does not build or validate external client certs (mTLS is handled by mesh).                                                   |
| `stdlib` | *Other 7 Go CVEs* | HIGH | **ACCEPT** | All remaining `stdlib` CVEs are tied to the current Go version (v1.24.13). They will be resolved simultaneously when we bump the base image to Go 1.25.11+ in `Dockerfile`. |

### Design Questions

**a) CVE severity is one input, not the answer. What else matters when triaging?**

1. **Reachability:** our code actually calls the vulnerable function
2. **Exposure:** the vulnerable component is exposed to the public internet
3. **Exploitability:** there is a known exploit (e.g., listed in CISA KEV) being used in the wild?

**b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?**

Distroless images lack a package manager (apt/apk), utilities (curl, wget), and a shell (sh/bash). It drastically reduces the attack surface. Even if an attacker achieves Remote Code Execution (RCE) in the application, they cannot easily download payloads or spawn a reverse shell because the container has no tools to do so.

**c) `.trivyignore` lets you suppress findings. When is that the right move, and when is it security theater?**

**Right move:** When a vulnerability is properly triaged, marked as a False Positive or an Accepted Risk, and documented with an expiration date for re-evaluation.
**Security theater:** When a developer blindly ignores a finding just to make the CI pipeline "green" without understanding the vulnerability or attempting to mitigate its root cause.

**d) The SBOM is a list of components. What concrete *future* problem does having it today solve?**

Incident Response speed: when a zero-day vulnerability like Log4Shell drops, having an SBOM means you don't need to rebuild or scan hundreds of repositories.


### CycloneDX SBOM

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:05b71bca-0d1c-4c75-919a-2b155aa33097",
  "version": 1,
  "metadata": {
    "timestamp": "2026-06-28T16:36:40+00:00",
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
      "bom-ref": "2ac31a95-755f-40ea-8f6b-13509a0bc019",
      "type": "container",
      "name": "quicknotes.tar",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:187cfc6d1e3e8a40a5e64653bcd3239c140807dcf1c09e48021178705a5a6139"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:275a30dd8ce958b21daa9ad962c6fbc09f98306ee2f486b65c9075dc257b1412"
```

## Task 2

### ZAP Baseline Output

**Command run:** `zap-baseline.py -t http://host.docker.internal:8080 -r baseline.html`
ZAP spider encountered 404s on `/`, `/robots.txt`, and `/sitemap.xml` because QuickNotes is an API without a root HTML index.

**Findings summary:**
- FAIL-NEW: 0
- WARN-NEW: 2

---

## ZAP Triage Table

| ID | Name | Risk | URL | Disposition | Reason / Action Plan |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 10049 | Storable and Cacheable Content | Low | `/`, `/robots.txt`, `/sitemap.xml` | **FIX** | By default, the API responses (even 404s) lack caching directives. We will implement a global middleware to inject `Cache-Control: no-store` alongside standard security headers. |
| 10116 | ZAP is Out of Date | Informational | N/A | **ACCEPT** | We intentionally pinned the ZAP scanner to `2.16.0` to ensure deterministic, reproducible CI/CD pipeline runs. Scanner update warnings are not application vulnerabilities. |

---

## Code Fix

To resolve the cacheable content warning and proactively enforce baseline API security, I implemented a global middleware in Go.

**Middleware Code:**
```go
package main

import "net/http"

func SecurityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Fix for ZAP [10049]
        w.Header().Set("Cache-Control", "no-store")
        
        // Proactive API security headers
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("Content-Security-Policy", "default-src 'none'")
        
        next.ServeHTTP(w, r)
    })
}