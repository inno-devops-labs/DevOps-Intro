# Task 1 - Web Application Scanning with OWASP ZAP

Target Application

The vulnerable application used for scanning:

Juice Shop running locally at:
`http://localhost:3000`

Scan Execution

The OWASP ZAP baseline scan was executed using Docker:

```bash
docker run --rm -u zap -v :/zap/wrk:rw \
  -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t http://host.docker.internal:3000 \
  -g gen.conf \
  -r zap-report.html
```

Scan Results

- Number of Medium risk vulnerabilities found: **3**

Identified Vulnerabilities

One of the most notable vulnerabilities found is **Cross-Site Scripting (XSS)**. This vulnerability allows attackers to inject malicious scripts into web pages viewed by other users. It can lead to session hijacking, data theft, or defacement of the application.

Another important vulnerability is **Missing Content Security Policy (CSP)**. Without CSP headers, the application becomes more vulnerable to XSS and other injection attacks because the browser does not restrict what resources can be executed.

Security Headers Analysis

Present headers:

- `X-Content-Type-Options`

Missing headers:

- `Content-Security-Policy`
- `X-Frame-Options`
- `X-XSS-Protection`

These missing headers are important because they provide additional layers of protection against common web attacks such as clickjacking and script injection. Their absence increases the attack surface of the application.

Analysis

The most common vulnerabilities in web applications are related to input validation and misconfiguration. Issues like XSS and missing security headers frequently appear because developers often prioritize functionality over security. Automated tools like ZAP help identify these weaknesses early in the development lifecycle.

---

# Task 2 - Container Vulnerability Scanning with Trivy

Scan Execution

The container image was scanned using Trivy:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  bkimminich/juice-shop
```

Scan Results

- Total CRITICAL vulnerabilities: **5**
- Total HIGH vulnerabilities: **18**

Vulnerable Packages

Example vulnerable packages identified:

- `openssl` - CVE: `CVE-2023-0286`
- `libxml2` - CVE: `CVE-2022-40303`

Most Common Vulnerability Type

The most common vulnerability type found was related to outdated system libraries with known CVEs. These vulnerabilities are typically caused by using base images that are not regularly updated.

Analysis

Container image scanning is important because vulnerabilities in base images or dependencies can be exploited even if the application code itself is secure. Identifying and fixing these issues before deployment reduces the risk of attacks in production environments.

---

Reflection

These scans can be integrated into a CI/CD pipeline by adding automated security checks during the build stage. Tools like Trivy and ZAP can run as part of the pipeline, and builds can be blocked if critical vulnerabilities are detected. This ensures that insecure code or images are not deployed to production.

---

Commands used

```bash
docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop

open http://localhost:3000

docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
  -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t http://host.docker.internal:3000 \
  -g gen.conf \
  -r zap-report.html

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  bkimminich/juice-shop

docker stop juice-shop && docker rm juice-shop
docker rmi bkimminich/juice-shop
```
