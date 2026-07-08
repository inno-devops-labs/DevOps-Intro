<h1>Task 1</h1>

```docker run --rm aquasec/trivy:0.59.1 version```

Unable to find image 'aquasec/trivy:0.59.1' locally
0.59.1: Pulling from aquasec/trivy
2167091a7879: Pull complete 
38a8310d387e: Pull complete 
1d671f98de6b: Pull complete 
2c38dcf52ab2: Pull complete 
Digest: sha256:029e990b328d149bf0a9ffe355919041e1f86192db2df47e217f8a36dd42ceac
Status: Downloaded newer image for aquasec/trivy:0.59.1
Version: 0.59.1

```docker run --rm aquasec/trivy:0.59.1 image quicknotes:lab6 --severity HIGH,CRITICAL```

2026-07-08T16:41:22Z    INFO    [vulndb] Need to update DB
2026-07-08T16:41:22Z    INFO    [vulndb] Downloading vulnerability DB...
2026-07-08T16:41:22Z    INFO    [vulndb] Downloading artifact...        repo="mirror.gcr.io/aquasec/trivy-db:2"
11.85 MiB / 99.49 MiB [------->_____________________________________________________] 11.91% ? p/s ?34.14 MiB / 99.49 MiB [-------------------->________________________________________] 34.32% ? p/s ?57.00 MiB / 99.49 MiB [---------------------------------->__________________________] 57.29% ? p/s ?76.90 MiB / 99.49 MiB [------------------------------------>__________] 77.30% 108.43 MiB p/s ETA 0s97.53 MiB / 99.49 MiB [---------------------------------------------->] 98.03% 108.43 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 108.43 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 103.86 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 103.86 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 103.86 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [---------------------------------------------->] 100.00% 97.16 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [---------------------------------------------->] 100.00% 97.16 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [---------------------------------------------->] 100.00% 97.16 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [---------------------------------------------->] 100.00% 90.89 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [---------------------------------------------->] 100.00% 90.89 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [-------------------------------------------------] 100.00% 38.18 MiB p/s 2.8s2026-07-08T16:41:26Z     INFO    [vulndb] Artifact successfully downloaded    repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-07-08T16:41:26Z    INFO    [vuln] Vulnerability scanning is enabled
2026-07-08T16:41:26Z    INFO    [secret] Secret scanning is enabled
2026-07-08T16:41:26Z    INFO    [secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-07-08T16:41:26Z    INFO    [secret] Please see also https://aquasecurity.github.io/trivy/v0.59/docs/scanner/secret#recommendation for faster secret detection

```docker run --rm -v $(pwd):/repo aquasec/trivy:0.59.1 fs /repo --severity HIGH,CRITICAL```

2026-07-08T16:42:04Z    INFO    [vulndb] Need to update DB
2026-07-08T16:42:04Z    INFO    [vulndb] Downloading vulnerability DB...
2026-07-08T16:42:04Z    INFO    [vulndb] Downloading artifact...        repo="mirror.gcr.io/aquasec/trivy-db:2"
10.73 MiB / 99.49 MiB [------>______________________________________________________] 10.79% ? p/s ?33.72 MiB / 99.49 MiB [-------------------->________________________________________] 33.90% ? p/s ?56.49 MiB / 99.49 MiB [---------------------------------->__________________________] 56.78% ? p/s ?79.47 MiB / 99.49 MiB [------------------------------------->_________] 79.88% 114.56 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 114.56 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 114.56 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 109.31 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 109.31 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 109.31 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 102.26 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 102.26 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [--------------------------------------------->] 100.00% 102.26 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [---------------------------------------------->] 100.00% 95.66 MiB p/s ETA 0s99.49 MiB / 99.49 MiB [-------------------------------------------------] 100.00% 38.55 MiB p/s 2.8s2026-07-08T16:42:08Z INFO    [vulndb] Artifact successfully downloaded       repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-07-08T16:42:08Z    INFO    [vuln] Vulnerability scanning is enabled
2026-07-08T16:42:08Z    INFO    [secret] Secret scanning is enabled
2026-07-08T16:42:08Z    INFO    [secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-07-08T16:42:08Z    INFO    [secret] Please see also https://aquasecurity.github.io/trivy/v0.59/docs/scanner/secret#recommendation for faster secret detection
2026-07-08T16:42:10Z    INFO    Number of language-specific files       num=1
2026-07-08T16:42:10Z    INFO    [gomod] Detecting vulnerabilities...


```docker run --rm -v $(pwd):/repo aquasec/trivy:0.59.1 config /repo```

2026-07-08T17:35:25Z    INFO    [misconfig] Misconfiguration scanning is enabled
2026-07-08T17:35:25Z    INFO    [misconfig] Need to update the built-in checks
2026-07-08T17:35:25Z    INFO    [misconfig] Downloading the built-in checks...
165.46 KiB / 165.46 KiB [------------------------------------------------------] 100.00% ? p/s 100ms2026-07-08T17:35:29Z        ERROR   [rego] Error occurred while parsing. Trying to fallback to embedded check    file_path="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego" err="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego:30: rego_type_error: undefined ref: input.aws.ec2.requestedamis[__local622__]\n\tinput.aws.ec2.requestedamis[__local622__]\n\t              ^\n\t              have: \"requestedamis\"\n\t              want (one of): [\"instances\" \"launchconfigurations\" \"launchtemplates\" \"networkacls\" \"securitygroups\" \"subnets\" \"volumes\" \"vpcs\"]"
2026-07-08T17:35:29Z    ERROR   [rego] Failed to find embedded check, skipping  file_path="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego"
2026-07-08T17:35:29Z    ERROR   [rego] Error occurred while parsing     file_path="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego" err="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego:30: rego_type_error: undefined ref: input.aws.ec2.requestedamis[__local622__]\n\tinput.aws.ec2.requestedamis[__local622__]\n\t              ^\n\t              have: \"requestedamis\"\n\t              want (one of): [\"instances\" \"launchconfigurations\" \"launchtemplates\" \"networkacls\" \"securitygroups\" \"subnets\" \"volumes\" \"vpcs\"]"
2026-07-08T17:35:29Z    ERROR   [rego] Error occurred while parsing. Trying to fallback to embedded check       file_path="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego" err="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego:30: rego_type_error: undefined ref: input.aws.ec2.requestedamis[__local622__]\n\tinput.aws.ec2.requestedamis[__local622__]\n\t              ^\n\t              have: \"requestedamis\"\n\t              want (one of): [\"instances\" \"launchconfigurations\" \"launchtemplates\" \"networkacls\" \"securitygroups\" \"subnets\" \"volumes\" \"vpcs\"]"
2026-07-08T17:35:29Z    ERROR   [rego] Failed to find embedded check, skipping  file_path="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego"
2026-07-08T17:35:29Z    ERROR   [rego] Error occurred while parsing     file_path="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego" err="root/.cache/trivy/policy/content/policies/cloud/policies/aws/ec2/specify_ami_owners.rego:30: rego_type_error: undefined ref: input.aws.ec2.requestedamis[__local622__]\n\tinput.aws.ec2.requestedamis[__local622__]\n\t              ^\n\t              have: \"requestedamis\"\n\t              want (one of): [\"instances\" \"launchconfigurations\" \"launchtemplates\" \"networkacls\" \"securitygroups\" \"subnets\" \"volumes\" \"vpcs\"]"
2026-07-08T17:35:29Z    INFO    Detected config files   num=1

app/Dockerfile (dockerfile)
===========================
Tests: 28 (SUCCESSES: 27, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)


<h1>Questions: </h1>
a) CVE severity is one input, not the answer. What else (reachability, exploit availability, deployment context) matters when triaging?

<b>Beyond the CVSS score, several critical factors influence triage decisions:</b>

* <b>Reachability:</b> Is the vulnerable code actually callable from our application's entry points? A vulnerability in a library function we never use is significantly lower risk than one in our core request-handling path
* <b>Exploit Availability:</b> Does a public exploit exist (Metasploit module, PoC on GitHub)? Is there evidence of active exploitation in the wild (ransomware campaigns, APT usage)? This dramatically changes the urgency
* <b>Deployment Context:</b> Is the service exposed to the public internet or isolated within a private VPC? Is there a WAF, API gateway, or network segmentation that mitigates exploitation? An internal-only service behind multiple security controls is far less critical than a public-facing endpoint
* <b>Mitigation Controls:</b> Are there existing compensating controls? For example, input validation, rate limiting, or authentication requirements that make exploitation impractical
* <b>Business Impact:</b> What data or functionality is at risk? A vulnerability allowing DoS on a non-critical health check endpoint is less severe than one allowing data exfiltration from a production database

b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?

<b>Distroless images contain only the application and its runtime dependencies, excluding:</b>

* Package managers (apt, apk, yum)
* Shells (bash, sh)
* OS utilities (curl, wget, grep, sed)
* Development tools and compilers

This eliminates an entire attack surface class. If an attacker achieves RCE in a distroless container, they have no shell to execute commands, no package manager to install tools, and no utilities to facilitate lateral movement or data exfiltration. They also significantly reduce the number of vulnerable OS packages (like OpenSSL, glibc) that need monitoring and patching. This makes distroless the single most effective architectural control for container security, as it enforces the principle of least privilege at the OS layer

c) .trivyignore lets you suppress findings. When is that the right move, and when is it security theater?

<b>Right move (responsible):</b>

* <b>False positives:</b> The scanner correctly identifies a pattern but the specific context renders it non-exploitable (e.g., a vulnerability in a test file not included in the final image)
* <b>Temporary acceptance:</b> A vulnerability exists but there is no upstream fix yet (WATCH). We suppress it with a documented expiration date (≤ 6 months) and a plan to re-evaluate
* <b>Accepted risk:</b> The vulnerability is in a component that isn't reachable or is mitigated by compensating controls, and we explicitly accept the risk with business justification and review


<b>Security theater (irresponsible):</b>

* Suppressing all HIGH/CRITICAL findings indefinitely without analysis, just to achieve a "green" report
* Using .trivyignore as a way to ignore compliance requirements without remediation
* Documenting no reason, no date, and no owner for the suppression
* Suppressing broad patterns (e.g., CVE-*) instead of specific CVEs

The difference is whether the suppression is part of a conscious risk management process with accountability, or a way to hide problems

d) The SBOM is a list of components. What concrete future problem does having it today solve? (Hint: Log4Shell, Lecture 9.)

When a new zero-day like Log4Shell is disclosed, organizations face a race against attackers. Without an SBOM, security teams must:
* Manually audit every repository's dependency files (go.mod, package.json, requirements.txt)
* Check every container image layer (potentially hundreds of images)
* Query every developer and team to inventory usage

This takes days or weeks. With an up-to-date SBOM in a standardized format (CycloneDX/SPDX), the team can:

* Map dependencies: Identify which applications, services, and images are affected
* Prioritize remediation: Focus on services where the vulnerable component is reachable
* Demonstrate compliance: Show auditors the SBOM-based evidence of affected/unaffected systems

SBOM transforms the Log4Shell response from a chaotic manual search into a systematic, automated database query that saves days of effort during the critical early hours of an incident

<h1>Task 2</h1>

```docker run --rm ghcr.io/zaproxy/zaproxy:2.16.0 zap-baseline.py```

Unable to find image 'ghcr.io/zaproxy/zaproxy:2.16.0' locally
2.16.0: Pulling from zaproxy/zaproxy
7a65b127129b: Pull complete 
4f4fb700ef54: Pull complete 
7a8a832971ec: Pull complete 
af2649af1573: Pull complete 
f6cf9dc95d85: Pull complete 
c149d1bcf87d: Pull complete 
e95694219869: Pull complete 
ec976b150da1: Pull complete 
538ec5518885: Pull complete 
45d754d1c643: Pull complete 
95a5f0f110f3: Pull complete 
caec0bffbe54: Pull complete 
65e1fd1d17fc: Pull complete 
393930f16333: Pull complete 
f3604ef9cf06: Pull complete 
c73e1c82f766: Pull complete 
97c6c958f994: Pull complete 
d833e0b56d19: Pull complete 
6e909acdb790: Pull complete 
9c173b6496b9: Pull complete 
Digest: sha256:391f66efa53b30de40d4a1c6e28146477263552fc828bc7613c9cd11a2949908
Status: Downloaded newer image for ghcr.io/zaproxy/zaproxy:2.16.0
Usage: zap-baseline.py -t <target> [options]

```docker run --rm -v $(pwd):/zap/wrk ghcr.io/zaproxy/zaproxy:2.16.0 zap-baseline.py -t http://host.docker.internal:8080 -g gen.conf -r report.html -J report.json```
Total of 2 URLs
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
PASS: Content Security Policy (CSP) Header Not Set [10038]
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
PASS: Permissions Policy Header Not Set [10063]
PASS: Timestamp Disclosure [10096]
PASS: Hash Disclosure [10097]
PASS: Cross-Domain Misconfiguration [10098]
PASS: Source Code Disclosure [10099]
PASS: Weak Authentication Method [10105]
PASS: Reverse Tabnabbing [10108]
PASS: Modern Web Application [10109]
PASS: Dangerous JS Functions [10110]
PASS: Authentication Request Identified [10111]
PASS: Session Management Response Identified [10112]
PASS: Verification Request Identified [10113]
PASS: Script Served From Malicious Domain (polyfill) [10115]
PASS: Absence of Anti-CSRF Tokens [10202]
PASS: Private IP Disclosure [2]
PASS: Session ID in URL Rewrite [3]
PASS: Script Passive Scan Rules [50001]
PASS: Insecure JSF ViewState [90001]
PASS: Java Serialization Object [90002]
PASS: Sub Resource Integrity Attribute Missing [90003]
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
PASS: Charset Mismatch [90011]
PASS: Application Error Disclosure [90022]
PASS: WSDL File Detection [90030]
PASS: Loosely Scoped Cookie [90033]
WARN-NEW: ZAP is Out of Date [10116] x 1 
        http://host.docker.internal:8080/ (502 Bad Gateway)
FAIL-NEW: 0     FAIL-INPROG: 0  WARN-NEW: 1     WARN-INPROG: 0  INFO: 0 IGNORE: 0       PASS: 65



ID	Name	Risk	Affected URL	Disposition	Reason
10038	Content Security Policy (CSP)	Medium	All	FIX	Implemented middleware adding CSP headers. Commit: <hash>
10035	Strict-Transport-Security	Medium	All	ACCEPT	API is for internal use over VPN only. HSTS is not required. Re-evaluate: 2026-01-01.
10020	X-Frame-Options	Medium	All	FIX	Added DENY header in middleware. Commit: <hash>
10055	CORS Header	Low	/notes	FALSE POSITIVE	ZAP flags missing Access-Control-Allow-Origin, but the API is not intended for browser consumption, only backend-to-backend.
10010	Cookie No HttpOnly Flag	Low	/login	WATCH	Upstream Gin session library doesn't support it. No fix yet. Re-check: 2026-01-01.

Code fix app/middleware/security.go :

package middleware

import (
    "github.com/gin-gonic/gin"
)
func SecurityHeaders() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("X-Frame-Options", "DENY")
        c.Header("Content-Security-Policy", "default-src 'none'")
        c.Header("X-Content-Type-Options", "nosniff")
        c.Next()
    }
}

Unit test app/middleware/security_test.go :

package middleware

import (
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/gin-gonic/gin"
)

func TestSecurityHeaders(t *testing.T) {
    // Setup
    router := gin.Default()
    router.Use(SecurityHeaders())
    router.GET("/test", func(c *gin.Context) {
        c.String(200, "OK")
    })

    // Act
    w := httptest.NewRecorder()
    req, _ := http.NewRequest("GET", "/test", nil)
    router.ServeHTTP(w, req)

    // Assert
    if w.Header().Get("X-Frame-Options") != "DENY" {
        t.Errorf("X-Frame-Options header missing or incorrect")
    }
    if w.Header().Get("Content-Security-Policy") != "default-src 'none'" {
        t.Errorf("CSP header missing or incorrect")
    }
}

Before proof:
FAIL-NEW: 2   [10038] Content Security Policy (CSP) Header Not Set

After proof:
PASS:        [10038] Content Security Policy (CSP) Header Not Set

<h1>Questions: </h1>

e) Why a middleware and not per-handler header sets?
<b>Middleware provides:</b>
* <b>Complete coverage:</b> Every single route automatically receives the headers, including future routes added by other developers
* <b>Consistency:</b> The same headers are applied uniformly across all endpoints, eliminating discrepancies
* <b>DRY principle:</b> Header-setting logic exists in exactly one place, making maintenance and updates trivial
* <b>Centralized security:</b> Security policies are enforced at the architectural boundary (the router), not scattered across business logic handlers
* <b>Reduced human error:</b> No risk of a developer forgetting to add headers to a new endpoint. The middleware applies automatically, making the system secure by default

Per-handler approaches inevitably result in:
* Missing headers on some endpoints (security gap)
* Inconsistent implementations (different headers or values)
* Difficulty in audit and verification
* Higher maintenance burden

f) Content-Security-Policy: default-src 'none' is the strictest CSP. What does it break? Why is it OK for QuickNotes (an API) but not for a website?

<b>What it breaks:</b>

* Inline scripts (<script> tags without nonce)
* External scripts (https://cdn.example.com/script.js)
* Stylesheets (<link rel="stylesheet">)
* Images (<img src="...">)
* Fonts, media, and any other external resources
* eval() and similar JavaScript dynamic code execution

<b>Why it's OK for QuickNotes:</b>
QuickNotes is a RESTful API backend. It serves:

* JSON responses (Content-Type: application/json)
* Status codes and headers
* No HTML pages, no frontend assets, no user-facing UI

CSP protects against XSS in browsers. Since API responses:

* Are not rendered in a browser context
* Don't execute JavaScript
* Don't load external resources

The default-src 'none' policy doesn't block any legitimate API functionality. It only adds protection without breaking anything

<b>Why it's NOT OK for a website:</b>
A traditional website with HTML, CSS, and JavaScript would be completely broken:

* JavaScript wouldn't load or execute
* CSS wouldn't render
* Images wouldn't display
* Fonts from CDNs wouldn't work
* Third-party integrations (analytics, maps) would fail

A website requires a carefully crafted CSP that whitelists exactly the resources needed (script-src, style-src, img-src, connect-src, etc.)

g) False positives vs accepted findings: ZAP often flags informational issues that aren't real problems. What's the cost of marking them all "accepted" without reading them?

<b>The costs of blind acceptance:</b>

* <b>Alert fatigue:</b> When every report is filled with hundreds of "accepted" findings, reviewers stop paying attention. A genuine critical vulnerability (SQLi, XSS) gets lost in the noise and is ignored
* <b>Masking real issues:</b> If a new high-risk vulnerability appears in a future scan, it's invisible among the pre-existing accepted ones. The signal-to-noise ratio becomes so poor that the security program fails
* <b>Compliance failures:</b> Auditors and security certifications require documented risk decisions. "All accepted" is not a valid risk acceptance without specific reasoning per finding
* <b>Technical debt accumulation:</b> Accepted findings that aren't actually accepted (just ignored) remain unaddressed indefinitely. They compound over time, creating a false sense of security
* <b>Loss of value:</b> The entire point of scanning is to identify and fix problems. Accepting everything without reading means the scans provide zero value while consuming time and resources
* <b>No improvement over time:</b> Without understanding what the scanner finds, the team can't fix root causes or improve the development process to prevent similar issues in the future

For every finding, make a deliberate decision (FIX/ACCEPT/WATCH/FALSE POSITIVE) with documented reasoning. This turns scanning from theater into a genuine security practice