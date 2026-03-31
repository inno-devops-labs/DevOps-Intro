# Lab 9 — Submission

## Task 1 — Web Application Scanning with OWASP ZAP

### 1.1 Start the Vulnerable Target Application

Command:

```sh
docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
```

Output:

![9\_img\_1.png](screenshots%2F9_img_1.png)


Open in browser: http://localhost:3000

Output:

![9\_img\_2.png](screenshots%2F9_img_2.png)

---

### 1.2 Scan with OWASP ZAP

Command:

```sh
docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
-t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
-t http://localhost:3000
-g gen.conf \
-r zap-report.html
```

Output:

![9\_img\_3.png](screenshots%2F9_img_3.png)

---

### 1.3 Results Analysis

- Number of Medium risk vulnerabilities: 2

- Vulnerability 1: Content Security Policy (CSP) Header Not Set  
This vulnerability indicates that the application does not define a Content Security Policy, which increases the risk of Cross-Site Scripting (XSS) attacks. Without CSP, malicious scripts injected into the page may be executed by the browser.

- Vulnerability 2: Cross-Domain Misconfiguration  
This issue is related to improper configuration of cross-origin resource sharing (CORS). It may allow unauthorized domains to access resources, which can lead to data leakage or unauthorized interactions.

- Security headers present:
  - Some basic HTTP headers are present, but they are not sufficient for full protection.

- Security headers missing:
  - Content-Security-Policy
  - Cross-Origin-Embedder-Policy
  - X-Content-Type-Options (partially)
  
  These headers are important because they help prevent XSS, data injection, and cross-origin attacks.

- Most interesting vulnerability:
  The most interesting vulnerability is the missing Content Security Policy (CSP), because it directly impacts protection against XSS attacks, which are among the most common and dangerous vulnerabilities in web applications.

![9\_img\_4.png](screenshots%2F9_img_4.png)

---

### Analysis

Web application scanning helps identify common vulnerabilities such as missing security headers, misconfigurations, and client-side risks.

In this scan, the most common issues are related to missing or improperly configured security headers. This is a typical problem in modern web applications, especially those that rely heavily on JavaScript.

Tools like OWASP ZAP allow developers to detect these issues early and improve application security before deployment.

---

### Reflection

In this task, I learned how to run an automated baseline security scan against a vulnerable web application and interpret the generated report.

This demonstrates how security scanning can be integrated into DevSecOps practices at an early stage of development.


## Task 2 — Container Vulnerability Scanning with Trivy (5 pts)

Command:
```sh
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
aquasec/trivy:latest image \
--severity HIGH,CRITICAL \
bkimminich/juice-shop
```
Output:

![9_img_5.png](screenshots%2F9_img_5.png)


### Container Vulnerability Scanning with Trivy

- Total CRITICAL vulnerabilities: 10
- Total HIGH vulnerabilities: 47

Examples of vulnerable packages:
- crypto-js — CVE-2023-46233 (CRITICAL)
- braces — CVE-2024-4068 (HIGH)

Most common vulnerability type:
- Node.js / npm package vulnerabilities

Analysis:
Container image scanning is important because it helps identify security issues in dependencies and system packages before deployment. Many applications rely on third-party libraries, which may contain known vulnerabilities (CVE). If these are not detected early, they can be exploited in production environments. Integrating tools like Trivy into the CI/CD pipeline allows automated security checks and reduces the risk of deploying vulnerable software.

Reflection:
These scans can be integrated into CI/CD pipelines by running Trivy as part of the build process. For example, a pipeline step can scan the container image and fail the build if CRITICAL vulnerabilities are found. This ensures that insecure images are not deployed and enforces security as part of the development workflow.