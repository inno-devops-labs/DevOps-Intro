# 1

1.1: 2 medium vulnerabilities

1.2:
- Web browser data loading may be possible, due to a Cross Origin Resource Sharing (CORS) misconfiguration on the web server.
- A dangerous JS function seems to be in use that would leave the site vulnerable.

1.3:
- Cross-Origin-Embedder-Policy Header Missing: This matters because without it, a malicious website can embed page as a resource and use side-channel attacks like Spectre to read sensitive data from page's memory.
- Cross-Origin-Opener-Policy Header Missing: This matters because without it, a malicious popup window can manipulate or steal data from page via window.opener references, leading to cross-origin information leaks.

1.4:
![zap screenshot](image-6.png)

1.5: Cross-Site Scripting (XSS) is consistently the most common vulnerability in web applications, occurring when untrusted data is executed as code in a user's browser without proper sanitization or output encoding.

# 2

2.1: high: 51; critical: 10

2.2: Node.js (node-pkg), bkimminich/juice-shop (debian 13.4)

2.3: Denial of Service vulnerabilities.

2.4: ![trivy results](image-7.png)

2.5 Container image scanning is critical before production deployment because it identifies known vulnerabilities in base OS packages and application dependencies that attackers could exploit to compromise your running containers or access sensitive data.

2.6: I would add an automated scan stage after build that fails the pipeline on CRITICAL/HIGH vulnerabilities before deployment.
