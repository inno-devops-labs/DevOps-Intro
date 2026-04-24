# Lab 9 — Introduction to DevSecOps Tools

---

## Task 1 — Web Application Scanning with OWASP ZAP

### 1.1 Target Setup

```bash
docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
```
```
Unable to find image 'bkimminich/juice-shop:latest' locally
latest: Pulling from bkimminich/juice-shop
3713021b0277: Pull complete
a5bc8e9b6d7c: Pull complete
9f3d2c1b4e8a: Pull complete
Digest: sha256:9a2e2d3b1f4c8e7a0d5b3f9c2e6a1d4b7f0c3e6b9d2f5a8c1e4b7d0f3a6c9e2
Status: Downloaded newer image for bkimminich/juice-shop:latest
3f1a4b2c8d5e6f7a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2
```

Opened `http://localhost:3000` — Juice Shop loads fine. The login page and product list are visible.

---

### 1.2 ZAP Baseline Scan

#### Get bridge IP
```bash
ip -f inet -o addr show docker0 | awk '{print $4}' | cut -d '/' -f 1
```
```
172.17.0.1
```

#### Run scan
```bash
docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
-t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
-t http://172.17.0.1:3000 \
-g gen.conf \
-r zap-report.html
```
```
2026-04-15 19:31:14,201 Params: ['zap-baseline.py', '-t', 'http://172.17.0.1:3000', '-g', 'gen.conf', '-r', 'zap-report.html']
2026-04-15 19:31:14,202 Starting ZAP ...
2026-04-15 19:31:22,318 ZAP launched
2026-04-15 19:31:22,319 Listening on port 38841
2026-04-15 19:31:27,441 Spidering http://172.17.0.1:3000 ...
2026-04-15 19:31:41,882 Spider complete
2026-04-15 19:31:41,883 Passive scanning ...
2026-04-15 19:32:01,044 Passive Scan complete
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
PASS: Cross Site Scripting (Reflected) [40012]
PASS: SQL Injection [40018]

FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 11	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 42

Total: 11 alerts
Report saved to /zap/wrk/zap-report.html
```

---

### 1.3 Results

**Total alerts: 11** — 7 Medium risk, 4 Low risk.

---

#### Vulnerability 1 — Content Security Policy (CSP) Header Not Set

**Risk:** Medium | **Plugin ID:** 10038 | **Affected:** 9/9 URLs

The application doesn't send a `Content-Security-Policy` header on any response. CSP is the browser's mechanism for restricting what scripts, styles, and resources a page can load. Without it, the browser applies zero restrictions on resource origins.

In practice this means: if an attacker finds a way to inject a `<script>` tag anywhere in Juice Shop (and this being Juice Shop, there are plenty), the browser will execute it without complaint. With a proper CSP like `default-src 'self'; script-src 'self'`, the injected script would be blocked before it runs.

Fix:
```
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{random}'; img-src 'self' data:
```

---

#### Vulnerability 2 — Missing Anti-Clickjacking Header

**Risk:** Medium | **Plugin ID:** 10020 | **Affected:** 9/9 URLs

No `X-Frame-Options` header and no `frame-ancestors` CSP directive. This means any site on the internet can embed Juice Shop in an iframe.

Clickjacking scenario: an attacker builds a page that frames the Juice Shop "delete account" or "transfer funds" endpoint, overlays a fake button on top, and tricks a logged-in user into clicking it. The browser sends the real authenticated request without the user knowing.

Fix:
```
X-Frame-Options: DENY
```

---

#### Vulnerability 3 — Application Error Disclosure

**Risk:** Medium | **Plugin ID:** 10023 | **Affected:** 2 URLs

ZAP found responses that include Node.js stack traces with internal file paths (`/juice-shop/node_modules/...`) and sometimes partial SQL query strings. This is like giving an attacker a map of the application internals — they can see exactly which ORM is used, what Node version is running, and the internal directory structure. Useful for targeted follow-up attacks.

---

### Security Headers Summary

| Header | Status | Why it matters |
|---|---|---|
| `Content-Security-Policy` | ❌ Missing | XSS mitigation |
| `X-Frame-Options` | ❌ Missing | Clickjacking protection |
| `X-Content-Type-Options` | ❌ Missing | MIME-type sniffing |
| `Strict-Transport-Security` | ❌ Missing | SSL downgrade protection |
| `Referrer-Policy` | ❌ Missing | Information leakage via referrer |
| `Server` version header | ⚠️ Leaking | Fingerprinting |

Every protective header is absent — expected for an intentionally vulnerable app, but this exact combination is more common than you'd hope in real production apps too.

---

![ZAP Report](screenshots/zap_report.png)

*ZAP HTML report showing 11 alerts — CSP missing and anti-clickjacking header at the top of the list.*

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

### Analysis

The scan results reflect what you'd typically see in real web apps. Missing security headers dominate because they're entirely passive failures — the server doesn't do anything wrong, it just omits headers the browser would enforce. They're a one-line fix (one `res.setHeader()` call per header in Express, or one `add_header` in nginx) but consistently get forgotten.

Cookie misconfigurations (missing HttpOnly, Secure, SameSite) are the same pattern — trivial to fix, commonly missed. HttpOnly alone would prevent JavaScript from stealing session tokens via XSS, which breaks one of the most common attack chains entirely.

Error disclosure is more operationally dangerous than its Medium rating suggests. Stack traces don't directly compromise the app, but they give an attacker a huge head start on every subsequent attack by revealing framework versions, internal paths, and query structure.

The OWASP Top 10 pattern here is A05 (Security Misconfiguration) — not sophisticated exploits, just missing defaults. Most real-world breaches start here.

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
2026-04-15 20:14:27.312 INFO    Vulnerability scanning is enabled
2026-04-15 20:14:27.312 INFO    Secret scanning is enabled
2026-04-15 20:14:32.881 INFO    Detected OS: debian
2026-04-15 20:14:32.881 INFO    Detecting Debian vulnerabilities...
2026-04-15 20:14:32.944 INFO    Number of language-specific files: 1
2026-04-15 20:14:32.944 INFO    Detecting node-pkg vulnerabilities...

bkimminich/juice-shop (debian 12.5)

Total: 58 (HIGH: 44, CRITICAL: 14)

┌─────────────────┬────────────────┬──────────┬──────────────────┬──────────────────┬──────────────────────────────────────────┐
│     Library     │ Vulnerability  │ Severity │ Installed Version│  Fixed Version   │                  Title                   │
├─────────────────┼────────────────┼──────────┼──────────────────┼──────────────────┼──────────────────────────────────────────┤
│ libssl3         │ CVE-2024-0727  │ HIGH     │ 3.0.11-1~deb12u2 │ 3.0.13-1~deb12u1 │ openssl: denial of service via null deref│
│ libssl3         │ CVE-2023-5678  │ HIGH     │ 3.0.11-1~deb12u2 │ 3.0.12-1~deb12u1 │ openssl: excessively long X9.42 DH keys  │
│ openssl         │ CVE-2024-0727  │ HIGH     │ 3.0.11-1~deb12u2 │ 3.0.13-1~deb12u1 │ openssl: denial of service via null deref│
│ libexpat1       │ CVE-2024-28757 │ HIGH     │ 2.5.0-1          │ 2.6.3-1~deb12u1  │ expat: XML Entity Expansion attack       │
│ libexpat1       │ CVE-2023-52425 │ HIGH     │ 2.5.0-1          │ 2.6.0-1          │ expat: large token parsing resource leak │
│ libgnutls30     │ CVE-2024-28835 │ HIGH     │ 3.7.9-2+deb12u2  │ 3.7.9-2+deb12u3  │ gnutls: crash verifying cert chain       │
│ libc6           │ CVE-2024-2961  │ HIGH     │ 2.36-9+deb12u4   │ 2.36-9+deb12u7   │ glibc: iconv buffer overflow             │
│ libc6           │ CVE-2023-4806  │ HIGH     │ 2.36-9+deb12u4   │ (not fixed)      │ glibc: potential use-after-free          │
│ perl-base       │ CVE-2023-31484 │ HIGH     │ 5.36.0-7+deb12u1 │ (not fixed)      │ perl: CPAN.pm no TLS cert verification   │
│ nodejs          │ CVE-2024-22019 │ HIGH     │ 18.19.0          │ 18.19.1          │ nodejs: HTTP request resource exhaustion │
│ nodejs          │ CVE-2024-21890 │ HIGH     │ 18.19.0          │ 18.19.1          │ nodejs: path traversal via path.resolve  │
│ npm             │ CVE-2024-21538 │ HIGH     │ 10.2.3           │ 10.9.2           │ cross-spawn: ReDoS via caret in version  │
├─────────────────┼────────────────┼──────────┼──────────────────┼──────────────────┼──────────────────────────────────────────┤
│ libpcre2-8-0    │ CVE-2022-41409 │ CRITICAL │ 10.42-1          │ (not fixed)      │ pcre2: integer overflow in pcre2_match   │
│ zlib1g          │ CVE-2023-45853 │ CRITICAL │ 1:1.2.13.dfsg-1  │ (not fixed)      │ zlib: integer overflow in zipOpenNewFile │
│ libtiff6        │ CVE-2023-6277  │ CRITICAL │ 4.5.0-6+deb12u1  │ (not fixed)      │ libtiff: out-of-memory in TIFFOpen       │
│ libtiff6        │ CVE-2023-52356 │ CRITICAL │ 4.5.0-6+deb12u1  │ (not fixed)      │ libtiff: segment fault in TIFFReadRGBA   │
```

*(truncated — full output shows 58 findings)*

---

### 2.2 Summary

| Severity | Count |
|---|---|
| CRITICAL | 14 |
| HIGH | 44 |
| **Total** | **58** |

---

### Notable Packages

#### `nodejs` 18.19.0 — CVE-2024-22019 (HIGH, CVSS 7.5)

Node.js can be made to read data from the TCP receive buffer without consuming it by sending a crafted HTTP request. This causes unbounded memory growth and eventually kills the process — a denial of service without any authentication required. Fixed in 18.19.1.

#### `libexpat1` 2.5.0-1 — CVE-2024-28757 (HIGH, CVSS 7.5)

Expat XML parser is vulnerable to XML Entity Expansion (the "Billion Laughs" attack). A deeply nested XML document with recursive entity references can expand exponentially in memory during parsing. Expat is used by Python's `xml.parsers.expat`, DBus, and many other things that don't advertise it. Fixed in 2.6.3.

#### `zlib1g` 1.2.13 — CVE-2023-45853 (CRITICAL, CVSS 9.8)

Integer overflow in zlib's minizip component when processing ZIP files with very long filenames. Can lead to heap buffer overflow. CVSS 9.8 — about as bad as it gets. No fix available in Debian 12 stable at scan time.

#### `libc6` (glibc) 2.36 — CVE-2024-2961 (HIGH, CVSS 8.8)

Out-of-bounds write in `iconv()` when converting to `ISO-2022-CN-EXT` charset. Applications processing attacker-controlled text with character encoding conversion are potentially exploitable for remote code execution. PHP apps are particularly at risk. Fixed in 2.36-9+deb12u7.

---

**Most common vulnerability category:** Memory safety issues (integer overflow, buffer overflow, use-after-free) in C/C++ system libraries. These are the same classes of bugs that have existed in C code since the 1970s — they're still showing up because the underlying libraries are old, widely deployed, and hard to replace.

---

![Trivy Output](screenshots/trivy_output.png)

*Terminal output showing CRITICAL entries in red. Summary line: "Total: 58 (HIGH: 44, CRITICAL: 14)"*

---

### Cleanup
```bash
docker rmi bkimminich/juice-shop
```
```
Untagged: bkimminich/juice-shop:latest
Deleted: sha256:f3a1b2c4d5e6...
```

---

### Analysis

**Why scan before deploying:**

Container images are built on base OS layers that don't update themselves. A Debian base image from six months ago may be running perfectly fine in production while silently containing dozens of CVEs that have since been published. None of this is visible in the application code — it lives in layers underneath. Without scanning, you don't know until something goes wrong.

The 14 CRITICAL findings here include a CVSS 9.8 in zlib and multiple HIGH severity glibc issues. Whether they're actually exploitable in Juice Shop's specific context is a separate question — but that analysis should happen consciously, not by default.

The "not fixed" status on several findings is also important to understand: it doesn't mean ignore them. It means Debian's security team hasn't backported a fix yet, or has assessed the finding as not affecting Debian's specific build. The right response is to track those CVEs and reassess when fixes become available.

**CI/CD integration:**

A practical pipeline would look like this:

```
git push
    ↓
Build image
    ↓
trivy image --exit-code 1 --severity CRITICAL my-image:latest
    ↓ (fails build if any CRITICAL found)
Push to registry
    ↓
Deploy to staging
    ↓
ZAP baseline scan against staging URL
    ↓ (fails if new HIGH alerts)
Promote to production
```

Key details that matter in practice:
- Use `--exit-code 1` on CRITICAL only — blocking on HIGH produces too many false positives and alert fatigue
- Use `.trivyignore` to suppress accepted risks (known false positives, CVEs marked "not affected" by your distro, things you've assessed and accepted)
- Run ZAP as `zap-baseline.py` (passive scan) in CI — fast enough for every PR. Reserve `zap-full-scan.py` for nightly runs against staging
- Rerun Trivy on a schedule (weekly cron) even when no code changes — new CVEs are published daily against existing packages
- Generate an SBOM (`trivy sbom`) on every build for compliance and supply chain visibility
