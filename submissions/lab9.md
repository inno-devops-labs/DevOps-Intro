# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

> Lab done on my MacBook Air M4. Builds on lab 6  and
> lab 3 (CI). I installed Trivy via `brew`, ran ZAP from its container, and
> pinned govulncheck in the CI.

What I have done?

---

## Task 1 — Trivy: image + filesystem + config + SBOM

### Image scan
```
$ ephy@Starless-night DevOps-Intro % trivy image --severity HIGH,CRITICAL quicknotes:lab6 
Detected OS family="debian" version="13.5"

Report Summary
┌───────────────────────────────┬──────────┬─────────────────┬─────────┐
│            Target             │   Type   │ Vulnerabilities │ Secrets │
├───────────────────────────────┼──────────┼─────────────────┼─────────┤
│ quicknotes:lab6 (debian 13.5) │  debian  │        0        │    -    │
│ healthcheck                   │ gobinary │       12        │    -    │
│ quicknotes                    │ gobinary │       12        │    -    │
└───────────────────────────────┴──────────┴─────────────────┴─────────┘

quicknotes & healthcheck (gobinary) — Total: 12 each (HIGH: 12, CRITICAL: 0)
Library stdlib, Installed v1.24.13, all fixed in 1.25.x / 1.26.x:
  CVE-2026-25679  net/url: incorrect parsing of IPv6 host literals
  CVE-2026-27145  crypto/x509: VerifyHostname / matchHostnames
  CVE-2026-32280  crypto/x509, crypto/tls: DoS in certificate chain building
  CVE-2026-32281  crypto/x509: DoS via inefficient cert chain validation
  CVE-2026-32283  crypto/tls: DoS via multiple TLS 1.3 keys
  CVE-2026-33811  net: DoS via long CNAME response
  CVE-2026-33814  net/http http2: DoS via malformed SETTINGS_MAX_FRAME_SIZE frame
  CVE-2026-39820  net/mail: DoS in ParseAddress / ParseAddressList
  CVE-2026-39823  net/url: URL parsing (follow-up to CVE-2026-27142)
  CVE-2026-39836  golang security update (ELSA-2026-22121)
  CVE-2026-42499  net/mail: DoS via consumePhrase
  CVE-2026-42504  mime: DoS decoding a malicious MIME header
```

### Filesystem scan
```
$ ephy@Starless-night DevOps-Intro % trivy fs --severity HIGH,CRITICAL . 
┌──────────────────────────────────────────────────┬───────┬─────────────────┬─────────┐
│                      Target                      │ Type  │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────┼───────┼─────────────────┼─────────┤
│ app/go.mod                                       │ gomod │        0        │    -    │
│ .vagrant/machines/default/virtualbox/private_key │ text  │        -        │    1    │
└──────────────────────────────────────────────────┴───────┴─────────────────┴─────────┘

.vagrant/machines/default/virtualbox/private_key (secrets) — Total: 1 (HIGH: 1, CRITICAL: 0)
  HIGH: AsymmetricPrivateKey (private-key)
  .vagrant/machines/default/virtualbox/private_key:2-7
  -----BEGIN OPENSSH PRIVATE KEY-----   (Vagrant's per-machine insecure key)
```

### Config scan (Dockerfile, compose)
```
$ephy@Starless-night DevOps-Intro % trivy config .
Report Summary
┌────────────────┬────────────┬───────────────────┐
│     Target     │    Type    │ Misconfigurations │
├────────────────┼────────────┼───────────────────┤
│ app/Dockerfile │ dockerfile │         0         │
└────────────────┴────────────┴───────────────────┘
```

### CycloneDX SBOM — first 30 lines
```
$ ephy@Starless-night DevOps-Intro % trivy image --format cyclonedx --output sbom.cdx.json quicknotes:lab6
$ ephy@Starless-night DevOps-Intro % head -n 30 sbom.cdx.json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:8d7b52bf-a3c2-477c-8ba9-827e623c973c",
  "version": 1,
  "metadata": {
    "timestamp": "2026-06-25T08:25:21+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "manufacturer": {
            "name": "Aqua Security Software Ltd."
          },
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.71.1"
        }
      ]
    },
    "component": {
      "bom-ref": "pkg:oci/quicknotes@sha256:06fd9c6ae0469e2892313882e97fd52bec6cc4c2c50482b74ee88126431b5b6d?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256:06fd9c6ae0469e2892313882e97fd52bec6cc4c2c50482b74ee88126431b5b6d?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:0264862bb5e01e545e46799c90b8b0fedbb1f0241330d10b6172c0570d33d042"
```

### Triage

> Reading the scans: distroless base = **0 OS-package CVEs** and **0 misconfigs**,
> deps = **0** (no `go.sum`). The only HIGHs are the **12 Go-stdlib CVEs**  -  into
> both Go binaries (because pinned **Go 1.24.13** EOL ) and
> **1 secret** (the gitignored Vagrant key picked up by `trivy fs`).

| # | Finding (CVE / ID) | Scan | Severity | Component | Disposition | Reason + re-eval date |
|---|--------------------|------|----------|-----------|-------------|------------------------|
| 1 | OS packages | image (debian 13.5) | — | distroless base | **N/A** | **0** HIGH/CRITICAL in the OS layer — minimal base, nothing to patch.|
| 2 | 12× Go stdlib CVEs: CVE-2026-25679, -27145, -32280, -32281, -32283, -33811, -33814, -39820, -39823, -39836, -42499, -42504 | image (gobinary — both `quicknotes` + `healthcheck`) | HIGH | Go stdlib **v1.24.13** | **WATCH** | All come from the pinned **Go 1.24.13** (EOL Feb 2026). There is no option rather than watch - 1.24.13 was chosen by lab requirements(actually, I might choose 1.25.x...). To **fix** them mean to change version:  `golang:1.24.13` → `golang:1.25.x` in `app/Dockerfile` and rebuild. Under the lab's Go 1.24 pin it stays **WATCH** until. In general case of "Watch" decision, I should put re-check date, say, one month, for example. 
| 3 | `app/go.mod` dependencies | fs (gomod) | — | repo deps | **N/A** | **0** — QuickNotes has zero third-party deps, no `go.sum`, nothing to be vulnerable. |
| 4 | AsymmetricPrivateKey (secret) | fs | HIGH | `.vagrant/.../private_key` | **ACCEPT** | It's Vagrant's per-machine **insecure throwaway** SSH key, in gitignored `.vagrant/` — never committed, never pushed, regenerated on every `vagrant up`. Real exposure ≈ none. I would silence it on purpose: `echo '.vagrant/' >> .trivyignore` . |
| 5 | `app/Dockerfile` misconfig | config (dockerfile) | — | Dockerfile | **N/A** | **0** misconfigs — distroless + `USER 65532` (nonroot); compose adds `read_only`, `cap_drop: ALL`, `no-new-privileges` - protection|



### Design questions

**a) CVE severity is one input — what else matters?**
Severity (CVSS) just says how bad it would be if exploited — not whether it matters
here. What actually drives my call: **reachability** — do we even call the
vulnerable function? A CVE in a code path QuickNotes never hits is basically noise.
Exploit availability — is there a publicly desribed or is it
theoretical? And deployment context — QuickNotes runs distroless, nonroot,
read-only, no shell, not exposed to the internet in the lab, so the blast radius is
tiny even for a HIGH. A remote-exploitable HIGH on a reachable, internet-facing path
beats  CRITICAL buried in a function I will never call. Severity sorts the queue,
context decides what I actually do.

**b) Distroless shows ~zero HIGH/CRITICAL**

Because you can not be vulnerable to what is not there. A normal ubuntu/debian base
ships hundreds of packages — shell, apt, curl — all this stuff is
attack surface and a future CVE. distroless `static:nonroot` has nothing basically no OS userland — just my static Go binary and certs. One base-image choice kills more risk than any single patch.

**c) `.trivyignore`**
Right move: documented + dated acceptance — you triaged the finding, it's a
false positive / unreachable / no fix yet, and you write down why + when you'll
re-check. 

Security theater: dumping findings into `.trivyignore` just to turn the
scan green without reading them — that's hiding the problem, not solving process.
you just stopped seeing it. 

Common rule: ignore with  reason and a date, never keep it silently.

**d) The SBOM**
The "am I affected?" paranoia. 

Suppose new Log4Shell package drops,  CVE in some deep
transitive dependency, the question is "do we even ship that, and where?". Without
an SBOM you're grepping repos at 3AM across every service. With an SBOM - 
machine-readable list of every component + version in the image -  you answer it in
seconds: yes/no, which image, which version. Basically, just convinient look up method: to be sure that we are safe or not.

---

## Task 2 — OWASP ZAP baseline + fix one finding in code

### ZAP baseline run (passive only)
QuickNotes running locally (lab 6 compose). ZAP in a container hits it via
`host.docker.internal`, image pinned to `2.17.0`. One catch I hit on the way:
QuickNotes has **no `/` route**, so scanning the bare root gives the spider three
404s (`/`, `/robots.txt`, `/sitemap.xml`) and the passive header rules stay silent
on error responses — the scan looks green while checking nothing. So the target is
a real endpoint, `/notes`:

```
ephy@Starless-night DevOps-Intro % docker run --rm -v "$PWD:/zap/wrk:rw" -t ghcr.io/zaproxy/zaproxy:2.17.0 \
    zap-baseline.py -t http://host.docker.internal:8080/notes \
    -r zap-report-before.html

WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
	http://host.docker.internal:8080/notes (200 OK)
WARN-NEW: Storable and Cacheable Content [10049] x 4
	http://host.docker.internal:8080/ (404 Not Found)
	http://host.docker.internal:8080/notes (200 OK)
	http://host.docker.internal:8080/robots.txt (404 Not Found)
	http://host.docker.internal:8080/sitemap.xml (404 Not Found)
WARN-NEW: Cross-Origin-Resource-Policy Header Missing or Invalid [90004] x 1
	http://host.docker.internal:8080/notes (200 OK)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 3	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 64
```

(the leftover spider error  404 expected 200 plan warning is the spider still
poking `/` — a web crawler pointed at a JSON API with no root - harmless)

### Triage — every ZAP finding

| ID | Name | Risk | URL / param | Disposition | Reason |
|----|------|------|-------------|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | `GET /notes` (200) | **FIX** | Fixed in code — `securityHeaders` middleware sets `X-Content-Type-Options: nosniff` on every route. Gone in the after-scan. |
| 90004 | Cross-Origin-Resource-Policy Header Missing or Invalid | Low | `GET /notes` (200) | **FIX** | Same middleware sets `Cross-Origin-Resource-Policy: same-origin` — nobody legitimately embeds this API cross-origin. Gone in the after-scan. |
| 10049 | Storable and Cacheable Content | Informational | `/`, `/notes`, `/robots.txt`, `/sitemap.xml` | **ACCEPT** | Responses carry no Cache-Control at all, so shared proxies may cache them. Demo notes, no auth, no per-user data — shared-cache leakage is a non-issue here.|

### The fix — security-headers middleware (all routes, not per-handler)

`app/middleware.go`:
```go
package main

import "net/http"

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("Cross-Origin-Resource-Policy", "same-origin")
		next.ServeHTTP(w, r)
	})
}
```

One-line wire-up in `app/main.go` (wrap the whole router):
```go
		Handler:           securityHeaders(server.Routes()),
```

Guard test `app/middleware_test.go` (fails if the middleware/wrap is removed):
```go
func TestSecurityHeaders(t *testing.T) {
	srv := newTestServer(t)
	handler := securityHeaders(srv.Routes())
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	want := map[string]string{
		"X-Content-Type-Options":  "nosniff",
		"X-Frame-Options":         "DENY",
		"Content-Security-Policy": "default-src 'none'",
		"Referrer-Policy":         "no-referrer",
		"Cross-Origin-Resource-Policy": "same-origin",
	}
	for header, value := range want {
		if got := rec.Header().Get(header); got != value {
			t.Errorf("header %s = %q, want %q", header, got, value)
		}
	}
}
```

Test passes (and `go vet` is clean):
```text
ephy@Starless-night DevOps-Intro % cd app && go test -run TestSecurityHeaders -v ./...
=== RUN   TestSecurityHeaders
--- PASS: TestSecurityHeaders (0.00s)
PASS
ok  	quicknotes	0.444s
?   	quicknotes/healthcheck	[no test files]
```

### Re-scan — the findings are gone

The most direct before/after is the raw response. Before (middleware not wired):

```text
ephy@Starless-night DevOps-Intro %  curl -si http://localhost:8080/notes | head -8
HTTP/1.1 200 OK
Content-Type: application/json
Date: Sat, 04 Jul 2026 07:07:07 GMT
Transfer-Encoding: chunked
```

After:

```text
$ curl -si http://localhost:8080/notes | head -12
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'
Content-Type: application/json
Cross-Origin-Resource-Policy: same-origin
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Date: Sat, 04 Jul 2026 07:16:50 GMT
Transfer-Encoding: chunked
```

And ZAP agrees — same baseline command against `/notes`

```text
PASS: X-Content-Type-Options Header Missing [10021]
PASS: Insufficient Site Isolation Against Spectre Vulnerability [90004]
WARN-NEW: Storable and Cacheable Content [10049] x 3
	http://host.docker.internal:8080/ (404 Not Found)
	http://host.docker.internal:8080/notes (200 OK)
	http://host.docker.internal:8080/sitemap.xml (404 Not Found)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 66
```

Both fixed findings moved WARN → PASS; the only WARN left is the accepted 10049.
(10049 is the spider nondeterministically grabbing
robots.txt/sitemap.xml, just a noise, not signal.)

### Design questions

**e) Why a middleware and not per-handler header sets?**
One place, every route, can't forget one. If I set headers inside each handler I would
have to remember to add them to every new endpoint — and the day I forget `/notes`,
that route ships with no protection. Middleware wraps the whole router once, so every current and
future route gets the headers automatically. Less code, no drift, and the test
guards it.

**f) `Content-Security-Policy: default-src 'none'` — what does it break, why OK for an API but not a website?**
`default-src 'none'` blocks everything — no scripts, styles, images, fonts, frames
from anywhere. For a website that is death: the page can not even load its own CSS/JS.
But QuickNotes is a JSON API — it serves no HTML, no browser ever renders it as a
page, so there's nothing to break. So I get the strictest possible CSP for free. On
a real site you would have to allowlist exactly what you load 
instead of `'none'`.

**g) False positives vs accepted findings — cost of marking them all "accepted" without reading?**
You turn the scanner into noise you have trained yourself to ignore. ZAP gives a lot
of informational stuff. If you blanket-accept everything without reading, the one
finding that actually matters gets accepted too, no discussion. "Accepted" should mean "I
read it, understood it, here's why it is fine" — not just clicke. This is similar with  alert fatigue

---

## Bonus Task — `govulncheck` as a CI PR gate

Added a `govulncheck` job to the lab 3 CI (`.github/workflows/ci.yml`). It's pinned
(not `@latest`), runs against `app/`, and has its own status check — a reachable Go
vuln fails it and blocks the PR. One deliberate deviation from the lab text: the job
runs on Go **1.25.x**, not 1.24 like the rest of CI — the gate itself forced that
decision on its very first run, see below.

```yaml
  govulncheck:
    name: govulncheck
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
      - uses: actions/setup-go@40f1582b2485089dde7abd97c1529aa768e1baff # v5.6.0
        with:
          go-version: "1.25.x"
          cache: true
          cache-dependency-path: app/go.mod
      - name: Install govulncheck (pinned, not @latest)
        run: go install golang.org/x/vuln/cmd/govulncheck@v1.1.4
      - name: Run govulncheck
        run: govulncheck ./...
```

### So, why I took 1.25.x

First run, clean code, zero third-party deps — and the job went **red** anyway:
with `go-version: "1.24.x"` govulncheck evaluates the stdlib of the analyzing
toolchain (1.24.13, EOL), and found **9 reachable stdlib vulnerabilities** — all
fixed only in 1.25.x, so under 1.24 they are unfixable:
Red run: 

!["prered"](prered.png)

Decision: the
gate moves to a supported toolchain (1.25.x) so it can ever be green and keeps
blocking on new findings; the shipped image stays on `golang:1.24.13` per the
lab pin, and those stdlib CVEs remain WATCHed in the Task 1 triage table. A gate
that is red forever is not a gate — everyone just learns to ignore it (same alert-
fatigue rule as lab 8).

I changed to 1.25: 

!["1.25 fix"](good_with_25.png)

### Bad dep catch
QuickNotes has no deps, so I temporarily add a known-vulnerable one and call it, push,
watch the gate go red, then revert.

```

import "golang.org/x/text/language"


func init() { 
	_, _, _ = language.ParseAcceptLanguage("en-US,en;q=0.9") 
}
```


1. CI `govulncheck` job goes red:
   
  !["catch bad dep"](bad_dep.png)

2. CI `govulncheck` job back to 
**green**:

  !["catch bad dep"](green_dep.png)
   
   


### Design questions

**h) Reachability — "module has a CVE but we don't call the affected function" vs "module has a CVE" — what it means for triage workload.**
Huge difference in how much you actually have to do. "Module has a CVE" (what Trivy /
plain SCA says) flags every dependency that contains vulnerable code — including
CVEs in functions you never call, so you drown in findings that don't affect you.
govulncheck does **reachability**: it only flags a CVE if your code actually calls
into the vulnerable function through the call graph. So instead of triaging 50
"present" CVEs you triage the 3 that are genuinely reachable. 

**i) Why pin the version of govulncheck instead of `@latest`?**
Same reason you pin anything in CI — reproducibility and no surprises. `@latest`
means tomorrow's release can change behaviour, add checks, or just break, and CI goes
red (or green) for reasons unrelated to my code — and two runs of the "same" commit
aren't the same. Pinning `@v1.1.4` makes the gate deterministic

**j) govulncheck only knows Go — what won't it catch that Trivy (image scan) would?**
It only sees the Go module graph + stdlib. It's blind to everything else in the
image: OS packages (the debian/alpine layer — openssl, libc, apt), system binaries,
non-Go stuff, base-image CVEs, Dockerfile misconfigs. Trivy's image scan catches
those.