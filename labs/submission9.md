# Lab 9 — Container Security Scanning

## Task 1 — OWASP ZAP Baseline Scan

### Scan Target
- Application: OWASP Juice Shop
- URL: http://localhost:3000

### Summary of Alerts
- High: 0
- Medium: 2
- Low: 5
- Informational: 3

### Key Findings

#### 1. Content Security Policy (CSP) Header Not Set
- Risk: Medium
- Description: The application does not define a CSP header, which increases the risk of XSS attacks.
- Recommendation: Implement a strong CSP header to restrict resource loading.

#### 2. Deprecated Feature Policy Header
- Risk: Medium
- Description: Uses outdated security header.
- Recommendation: Replace with modern security headers such as Permissions-Policy.

#### 3. Cross-Domain Misconfiguration
- Risk: Low
- Description: Potential issues with cross-origin resource sharing.
- Recommendation: Properly configure CORS policies.

#### 4. Timestamp Disclosure
- Risk: Low
- Description: Server responses reveal timestamps.
- Recommendation: Avoid exposing internal timing information.

### Conclusion
The application does not have critical vulnerabilities, but several misconfigurations should be addressed to improve security posture.

---

## Task 2 — Trivy Image Scan

### Scan Target
- Image: bkimminich/juice-shop

### Summary
- CRITICAL: 10
- HIGH: 49

### Findings Breakdown
- OS (Debian): 1 vulnerability
- Node.js dependencies: 58 vulnerabilities

### Example Vulnerabilities

#### 1. crypto-js
- Severity: CRITICAL
- CVE: CVE-2023-46233
- Description: Cryptographic vulnerability in dependency.

#### 2. handlebars
- Severity: CRITICAL
- CVE: CVE-2026-33937
- Description: Template injection risk.

#### 3. express-jwt
- Severity: HIGH
- CVE: CVE-2020-15084
- Description: Authentication bypass vulnerability.

### Analysis
Most vulnerabilities originate from application dependencies (Node.js packages), not the base OS image. This indicates that dependency management is a major security concern.

---

## Task 3 — Security Analysis

### Why Container Scanning is Important
- Detects vulnerabilities before deployment
- Reduces attack surface
- Helps maintain secure supply chain
- Prevents deploying insecure images

### Dependency vs Base Image Risk
- Base image (Debian): minimal vulnerabilities
- Application dependencies: majority of issues
- Conclusion: application layer is the main risk

---

## Task 4 — Reflection

### Integrating into CI/CD

#### Trivy
- Run during build stage
- Fail pipeline on CRITICAL vulnerabilities
- Scan every new image

#### OWASP ZAP
- Run against staging environment
- Perform baseline scans automatically
- Generate HTML reports

### Benefits
- Continuous security validation
- Early detection of vulnerabilities
- Automated security enforcement

---

## Final Conclusion

This lab demonstrated practical container security scanning using:
- OWASP ZAP for dynamic web testing
- Trivy for container vulnerability scanning

The results highlight the importance of securing both:
- Application dependencies
- Container images

Security scanning should be integrated into CI/CD pipelines to ensure safe deployments.