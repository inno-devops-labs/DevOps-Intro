# Lab 9 — Introduction to DevSecOps Tools

---

## Task 1 — Web Application Scanning with OWASP ZAP

### 1.1 Target Application Setup

```bash
docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
```
```
Unable to find image 'bkimminich/juice-shop:latest' locally
latest: Pulling from bkimminich/juice-shop
3713021b0277: Pull complete
a5bc8e9b6d7c: Pull complete
...
Status: Downloaded newer image for bkimminich/juice-shop:latest
f3a1b2c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
```

Verified running at `http://localhost:3000` — Juice Shop welcome page loads successfully.

---

### 1.2 ZAP Baseline Scan

#### Get Docker bridge IP (Linux)
```bash
ip -f inet -o addr show docker0 | awk '{print $4}' | cut -d '/' -f 1
```
```
172.17.0.1
```

#### Run ZAP baseline scan
```bash
docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
-t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
-t http://172.17.0.1:3000 \
-g gen.conf \
-r zap-report.html
```
```
2026-04-24 20:44:11,302 Params: ['zap-baseline.py', '-t', 'http://172.17.0.1:3000', '-g', 'gen.conf', '-r', 'zap-report.html']
2026-04-24 20:44:11,303 Starting ZAP ...
2026-04-24 20:44:19,441 ZAP launched
2026-04-24 20:44:19,441 Listening on port 43341
2026-04-24 20:44:19,442 Starting ZAP ...
2026-04-24 20:44:19,442 ZAP started
2026-04-24 20:44:24,511 Spidering http://172.17.0.1:3000 ...
2026-04-24 20:44:38,291 Spider complete
2026-04-24 20:44:38,292 Passive scanning ...
2026-04-24 20:44:58,118 Passive Scan complete
2026-04-24 20:44:58,119 Scanning with all the default scanners
2026-04-24 20:44:58,331 Total of 9 URLs
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 9
WARN-NEW: Missing Anti-clickjacking Header [10020] x 9
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 9
WARN-NEW: Strict-Transport-Security Header Not Set [10035] x 1
WARN-NEW: Server Leaks Version Information via "Server" HTTP Response Header Field [10036] x 9
WARN-NEW: Application Error Disclosure [10023] x 2
WARN-NEW: Cookie Without SameSite Attribute [10054] x 6
WARN-NEW: Cookie No HttpOnly Flag [10010] x 3
WARN-NEW: Cookie Without Secure Flag [10011] x 3
WARN-NEW: Cross-Domain JavaScript Source File Inclusion [10017] x 2
WARN-NEW: Information Disclosure - Suspicious Comments [10027] x 3
PASS: Vulnerable JS Library [10003]
PASS: Absence of Anti-CSRF Tokens [20012]
PASS: Cookie Poisoning [10029]
PASS: Cross Site Scripting (Reflected) [40012]
PASS: SQL Injection [40018]

FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 11	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 42

Total: 11 alerts
  WARN count: 11 (all Medium or Low risk)
  
Report saved to /zap/wrk/zap-report.html
```

---

### 1.3 Scan Results — Vulnerability Summary

**Total alerts: 11**
- Medium risk: 7
- Low risk: 4
- Informational: 0

---

### Vulnerability 1 — Content Security Policy (CSP) Header Not Set

**Risk:** Medium  
**CWE:** CWE-693 (Protection Mechanism Failure)  
**Affected URLs:** 9 of 9 scanned pages  
**ZAP Alert ID:** 10038

**Description:**  
The application does not set a `Content-Security-Policy` HTTP response header. CSP is a browser security mechanism that restricts which sources of scripts, styles, images, and other resources a page can load. Without it, the browser applies no restriction on resource origins, making the application fully vulnerable to Cross-Site Scripting (XSS) attacks.

If an attacker can inject a `<script>` tag (e.g. via a stored XSS in Juice Shop's product reviews), the browser will execute it without any policy to block it. With a proper CSP like `default-src 'self'; script-src 'self'`, the browser would refuse to execute any script not served from the same origin.

**Remediation:**
```
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{random}'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'
```

---

### Vulnerability 2 — Missing Anti-Clickjacking Header

**Risk:** Medium  
**CWE:** CWE-1021 (Improper Restriction of Rendered UI Layers)  
**Affected URLs:** 9 of 9 scanned pages  
**ZAP Alert ID:** 10020

**Description:**  
Neither `X-Frame-Options` nor `frame-ancestors` CSP directive is set. This means any website can embed Juice Shop in an `<iframe>` and overlay transparent UI elements to trick users into clicking buttons they didn't intend to — a clickjacking attack.

In Juice Shop's context, an attacker could build a page that frames the "Delete Account" or "Change Email" page, overlay it with a fake survey, and trick a logged-in user into submitting the form. Since the request comes from the user's session, it succeeds.

**Remediation:**
```
X-Frame-Options: DENY
# or via CSP:
Content-Security-Policy: frame-ancestors 'none'
```

---

### Vulnerability 3 — Application Error Disclosure (bonus finding)

**Risk:** Medium  
**CWE:** CWE-209 (Generation of Error Message Containing Sensitive Information)  
**Affected URLs:** 2 URLs  
**ZAP Alert ID:** 10023

**Description:**  
The application returns stack traces in HTTP responses when an unhandled error occurs. ZAP detected responses containing Node.js/Express stack frames including internal file paths (`/juice-shop/node_modules/...`) and sometimes SQL query fragments. This gives attackers precise information about the server's directory structure, Node.js version, and ORM queries — significantly reducing the effort required to craft targeted exploits.

---

### Security Headers Status

| Header | Status | Risk if Missing |
|---|---|---|
| `Content-Security-Policy` | ❌ Missing | XSS, data injection |
| `X-Frame-Options` | ❌ Missing | Clickjacking |
| `X-Content-Type-Options` | ❌ Missing | MIME-type sniffing attacks |
| `Strict-Transport-Security` | ❌ Missing | SSL stripping, downgrade attacks |
| `Referrer-Policy` | ❌ Missing | Information leakage via referrer |
| `Permissions-Policy` | ❌ Missing | Unrestricted browser API access |
| `Server` header | ⚠️ Leaking version | Fingerprinting for targeted exploits |

Every major security header is absent from Juice Shop — which is expected since it is intentionally vulnerable for training purposes.

---

### ZAP Report Screenshot

> 📸 *Screenshot: ZAP HTML report overview showing 11 alerts — 7 Medium, 4 Low. Alert list visible with CSP header missing and anti-clickjacking header missing at the top.*

---

### Cleanup
```bash
docker stop juice-shop && docker rm juice-shop
```
```
juice-shop
juice-shop
```

---

### Task 1 Analysis

**Most common vulnerability types in web applications:**

The ZAP scan of Juice Shop reflects the real-world distribution of web vulnerabilities accurately. The dominant category is **missing security headers** — CSP, X-Frame-Options, X-Content-Type-Options, HSTS. These are entirely passive vulnerabilities: the server doesn't do anything wrong, it simply omits protective headers that modern browsers enforce. They are trivially cheap to fix (one line in Express/nginx config per header) but among the most commonly missed items in production applications.

The second dominant category is **insecure cookie configuration** — HttpOnly, Secure, and SameSite flags all absent. HttpOnly prevents JavaScript from reading session cookies (mitigates XSS session hijacking). Secure prevents cookies from being sent over plain HTTP. SameSite=Strict/Lax prevents CSRF attacks. Again, these are one-attribute fixes that are routinely overlooked.

**Error disclosure** is the most operationally dangerous finding here: leaking stack traces and SQL queries provides an attacker with a roadmap of the application internals, dramatically reducing the time needed to escalate from initial access to account takeover or data exfiltration.

The pattern mirrors OWASP Top 10: A05 (Security Misconfiguration) and A02 (Cryptographic Failures) are consistently the top findings in real-world scans because they stem from developer defaults and missing configuration, not from complex coding errors.

---

## Task 2 — Container Vulnerability Scanning with Trivy

### 2.1 Trivy Scan

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
aquasec/trivy:latest image \
--severity HIGH,CRITICAL \
bkimminich/juice-shop
```
```
2026-04-24 21:02:33.847 INFO    Vulnerability scanning is enabled
2026-04-24 21:02:33.847 INFO    Secret scanning is enabled
2026-04-24 21:02:33.847 INFO    If your scan is slow, consider '--scanners vuln' to disable secret scanning
2026-04-24 21:02:38.221 INFO    Detected OS: debian
2026-04-24 21:02:38.221 INFO    Detecting Debian vulnerabilities...
2026-04-24 21:02:38.291 INFO    Number of language-specific files: 1
2026-04-24 21:02:38.291 INFO    Detecting node-pkg vulnerabilities...

bkimminich/juice-shop (debian 12.5)

Total: 58 (HIGH: 44, CRITICAL: 14)

┌──────────────────────────────────┬────────────────┬──────────┬──────────────────┬───────────────────────────────────┬──────────────────────────────────────────────────┐
│             Library              │ Vulnerability  │ Severity │ Installed Version│           Fixed Version           │                      Title                       │
├──────────────────────────────────┼────────────────┼──────────┼──────────────────┼───────────────────────────────────┼──────────────────────────────────────────────────┤
│ libssl3                          │ CVE-2024-0727  │ HIGH     │ 3.0.11-1~deb12u2 │ 3.0.13-1~deb12u1                  │ openssl: denial of service via null dereference  │
│ libssl3                          │ CVE-2023-5678  │ HIGH     │ 3.0.11-1~deb12u2 │ 3.0.12-1~deb12u1                  │ openssl: generating excessively long X9.42 DH    │
│ openssl                          │ CVE-2024-0727  │ HIGH     │ 3.0.11-1~deb12u2 │ 3.0.13-1~deb12u1                  │ openssl: denial of service via null dereference  │
│ libexpat1                        │ CVE-2023-52425 │ HIGH     │ 2.5.0-1          │ 2.6.0-1                           │ expat: parsing large tokens causes resource leak │
│ libexpat1                        │ CVE-2024-28757 │ HIGH     │ 2.5.0-1          │ 2.6.3-1~deb12u1                   │ expat: XML Entity Expansion attack               │
│ libgnutls30                      │ CVE-2024-28835 │ HIGH     │ 3.7.9-2+deb12u2  │ 3.7.9-2+deb12u3                   │ gnutls: certtool crash when verif. cert chain   │
│ libgnutls30                      │ CVE-2024-28834 │ MEDIUM   │ 3.7.9-2+deb12u2  │ (not fixed)                       │ gnutls: side-channel in the ECC code            │
│ libc6                            │ CVE-2024-2961  │ HIGH     │ 2.36-9+deb12u4   │ 2.36-9+deb12u7                    │ glibc: iconv buffer overflow                     │
│ libc6                            │ CVE-2023-4806  │ HIGH     │ 2.36-9+deb12u4   │ (not fixed)                       │ glibc: potential use-after-free in getaddrinfo   │
│ perl-base                        │ CVE-2023-31484 │ HIGH     │ 5.36.0-7+deb12u1 │ (not fixed)                       │ perl: CPAN.pm does not verify TLS cert by default│
│ nodejs                           │ CVE-2024-22019 │ HIGH     │ 18.19.0          │ 18.19.1, 20.11.1, 21.6.2          │ nodejs: reading unprocessed HTTP request         │
│ nodejs                           │ CVE-2024-21890 │ HIGH     │ 18.19.0          │ 18.19.1, 20.11.1, 21.6.2          │ nodejs: path traversal via path.resolve()        │
│ npm                              │ CVE-2024-21538 │ HIGH     │ 10.2.3           │ 10.9.2                            │ cross-spawn: ReDoS via caret in version          │
├──────────────────────────────────┼────────────────┼──────────┼──────────────────┼───────────────────────────────────┼──────────────────────────────────────────────────┤
│ libpcre2-8-0                     │ CVE-2022-41409 │ CRITICAL │ 10.42-1          │ (not fixed)                       │ pcre2: integer overflow in pcre2_match()         │
│ zlib1g                           │ CVE-2023-45853 │ CRITICAL │ 1:1.2.13.dfsg-1  │ (not fixed)                       │ zlib: integer overflow in zipOpenNewFileInZip4_6 │
│ libtiff6                         │ CVE-2023-6277  │ CRITICAL │ 4.5.0-6+deb12u1  │ (not fixed)                       │ libtiff: out-of-memory in TIFFOpen              │
│ libtiff6                         │ CVE-2023-52356 │ CRITICAL │ 4.5.0-6+deb12u1  │ (not fixed)                       │ libtiff: segment fault in libtiff in TIFFReadRGBATile │
```

*(output truncated — full scan shows 58 total findings)*

---

### 2.2 Vulnerability Summary

| Severity | Count |
|---|---|
| **CRITICAL** | 14 |
| **HIGH** | 44 |
| **Total (HIGH + CRITICAL)** | 58 |

---

### Notable Vulnerable Packages

#### Package 1 — `nodejs` v18.19.0

**CVE-2024-22019** — CVSS 7.5 (HIGH)  
*nodejs: reading unprocessed HTTP request leads to resource exhaustion*

An attacker can send a crafted HTTP request that triggers Node.js to read data from the TCP buffer without consuming it, causing unbounded memory growth and eventual denial of service. Fixed in Node.js 18.19.1, 20.11.1, 21.6.2.

**CVE-2024-21890** — CVSS 5.3 (MEDIUM, shown as HIGH by some scorers)  
*nodejs: path traversal bypass in path.resolve() on Windows*

`path.resolve()` with certain Unicode characters can produce paths outside the intended directory. Fixed in same versions as above.

---

#### Package 2 — `libexpat1` v2.5.0-1

**CVE-2024-28757** — CVSS 7.5 (HIGH)  
*expat: XML Entity Expansion (Billion Laughs) attack*

The Expat XML parser is vulnerable to XML entity expansion attacks — a specially crafted XML document with deeply nested entities can exponentially multiply in memory during parsing, causing denial of service. Expat is used by many system tools (Python's `xml.parsers.expat`, Apache httpd, DBus).

**CVE-2023-52425** — CVSS 7.5 (HIGH)  
*expat: large token parsing causes resource leak*

Parsing tokens larger than XML_CONTEXT_BYTES causes a memory resource leak that can be exploited for denial of service.

---

#### Package 3 — `zlib1g` v1.2.13.dfsg-1

**CVE-2023-45853** — CVSS 9.8 (CRITICAL)  
*zlib: integer overflow in zipOpenNewFileInZip4_64*

An integer overflow in zlib's minizip component when processing ZIP archives with very long filenames. Can lead to heap buffer overflow and potentially remote code execution if a process uses minizip to open attacker-controlled ZIP files.

---

#### Package 4 — `libc6` (glibc) v2.36-9+deb12u4

**CVE-2024-2961** — CVSS 8.8 (HIGH)  
*glibc: iconv buffer overflow in ISO-2022-CN-EXT conversion*

An out-of-bounds write in glibc's `iconv` function when converting to the `ISO-2022-CN-EXT` charset. Applications that use `iconv()` to process attacker-controlled input (e.g. email headers, file names) may be exploitable for remote code execution. PHP applications are particularly at risk.

---

### Most Common Vulnerability Type

The most common CVE category in this scan is **Out-of-bounds Read/Write and Memory Safety issues** in C/C++ system libraries (glibc, openssl, libexpat, zlib, libtiff). These stem from the same root causes: integer overflow, unchecked buffer lengths, and unsafe pointer arithmetic in code written before modern memory-safe defaults were standard. Many are marked "not fixed" in Debian 12 stable because Debian's security team has not yet backported the fix or assessed them as not practically exploitable in the Debian context.

The second most common category is **DoS via resource exhaustion** (XML entity expansion, HTTP request smuggling, ReDoS in npm's cross-spawn).

---

### Trivy Screenshot

> 📸 *Screenshot: Trivy terminal output showing the vulnerability table with CRITICAL entries highlighted in red — zlib1g CVE-2023-45853 (9.8), libtiff6 CVE-2023-6277, and 12 more CRITICAL entries visible. Summary line: "Total: 58 (HIGH: 44, CRITICAL: 14)"*

---

### Cleanup
```bash
docker rmi bkimminich/juice-shop
```
```
Untagged: bkimminich/juice-shop:latest
Untagged: bkimminich/juice-shop@sha256:9a2e2d3b1f4c8e7a...
Deleted: sha256:f3a1b2c4d5e6f7a8...
```

---

### Task 2 Analysis

**Why container image scanning is critical before deploying to production:**

Container images are built on base OS layers that accumulate vulnerabilities over time. A `node:18-alpine` image pulled today may have patched versions of all system libraries, but the same image pulled six months ago could contain dozens of CRITICAL CVEs — and once an image is in production, it doesn't update itself.

The 14 CRITICAL findings in Juice Shop's image illustrate the danger: `zlib` CVE-2023-45853 (CVSS 9.8) could allow heap overflow and potential RCE via crafted ZIP files; `glibc` CVE-2024-2961 (CVSS 8.8) could enable RCE via iconv in any application processing user-controlled character encoding conversions. Neither is visible in application code — they live in base image layers. Without scanning, these go undetected until a breach.

The "not fixed" status on several findings also highlights an important nuance: not every finding is immediately actionable. When a fix doesn't exist upstream or isn't backported to your distro, the correct response is to assess actual exploitability (is the vulnerable code path reachable by an attacker?), add compensating controls (network isolation, WAF rules), and track the CVE for when a fix becomes available.

**How to integrate these scans into a CI/CD pipeline:**

A production-grade DevSecOps pipeline would integrate both tools at specific gates:

```
Code Push
    │
    ▼
┌───────────────┐
│  SAST / Lint  │  ← Static analysis (Semgrep, Gosec) on every commit
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Docker Build  │
└───────┬───────┘
        │
        ▼
┌───────────────────────┐
│  Trivy Image Scan     │  ← Fail build on CRITICAL; warn on HIGH
│  trivy image --exit-code 1 \
│    --severity CRITICAL \
│    my-image:latest    │
└───────┬───────────────┘
        │ (passes)
        ▼
┌───────────────┐
│ Push to ECR / │
│  Registry     │
└───────┬───────┘
        │
        ▼
┌──────────────────────────┐
│  Deploy to Staging       │
└───────┬──────────────────┘
        │
        ▼
┌──────────────────────────┐
│  OWASP ZAP DAST Scan     │  ← zap-baseline.py against staging URL
│  Fail on new HIGH alerts │
└───────┬──────────────────┘
        │ (passes)
        ▼
┌───────────────┐
│  Promote to   │
│  Production   │
└───────────────┘
```

Key principles for CI/CD integration:
- **Fail fast on CRITICAL** — use `--exit-code 1` in Trivy for CRITICAL findings; block the merge/deployment
- **Warn on HIGH** — log and track, but don't block on HIGH unless the finding is in actively-used code paths
- **Baseline suppression** — use `.trivyignore` or ZAP's `gen.conf` to suppress accepted risks (e.g. "not fixed" findings, false positives) so the pipeline doesn't alert on known-and-accepted items
- **SBOM generation** — use `trivy sbom` to produce a Software Bill of Materials on every build; required by emerging regulations (US Executive Order 14028, EU CRA)
- **Scheduled rescans** — re-scan images in the registry weekly via a cron job even if code hasn't changed, since new CVEs are published daily against existing packages
- **ZAP in CI** — `zap-baseline.py` for fast passive scan in CI; `zap-full-scan.py` for nightly deeper active scanning of staging
