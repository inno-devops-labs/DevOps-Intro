# Lab 9 — Introduction to DevSecOps Tools

## Task 1 — Web Application Scanning with OWASP ZAP

### Scan Summary

- **Target:** `http://localhost:3000` (OWASP Juice Shop)
- **Tool:** OWASP ZAP Baseline Scan (`ghcr.io/zaproxy/zaproxy:stable`)
- **Total URLs scanned:** 123
- **WARN-NEW (vulnerabilities found):** 6
- **FAIL-NEW:** 0
- **PASS:** 60

---

### ZAP Report — Screenshot
![alt text](<Снимок экрана 2026-04-03 в 18.52.28.png>)
![alt text](<Снимок экрана 2026-04-03 в 19.00.52.png>)
![alt text](<Снимок экрана 2026-04-03 в 19.01.33.png>)
![alt text](<Снимок экрана 2026-04-03 в 19.01.38.png>)



---

### Number of Medium Risk Vulnerabilities Found

**6 Medium risk vulnerabilities** were identified during the ZAP baseline scan:

| # | Vulnerability | Alert ID | Count |
|---|---|---|---|
| 1 | Content Security Policy (CSP) Header Not Set | 10038 | 11 |
| 2 | Deprecated Feature Policy Header Set | 10063 | 11 |
| 3 | Timestamp Disclosure - Unix | 10096 | 16 |
| 4 | Cross-Domain Misconfiguration | 10098 | 11 |
| 5 | Dangerous JS Functions | 10110 | 2 |
| 6 | Cross-Origin-Embedder-Policy Header Missing or Invalid | 90004 | 10 |

---

### Two Most Interesting Vulnerabilities

#### 1. Content Security Policy (CSP) Header Not Set — Medium Risk

**Description:**
Content Security Policy is an HTTP response header that allows a website to control which resources the browser is permitted to load. Juice Shop does not set this header, meaning the browser has no policy to restrict script execution, style loading, or iframe embedding. This significantly increases the attack surface for Cross-Site Scripting (XSS) attacks — if an attacker manages to inject malicious JavaScript into the page, the browser will execute it without restriction.

**Why it matters:**
Without CSP, even a minor XSS vulnerability can escalate to full session hijacking, credential theft, or malicious redirects. CSP acts as a critical second line of defence after input validation.

**Evidence from scan:**
- URL: `http://host.docker.internal:3000/` (200 OK)
- Method: GET
- Found on 11 URLs across the application

---

#### 2. Cross-Domain Misconfiguration — Medium Risk

**Description:**
The application sets permissive Cross-Origin Resource Sharing (CORS) headers, allowing any external domain to make cross-origin requests to the API. Specifically, the `Access-Control-Allow-Origin` header is set too broadly, which means a malicious third-party website could send authenticated requests to the Juice Shop API on behalf of a logged-in user.

**Why it matters:**
A misconfigured CORS policy can expose sensitive user data and API endpoints to unauthorized external origins. Combined with a social engineering attack, this could allow an attacker to silently extract user information or perform actions on behalf of victims.

**Evidence from scan:**
- Found on 11 URLs including `/`, `/robots.txt`, `/assets/public/favicon_js.ico`

---

### Security Headers Status

| Header | Status | Why It Matters |
|---|---|---|
| `Content-Security-Policy` | ❌ Missing | Prevents XSS by whitelisting allowed content sources (scripts, styles, frames) |
| `Cross-Origin-Embedder-Policy` | ❌ Missing | Prevents loading cross-origin resources without explicit permission |
| `Feature-Policy` (deprecated) | ⚠️ Deprecated version set | Old syntax used instead of modern `Permissions-Policy` |
| `Strict-Transport-Security` | ✅ Pass | Forces HTTPS connections, prevents downgrade attacks |
| `X-Content-Type-Options` | ✅ Pass | Prevents MIME-type sniffing |
| `X-Frame-Options` / Anti-clickjacking | ✅ Pass | Prevents embedding the site in malicious iframes |

---

### Analysis: Most Common Vulnerability Types in Web Applications

The scan results reveal that **missing or misconfigured HTTP security headers** are by far the most prevalent issue class in web applications. This is consistent with the OWASP Top 10, where Security Misconfiguration consistently ranks in the top five.

The reasons these issues are so common:
1. **Not enabled by default** — most web frameworks and servers ship without security headers configured. Developers must explicitly add them.
2. **Developer focus on functionality** — security hardening is often deferred until late in the development cycle or overlooked entirely.
3. **Headers are invisible to users** — unlike a broken UI feature, a missing security header causes no visible symptom, making it easy to miss in testing.
4. **Evolving standards** — new headers like `Cross-Origin-Embedder-Policy` are relatively recent; many teams are unaware they exist.

Beyond headers, injection-based vulnerabilities (XSS, SQL injection) remain the most impactful category. They combine high exploitability with high impact — a single XSS vector can compromise every user of an application.

---

---

## Task 2 — Container Vulnerability Scanning with Trivy

### Scan Summary

- **Tool:** Trivy (`ghcr.io/aquasecurity/trivy:latest`)
- **Target image:** `bkimminich/juice-shop`
- **Severity filter:** HIGH, CRITICAL
- **Total CRITICAL vulnerabilities:** 11
- **Total HIGH vulnerabilities:** 15

---

### Trivy Output — Screenshot

<!-- ВСТАВЬ СКРИНШОТ ТЕРМИНАЛА С TRIVY OUTPUT ЗДЕСЬ -->
<!-- Например: ![Trivy Scan Output](screenshots/trivy-output.png) -->

![alt text](<Снимок экрана 2026-04-03 в 19.04.39.png>)
![alt text](<Снимок экрана 2026-04-03 в 19.06.14.png>)
![alt text](<Снимок экрана 2026-04-03 в 19.06.50.png>)
---

### Two Vulnerable Packages with CVE IDs

| Package | CVE ID | Severity | Installed Version | Fixed Version | Description |
|---|---|---|---|---|---|
| `jsonwebtoken` | CVE-2015-9235 | CRITICAL | 0.4.0 | 4.2.2 | Verification step bypass with an altered token — an attacker can forge JWT tokens and bypass authentication entirely |
| `jsonwebtoken` | CVE-2022-23539 | HIGH | 0.4.0 | 9.0.0 | Unrestricted key type could lead to legacy keys usage — weak or legacy signing algorithms accepted, weakening token security |

---

### Most Common Vulnerability Type

The most common vulnerability category found was **outdated npm dependencies with known CVEs**, particularly in authentication and utility libraries. The `jsonwebtoken` package alone carried multiple critical issues spanning several years (2015–2022), indicating that the application's dependencies had not been updated for a long period.

This falls under the **OWASP Top 10 A06:2021 — Vulnerable and Outdated Components** category. Many vulnerabilities were also found in transitive dependencies — packages not used directly by Juice Shop, but pulled in by its direct dependencies — which are often harder to track and update.

---

### Analysis: Why Container Image Scanning Matters Before Production

Container images are composed of multiple layers: a base OS image, runtime (e.g., Node.js), and application dependencies. Each layer can harbour known vulnerabilities. Without scanning:

- **You ship vulnerabilities unknowingly.** Developers focus on application logic and rarely audit the OS packages or transitive npm dependencies bundled inside the image.
- **Attackers exploit known CVEs.** Once a vulnerability is published in the National Vulnerability Database, automated scanners probe the internet for unpatched services within hours.
- **Compliance requirements.** Standards like PCI-DSS, SOC 2, and ISO 27001 mandate vulnerability management processes. Unscanned images create audit failures.
- **Supply chain risk.** A single compromised or outdated package can affect thousands of downstream applications using that image.

Trivy catches these issues at build time — before a vulnerable image reaches production — making it a critical gate in the delivery pipeline.

---

### Reflection: Integrating Scans into a CI/CD Pipeline

Both ZAP and Trivy can be embedded directly into a GitHub Actions pipeline:

```yaml
# .github/workflows/security.yml
name: Security Scans

on: [push, pull_request]

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          severity: CRITICAL,HIGH
          exit-code: 1        # Fail the build on CRITICAL findings
          format: table

  zap-scan:
    runs-on: ubuntu-latest
    needs: trivy-scan
    steps:
      - name: Start application
        run: docker run -d -p 3000:3000 myapp:${{ github.sha }}

      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.10.0
        with:
          target: 'http://localhost:3000'
          fail_action: true   # Fail on new Medium+ findings
```

**Key principles for pipeline integration:**
- `exit-code: 1` on CRITICAL blocks deployment of critically vulnerable images — no critical CVEs reach production
- Run scans on every pull request, not just on merge to main — catch issues before they enter the codebase
- Store HTML reports as CI artifacts for the security team to review
- Maintain an allowlist for accepted false positives to reduce noise over time
- Use scheduled scans (e.g., nightly) to catch newly published CVEs against existing images