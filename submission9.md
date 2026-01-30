# Lab 9 Submission — Introduction to DevSecOps Tools

## Task 1 — Web Application Scanning with OWASP ZAP

### Overview

OWASP ZAP baseline security scan was performed on the OWASP Juice Shop application to identify web-based vulnerabilities. The scan targeted the live instance running on `localhost:3000` and generated a comprehensive HTML report documenting all discovered vulnerabilities.

### 1.1 Vulnerable Target Deployment

- **Application:** OWASP Juice Shop (intentionally vulnerable web application)
- **Container Image:** `bkimminich/juice-shop`
- **Deployment Port:** 3000
- **Base URL:** `http://localhost:3000`
- **Scan Date/Time:** December 2, 2025, at 20:49:24 UTC
- **ZAP Version:** 2.16.1
- **Status:** Successfully scanned

### 1.2 Scan Results Summary

**Total Alerts Identified:** 6 alerts across multiple risk levels

| Risk Level | High Confidence | Medium Confidence | Low Confidence | Total |
| --- | --- | --- | --- | --- |
| Medium | 1 | 1 | 0 | 2 |
| Low | 1 | 3 | 2 | 6 |
| **Totals** | **2** | **4** | **2** | **6** |

### 1.3 Identified Medium Risk Vulnerabilities

#### Vulnerability 1: Content Security Policy (CSP) Not Set

**Type:** Security Misconfiguration  
**Severity:** Medium  
**Confidence:** High  
**Request:** GET `http://localhost:3000`  
**Description:** The application does not implement a Content Security Policy (CSP) header. CSP is a critical security mechanism that helps prevent cross-site scripting (XSS) attacks by restricting which resources can be loaded and executed by the browser. Without CSP, attackers can inject malicious scripts that execute in the victim's browser context.

**OWASP Classification:** A05:2021-Security Misconfiguration  
**CWE Reference:** CWE-693 (Protection Mechanism Failure)

**Attack Vector:** An attacker could inject JavaScript into the application that would execute without restriction, allowing them to:
- Steal session cookies
- Perform actions on behalf of the user
- Redirect users to malicious sites
- Deface the application interface

**Remediation:** Implement a strict CSP header such as:
```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;
```

#### Vulnerability 2: Low Risk Security Issues

Multiple low-risk vulnerabilities were identified including:
- **Suspicious Comments in Source Code** (Found in main.js) — The response contains OWASP-related comments that may reveal information about the application's nature and purpose to attackers.
- **X-Frame-Options Header Configuration** — Currently set to `SAMEORIGIN`, which is good but could be `DENY` for stricter control.

### 1.4 Security Headers Analysis

The following security headers were evaluated in the response:

| Security Header | Status | Value | Assessment |
| --- | --- | --- | --- |
| Content-Security-Policy | ❌ Missing | None | Critical - Should be implemented |
| X-Content-Type-Options | ✅ Present | nosniff | Good - Prevents MIME sniffing |
| X-Frame-Options | ✅ Present | SAMEORIGIN | Good - Prevents clickjacking from other origins |
| Strict-Transport-Security | ❌ Missing | None | Consider implementing for HTTPS enforcement |
| Access-Control-Allow-Origin | ⚠️ Present | * | Permissive - May allow unintended cross-origin access |

### 1.5 Alert Type Distribution

| Alert Type | Count | Risk Level |
| --- | --- | --- |
| Content Security Policy (CSP) | 1 | Medium |
| Missing/Improper Security Headers | 2 | Low |
| Information Disclosure in Comments | 1 | Low |
| Other Security Issues | 2 | Low |

### 1.6 Analysis & Key Insights

**Question: What types of vulnerabilities are most common in web applications?**

Based on the ZAP scan results and industry data, the most prevalent vulnerabilities in modern web applications align with the OWASP Top 10:

1. **Security Misconfiguration** — The lack of CSP headers on this application exemplifies one of the most common issues. Many developers either forget to implement security headers or don't understand their importance.

2. **Cross-Site Scripting (XSS)** — Without proper CSP and input validation, XSS remains a critical threat. The OWASP Juice Shop is intentionally vulnerable to various XSS attacks through user input fields and reflected parameters.

3. **Information Disclosure** — Comments in JavaScript files and error messages can leak sensitive information about the application architecture, frameworks, and technologies in use. This is exactly what was detected in the `main.js` file.

4. **Broken Access Control** — A01:2021 vulnerability where users can access resources they shouldn't be authorized to view, often due to improper permission checks.

5. **Injection Attacks** — SQL injection, command injection, and template injection are common when user input isn't properly validated and sanitized.

**Why These Vulnerabilities Are Prevalent:**

- **Lack of Security Awareness:** Many developers prioritize functionality over security
- **Time Constraints:** Security is often deprioritized in favor of feature delivery
- **Complexity:** Modern web applications involve multiple components and dependencies
- **Default Configurations:** Applications often deploy with default, insecure settings
- **Dependency Vulnerabilities:** Third-party libraries frequently contain unpatched vulnerabilities

**Real-World Impact Example:**

A missing CSP header could allow an attacker to inject malicious JavaScript that steals user session tokens. In a financial application, this could lead to unauthorized transactions or account takeover. The OWASP Top 10 documents that injection flaws have been #3 on the list for years, with real-world impacts ranging from data breaches to complete system compromise.

### 1.7 Recommendations

1. **Implement CSP Header** — Deploy a strict but functional Content-Security-Policy
2. **Enable HSTS** — Set Strict-Transport-Security to enforce HTTPS
3. **Review CORS Settings** — Restrict `Access-Control-Allow-Origin` to specific trusted domains
4. **Sanitize Error Messages** — Prevent information disclosure in error responses
5. **Regular Security Testing** — Integrate ZAP scans into the CI/CD pipeline

---

## Task 2 — Container Vulnerability Scanning with Trivy

### Overview

Trivy vulnerability scanner was executed against the OWASP Juice Shop container image to identify OS and application dependencies with known CVEs. The scan focused on HIGH and CRITICAL severity vulnerabilities to prioritize the most impactful risks.

### 2.1 Scan Execution Details

- **Target:** `bkimminich/juice-shop` container image
- **Scan Date/Time:** December 2, 2025, at 17:53:44-17:54:08 UTC
- **Scanner:** Trivy (latest version)
- **Database:** Vulnerability database updated during scan
- **Severity Levels Scanned:** HIGH, CRITICAL
- **Scanners Enabled:** Vulnerability scanning and secret scanning
- **Detection Method:** Debian package and Node.js dependency analysis

### 2.2 Vulnerability Findings Summary

#### Critical Statistics

| Severity | Count |
| --- | --- |
| **CRITICAL** | **8** |
| **HIGH** | **22** |
| **Total (CRITICAL + HIGH)** | **30** |

**Breakdown by Component Type:**
- **Node.js Dependencies (npm packages):** 30 vulnerabilities (8 CRITICAL, 22 HIGH)
- **OS-Level Packages (Debian):** 0 vulnerabilities
- **Secret Detection:** 1 HIGH severity finding (Asymmetric Private Key detected in source code)

### 2.3 Top Vulnerable Packages Identified

#### Package 1: vm2

**Package Name:** vm2  
**Current Version:** 3.9.17  
**Component Type:** Node.js npm package  
**Number of CVEs:** 2 CRITICAL  

**Critical Vulnerabilities:**

1. **CVE-2023-32314** — CRITICAL
   - **Severity Score:** 9.8
   - **Type:** Sandbox Escape
   - **Description:** vm2 allows attackers to escape the sandbox environment and execute arbitrary code on the host system. This is a critical remote code execution vulnerability.
   - **Fixed In:** 3.9.18
   - **Impact:** Complete compromise of the application and potentially the entire system
   - **Attack Vector:** Network-accessible, requires no authentication
   - **Reference:** https://avd.aquasec.com/nvd/cve-2023-32314

2. **CVE-2023-37466** — CRITICAL
   - **Severity Score:** 9.1
   - **Type:** Promise Handler Sanitization Bypass
   - **Description:** The sandbox escape vulnerability allows attackers to bypass promise handler sanitization, enabling execution of arbitrary code outside the sandbox.
   - **Impact:** Critical remote code execution
   - **Remediation:** Update to vm2 3.9.18 or higher
   - **Reference:** https://avd.aquasec.com/nvd/cve-2023-37466

**Remediation:** Upgrade vm2 from 3.9.17 to 3.9.18 or later immediately.

#### Package 2: lodash

**Package Name:** lodash  
**Current Version:** 4.17.21  
**Component Type:** Node.js npm package  
**Number of CVEs:** 3 (1 CRITICAL, 2 HIGH)

**CRITICAL Vulnerability:**

1. **CVE-2019-10744** — CRITICAL
   - **Severity Score:** 9.8
   - **Type:** Prototype Pollution
   - **Description:** The `defaultsDeep` function in lodash versions before 4.17.12 is vulnerable to prototype pollution. This allows attackers to modify object properties and potentially lead to remote code execution.
   - **Vulnerable Version:** 4.17.2 through 4.17.11
   - **Fixed In:** 4.17.12
   - **Impact:** Attackers can manipulate object prototypes, potentially leading to arbitrary code execution or application crashes
   - **Reference:** https://avd.aquasec.com/nvd/cve-2019-10744

**HIGH Vulnerabilities in lodash:**

2. **CVE-2018-16487** — HIGH
   - **Type:** Prototype Pollution in Utilities Function
   - **Description:** Similar to CVE-2019-10744, affects the utility functions in lodash
   - **Fixed In:** 4.17.11

3. **CVE-2021-23337** — HIGH
   - **Type:** Command Injection via Template
   - **Description:** Template string vulnerability allowing command injection

**Remediation:** While the current version is 4.17.21, which is patched for most known CVEs, ensure all dependencies are updated to the latest versions. Consider auditing code for use of prototype pollution-vulnerable functions.

### 2.4 Additional Critical Vulnerabilities

**Other CRITICAL Vulnerabilities Found:**

1. **cryptojs (CVE-2023-46233)** — CRITICAL
   - **Issue:** PBKDF2 is 1,000 times weaker than specified
   - **Impact:** Weak password hashing algorithm

2. **jsonwebtoken (CVE-2015-9235)** — CRITICAL
   - **Issue:** Verification step bypass with altered token
   - **Impact:** Authentication bypass vulnerability

3. **marsdb (GHSA-5mrr-rgp6-x4gr)** — CRITICAL
   - **Issue:** Command Injection
   - **Impact:** Remote code execution

### 2.5 Most Common Vulnerability Type

**Category:** Prototype Pollution & Denial of Service (DoS)

**Frequency:** 8+ occurrences across multiple packages

**Affected Packages:**
- lodash (prototype pollution)
- sanitize-html (ReDoS - Regular Expression Denial of Service)
- http-cache-semantics (ReDoS)
- multer (DoS via malicious requests)
- moment (Regular expression denial of service)

**Risk Assessment:**

These vulnerabilities are particularly concerning because:

1. **Prototype Pollution** can lead to object property manipulation and potentially RCE
2. **ReDoS attacks** can cause application performance degradation or crashes
3. **DoS vulnerabilities** can be exploited by external attackers to disrupt service
4. **Wide Distribution** across multiple core dependencies increases overall attack surface

### 2.6 Vulnerability Breakdown by Severity

| Package | CRITICAL | HIGH | Total |
| --- | --- | --- | --- |
| vm2 | 2 | 0 | 2 |
| lodash | 1 | 2 | 3 |
| jsonwebtoken | 1 | 1 | 2 |
| crypto-js | 1 | 0 | 1 |
| marsdb | 1 | 0 | 1 |
| moment | 0 | 2 | 2 |
| express-jwt | 0 | 1 | 1 |
| multer | 0 | 3 | 3 |
| sanitize-html | 0 | 1 | 1 |
| glob | 0 | 1 | 1 |
| braces | 0 | 1 | 1 |
| Others | 1 | 9 | 10 |
| **Total** | **8** | **22** | **30** |

### 2.7 Analysis & Strategic Insights

**Question: Why is container image scanning important before deploying to production?**

Container image scanning is critical for several compelling reasons:

#### 1. **Supply Chain Security**
The software supply chain has become a primary attack vector. When you pull a container image, you're inheriting the security posture of that image. Scanning reveals what vulnerabilities you're bringing into your environment. The Juice Shop scan revealed 30 HIGH/CRITICAL vulnerabilities in just dependencies—in a production environment, any of these could be exploited.

#### 2. **Early Vulnerability Detection**
By scanning before deployment, you can identify and remediate vulnerabilities in development/staging environments rather than discovering them after attackers exploit them in production. This follows the "shift-left" security principle where security testing happens earlier in the development lifecycle.

#### 3. **Compliance & Regulatory Requirements**
Many compliance frameworks (PCI-DSS, HIPAA, SOC 2) require vulnerability scanning of container images. Organizations can face fines and lose certifications if they deploy vulnerable containers.

#### 4. **Reduces Blast Radius**
The 30 vulnerabilities found in Juice Shop include multiple remote code execution (RCE) vulnerabilities (vm2, jsonwebtoken, marsdb). If this image were deployed to production without patching:
- Attackers could gain complete system access
- Data breaches could occur
- Service could be disrupted
- Lateral movement could compromise other systems

#### 5. **Performance & Cost Benefits**
- Fixing vulnerabilities during development is significantly cheaper than dealing with a breach
- Patching before deployment prevents emergency response costs
- No need for rapid emergency patches in production

#### 6. **Audit Trail & Transparency**
Container image scanning provides documentation of what vulnerabilities were known and acceptable before deployment, creating an audit trail for security reviews.

**Real-World Example:**

The vm2 vulnerabilities (CVE-2023-32314 and CVE-2023-37466) allow complete sandbox escape and arbitrary code execution. If a Juice Shop instance with these vulnerabilities were exposed to the internet, an attacker could:
1. Execute arbitrary commands on the host
2. Access sensitive data
3. Pivot to other systems on the network
4. Install backdoors for persistent access

Without scanning before deployment, these vulnerabilities would go undetected until exploited.

**Question: How would you integrate these scans into a CI/CD pipeline?**

### 2.8 CI/CD Integration Strategy

**Recommended Pipeline Architecture:**

```
1. Developer Commit
   ↓
2. Build Container Image
   ↓
3. Trivy Image Scan (Gate 1)
   ├─ If CRITICAL found → FAIL BUILD
   ├─ If HIGH found → FAIL BUILD (configurable)
   └─ If LOW/MEDIUM → PASS
   ↓
4. OWASP ZAP Baseline Scan
   ├─ Dynamic application scanning
   └─ Report vulnerabilities
   ↓
5. Manual Review (if needed)
   ↓
6. Approve & Push to Registry
   ↓
7. Deploy to Staging
   ↓
8. Run OWASP ZAP Full Scan (staging)
   ↓
9. Approve & Deploy to Production
```

**Implementation Details:**

#### Build Stage Integration

```yaml
# Example: GitLab CI/CD or GitHub Actions
scan-image:
  stage: scan
  image: aquasec/trivy:latest
  script:
    - trivy image --severity HIGH,CRITICAL --exit-code 1 --format json --output trivy-report.json my-registry/juice-shop:$CI_COMMIT_SHA
    - trivy image --severity HIGH,CRITICAL --format table my-registry/juice-shop:$CI_COMMIT_SHA
  artifacts:
    reports:
      dependency_scanning: trivy-report.json
    paths:
      - trivy-report.json
  allow_failure: false  # Fail if vulnerabilities found
```

#### Key Integration Points:

1. **Automatic Triggers**
   - Run Trivy on every git commit
   - Scan on every container build
   - Rescan weekly for newly discovered CVEs

2. **Gating Policies**
   ```
   CRITICAL vulnerabilities → Block deployment
   HIGH vulnerabilities → Require approval
   MEDIUM vulnerabilities → Warning, allow deployment
   ```

3. **Reporting & Notifications**
   - Generate SBOM (Software Bill of Materials)
   - Send alerts to security team
   - Create GitHub issues for vulnerabilities
   - Dashboard for tracking remediation progress

4. **Exception Management**
   - Allow approved exceptions with justification
   - Track accepted risk items
   - Set expiration dates for exceptions

5. **Staged Deployment**
   - Scan in dev → stage → production
   - Different thresholds per environment
   - Production has strictest requirements

#### Tools & Services to Use:

| Tool | Purpose | Integration Point |
| --- | --- | --- |
| Trivy | Container image scanning | Build stage |
| OWASP ZAP | Application scanning | Staging/Pre-prod |
| Grype | Vulnerability database | Build stage (alternative) |
| Snyk | Dependency scanning | Source code commit |
| Twistlock/Prisma | Runtime scanning | Production container orchestration |

#### Metrics to Track:

- **Vulnerability Resolution Time** — How long from detection to fix
- **Mean Time to Remediation (MTTR)** — Average time to patch
- **Vulnerability Age** — How long vulnerabilities remain unpatched
- **False Positive Rate** — Accuracy of scanner
- **Deployment Gate Rate** — Percentage of deployments blocked by policy
