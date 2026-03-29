# TASK 1

Medium risk vulnerabilities: 2

Descriptions:

1. Content Security Policy (CSP) is an added layer of security that helps to detect and mitigate certain types of attacks, including Cross Site Scripting (XSS) and data injection attacks. These attacks are used for everything from data theft to site defacement or distribution of malware. CSP provides a set of standard HTTP headers that allow website owners to declare approved sources of content that browsers should be allowed to load on that page — covered types are JavaScript, CSS, HTML frames, fonts, images and embeddable objects such as Java applets, ActiveX, audio and video files.

2. Web browser data loading may be possible, due to a Cross Origin Resource Sharing (CORS) misconfiguration on the web server.

Security header statuses:

1. Content Security Policy (CSP) Header Not Set
2. Access-Control-Allow-Origin misconfigured
3. Deprecated Feature Policy Header Set
4. Cross-Origin-Opener-Policy Header Missing or Invalid
5. Cross-Origin-Embedder-Policy Header Missing or Invalid

![Zap report](images/zap-report.png)

The most common web application vulnerabilities are Broken Access Control, Injection flaws like SQLi, and Cross-Site Scripting (XSS). These top the list due to poor input validation, misconfigurations, and inadequate authentication checks.

# TASK 2

Total: 52 (HIGH: 43, CRITICAL: 9)

base64url — NSWG-ECO-428
braces — CVE-2024-4068

Most common vulnerability type: Denial of Service, including Redos memory leaks and catastrophic backtracking.

Trivy output is in the [Text file](../trivy-report.txt).

![Screenshot](images/trivy-report.png)

Container image scanning before production deployment detects known vulnerabilities, misconfigurations, and malware in OS packages, libraries, and dependencies that attackers could exploit. This shift-left security practice prevents compromised images from reaching production, reducing breach risk, ensuring compliance, and maintaining software supply chain integrity.

I would integrate container scans by adding a Trivy step in your CI/CD pipeline after building the Docker image but before pushing to the registry. Configure it to fail the build if CRITICAL or HIGH vulnerabilities exceed your threshold, blocking insecure images from production.
