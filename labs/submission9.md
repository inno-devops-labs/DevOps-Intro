# Lab 9 Submission — Introduction to DevSecOps Tools

**Student:** Diana Minnakhmetova  
**Date:** 28-03-2026  

---

## Task 1: Web Application Scanning with OWASP ZAP

### 1.1 Application Deployment

**Deployed Juice Shop container:**

```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
```

Application successfully running and accessible at `http://localhost:3000`

### 1.2 ZAP Baseline Scan Execution

**Scan command:**
```bash
dminnakhmetova@MacBook-Air-Diana-3 DevOps-Intro % docker run --rm -u zap -v $(pwd):/zap/wrk:rw
-t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py
WARN-NEW: Deprecated Feature Policy Header Set [10063] x 11
http://host.docker.internal:3000/ (200 OK)
http://host.docker.internal:3000/sitemap.xml (200 OK)
http://host.docker.internal:3000 (200 OK)
http://host.docker.internal:3000/chunk-TWZW5B45.js (200 OK)
http://host.docker.internal:3000/chunk-24EZLZ4I.js (200 OK)
WARN-NEW: Timestamp Disclosure - Unix [10096] x 9
http://host.docker.internal:3000/ (200 OK)
http://host.docker.internal:3000/ (200 OK)
http://host.docker.internal:3000/ (200 OK)
http://host.docker.internal:3000/sitemap.xml (200 OK)
http://host.docker.internal:3000 (200 OK)
WARN-NEW: Cross-Domain Misconfiguration [10098] x 11
http://host.docker.internal:3000/ (200 OK)
http://host.docker.internal:3000/robots.txt (200 OK)
http://host.docker.internal:3000 (200 OK)
http://host.docker.internal:3000/sitemap.xml (200 OK)
http://host.docker.internal:3000/chunk-TWZW5B45.js (200 OK)
WARN-NEW: Dangerous JS Functions [10110] x 2
http://host.docker.internal:3000/chunk-LHKS7QUN.js (200 OK)
http://host.docker.internal:3000/main.js (200 OK)
WARN-NEW: Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] x 10
http://host.docker.internal:3000/ (200 OK)
http://host.docker.internal:3000/ (200 OK)
http://host.docker.internal:3000/sitemap.xml (200 OK)
http://host.docker.internal:3000/sitemap.xml (200 OK)
http://host.docker.internal:3000 (200 OK)
FAIL-NEW: 0 FAIL-INPROG: 0 WARN-NEW: 6 WARN-INPROG: 0 INFO: 0 IGNORE: 0 PASS: 60
```

**Scan Summary:**
- Total URLs scanned: 123
- Scan duration: ~2 minutes
- Report generated: `zap-report.html` (91.3 KB)

### 1.3 Vulnerabilities Identified

**Overall Risk Summary:**
- High Risk: 0
- Medium Risk: 2
- Low Risk: 5
- Informational: 3
- False Positives: 0

#### Most Interesting Vulnerabilities Found

**Vulnerability 1: Content Security Policy (CSP) Header Not Set**
- Risk Level: MEDIUM
- Instances: Systemic (affects multiple endpoints)
- Description: The web application does not send a Content-Security-Policy HTTP response header. CSP is a critical security mechanism that helps prevent Cross-Site Scripting (XSS), clickjacking, and data injection attacks by declaring approved sources of content.
- Affected URLs: http://host.docker.internal:3000, http://host.docker.internal:3000/, http://host.docker.internal:3000/ftp, http://host.docker.internal:3000/sitemap.xml
- Impact: Without CSP, attackers could inject malicious JavaScript into the application, stealing user data or performing unauthorized actions.
- Remediation: Configure the web server to set Content-Security-Policy header (e.g., `Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'`)

**Vulnerability 2: Cross-Domain Misconfiguration (CORS)**
- Risk Level: MEDIUM
- Instances: Systemic
- Evidence: `Access-Control-Allow-Origin: *`
- Description: The server is configured to allow Cross-Origin Resource Sharing (CORS) from any origin. While this enables cross-domain requests, it can expose sensitive data if combined with unauthenticated APIs or IP-based access controls.
- Affected URLs: Multiple endpoints including root, chunk files, robots.txt, sitemap.xml
- Impact: Any third-party website could access data from this application by making cross-origin requests. While modern browsers restrict reading authenticated responses, this still poses a risk for public or sensitive information.
- Remediation: Restrict `Access-Control-Allow-Origin` to specific trusted domains (e.g., `Access-Control-Allow-Origin: https://trusted-domain.com`)

### 1.4 Security Headers Analysis

**Present Headers:**
- Cache-Control headers with `max-age=0` (prevents aggressive caching)
- Feature-Policy header (though deprecated, provides some protection)

**Missing Headers (Impact Analysis):**

| Header | Purpose | Impact if Missing |
|--------|---------|-------------------|
| Content-Security-Policy | Prevent XSS attacks | High - allows script injection |
| X-Frame-Options | Prevent clickjacking | Medium - allows embedding in iframes |
| X-Content-Type-Options | Prevent MIME sniffing | Medium - browser may misinterpret file types |
| Strict-Transport-Security | Enforce HTTPS | Medium - enables downgrade attacks |
| Cross-Origin-Embedder-Policy | Isolate page context | Low - modern security feature |
| Cross-Origin-Opener-Policy | Prevent window attacks | Low - mitigates cross-window exploits |

### 1.5 Common Web Vulnerabilities Analysis

The vulnerabilities discovered in this scan align with the OWASP Top 10:

1. **Broken Access Control & Misconfiguration** - The permissive CORS policy without proper authentication checks falls into this category.

2. **Injection & XSS Prevention** - Lack of CSP header leaves the application vulnerable to XSS attacks, one of the most common web vulnerabilities.

3. **Information Disclosure** - Timestamp disclosure and exposed error messages reveal application details that could aid attackers.

4. **Design Flaws** - The application uses deprecated security headers instead of modern alternatives, indicating outdated security practices.

Most web applications share similar vulnerability patterns because they often:
- Use frameworks with default insecure configurations
- Forget to implement security headers
- Prioritize functionality over security in early development
- Fail to update dependencies with security patches

### 1.6 Evidence: ZAP Report Screenshots

![ZAP Report Overview - Summary of Alerts](https://github.com/user-attachments/assets/083dbfca-326a-448a-9e6d-7ddab64ccfb3)

![ZAP Report - Alert Details](https://github.com/user-attachments/assets/88a8b78e-09d7-4ca4-8322-9db695a232c8)
![ZAP Report - Alert Details](https://github.com/user-attachments/assets/d32f17bb-d78b-4e57-b9bb-9496ac622334)

### 1.7 Cleanup

```bash
docker stop juice-shop && docker rm juice-shop
# Output:
# juice-shop
# juice-shop
```

---

## Task 2: Container Vulnerability Scanning with Trivy

### 2.1 Trivy Scan Execution

**Scan command:**
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
ghcr.io/aquasecurity/trivy:latest image \
--severity HIGH,CRITICAL \
bkimminich/juice-shop
```

### 2.2 Vulnerability Summary

**Total Vulnerabilities Found: 52**
- CRITICAL: 9
- HIGH: 43

**Additional Findings:**
- Secrets discovered: 2 (private RSA keys embedded in code)
- Node.js packages affected: Multiple core dependencies

### 2.3 Critical Packages and CVEs

**Package 1: crypto-js (version 3.3.0)**
- CVE ID: CVE-2023-46233
- Severity: CRITICAL
- Vulnerability Type: Weak Cryptographic Implementation
- Description: The PBKDF2 implementation in crypto-js uses only 1 iteration instead of the recommended 1,000+ iterations. This makes password hashing approximately 1,000 times weaker than specified, allowing attackers to crack passwords much faster.
- Fixed Version: 4.2.0
- Impact: High - Compromises the security of all hashed passwords in the application

**Package 2: jsonwebtoken (version 0.1.0 & 0.4.0)**
- CVE ID: CVE-2015-9235
- Severity: CRITICAL
- Vulnerability Type: Authentication Bypass / Verification Bypass
- Description: The jsonwebtoken library fails to properly verify JWT signatures in certain cases. Attackers can forge authentication tokens by sending an altered token that passes validation checks, allowing them to impersonate any user.
- Fixed Version: 4.2.2 or higher
- Impact: Critical - Complete authentication bypass allowing unauthorized access

**Package 3: vm2 (version 3.9.17)**
- CVE ID: CVE-2023-32314
- Severity: CRITICAL
- Vulnerability Type: Sandbox Escape / Remote Code Execution
- Description: The vm2 library (JavaScript sandbox environment) contains a vulnerability that allows attackers to escape the sandbox and execute arbitrary code with the privileges of the Node.js process. This completely defeats the purpose of the sandbox.
- Fixed Version: 3.9.18 or higher
- Impact: Critical - Complete system compromise possible

**Package 4: lodash (version 2.4.2)**
- CVE ID: CVE-2019-10744
- Severity: CRITICAL
- Vulnerability Type: Prototype Pollution
- Description: The `defaultsDeep` function in lodash allows prototype pollution attacks. Attackers can inject properties into Object.prototype, potentially affecting all objects in the application.
- Fixed Version: 4.17.12 or higher
- Impact: Critical - Can lead to code injection and privilege escalation

**Package 5: marsdb (version 0.6.11)**
- CVE ID: GHSA-5mrr-rgp6-x4gr
- Severity: CRITICAL
- Vulnerability Type: Command Injection
- Description: The marsdb library does not properly sanitize user input in database query operations, allowing attackers to inject arbitrary commands.
- Fixed Version: No patch available (library abandoned)
- Impact: Critical - Remote code execution possible

### 2.4 Most Common Vulnerability Type

**Primary Category: Authentication & Authorization Bypass (30% of findings)**

The most prevalent vulnerability type is related to weak or bypassable authentication mechanisms:
- JWT token verification bypass (jsonwebtoken, jws)
- Weak password hashing (crypto-js)
- Legacy key type acceptance vulnerabilities

**Secondary Category: Prototype Pollution & Code Injection (25% of findings)**

Multiple packages (lodash, marsdb, multer) suffer from injection vulnerabilities where attacker-controlled input can modify object prototypes or execute unintended code.

**Tertiary Category: Denial of Service (DoS) (20% of findings)**

Regular expression-based DoS vulnerabilities (ReDoS) and unbounded resource consumption issues in packages like minimatch, moment, and http-cache-semantics.

### 2.5 Additional Finding: Hardcoded Secrets

**Location:** `/juice-shop/lib/insecurity.ts:23` and `/juice-shop/build/lib/insecurity.js:47`

**Finding:** Private RSA encryption keys are embedded directly in the application code and Docker image.

**Risk:** HIGH - Private keys should never be stored in version control or container images. This represents a critical security breach that could compromise all encrypted communications.

**Best Practice:** Use secrets management systems (HashiCorp Vault, AWS Secrets Manager, Kubernetes Secrets) to handle sensitive credentials.

### 2.6 Why Container Scanning is Critical Before Production Deployment

1. **Early Detection Window:** Identifying vulnerabilities at the image level, before deployment, prevents vulnerable code from reaching production systems where attackers can target it.

2. **Compliance & Governance:** Many security standards (ISO 27001, PCI DSS, HIPAA, SOC 2) require vulnerability scanning as part of the deployment process. Compliance failures can result in legal and financial penalties.

3. **Attack Surface Reduction:** Understanding what vulnerabilities exist allows teams to either patch them, apply compensating controls, or make informed risk decisions.

4. **Supply Chain Security:** Container images often come from third-party sources. Scanning ensures that base images and dependencies don't introduce known vulnerabilities into your systems.

5. **Cost Prevention:** Fixing vulnerabilities during development costs 10-100x less than responding to a breach in production.

6. **Zero-Day Preparedness:** Regular scanning creates a baseline for comparison, helping detect newly disclosed vulnerabilities quickly.

### 2.7 CI/CD Pipeline Integration Strategy

**Proposed Security Scanning Pipeline:**

```
Source Code Commit
    ↓
[1] Dependency Check (scan package.json)
    - Tools: npm audit, Snyk
    - Action: Block merge if CRITICAL found
    ↓
[2] Image Build
    ↓
[3] Container Image Scanning (Trivy)
    - Severity: CRITICAL, HIGH
    - Action: Block deployment if findings exceeds threshold
    ↓
[4] Runtime Security Policies
    - Network policies
    - Pod security standards
    ↓
[5] Continuous Monitoring
    - Registry scanning (scheduled, e.g., daily)
    - Alert on new CVE discoveries
```

**Implementation Example:**

```yaml
# In CI/CD Pipeline (GitHub Actions / GitLab CI)
security-scan:
  stage: test
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
    - trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:$CI_COMMIT_SHA
  allow_failure: false  # Block pipeline on vulnerable images
```

**Key Integration Points:**

- Run scans on every commit, not just releases
- Fail builds on CRITICAL vulnerabilities
- Generate reports for security team review
- Maintain vulnerability baseline and track trends
- Set up alerts for newly disclosed CVEs affecting deployed images
- Implement automated patching for non-breaking updates

### 2.8 Evidence: Trivy Scan Output

![Trivy Results - Summary](https://github.com/user-attachments/assets/a279bf67-ce18-4ea3-ae9a-c8e7b73ba396)

![Trivy Results - Detailed Findings](https://github.com/user-attachments/assets/264b7389-8402-48a3-b0bd-07f311f18c08)

![Trivy Results - Detailed Findings](https://github.com/user-attachments/assets/3b9307b5-e39c-4a4f-a122-32cec016cf47)

---

## Key Learnings & Reflections

### What I Learned

1. **DevSecOps is not a separate step** - Security scanning must be integrated into every stage of the development pipeline, not added as an afterthought.

2. **Dependency vulnerabilities are pervasive** - A simple Node.js application can have dozens of critical vulnerabilities inherited from third-party packages.

3. **Security headers matter** - A single missing header can open attack vectors that compromise the entire application.

4. **Automation is essential** - Manual security reviews don't scale. Tools like ZAP and Trivy enable catching vulnerabilities at scale.

5. **Container image attacks are real** - Hardcoded secrets and vulnerable base images are surprisingly common in production deployments.

### Most Useful Tools & Why

**OWASP ZAP** was particularly valuable for:
- Automated detection of web-specific vulnerabilities
- Clear, actionable remediation guidance
- Visual HTML reports that stakeholders can understand

**Trivy** excelled at:
- Comprehensive vulnerability database (updated regularly)
- Fast scanning performance
- Detailed CVE information and severity scoring

### Recommendations for Future Work

1. Implement the proposed CI/CD scanning pipeline immediately
2. Update vulnerable dependencies to patched versions
3. Implement all missing security headers
4. Move hardcoded secrets to a secrets management system
5. Set up automated daily image scanning in the container registry
6. Create a vulnerability remediation policy with timelines based on severity
