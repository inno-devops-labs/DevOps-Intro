## Task 1 — Web Application Scanning with OWASP ZAP

### Scan Results
- **Number of Medium risk vulnerabilities found:** 2
- **Security headers status:** 
  - Content Security Policy (CSP) Header Not Set
  - Permissions-Policy header not properly configured (deprecated Feature-Policy header found)
  - Cross-Origin-Embedder-Policy header missing
  - Access-Control-Allow-Origin header needs more restrictive configuration

### Most Interesting Vulnerabilities
1. **Content Security Policy (CSP) Header Not Set** - The application lacks CSP headers, which could allow content injection attacks like XSS. CSP provides a critical layer of protection by restricting sources of executable scripts.
2. **Cross-Domain Misconfiguration** - The application has overly permissive CORS settings with 12 instances found. This could allow unauthorized domains to access sensitive data through cross-origin requests.

### Analysis
Most issues found are related to missing or misconfigured security headers. Without them, the app is vulnerable to script injection and unauthorized data access.

### Screenshot



## Task 2 — Container Vulnerability Scanning with Trivy

### Scan Results
Based on the provided Trivy output:

- **Total CRITICAL vulnerabilities:** 8
- **Total HIGH vulnerabilities:** 23 (1 from OS packages + 22 from Node.js)
- **Most common vulnerability type:** Authentication/Authorization bypass and prototype pollution vulnerabilities

### Vulnerable Packages
1. **jsonwebtoken** - CVE-2015-9235 (CRITICAL) - Verification step bypass with altered token
2. **crypto-js** - CVE-2023-46233 (CRITICAL) - PBKDF2 1,000 times weaker than specified

### Analysis
- Helps maintain compliance and security standards
- Reduces the attack surface of deployed applications

### Screenshot


### Reflection
Those tools help with security when creating app, they help to see security problems and fix them.