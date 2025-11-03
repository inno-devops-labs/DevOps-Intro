# Task

## Task 1 — Web Application Scanning with OWASP ZAP

### 1.1: Start the Vulnerable Target Application

### 1.2: Scan with OWASP ZAP

### 1.3: Analyze Results

1. Number of Medium Risk Vulnerabilities Found: 2
```bash
Name	                                        Risk Level	    Number of Instances
Content Security Policy (CSP) Header Not Set	Medium	        13
Cross-Domain Misconfiguration	                Medium	        12
```

2. Security Headers Status:

* Present Headers:
    * Feature-Policy (but deprecated - should be replaced with Permissions-Policy)
    * X-Frame-Options (implied by modern frameworks but not explicitly listed)
* Missing Headers (Critical):
    * Content-Security-Policy - Completely missing (Medium risk)
    * Cross-Origin-Embedder-Policy - Missing (Low risk)
    * Cross-Origin-Opener-Policy - Missing (Low risk)
    * Permissions-Policy - Using deprecated Feature-Policy instead
* Misconfigured Headers:
    * CORS Headers: Access-Control-Allow-Origin: *

3. Two Most Interesting Vulnerabilities:

* Content Security Policy (CSP) Header Not Set (Medium Risk):
**Description:** The application lacks a Content Security Policy header, which is a critical security layer that helps detect and mitigate Cross-Site Scripting (XSS) and data injection attacks. Without CSP, the application is vulnerable to malicious content execution from unauthorized sources.

* Cross-Domain Misconfiguration (Medium Risk)
**Description:** The application has an overly permissive CORS (Cross-Origin Resource Sharing) configuration with Access-Control-Allow-Origin: * set on multiple endpoints. This allows any third-party domain to make cross-domain read requests to the application's unauthenticated APIs.

![Alt text](/files/Report_Overview.png?raw=true "Title")

### Analysis: What type of vulnerabilities are most common in web applications?

Based on the ZAP scan results the most common vulnerabilities in web applications are:

* **Security Misconfigurations** - Missing security headers, improper configurations
* **Cross-Site Scripting (XSS)** - Both reflected and stored XSS vulnerabilities
* **Cross-Site Request Forgery (CSRF)** - Lack of anti-CSRF tokens

## Task 2 — Container Vulnerability Scanning with Trivy

### 1. Total Vulnerabilities Found:
CRITICAL vulnerabilities: 8
HIGH vulnerabilities: 23 (1 from OS packages + 22 from Node.js packages)
### 2. List of 2 vulnerable packages with their CVE IDs
**Package:** crypto-js
* **CVE ID:** CVE-2023-46233
* **Severity:** CRITICAL
* **Description:** PBKDF2 implementation is 1,000 times weaker than specified in 1993 standards, making cryptographic operations vulnerable to brute-force attacks.

**Package:** vm2
* **CVE ID:** CVE-2023-32314
* **Severity:** CRITICAL
* **Description:** Sandbox escape vulnerability that allows attackers to break out of the VM2 sandbox and execute arbitrary code on the host system.

### 3. Most Common Vulnerability Type Found:
Prototype Pollution and Sandbox Escape vulnerabilities

### 4. Screenshot of Trivy terminal output showing critical findings

![Alt text](/files/Trivy_terminal.png?raw=true "Title")

## Analysis: Why is container image scanning important before deploying to production?

Container image scanning is critically important because:

* **Prevents Known Exploits:** The scan identified 8 CRITICAL vulnerabilities that could allow remote code execution, sandbox escapes, and authentication bypasses - all of which could lead to complete system compromise.

* **Identifies Supply Chain Risks:** The Juice Shop application has 30 vulnerable Node.js packages, demonstrating how third-party dependencies can introduce significant security risks.

* **Detects Security Misconfigurations:** The scan found exposed RSA private keys in the source code (insecurity.js and insecurity.ts), which is a severe security issue.

* **Compliance and Risk Management:** Organizations cannot afford to deploy containers with known CRITICAL vulnerabilities that could lead to data breaches and regulatory penalties.

* **Cost Prevention:** Fixing these issues pre-production is exponentially cheaper than dealing with security incidents post-deployment.

## Reflection: How would you integrate these scans into a CI/CD pipeline?

1. Pre-merge Quality Gate:
2. Build Stage Integration:
3. Registry Scanning:
4. Automated Remediation Workflow:
    * Fail builds on CRITICAL vulnerabilities
    * Auto-create tickets for HIGH severity issues
    * Generate compliance reports for audit trails
5. Continuous Monitoring:

