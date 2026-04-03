![Website works on localhost:3000](image-6.png)

![ZAP report page](image-7.png)

![ZAP insights](image-8.png)

![ZAP summary](image-9.png)

# Lab 9 - DevSecOps Tools

## Student Info
- Name: TODO
- Group: TODO
- Date: 2026-04-04
- Branch: feature/lab9

## Task 1 - OWASP ZAP

### What I did
- Started Juice Shop on port 3000.
- Ran ZAP baseline scan from Docker.
- Opened `zap-report.html` in browser.

### Results
- High: 0
- Medium: 2
- Low: 5
- Informational: 3

### Two most interesting Medium findings
1. Content Security Policy (CSP) Header Not Set
   - Why important: no CSP makes XSS defense weaker.

2. Cross-Domain Misconfiguration
   - Why important: bad CORS setup can allow unsafe cross-origin read access.

### Security headers
- Present: some basic headers are set.
- Missing: `Content-Security-Policy` (found by ZAP).
- Why it matters: missing security headers reduce browser protection against XSS and other attacks.

### Short analysis
Most common web issues are configuration mistakes: missing headers and weak CORS rules.

### Cleanup
```bash
docker stop juice-shop
docker rm juice-shop
```

## Task 2 - Trivy

### What I did
- Scanned image `bkimminich/juice-shop` with Trivy.
- Used severity filter `HIGH,CRITICAL`.

### Results
- CRITICAL: 10
- HIGH: 49

### Two vulnerable packages and CVEs
1. Package: `crypto-js`
   - CVE: `CVE-2023-46233`
   - Severity: CRITICAL

2. Package: `lodash`
   - CVE: `CVE-2019-10744`
   - Severity: CRITICAL

### Most common vulnerability type
Most vulnerabilities are in Node.js dependencies (outdated npm packages).

### Why container scanning is important
It helps find known vulnerabilities before deploy. This lowers security risk in production.

### CI/CD integration (simple plan)
- Run Trivy in every build.
- Fail pipeline on CRITICAL findings.
- Run ZAP baseline on staging before release.
- Save reports as CI artifacts.

### Cleanup
```bash
docker rmi bkimminich/juice-shop
```

## PR checklist
- [x] Task 1 — Web Application Scanning with OWASP ZAP
- [x] Task 2 — Container Vulnerability Scanning with Trivy

## What is still missing
- Fill student name and group.
- Add one screenshot from Trivy terminal output with critical findings (required by lab).
