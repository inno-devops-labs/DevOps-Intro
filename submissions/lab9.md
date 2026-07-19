Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

Task 1 — Trivy

Image scan results:
10 HIGH vulnerabilities found in Go standard library (CVE-2026-25679, CVE-2026-27145, CVE-2026-32280, CVE-2026-32281, CVE-2026-32283, and 5 more related to TLS/crypto). All require Go upgrade to versions 1.26.1 or 1.26.4. Decision: FIX.

Filesystem scan results:
1 HIGH finding: private key in .vagrant/machines/default/virtualbox/private_key. Decision: FIX - remove .vagrant directory from repository.

Config scan results:
No HIGH or CRITICAL findings.

SBOM generated successfully (cyclonedx format, 13KB).

Design questions:

a) CVE severity is just the starting point. When I triage findings I also need to understand if the vulnerable code is actually reachable from our application logic. If we don't call the vulnerable function, the risk is much lower. I look at whether there are public exploits and if the vulnerability is being actively used in attacks. Deployment context matters a lot - is this service exposed to the internet or only internal? The attack complexity matters too - some vulnerabilities require specific conditions or privileges that make them hard to exploit. Finally I consider the actual business impact if someone did exploit it. A critical vulnerability in a non-critical service might be less urgent than a high vulnerability in our main API.

b) Distroless images are effective because they remove almost everything except the application itself. No package managers means attackers can't install new tools. No shell makes it harder to execute commands. No OS utilities like curl or wget means attackers can't download additional payloads. The attack surface shrinks dramatically because there are fewer packages to have vulnerabilities and fewer tools for attackers to use. The image size also decreases significantly which helps with scan times.

c) I think .trivyignore is legitimate when you have a false positive that the scanner consistently flags incorrectly, or when you've accepted a risk with clear mitigation in place like a WAF or network isolation. You might also ignore vulnerabilities that only affect test dependencies that never run in production. The key is that each ignored finding needs documentation explaining why and a date when you'll re-evaluate. It becomes security theater when teams use it to sweep findings under the rug just to pass compliance checks, or when they ignore critical vulnerabilities permanently without ever reviewing them again.

d) Having an SBOM solves the problem of knowing what you're actually running. When a new vulnerability like Log4Shell is disclosed, you can immediately search your SBOM to see if you're affected and what version you're using. Without an SBOM you'd have to manually inspect every container and dependency. It also helps with license compliance and supply chain transparency. When auditors ask what's in your software, you can show them the SBOM instead of guessing.

Task 2 — OWASP ZAP

ZAP findings from baseline scan:
1. X-Content-Type-Options Header Missing - FIX (implemented middleware)
2. Storable and Cacheable Content - ACCEPT (API responses can be cached, re-evaluate in 3 months)
3. ZAP is Out of Date - ACCEPT (using pinned version 2.16.0, re-evaluate in 3 months)
4. Insufficient Site Isolation Against Spectre - ACCEPT (internal API, risk acceptable)

Fix implemented: Security headers middleware in app/middleware/security.go

Before fix - curl -I http://172.17.0.1:8080/health returned:
Content-Type: application/json

After fix - curl -I http://172.17.0.1:8080/health returns:
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Content-Type: application/json
Referrer-Policy: strict-origin-when-cross-origin
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-Xss-Protection: 1; mode=block

Unit test added in middleware/security_test.go that asserts headers are present. Test passes.

ZAP re-scan confirmed X-Content-Type-Options Header Missing is now PASS (no longer WARN).

Design questions:

e) Middleware is the right approach because it applies headers to every route automatically. If I set headers in each handler individually, I might forget to do it for a new route or change one handler but not another. Middleware gives me a single place to add or modify headers. It also keeps security concerns separate from business logic - handlers focus on what they're supposed to do, not on HTTP header details.

f) Content-Security-Policy: default-src 'none' means nothing can load from anywhere - no scripts, no styles, no images, no fonts. For a website this breaks everything because browsers need to load JavaScript and CSS to render pages. For an API like QuickNotes that only returns JSON, there's nothing to load so it's perfectly fine. The policy protects against injection attacks without breaking functionality because the API doesn't serve HTML content anyway.

g) The problem with accepting all findings without review is that you might miss something important. Some informational findings could indicate real issues or become exploitable in combination with other problems. You also lose the opportunity to learn what the scanner is telling you and how to improve your security. Accumulating ignored findings creates technical debt and makes it harder to notice when something genuinely new and serious appears. The review process helps you understand the security posture of your application.

Bonus — govulncheck CI

CI job added to .github/workflows/ci.yml:
- Runs govulncheck ./... against app/
- Uses pinned version v1.0.0
- Blocks PR if vulnerabilities found

Demonstration: temporarily added vulnerable dependency, CI turned red. After revert, CI green.

Design questions:

h) The difference between reachability analysis and just listing CVEs is that reachability tells you whether the vulnerable code path is actually used in your application. This dramatically reduces false positives and triage workload. Instead of investigating every vulnerability in your dependency tree, you only need to look at the ones that could actually affect your running application. It saves time and helps prioritize real risks.

i) Pinning govulncheck version matters because scanners change over time - new versions might have different detection rules or output formats. If you use @latest and the scanner updates, your CI could start failing or passing differently without any code change, which makes it hard to debug. A pinned version gives you reproducible builds and stable expectations. If you want to upgrade the scanner, you do it intentionally and can verify the results before committing.

j) govulncheck only looks at Go code and its dependencies. Trivy scans the whole container image including OS packages like libc or openssl, any other language dependencies like Python packages in a virtualenv, configuration files for misconfigurations, Dockerfile issues, and even secrets like hardcoded credentials. Trivy gives you the full picture of what's in your container, while govulncheck focuses on a specific part of it.

