# Lab 9 — Introduction to DevSecOps Tools

## Task 1 — Web Application Scanning with OWASP ZAP

### Number of Medium risk vulnerabilities found

The automated OWASP ZAP baseline scan was executed against Juice Shop running at http://172.17.0.1:3000.
The ZAP baseline log shows **7 WARN-NEW alerts** in total, corresponding to multiple instances of these **two Medium-risk vulnerability types**.

### Medium-Risk Vulnerabilities

1. **Content Security Policy (CSP) Header Not Set [10038]**

- Risk: Medium (11 instances)
- Description: The application does not send a Content-Security-Policy header in HTTP responses.
Without this header, modern browsers cannot restrict which external scripts, images, or frames can be loaded.
- Impact: Increases exposure to Cross-Site Scripting (XSS) and data-injection attacks.
- Recommendation: Define and enable a strict CSP (e.g. default-src 'self') to limit allowed content sources.

2. **Cross-Domain Misconfiguration [10098]**

- Risk: Medium (11 instances)
- Description: The application allows or references resources from multiple domains without proper cross-origin controls.
- Impact: Potential leakage of sensitive information through insecure CORS or inclusion of malicious third-party scripts.
- Recommendation: Review CORS and Access-Control-Allow-Origin settings; restrict allowed origins to trusted domains only.

### Security Headers Status
| Header                          | Status                    | Description / Importance                                                             |
| ------------------------------- | ------------------------- | ------------------------------------------------------------------------------------ |
| **Content-Security-Policy**     | ❌ Missing                 | Defines trusted sources for scripts and other resources to mitigate XSS.             |
| **Strict-Transport-Security**   | ❌ Missing                 | Forces HTTPS for future requests; prevents protocol downgrade attacks.               |
| **Referrer-Policy**             | ❌ Missing                 | Reduces leakage of internal URLs in the `Referer` header.                            |
| **Access-Control-Allow-Origin** | ✅ Present (`*`)           | Allows all origins; convenient for dev but insecure for production.                  |
| **X-Content-Type-Options**      | ✅ Present (`nosniff`)     | Prevents browsers from MIME-sniffing content types.                                  |
| **X-Frame-Options**             | ✅ Present (`SAMEORIGIN`)  | Protects against clickjacking attacks.                                               |
| **Feature-Policy**              | ⚠️ Present but deprecated | Controls browser features (camera, mic, payments); replaced by `Permissions-Policy`. |

**Summary:**

Some security headers (`X-Content-Type-Options`, `X-Frame-Options`) are correctly configured, but essential ones like **CSP**, **HSTS**, and **Referrer-Policy** are missing.
The `Access-Control-Allow-Origin: *` header allows any domain, which is unsafe in production because it opens cross-origin access.
Overall, the application lacks strong client-side security controls typical of modern hardened web servers.

### 2 Most Interesting Vulnerabilities Found

1. **Content Security Policy (CSP) Header Not Set [10038]**

This issue is critical for client-side protection. The absence of a Content-Security-Policy header means the browser has no restrictions on which scripts, images, or frames can load.
If a malicious script is injected anywhere into the page, the browser will execute it without question.
A strict CSP (for example, `default-src 'self'; script-src 'self'`) drastically reduces the risk of XSS and data-injection attacks.

2. **Dangerous JavaScript Functions [10110]**

ZAP detected the presence of potentially unsafe functions such as `eval()` and `document.write()` inside `main.js` and `vendor.js`.
These functions are often exploited when user input is passed directly to them, allowing arbitrary JavaScript execution in the browser.
They should be replaced with safer alternatives or sandboxed carefully to avoid client-side code injection.

### Screenshot

![ZAP HTML report overview](https://github.com/user-attachments/assets/38a6e859-6031-4fd2-a349-4264be220d5b)

### Analysis

Web applications most frequently suffer from **misconfigured or missing security headers, overly permissive CORS policies, and unsafe client-side JavaScript practices.**
These weaknesses rarely break functionality, which is why developers often overlook them, but they form the base layer for common exploits like XSS, clickjacking, and information disclosure.
Regular automated scans with tools such as OWASP ZAP help identify these issues early in the development pipeline so they can be fixed before deployment.

## Task 2 — Container Vulnerability Scanning with Trivy

### Scan Summary

A Trivy image scan was executed against the `bkimminich/juice-shop` image and the results were saved to `trivy.json`. The JSON was analyzed with `jq` to extract counts and top findings.

**Key Findings**
- Total CRITICAL vulnerabilities: `8`
- Total HIGH vulnerabilities: `23`

Commands used to obtain these counts:

```bash
CRIT=$(jq '[.. | objects | select(has("Vulnerabilities")) | .Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy.json)
HIGH=$(jq  '[.. | objects | select(has("Vulnerabilities")) | .Vulnerabilities[]? | select(.Severity=="HIGH")]      | length' trivy.json)
echo "CRITICAL: $CRIT"
echo "HIGH: $HIGH"

```

### Example vulnerable packages (with CVE IDs)

Below are specific vulnerable packages and CVE IDs extracted from `trivy.json` (unique list command shown in logs):
- `braces` — **CVE-2024-4068**
- `crypto-js` — **CVE-2023-46233**

Additional notable package:

- `jsonwebtoken` — appears **6** times in the high/critical findings. Associated identifiers in the scan include **CVE-2015-9235**, **CVE-2022-23539**, and `NSWG-ECO-17` (non-CVE advisory noted in the output).

Commands used to list packages + CVEs

```bash
jq -r '
  .. | objects | select(has("Vulnerabilities")) | .Vulnerabilities[]? 
  | select(.Severity=="HIGH" or .Severity=="CRITICAL")
  | "\(.PkgName)\t\(.VulnerabilityID)"
' trivy.json | sort -u | head -n 10
```

And the top vulnerable packages by count:

```bash
jq -r '
  .. | objects | select(has("Vulnerabilities")) | .Vulnerabilities[]? 
  | select(.Severity=="HIGH" or .Severity=="CRITICAL") 
  | .PkgName
' trivy.json | sort | uniq -c | sort -nr | head
```

Output snippet:

```bash
6 jsonwebtoken
4 multer
3 vm2
3 lodash
...
```

### Most common vulnerability type (CVE category / attacker impact)

From the `.Title` fields in the scan, the most recurring class of issues is **token verification / authentication bypasses** related to `jsonwebtoken` (titles like “Verification Bypass”, “nodejs-jsonwebtoken: verification step bypass with an altered token”, etc.). This indicates multiple high-impact issues in authentication/verification logic or in libraries used for token handling.

How this was derived:

```bash
jq -r '
  .. | objects | select(has("Vulnerabilities")) | .Vulnerabilities[]? 
  | select(.Severity=="HIGH" or .Severity=="CRITICAL") 
  | .Title
' trivy.json | sed 's/ (.*//g' | sort | uniq -c | sort -nr | head
```

Top lines in output:

```bash
2 Verification Bypass
2 nodejs-jsonwebtoken: verification step bypass with an altered token
2 jsonwebtoken: Unrestricted key type could lead to legacy keys usagen
...
```

### Screenshots

![Command run](https://github.com/user-attachments/assets/2d250f71-67de-4552-9c5d-226375934502)

![bkimminich/juice-shop](https://github.com/user-attachments/assets/3d19c338-bad5-48d2-bdbd-e5af3320088f)

![Node.js (node-pkg)](https://github.com/user-attachments/assets/2862c2f3-001d-4e16-81e1-f6bd3821b099)

### Analysis — Why container image scanning is important before production

1. **Find issues early, reduce blast radius.** Images frequently contain transitive dependencies (OS libs, language packages). Scanning detects known CVEs before they reach production; fixing them in the build phase is far cheaper and safer than emergency patches in production.

2. **Attack surface in supply chain.** A vulnerable library (e.g., token handling or sandbox escape) inside an image can lead to severe breaches: auth bypass, remote code execution, DoS. Scanning helps catch high-impact items like these.

3. **Compliance and auditability.** Automated scans produce artifacts and records that security teams and auditors can review.

4. **Risk-based prioritization.** Severity counts (CRITICAL / HIGH) let teams triage fixes effectively and block deployments when necessary.

### Reflection — How to integrate Trivy scans into a CI/CD pipeline

Practical, concrete steps to automate and enforce image security:

1. **Scan during the Build Stage**
    - Add a pipeline step after the image is built but before pushing to registry:
        - `trivy image --format json -o trivy.json <image>`
    - Save `trivy.json` as a pipeline artifact for reviewers.
2. **Fail on policy**
    - Enforce a policy that fails the pipeline when CRITICAL vulnerabilities are present, and optionally when HIGH count > threshold.
    - Example: fail if `CRITICAL > 0` OR `HIGH > 10` (tune thresholds to org risk appetite).
3. **Produce human-friendly reports**
    - Convert Trivy JSON to HTML or table output and upload as build artifacts (so reviewers and security team can inspect easily).
4. **Annotate PRs / MR**
    - Integrate the scanner with the VCS to post summary comments on Pull Requests (e.g., “3 CRITICAL, 7 HIGH — see artifact: trivy-report.html”). This gives developers immediate feedback.
5. **Use baselines and ignore lists carefully**
    - Maintain a vulnerability baseline for legacy images and an allowlist for accepted risks (with ticketing and expiration). Avoid permanent silencing.
6. **Shift-left + automated PR remediation**
    - Optionally, configure automated dependency bump PRs for fixable vulnerabilities (dependabot-like), and block merges until severity drops below policy.
7. **Periodic registry scanning**
    - Schedule daily/weekly scans of images in the registry (not just built images) to catch newly published CVE data affecting previously clean images.
8. **Alerting & Escalation**
    - Critical findings should trigger notifications to on-call/security team and open remediation tickets automatically.