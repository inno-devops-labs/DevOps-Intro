# Lab 9 Submission — DevSecOps Tools: Security Scanning

**Student:** Rodion Krainov

**Email:** [r.krainov@innopolis.university](mailto:r.krainov@innopolis.university)

**GitHub:** r3based

## Task 1 — Web Application Scanning with OWASP ZAP

### Scan Summary

* **Target:** `http://localhost:3000` (OWASP Juice Shop)
* **Tool:** OWASP ZAP Baseline Scan
* **Scan type:** Baseline web application scan

---

### Number of Medium Risk Vulnerabilities Found

The ZAP scan identified **6 medium-risk vulnerability categories**.

| # | Vulnerability                                          | Alert ID | Count |
| - | ------------------------------------------------------ | -------- | ----- |
| 1 | Content Security Policy (CSP) Header Not Set           | 10038    | 11    |
| 2 | Deprecated Feature Policy Header Set                   | 10063    | 11    |
| 3 | Timestamp Disclosure - Unix                            | 10096    | 16    |
| 4 | Cross-Domain Misconfiguration                          | 10098    | 11    |
| 5 | Dangerous JS Functions                                 | 10110    | 2     |
| 6 | Cross-Origin-Embedder-Policy Header Missing or Invalid | 90004    | 10    |

---

### Two Most Noteworthy Vulnerabilities

#### 1. Content Security Policy (CSP) Header Not Set — Medium

The application does not return a `Content-Security-Policy` header. Without CSP, the browser has no strict policy describing which scripts, styles, frames, or other resources are trusted. This increases the attack surface for Cross-Site Scripting (XSS) and related injection attacks because malicious content can be executed more easily if any injection point exists.

**Why it matters:**
CSP is an important defence-in-depth control. Even if an application has an XSS flaw, a properly configured CSP can reduce the impact by preventing execution of untrusted scripts.

**Evidence:**
The issue was reported on multiple URLs, including the application root.

---

#### 2. Cross-Domain Misconfiguration — Medium

The application exposes an overly permissive CORS configuration. In practice, this means external origins may be allowed to access responses that should ideally be restricted to trusted sites only.

**Why it matters:**
If sensitive endpoints are exposed through permissive CORS rules, a malicious third-party site may be able to read data through the victim’s browser session. This weakens the browser same-origin security model and can lead to unauthorized data exposure.

**Evidence:**
The alert appeared on multiple endpoints, including `/` and static resources.

---

### Security Headers Assessment

| Header                                  | Status                              | Significance                                                                    |
| --------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------- |
| `Content-Security-Policy`               | Missing                             | Increases exposure to XSS and untrusted content execution                       |
| `Cross-Origin-Embedder-Policy`          | Missing or invalid                  | Weakens cross-origin isolation protections                                      |
| `Cross-Origin-Opener-Policy`            | Missing                             | Reduces browsing-context isolation and can increase cross-window attack surface |
| `Feature-Policy` / `Permissions-Policy` | Deprecated/incorrect usage observed | Indicates incomplete or outdated browser security hardening                     |
| `Access-Control-Allow-Origin`           | Overly permissive                   | May allow unintended cross-origin access                                        |
| `Strict-Transport-Security`             | Present                             | Helps enforce HTTPS usage                                                       |
| `X-Content-Type-Options`                | Present                             | Helps prevent MIME-sniffing attacks                                             |
| `X-Frame-Options`                       | Present                             | Helps protect against clickjacking                                              |

---

### Analysis — Most Prevalent Web Vulnerability Categories

The most visible issue class in the ZAP results was **security misconfiguration**, especially missing or weak HTTP security headers. This is one of the most common real-world web security problems because frameworks often do not enable secure defaults automatically, and teams tend to focus first on functionality rather than hardening.

Other highly prevalent categories in web applications are:

* **Injection vulnerabilities** such as XSS and SQL injection
* **Broken access control**
* **Vulnerable and outdated components**
* **Insecure cross-origin configuration**

In this scan, the dominant pattern was clearly misconfiguration rather than direct exploit-ready injection findings. That still matters because weak configuration lowers the security baseline and makes future exploitation easier if another flaw appears.

---

## Task 2 — Container Vulnerability Scanning with Trivy

### Scan Summary

* **Tool:** Trivy
* **Target image:** `bkimminich/juice-shop`
* **Severity filter:** `HIGH,CRITICAL`

---

### Vulnerability Totals

| Severity  |  Count |
| --------- | -----: |
| CRITICAL  |     11 |
| HIGH      |     15 |
| **Total** | **26** |

These results show that the container image includes a substantial number of severe known vulnerabilities and should not be considered production-ready without remediation or risk acceptance.

---

### Two Vulnerable Packages with CVE IDs

| Package        | CVE ID         | Severity | Installed Version | Fixed Version | Description                                                               |
| -------------- | -------------- | -------- | ----------------- | ------------- | ------------------------------------------------------------------------- |
| `jsonwebtoken` | CVE-2015-9235  | CRITICAL | 0.4.0             | 4.2.2         | Verification bypass can allow forged JWT tokens and broken authentication |
| `jsonwebtoken` | CVE-2022-23539 | HIGH     | 0.4.0             | 9.0.0         | Weak key handling and legacy behavior reduce token security guarantees    |

These findings are especially important because they affect an authentication-related library. Vulnerabilities in token validation logic can have direct security impact, including authentication bypass and privilege abuse.

---

### Most Frequently Observed Vulnerability Type

The most common vulnerability pattern was **outdated third-party dependencies with known CVEs**, especially in npm packages. This maps directly to **OWASP Top 10 A06:2021 — Vulnerable and Outdated Components**.

A large part of the risk in container images does not come only from the application code itself, but from:

* direct dependencies,
* transitive dependencies,
* runtime packages,
* base image components.

This is why container scanning is an important part of supply chain security.

---

### Analysis — Why Container Image Scanning Matters Before Production

Container images bundle the full runtime environment: operating system libraries, language runtime, application packages, and third-party dependencies. Any vulnerable component in that stack becomes part of the deployed system.

Scanning images before production is important because it provides:

* **Early detection** of known vulnerabilities before release
* **Supply chain visibility** into transitive dependencies and bundled components
* **Risk reduction** by preventing vulnerable images from reaching production
* **Compliance evidence** for secure delivery processes
* **Faster remediation** because issues are found during build time rather than during an incident

Without container scanning, teams may unknowingly deploy images with public CVEs that are already widely exploitable.

---

### Reflection — Integrating Security Scans into CI/CD

A practical DevSecOps integration strategy would include both ZAP and Trivy in the delivery pipeline:

1. **Pull request stage**
   Run scans automatically for every pull request so issues are detected before merge.

2. **Image build stage**
   Build the container image and immediately scan it with Trivy.

3. **Security gate**
   Fail the pipeline on **CRITICAL** findings, and optionally warn or require approval for **HIGH** findings.

4. **Artifact retention**
   Store scan reports as CI/CD artifacts for auditability and later review.

5. **Scheduled rescanning**
   Re-scan already built images regularly because new CVEs may appear after the original build date.

6. **False-positive management**
   Maintain an allowlist or exception process for accepted risks to keep scans actionable and reduce noise.

This approach shifts security left while also preserving continuous visibility after deployment.

---

## Final Conclusion

This lab demonstrated two important DevSecOps practices:

* **Web application scanning** with OWASP ZAP to identify security misconfiguration and browser-facing weaknesses
* **Container vulnerability scanning** with Trivy to detect severe known issues in dependencies and runtime layers

The ZAP results showed that the main web risk area was missing or weak security hardening, especially around HTTP headers and cross-origin protections.
The Trivy results showed that vulnerable and outdated dependencies remain a major supply chain risk, including critical issues in authentication-related packages.

The key takeaway is that security scanning should be integrated directly into CI/CD, not treated as a separate manual step. That makes vulnerabilities visible earlier, reduces the chance of insecure releases, and improves the overall security posture of the software delivery process.
