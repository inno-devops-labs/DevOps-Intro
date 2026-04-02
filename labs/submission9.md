# Lab 9

## Task 1

Scan files:

- labs/lab9/zap-report.html
- labs/lab9/zap-baseline.txt
- labs/lab9/gen.conf

Medium risk vulnerabilities found: 2

The 2 most interesting vulnerabilities:

- Content Security Policy (CSP) Header Not Set - the app does not send a CSP header, so the browser has fewer restrictions against XSS and script injection.
- Cross-Domain Misconfiguration - the app sends Access-Control-Allow-Origin: *, which is too open and can allow unsafe cross-origin access.

Security headers:

- Present: X-Content-Type-Options: nosniff, X-Frame-Options: SAMEORIGIN, Feature-Policy: payment 'self'
- Missing or weak: Content-Security-Policy, Cross-Origin-Embedder-Policy, Cross-Origin-Opener-Policy
- Note: Feature-Policy is deprecated, so Permissions-Policy would be better.
- Also, Strict-Transport-Security is not used here because this local lab app is running on HTTP, not HTTPS.

Why headers matter: they help protect against XSS, clickjacking, unsafe cross-origin behavior, and data leaks between pages.

Screenshot:

- labs/lab9/zap-report-overview.png

Common web app issues are missing security headers, weak CORS settings, and XSS-related problems. These issues are common because many apps work without secure defaults.

## Task 2

I scanned the bkimminich/juice-shop container image with Trivy.

Scan files:

- labs/lab9/trivy-vuln.txt
- labs/lab9/trivy-output.json

Total vulnerabilities found:

- CRITICAL: 10
- HIGH: 49

2 vulnerable packages with CVE IDs:

- vm2 - CVE-2023-32314, CVE-2023-37466, CVE-2023-37903, CVE-2026-22709
- tar - CVE-2026-23745, CVE-2026-23950, CVE-2026-24842, CVE-2026-26960, CVE-2026-29786, CVE-2026-31802

Most common vulnerability type:

- The most common issues were in Node.js dependencies.
- The package with the most findings was tar with 12 vulnerabilities.
- Many of them were archive handling issues like path traversal and arbitrary file overwrite.

Screenshot:

- labs/lab9/trivy-critical-findings.png

Container image scanning is important because vulnerable OS and app dependencies can go to production together with the image. It helps catch critical issues before deployment.