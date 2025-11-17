# Lab 9 — Introduction to DevSecOps Tools

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-DevSecOps-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Explore fundamental DevSecOps practices by performing security scans on containers and web applications using industry-standard tools.  
> **Deliverable:** A PR from `feature/lab9` to the course repo with `labs/submission9.md` containing scan results, analysis, and screenshots. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Performing **web application scanning** using OWASP ZAP to identify common vulnerabilities.
- Conducting **container vulnerability scanning** with Trivy to detect OS/library security issues.
- Analyzing security scan results and understanding vulnerability types.
- Working with intentionally vulnerable applications in a safe, controlled environment.

These skills are essential for integrating security into the DevOps pipeline and building secure applications.

---

## Tasks

### Task 1 — Web Application Scanning with OWASP ZAP (5 pts)

**Objective:** Perform automated security scanning of a vulnerable web application using OWASP ZAP to identify common web vulnerabilities.

**Why This Matters:** Web application scanning helps discover security flaws like XSS, SQL injection, and misconfigurations before attackers exploit them. ZAP is an industry-standard tool maintained by OWASP.

#### 1.1: Start the Vulnerable Target Application

1. **Deploy Juice Shop (Intentionally Vulnerable Application):**

   ```bash
   docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
   ```

2. **Verify It's Running:**

   Open your browser and navigate to `http://localhost:3000`

#### 1.2: Scan with OWASP ZAP

1. **Run ZAP Baseline Scan:**

   <details>
   <summary>🐧 Linux Users - Network Configuration</summary>

   On Linux, Docker containers can't use `host.docker.internal`. Get your Docker bridge IP:

   ```bash
   ip -f inet -o addr show docker0 | awk '{print $4}' | cut -d '/' -f 1
   ```

   Then use that IP in the ZAP command below instead of `host.docker.internal`.

   </details>

   ```bash
   docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
   -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
   -t http://host.docker.internal:3000 \
   -g gen.conf \
   -r zap-report.html
   ```

   > Mac/Windows users: Use `host.docker.internal` as shown above

#### 1.3: Analyze Results

1. **Open the Report:**

   - Find `zap-report.html` in your current directory
   - Open it in a browser

2. **Identify Vulnerabilities:**

   - Find at least 2 Medium risk vulnerabilities
   - Check security headers status (which headers are present/missing?)
   - Note the most interesting vulnerability found

#### 1.4: Clean Up

   ```bash
   docker stop juice-shop && docker rm juice-shop
   ```

In `labs/submission9.md`, document:
- Number of Medium risk vulnerabilities found
- Description of the 2 most interesting vulnerabilities
- Security headers status (which are present/missing and why they matter)
- Screenshot of ZAP HTML report overview
- Analysis: What type of vulnerabilities are most common in web applications?

---

### Task 2 — Container Vulnerability Scanning with Trivy (5 pts)

**Objective:** Identify vulnerabilities in container images using Trivy, focusing on intentionally vulnerable images for educational purposes.

**Why This Matters:** Container scanning detects OS/library vulnerabilities in images before deployment. Trivy is the industry's most comprehensive open-source scanner.

#### 2.1: Scan Container Image

1. **Run Trivy Scan:**

   ```bash
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
   aquasec/trivy:latest image \
   --severity HIGH,CRITICAL \
   bkimminich/juice-shop
   ```

   <details>
   <summary>🔍 Understanding Trivy flags</summary>

   - `--severity HIGH,CRITICAL`: Only show high and critical vulnerabilities
   - `-v /var/run/docker.sock`: Allows Trivy to access Docker images on your host
   - `image`: Scan a container image

   </details>

#### 2.2: Analyze Results

1. **Identify Key Findings:**

   From the scan output, identify:
   - Total number of CRITICAL vulnerabilities
   - Total number of HIGH vulnerabilities
   - At least 2 vulnerable package names
   - The most common vulnerability type (CVE category)

#### 2.3: Clean Up

   ```bash
   docker rmi bkimminich/juice-shop
   ```

In `labs/submission9.md`, document:
- Total count of CRITICAL and HIGH vulnerabilities
- List of 2 vulnerable packages with their CVE IDs
- Most common vulnerability type found
- Screenshot of Trivy terminal output showing critical findings
- Analysis: Why is container image scanning important before deploying to production?
- Reflection: How would you integrate these scans into a CI/CD pipeline?

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab9
   # create labs/submission9.md with your findings
   git add labs/submission9.md
   git commit -m "docs: add lab9 submission"
   git push -u origin feature/lab9
   ```

2. Open a PR from your fork's `feature/lab9` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 — Web Application Scanning with OWASP ZAP
   - [x] Task 2 — Container Vulnerability Scanning with Trivy
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab9` exists with commits for each task.
- ✅ File `labs/submission9.md` contains required outputs and analysis for Tasks 1-2.
- ✅ ZAP scan completed with HTML report generated.
- ✅ Trivy scan completed with vulnerability counts documented.
- ✅ Screenshots included as evidence.
- ✅ PR from `feature/lab9` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                       | Points |
| ----------------------------------------------- | -----: |
| Task 1 — Web Application Scanning with OWASP ZAP |  **5** |
| Task 2 — Container Vulnerability Scanning with Trivy |  **5** |
| **Total**                                       | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission9.md`.
- Include both scan outputs and written analysis for each task.
- Take clear screenshots showing key findings.
- Provide thoughtful analysis of vulnerability types and their impact.
- Follow responsible disclosure practices in documentation.

<details>
<summary>📚 Helpful Resources</summary>

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Common Vulnerabilities and Exposures (CVE)](https://cve.mitre.org/)

</details>

<details>
<summary>🔒 Security Best Practices</summary>

1. **Scanning Ethics:**
   - Only scan applications you own or have explicit permission to test
   - All scans in this lab target intentionally vulnerable containers running locally
   - Never run automated scanners against production systems without permission

2. **Vulnerability Management:**
   - Prioritize fixing CRITICAL and HIGH vulnerabilities first
   - Understand the context of each vulnerability (exploitability, impact)
   - Keep base images updated regularly
   - Use minimal base images to reduce attack surface

3. **CI/CD Integration:**
   - Run security scans as part of your build pipeline
   - Fail builds on CRITICAL vulnerabilities
   - Generate reports for security team review

</details>

<details>
<summary>💡 DevSecOps Tips</summary>

1. Shift security left - scan early and often in the development cycle.
2. Automate security scanning to make it part of the workflow, not an afterthought.
3. Understand false positives - not all reported vulnerabilities are exploitable in your context.
4. Create a vulnerability remediation plan with priorities and timelines.
5. Use security scanning tools as learning opportunities to understand common vulnerabilities.

</details>

<details>
<summary>🎯 Understanding Vulnerability Severity</summary>

**CVSS Severity Ratings:**
- **CRITICAL (9.0-10.0):** Immediate action required, actively exploited
- **HIGH (7.0-8.9):** Should be fixed soon, high impact
- **MEDIUM (4.0-6.9):** Plan remediation, moderate impact
- **LOW (0.1-3.9):** Fix when convenient, minimal impact

Consider both technical severity and business context when prioritizing fixes.

</details>