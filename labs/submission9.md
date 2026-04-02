# Task 1 — Web Application Scanning with OWASP ZAP

## Screenshot of ZAP HTML report

https://imgur.com/a/CyvMVP0

## Number of Medium risk vulnerabilities found

*Found 2 medium-risk vulnerabilities:*
*   **Missing Content Security Policy (CSP) Header:** Increases the risk of XSS and data injection.
*   **Cross-Domain Misconfiguration:** Permissive CORS (`Access-Control-Allow-Origin: *`) allows any third-party domain to read server responses.


## Description of the 2 most interesting vulnerabilities

*   **Content Security Policy (CSP) Header Not Set:** CSP restricts where resources can load from, preventing XSS. Without it, the entire application is vulnerable to script injections, defacement, and session theft.
*   **Cross-Domain Misconfiguration:** Using a wildcard (`*`) for CORS breaks the Same Origin Policy. It allows any external website to access potentially sensitive API responses, which is a dangerous configuration error.


## Security headers status (which are present/missing and why they matter)

The application lacks critical security headers, increasing its attack surface:
*   **Missing CSP:** Fails to block XSS attacks.
*   **Missing COEP/COOP:** Lacks isolation against cross-origin attacks (like Spectre).
*   **CORS Wildcard (`*`):** Dangerously allows any domain to read responses.
*   **Deprecated Feature-Policy:** Used instead of the modern Permissions-Policy.


## Analysis: What type of vulnerabilities are most common in web applications?

According to the OWASP Top 10, the most common vulnerabilities are:
1.  **Injection flaws** (e.g., SQLi, XSS) due to poor input validation.
2.  **Broken authentication** (weak session/credential handling).
3.  **Security misconfigurations** (missing headers, permissive CORS, default settings).


---

# Task 2 — Container Vulnerability Scanning with Trivy

## Total number of CRITICAL vulnerabilities

**9 critical vulnerabilities** found in Node.js dependencies. Examples include `crypto-js` (severely weakened PBKDF2 encryption) and `jsonwebtoken` (token verification bypass). These can lead to complete system compromise or data exposure.


## Total number of HIGH vulnerabilities

**44 high vulnerabilities** (43 in Node.js packages + 1 hardcoded RSA private key). Examples include authorization bypass (`express-jwt`) and ReDoS (`braces`). These can cause DoS, data leaks, or unauthorized access.


## List of 2 vulnerable packages with their CVE IDs

*   **crypto-js (CVE-2023-46233):** Affects v3.3.0 (fixed in 4.2.0). PBKDF2 encryption is heavily weakened, making password hashes easy to crack.
*   **jsonwebtoken (CVE-2015-9235):** Affects v0.1.0 (fixed in 4.2.2). Allows attackers to bypass verification using malformed tokens.


## Most common vulnerability type found

The most common types are **cryptographic weaknesses** (e.g., weak encryption, token bypasses) and **security misconfigurations** (e.g., outdated dependencies, hardcoded RSA keys).


## Screenshot of Trivy terminal 

https://imgur.com/a/DyYMXD2


## Analysis: Why is container image scanning important before deploying to production?

Scanning detects known flaws in dependencies, base images, and code before release. Without it, this image would have deployed with 52 known vulnerabilities. Scanning secures the supply chain, provides risk visibility, and blocks exploitable components from reaching production.


## Reflection: How would you integrate these scans into a CI/CD pipeline?

1.  **Mandatory Build Gate:** Run Trivy right after the image build step.
2.  **Fail the Pipeline:** Automatically stop the deployment if critical/high vulnerabilities exceed allowed limits.
3.  **Continuous Monitoring:** Schedule regular scans on deployed images to catch newly published vulnerabilities.