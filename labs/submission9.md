# Lab 9 — Introduction to DevSecOps Tools



## Task 1 — Web Application Scanning with OWASP ZAP

### Deploy Juice Shop (Intentionally Vulnerable Application):

```bash
docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
```

```bash
Unable to find image 'bkimminich/juice-shop:latest' locally
latest: Pulling from bkimminich/juice-shop
896a196ba7ee: Pull complete 
b839dfae01f6: Pull complete 
3214acf345c0: Pull complete 
d835e33e71c7: Pull complete 
3a298f7bd583: Pull complete 
2707c52e6030: Pull complete 
7c12895b777b: Pull complete 
3a6a574b4221: Pull complete 
52b2cf548ae5: Pull complete 
2780920e5dbf: Pull complete 
bdfd7f7e5bf6: Pull complete 
8072b5a0f795: Pull complete 
dd64bf2dd177: Pull complete 
d6b1b89eccac: Pull complete 
77d3479ca1b9: Pull complete 
52630fc75a18: Pull complete 
0d7ab412c19f: Pull complete 
ebddc55facdc: Pull complete 
35d8e5f294cf: Pull complete 
ff43311d121d: Pull complete 
278aecde295e: Pull complete 
8cd02d02ae08: Pull complete 
0be67ec41ee7: Pull complete 
c172f21841df: Pull complete 
5b1ddafc3f24: Download complete 
Digest: sha256:33d4db6a9f57e220db0bf4ee764a4f8f39aa0635eae3cd074c8fe865beb040b4
Status: Downloaded newer image for bkimminich/juice-shop:latest
4acf79578e478465d2eebbfbaa4d21539dbee4abd0457266f3e44ef7b72cacfd
```

### Verify It's Running:

```bash
curl http://localhost:3000
```

```bash
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Feature-Policy: payment 'self'
X-Recruiting: /#/jobs
Accept-Ranges: bytes
Cache-Control: public, max-age=0
Last-Modified: Mon, 09 Mar 2026 10:51:26 GMT
ETag: W/"124fa-19cd23923d4"
Content-Type: text/html; charset=UTF-8
Content-Length: 75002
Vary: Accept-Encoding
Date: Mon, 09 Mar 2026 10:52:10 GMT
Connection: keep-alive
Keep-Alive: timeout=5

<!--
  ~ Copyright (c) 2014-2026 Bjoern Kimminich & the OWASP Juice Shop contributors.
  ~ SPDX-License-Identifier: MIT
  -->
...
```

### Run ZAP Baseline Scan:

```bash
docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
-t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
-t http://host.docker.internal:3000 \
-g gen.conf \
-r zap-report.html
```

```bash
docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
-t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
-t http://host.docker.internal:3000 \
-g gen.conf \
-r zap-report.html
Unable to find image 'ghcr.io/zaproxy/zaproxy:stable' locally
stable: Pulling from zaproxy/zaproxy
068a090ce0c0: Pull complete 
eb04ef52de3a: Pull complete 
9cd477812358: Pull complete 
4a755f9e407e: Pull complete 
8d7c7d8d948c: Pull complete 
10bff4d78e4a: Pull complete 
e465d4219d66: Pull complete 
4f4fb700ef54: Pull complete 
7fe30193948c: Pull complete 
ddeb8e8bb81f: Pull complete 
04c9bfddfe0a: Pull complete 
5c5ce62775ba: Pull complete 
80414daa6971: Pull complete 
94428a06f602: Pull complete 
0518d3bee6c6: Pull complete 
605dcdf58e46: Pull complete 
4e108a765cac: Pull complete 
7b417353d040: Pull complete 
f65449d4570b: Pull complete 
85a5f9a01a9f: Pull complete 
Digest: sha256:c4da4c234258d444d9988fce9d034b00323724818daa4c91ca46f09aa04b46db
Status: Downloaded newer image for ghcr.io/zaproxy/zaproxy:stable
Total of 123 URLs
PASS: Vulnerable JS Library (Powered by Retire.js) [10003]
PASS: In Page Banner Information Leak [10009]
PASS: Cookie No HttpOnly Flag [10010]
PASS: Cookie Without Secure Flag [10011]
PASS: Re-examine Cache-control Directives [10015]
PASS: Cross-Domain JavaScript Source File Inclusion [10017]
PASS: Content-Type Header Missing [10019]
PASS: Anti-clickjacking Header [10020]
PASS: X-Content-Type-Options Header Missing [10021]
PASS: Information Disclosure - Debug Error Messages [10023]
PASS: Information Disclosure - Sensitive Information in URL [10024]
PASS: Information Disclosure - Sensitive Information in HTTP Referrer Header [10025]
PASS: HTTP Parameter Override [10026]
PASS: Information Disclosure - Suspicious Comments [10027]
PASS: Off-site Redirect [10028]
PASS: Cookie Poisoning [10029]
PASS: User Controllable Charset [10030]
PASS: User Controllable HTML Element Attribute (Potential XSS) [10031]
PASS: Viewstate [10032]
PASS: Directory Browsing [10033]
PASS: Heartbleed OpenSSL Vulnerability (Indicative) [10034]
PASS: Strict-Transport-Security Header [10035]
PASS: HTTP Server Response Header [10036]
PASS: Server Leaks Information via "X-Powered-By" HTTP Response Header Field(s) [10037]
PASS: X-Backend-Server Header Information Leak [10039]
PASS: Secure Pages Include Mixed Content [10040]
PASS: HTTP to HTTPS Insecure Transition in Form Post [10041]
PASS: HTTPS to HTTP Insecure Transition in Form Post [10042]
PASS: User Controllable JavaScript Event (XSS) [10043]
PASS: Big Redirect Detected (Potential Sensitive Information Leak) [10044]
PASS: Content Cacheability [10049]
PASS: Retrieved from Cache [10050]
PASS: X-ChromeLogger-Data (XCOLD) Header Information Leak [10052]
PASS: Cookie without SameSite Attribute [10054]
PASS: CSP [10055]
PASS: X-Debug-Token Information Leak [10056]
PASS: Username Hash Found [10057]
PASS: X-AspNet-Version Response Header [10061]
PASS: PII Disclosure [10062]
PASS: Hash Disclosure [10097]
PASS: Source Code Disclosure [10099]
PASS: Weak Authentication Method [10105]
PASS: Reverse Tabnabbing [10108]
PASS: Modern Web Application [10109]
PASS: Authentication Request Identified [10111]
PASS: Session Management Response Identified [10112]
PASS: Verification Request Identified [10113]
PASS: Script Served From Malicious Domain (polyfill) [10115]
PASS: ZAP is Out of Date [10116]
PASS: Absence of Anti-CSRF Tokens [10202]
PASS: Private IP Disclosure [2]
PASS: Session ID in URL Rewrite [3]
PASS: Script Passive Scan Rules [50001]
PASS: Insecure JSF ViewState [90001]
PASS: Java Serialization Object [90002]
PASS: Sub Resource Integrity Attribute Missing [90003]
PASS: Charset Mismatch [90011]
PASS: Application Error Disclosure [90022]
PASS: WSDL File Detection [90030]
PASS: Loosely Scoped Cookie [90033]
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 13 
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000 (200 OK)
        http://host.docker.internal:3000/sitemap.xml (200 OK)
        http://host.docker.internal:3000/ftp/coupons_2013.md.bak (403 Forbidden)
        http://host.docker.internal:3000/ftp/package-lock.json.bak (403 Forbidden)
WARN-NEW: Deprecated Feature Policy Header Set [10063] x 11 
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000/chunk-24EZLZ4I.js (200 OK)
        http://host.docker.internal:3000/chunk-TWZW5B45.js (200 OK)
        http://host.docker.internal:3000/chunk-I2PSG472.js (200 OK)
        http://host.docker.internal:3000/polyfills.js (200 OK)
WARN-NEW: Timestamp Disclosure - Unix [10096] x 9 
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000/sitemap.xml (200 OK)
        http://host.docker.internal:3000 (200 OK)
WARN-NEW: Cross-Domain Misconfiguration [10098] x 11 
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000/robots.txt (200 OK)
        http://host.docker.internal:3000/assets/public/favicon_js.ico (200 OK)
        http://host.docker.internal:3000/chunk-24EZLZ4I.js (200 OK)
        http://host.docker.internal:3000/chunk-TWZW5B45.js (200 OK)
WARN-NEW: Dangerous JS Functions [10110] x 2 
        http://host.docker.internal:3000/chunk-BBQJZN7H.js (200 OK)
        http://host.docker.internal:3000/main.js (200 OK)
WARN-NEW: Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] x 10 
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000/ (200 OK)
        http://host.docker.internal:3000/sitemap.xml (200 OK)
        http://host.docker.internal:3000/sitemap.xml (200 OK)
        http://host.docker.internal:3000 (200 OK)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 6     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 60
```

### Identify Vulnerabilities:

- 2 Medium risk vulnerabilities: Content Security Policy (CSP) Header Not Set, Cross-Domain Misconfiguration
- Check security headers status: High is missing, others - present
- Note the most interesting vulnerability found: Storable and Cacheable Content - only 1 informational vulnerability

### Clean Up:

```bash
docker stop juice-shop && docker rm juice-shop
```

```bash
juice-shop
juice-shop
```

**Analysis**: What type of vulnerabilities are most common in web applications? - Missing headers

## Task 2 — Container Vulnerability Scanning with Trivy

### Run Trivy Scan:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
aquasec/trivy:latest image \
--severity HIGH,CRITICAL \
bkimminich/juice-shop
```

```bash
Unable to find image 'aquasec/trivy:latest' locally
latest: Pulling from aquasec/trivy
afb5f192254f: Pull complete 
15e23908324b: Pull complete 
95841b475c1b: Pull complete 
Digest: sha256:bcc376de8d77cfe086a917230e818dc9f8528e3c852f7b1aff648949b6258d1c
Status: Downloaded newer image for aquasec/trivy:latest
2026-03-09T11:20:28Z    INFO    [vulndb] Need to update DB
2026-03-09T11:20:28Z    INFO    [vulndb] Downloading vulnerability DB...
2026-03-09T11:20:28Z    INFO    [vulndb] Downloading artifact...        repo="mirror.gcr.io/aquasec/trivy-db:2"
...
```

### Identify Key Findings:

- Total number of CRITICAL vulnerabilities: 15
- Total number of HIGH vulnerabilities: 50
- At least 2 vulnerable package names: @adraffy, @babel
- The most common vulnerability type (CVE category): tar

### Clean Up:

```bash
docker rmi bkimminich/juice-shop
```

```bash
Untagged: bkimminich/juice-shop:latest
Deleted: sha256:33d4db6a9f57e220db0bf4ee764a4f8f39aa0635eae3cd074c8fe865beb040b4
```

**Analysis**: Scanning container images before deployment is important to detect known vulnerabilities in dependencies, libraries, and base images. This helps prevent vulnerable software from entering production, reduces the risk of exploitation by attackers, and increases the security of the entire infrastructure.

**Reflection**: Scanning can be integrated into the CI/CD pipeline as an automatic step after the image is built.
