# Lab 9 — DevSecOps: Trivy + ZAP on QuickNotes

**Branch:** `feature/lab9`
**Base commit:** `e32dc95` (Lab 6 — multi-stage Dockerfile + hardening); PR target = course `main`.
**Scope:** Task 1 (Trivy: image + fs + config + SBOM + triage) + Task 2 (ZAP baseline + security-headers fix). Bonus (govulncheck CI gate) intentionally skipped.

---

## TL;DR

- Trivy scanned the `quicknotes:lab6` image (**22 HIGH** — 11 stdlib CVEs × 2 gobinaries), repo filesystem (**1 HIGH** — Vagrant-insecure `private_key` false positive), and Dockerfile/compose configs (**0 HIGH/CRITICAL**, 1 LOW: HEALTHCHECK).
- CycloneDX SBOM emitted (12 components — 5 distroless base packages + 2 gobinaries with Go stdlib).
- ZAP baseline (2.16.1) against the running container flagged **1 WARN**: `X-Content-Type-Options Header Missing [10021]` on `GET /notes`.
- Fixed in code as `securityHeaders` middleware wrapping the router — sets `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Content-Security-Policy: default-src 'none'`, `Referrer-Policy: no-referrer` on **every** route. Guarded by a table-driven test covering health, list, get-by-id, metrics — fails if the wrapper is removed.
- Rebuilt image; re-ran ZAP; the WARN is gone. `FAIL-NEW: 0    WARN-NEW: 0    PASS: 58`.

Artifacts under [`submissions/lab9/`](./lab9/) — Trivy stdout for each of the four scans, ZAP HTML+JSON+console before/after, SBOM.

---

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

**Trivy version pin:** `aquasec/trivy:0.59.1` (via podman docker-compat).

Persistent DB cache mounted at `/tmp/trivy-cache` — first run downloaded `mirror.gcr.io/aquasec/trivy-db:2` (~165 KB after decompression); subsequent runs offline for DB.

### 1.1 Scan outputs (heads)

#### 1.1.1 Image scan — `quicknotes:lab6`

Command:

```
docker save quicknotes:lab6 -o /tmp/quicknotes-lab6.tar
docker run --rm -v /tmp/trivy-cache:/root/.cache/trivy \
  -v /tmp/quicknotes-lab6.tar:/img.tar:ro \
  aquasec/trivy:0.59.1 image --input /img.tar \
  --severity HIGH,CRITICAL --scanners vuln,secret --no-progress
```

Head of output ([`submissions/lab9/trivy/image-scan.txt`](./lab9/trivy/image-scan.txt)):

```
2026-07-07T20:29:51Z INFO Detected OS  family="debian" version="12.14"
2026-07-07T20:29:51Z INFO [debian] Detecting vulnerabilities...  pkg_num=4
2026-07-07T20:29:51Z INFO Number of language-specific files  num=2
2026-07-07T20:29:51Z INFO [gobinary] Detecting vulnerabilities...

/img.tar (debian 12.14)
=======================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 11 (HIGH: 11, CRITICAL: 0)
 …[table of 11 stdlib CVEs, Go 1.24.13 → fixed 1.25.8+ / 1.26.1+]…

quicknotes (gobinary)
=====================
Total: 11 (HIGH: 11, CRITICAL: 0)
 …[same 11 stdlib CVEs]…
```

Distroless base **0** vulns. Both Go binaries pick up the **same 11 stdlib CVEs** because they were built from the identical `golang:1.24.13-alpine` builder stage.

#### 1.1.2 Filesystem scan — repo working tree

Command:

```
docker run --rm -v /tmp/trivy-cache:/root/.cache/trivy \
  -v /home/karim/Dev/DevOps-Intro:/repo:ro \
  aquasec/trivy:0.59.1 fs /repo \
  --severity HIGH,CRITICAL --scanners vuln,secret,misconfig --no-progress
```

Full findings ([`submissions/lab9/trivy/fs-scan.txt`](./lab9/trivy/fs-scan.txt)):

```
2026-07-07T20:30:17Z INFO Number of language-specific files  num=1
2026-07-07T20:30:17Z INFO [gomod] Detecting vulnerabilities...
2026-07-07T20:30:17Z INFO Detected config files  num=1

.vagrant/machines/default/libvirt/private_key (secrets)
=======================================================
Total: 1 (HIGH: 1, CRITICAL: 0)

HIGH: AsymmetricPrivateKey (private-key)
```

`go.mod` — no HIGH/CRITICAL. One Dockerfile detected — no HIGH/CRITICAL misconfigs. Only finding: the Vagrant *well-known insecure* SSH key stored in `.vagrant/` (created by Lab 5). It is not tracked by git (`.gitignore` line `.vagrant/`) and is a publicly-published key with a documented public counterpart — see [`vagrant-insecure_private_key`](https://github.com/hashicorp/vagrant/blob/main/keys/vagrant.pub). Disposition below.

#### 1.1.3 Config scan — Dockerfile + compose

Command:

```
docker run --rm -v /tmp/trivy-cache:/root/.cache/trivy \
  -v /home/karim/Dev/DevOps-Intro:/repo:ro \
  aquasec/trivy:0.59.1 config /repo --severity HIGH,CRITICAL
```

`--severity HIGH,CRITICAL` filter output ([`submissions/lab9/trivy/config-scan.txt`](./lab9/trivy/config-scan.txt)) — 0 findings.

Unfiltered run showed one LOW ([`submissions/lab9/trivy/config-scan-all.txt`](./lab9/trivy/config-scan-all.txt)):

```
app/Dockerfile (dockerfile)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AVD-DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

Below HIGH/CRITICAL cut, and false positive besides: healthcheck runs at the **compose** level (`healthcheck: test: ["CMD", "/healthcheck"]`) rather than as a `HEALTHCHECK` line inside the Dockerfile — Trivy's Dockerfile-only view can't see that.

#### 1.1.4 CycloneDX SBOM

Command:

```
docker run --rm -v /tmp/trivy-cache:/root/.cache/trivy \
  -v /tmp/quicknotes-lab6.tar:/img.tar:ro \
  -v ./submissions/lab9/trivy:/out \
  aquasec/trivy:0.59.1 image --input /img.tar \
  --format cyclonedx --output /out/sbom.cyclonedx.json --no-progress
```

Head of `sbom.cyclonedx.json` (first 30 lines):

```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:e0cf6ad0-5c26-48ea-8c90-ea357999b98b",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T20:31:30+00:00",
    "tools": {
      "components": [
        {
          "type": "application",
          "group": "aquasecurity",
          "name": "trivy",
          "version": "0.59.1"
        }
      ]
    },
    "component": {
      "bom-ref": "3b835356-6e2e-47d8-a3db-3032fcd694fd",
      "type": "container",
      "name": "/img.tar",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:0394064ba4f0e158620900870ed87401ef71cd4c416c61c93745fed3b300f8fc"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:114dde0fefebbca13165d0da9c500a66190e497a82a53dcaabc3172d630be1e9"
```

Components identified: `base-files`, `debian`, `media-types`, `netbase`, `tzdata` (distroless OS layer) + `healthcheck`, `quicknotes` (gobinary) + Go `stdlib`. **12 components total.** Full file at [`submissions/lab9/trivy/sbom.cyclonedx.json`](./lab9/trivy/sbom.cyclonedx.json).

### 1.2 Triage — every HIGH/CRITICAL

The 11 stdlib CVEs appear in **both** `quicknotes` and `healthcheck` binaries (same Go builder stage). Same disposition applies to each pair — one row per unique CVE below.

| Finding | Where | Severity | Disposition | Reason & re-eval date |
|---|---|---|---|---|
| **CVE-2026-25679** — `net/url` IPv6 host parsing | image / stdlib (both bins) | HIGH | **ACCEPT** | Not reachable: QuickNotes accepts only plain HTTP paths (`/notes`, `/notes/{id}`, `/health`, `/metrics`) — never parses external URLs via `net/url`. Fixed in Go 1.25.8. Re-evaluate on next Dockerfile bump (**2026-08-07**). |
| **CVE-2026-27145** — `crypto/x509` DNS DoS | image / stdlib | HIGH | **ACCEPT** | Not reachable: distroless container serves plain HTTP, never validates X.509 chains. Fixed 1.25.11. Re-eval **2026-08-07**. |
| **CVE-2026-32280** — `crypto/x509` cert-chain DoS | image / stdlib | HIGH | **ACCEPT** | Same rationale: no TLS handshake in the container. Re-eval **2026-08-07**. |
| **CVE-2026-32281** — `crypto/x509` chain validation DoS | image / stdlib | HIGH | **ACCEPT** | Same. Re-eval **2026-08-07**. |
| **CVE-2026-32283** — `crypto/tls` TLS 1.3 DoS | image / stdlib | HIGH | **ACCEPT** | No TLS surface. Re-eval **2026-08-07**. |
| **CVE-2026-33811** — `net` CNAME DoS | image / stdlib | HIGH | **ACCEPT** | QuickNotes does not resolve external hostnames (in-container storage is a file on a bind mount). Re-eval **2026-08-07**. |
| **CVE-2026-33814** — HTTP/2 `SETTINGS_MAX_FRAME_SIZE` DoS | image / stdlib | HIGH | **ACCEPT** | `net/http` server on Go 1.24 only enables HTTP/2 when TLS is configured; we serve plain HTTP. Not reachable. Re-eval **2026-08-07**. |
| **CVE-2026-39820** — `net/mail` DoS | image / stdlib | HIGH | **ACCEPT** | We do not parse emails. Re-eval **2026-08-07**. |
| **CVE-2026-39836** — Oracle Linux `golang` bundle | image / stdlib | HIGH | **ACCEPT** | Vendor-side bundle CVE covering the above `net/*` DoS set. Same rationale. Re-eval **2026-08-07**. |
| **CVE-2026-42499** — `net/mail` pathological addr DoS | image / stdlib | HIGH | **ACCEPT** | No email parsing. Re-eval **2026-08-07**. |
| **CVE-2026-42504** — MIME header decode DoS | image / stdlib | HIGH | **ACCEPT** | No MIME parsing. Re-eval **2026-08-07**. |
| **AsymmetricPrivateKey** in `.vagrant/…/private_key` | fs / secrets | HIGH | **FALSE POSITIVE** | Vagrant *insecure* well-known key — private counterpart of a publicly-published pubkey shipped with Vagrant for dev-VM bootstrap. `.vagrant/` is in `.gitignore`; the key never enters the repo, only the local Lab 5 workspace. Trivy secret-scanner has no way to distinguish "well-known dev key" from "real". |

**All 11 unique stdlib CVEs are DoS-only** (no RCE, no data exfiltration). All are reachable only via specific attack vectors (TLS handshake, x509 chain, HTTP/2 frames, net/mail, DNS CNAME) that QuickNotes' **distroless-static + plain-HTTP + file-backed store** deployment does not expose. A cleaner "FIX" path would be bumping the builder to `golang:1.25.11-alpine` in a follow-up Lab 6 commit — logged as a planned upgrade rather than a Lab 9 change to keep the diff focused.

### 1.3 Design questions

**a) CVE severity is one input, not the answer. What else matters?**

Beyond CVSS the important axes are:

- **Reachability** — does our binary actually call the vulnerable function? A CVSS-9 stdlib CVE in `crypto/x509` is meaningless if we never validate certificates. This is why `govulncheck` (call-graph-aware) triages far tighter than Trivy (module-presence-aware) — see (j) for the reciprocal.
- **Exploit availability** — public PoC, Metasploit module, weaponisation, in-the-wild reports. A CVSS-6 with a working exploit is often more urgent than a CVSS-9 without one.
- **Deployment context** — public-facing vs internal-only; direct exposure vs behind a reverse proxy that terminates TLS; multi-tenant vs single-tenant; sensitive vs commodity data.
- **Compensating controls** — WAF rules, rate limits, network policies, mTLS. A vulnerable component fronted by a strict WAF may not be exploitable.
- **Blast radius on exploit** — RCE > auth bypass > info disclosure > DoS. Our 11 findings are all "DoS", which is the least severe class and often equivalent to "someone can waste our CPU".
- **Time-to-remediate** — how long from now until patch? A CVE fixed upstream today with an unmergeable bump for us is different from a still-open zero-day.

**b) Distroless images often show zero HIGH/CRITICAL. Why is the minimal base the strongest single security control?**

Nearly every image-scan finding on a "normal" container is a base-OS package CVE — `openssl`, `curl`, `glibc`, `python`, `bash`. Those are ambient dependencies pulled in by the base image, not chosen by the application. A minimal base has **almost no such packages** — our distroless base ships `base-files`, `netbase`, `tzdata`, `ca-certificates`, and glibc, and that's the whole package set. So the class of "CVE announced against a package we happen to ship" is nearly extinguished. In our scan the debian 12.14 layer registered **0 HIGH/CRITICAL** despite Trivy checking all four packages.

Two second-order wins compound this:

1. **No shell = no shell chain**. Even if the app itself is popped, an attacker landing arbitrary code cannot pivot via `sh -c` or `curl | sh`, cannot exec arbitrary binaries — the image doesn't contain any.
2. **Predictable inventory**. When the next Log4Shell-style zero-day drops, you can answer "am I affected?" by inspection: with 5 base packages the answer is obvious. On a full `debian:slim` you must actually run a scan.

**c) `.trivyignore` — when right vs security theater?**

Right, when:
- The finding is genuinely non-applicable to your context (unreachable code path, wrong platform, disabled feature) — and you've written that context down alongside the ignore.
- The ignore has an **expiry date**. `# expires 2026-08-01 — bump Go to 1.25.11` is legitimate. `# nosniff issue, ignore` is not.
- The pointer to the accepting decision is one commit-message search away.

Theater when:
- It exists to make CI green without a triage step.
- CVEs pile up without comments — nobody reviewing the file knows what's actually accepted vs merely hidden.
- The ignore has no expiry — it becomes a permanent rug-pull; the next person assumes the previous person made a real decision.

Rule of thumb: if you can't defend the ignore in one sentence during a security review, delete it.

**d) The SBOM — what future problem does having it today solve?**

The Log4Shell problem: on 2021-12-09, `log4j-core 2.14.1 ≤ x ≤ 2.14.1` became actively exploited RCE. Every enterprise scrambled to answer "do we run this?" — most could not, because they had no committed inventory of what versions shipped in what image. Teams spent days scanning production images, backfilling data, checking every service, before they could even *start* patching.

An SBOM committed alongside the release turns this into: `grep '"name": "log4j-core"' sboms/*.json | grep 2.14.1`. Fifteen seconds instead of two days. Same story for the Struts CVE-2017-5638 that Equifax rode into a 147M-record breach — GAO's 2018 report is explicit that Equifax's asset-inventory problem was the root cause, not the CVE.

Ship-time SBOMs prepare you for a class of incidents where **the difference between panic and calm is inventory speed**, not fix speed. The SBOM is cheap insurance for that day.

---

## Task 2 — OWASP ZAP Baseline + Security-Headers Middleware

**ZAP version pin:** `ghcr.io/zaproxy/zaproxy:2.16.1`.
**Target:** `http://127.0.0.1:8080` (Lab 6 compose default binding). Scan seeded at `/notes`, not `/` — see pitfall #2.

### 2.1 Baseline run — before fix

Command:

```
docker run --rm --net=host \
  -v ./submissions/lab9/zap:/zap/wrk:rw \
  ghcr.io/zaproxy/zaproxy:2.16.1 \
  zap-baseline.py -t http://127.0.0.1:8080/notes \
    -J baseline-before.json -r baseline-before.html \
    -z "-silent" \
    -T 3 -m 1
```

Result (full console at [`submissions/lab9/zap/baseline-before-console.txt`](./lab9/zap/baseline-before-console.txt)):

```
Total of 5 URLs
PASS: … (57 rules omitted, all PASS)
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
    http://127.0.0.1:8080/notes (200 OK)
FAIL-NEW: 0    FAIL-INPROG: 0    WARN-NEW: 1    WARN-INPROG: 0    INFO: 0    IGNORE: 0    PASS: 57
```

One WARN, no FAIL. That is the whole finding surface for a JSON-only API behind a distroless container.

### 2.2 Triage — every ZAP finding

Baseline classifies each of the ~58 active passive-scan rules per site. **57 PASSED** (i.e. rule executed against actual scanned responses and found no violation); **1 WARN-NEW**. The single active finding + a representative sample of the PASS'd rules that are still worth commenting on:

| Rule ID | Rule | URL / where | Risk | Disposition | Reason |
|---|---|---|---|---|---|
| **10021** | X-Content-Type-Options Header Missing | `GET /notes` (200) | Low (WARN) | **FIX** | Landed as `securityHeaders` middleware — see §2.3 diff. Fix verified in §2.4 rescan. |
| 10020 | Anti-Clickjacking Header | (not fired) | — | (proactively fixed) | Same middleware sets `X-Frame-Options: DENY`. |
| 10038 | Content Security Policy Header Not Set | (not fired) | — | (proactively fixed) | Middleware sets `Content-Security-Policy: default-src 'none'` — strictest, safe because API returns JSON only (see design question f). |
| 10019 | Content-Type Header Missing | `/notes` (200) | (PASS) | — | Handlers set `Content-Type: application/json` explicitly. |
| 10037 | Server Leaks Info via `X-Powered-By` | (PASS) | — | — | Go's `net/http` doesn't emit `X-Powered-By`. |
| 10036 | HTTP Server Response Header | (PASS) | — | — | Go's default `Server:` is empty when not set. |
| 10035 | Strict-Transport-Security | (PASS) | — | — | HSTS is a *response* header ZAP flags only on HTTPS pages; we scan plain HTTP → PASS by omission. Not applicable to this deployment. |
| 10098 | Cross-Domain Misconfiguration | (PASS) | — | — | No `Access-Control-Allow-Origin: *`. |
| 10010–11 | Cookie flags (HttpOnly / Secure) | (PASS) | — | — | API doesn't set cookies. |
| 10054 | Cookie without SameSite | (PASS) | — | — | Same. |
| 10202 | Absence of Anti-CSRF Tokens | (PASS) | — | — | No HTML forms to protect. |
| 10105 | Weak Authentication Method | (PASS) | — | — | No auth in scope for Lab 6 image; when auth is added (Lab 11+) this rule becomes relevant. |
| 10096 | Timestamp Disclosure | (PASS) | — | — | ISO-8601 timestamps on notes are intentional in the model. |
| 10062 | PII Disclosure | (PASS) | — | — | Sample seed notes contain no PII. |
| 10116 | ZAP is Out of Date | (PASS) | — | — | Version 2.16.1 within tolerance. |

**On the "all-PASS = no problem" trap.** ZAP baseline is a *passive* scanner — it looks at responses returned during spidering. A PASS means "the rule ran against actual responses and found no violation", not "the target is invulnerable to that class of attack". E.g., `10202 Absence of Anti-CSRF Tokens` PASSes because we have no HTML forms; if we add a login form tomorrow, the same PASS becomes a real gap. Baseline is a floor, not a ceiling.

### 2.3 Code fix — `securityHeaders` middleware

Diff on `app/handlers.go` — `Routes()` now returns `http.Handler` and wraps the mux:

```diff
-func (s *Server) Routes() *http.ServeMux {
+func (s *Server) Routes() http.Handler {
        mux := http.NewServeMux()
        mux.HandleFunc("GET /health", s.wrap(s.handleHealth))
        …
        mux.HandleFunc("DELETE /notes/{id}", s.wrap(s.handleDeleteNote))
-       return mux
+       return securityHeaders(mux)
 }
```

New file `app/middleware.go`:

```go
package main

import "net/http"

// securityHeaders wraps the router and sets a fixed set of defensive
// response headers on every route. CSP is `default-src 'none'` because
// QuickNotes serves only JSON — strictest is safe here.
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Content-Security-Policy", "default-src 'none'")
		h.Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}
```

Design rationale for **why middleware, not per-handler `.Set(...)`** — see design question (e).

Guard test `app/middleware_test.go` — table-driven across every route × every expected header:

```go
func TestSecurityHeaders_PresentOnAllRoutes(t *testing.T) {
	srv := newTestServer(t)
	n, err := srv.store.Create("t", "b")
	if err != nil {
		t.Fatalf("seed: %v", err)
	}

	wantHeaders := map[string]string{
		"X-Content-Type-Options":  "nosniff",
		"X-Frame-Options":         "DENY",
		"Content-Security-Policy": "default-src 'none'",
		"Referrer-Policy":         "no-referrer",
	}

	routes := []struct {
		name, method, target string
	}{
		{"health", http.MethodGet, "/health"},
		{"list", http.MethodGet, "/notes"},
		{"get", http.MethodGet, "/notes/" + strconv.Itoa(n.ID)},
		{"metrics", http.MethodGet, "/metrics"},
	}

	for _, r := range routes {
		t.Run(r.name, func(t *testing.T) {
			req := httptest.NewRequest(r.method, r.target, nil)
			rec := httptest.NewRecorder()
			srv.Routes().ServeHTTP(rec, req)
			for hdr, want := range wantHeaders {
				if got := rec.Header().Get(hdr); got != want {
					t.Errorf("%s: got %q, want %q", hdr, got, want)
				}
			}
		})
	}
}
```

Test run:

```
$ go test -v -run 'SecurityHeaders' ./...
=== RUN   TestSecurityHeaders_PresentOnAllRoutes
=== RUN   TestSecurityHeaders_PresentOnAllRoutes/health
=== RUN   TestSecurityHeaders_PresentOnAllRoutes/list
=== RUN   TestSecurityHeaders_PresentOnAllRoutes/get
=== RUN   TestSecurityHeaders_PresentOnAllRoutes/metrics
--- PASS: TestSecurityHeaders_PresentOnAllRoutes (0.00s)
    --- PASS: …/health (0.00s)
    --- PASS: …/list (0.00s)
    --- PASS: …/get (0.00s)
    --- PASS: …/metrics (0.00s)
PASS
ok   quicknotes  0.003s
```

**Guard property.** If someone edits `Routes()` to drop `securityHeaders(mux)` and return `mux` directly, each of the four sub-tests immediately fails: the recorded response header for each of the four keys is `""`, not the expected value. The middleware fix is genuinely guarded, not just present-once-and-forgotten.

Live-container smoke check on the newly-built image:

```
$ curl -sSI http://127.0.0.1:8080/notes
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'none'
Content-Type: application/json
Referrer-Policy: no-referrer
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Date: Tue, 07 Jul 2026 20:54:13 GMT
Content-Length: 635
```

### 2.4 Re-scan — after fix

Rebuilt the image via `docker compose up -d --build`, then re-ran the identical baseline command with output paths `-J baseline-after.json -r baseline-after.html`.

Result (full console at [`submissions/lab9/zap/baseline-after-console.txt`](./lab9/zap/baseline-after-console.txt)):

```
Total of 5 URLs
PASS: … (58 rules — including)
PASS: X-Content-Type-Options Header Missing [10021]
…
FAIL-NEW: 0    FAIL-INPROG: 0    WARN-NEW: 0    WARN-INPROG: 0    INFO: 0    IGNORE: 0    PASS: 58
```

**Diff between the two runs, in one line:**

```
--- before: WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1  http://127.0.0.1:8080/notes (200 OK)
+++ after:  PASS: X-Content-Type-Options Header Missing [10021]
```

The finding is gone. Rule count goes from PASS 57 → PASS 58 (the rule that previously fired now finds no violation and joins the passing count).

### 2.5 Design questions

**e) Why middleware, not per-handler `.Set(...)` calls?**

- **Coverage** — the wrapper applies to every route that ever exists, including future ones and error paths. Per-handler `.Set` would have to be re-added for every new endpoint.
- **Consistency** — no possibility of one handler forgetting one header. The set is defined once.
- **Auditability** — one file to read to know what security headers this service enforces. One test to guard it.
- **Separation of concerns** — handlers focus on business logic (turn a note into JSON); middleware handles transport-layer policy (add defensive headers, log request timing, cap body size). Mixing them makes both harder to change.
- **Order-preservation** — the middleware sets headers *before* calling `next.ServeHTTP`, so handler `.WriteHeader` calls can still change status but cannot clobber our security headers. Per-handler `.Set(...)` after `.WriteHeader` is silently a no-op.

**f) `Content-Security-Policy: default-src 'none'` — what does it break, and why is that OK for QuickNotes?**

`default-src 'none'` means: **no external resource of any kind is allowed to load** — no scripts, no styles, no images, no fonts, no fetch/XHR, no frames, no forms, no workers. Everything is blocked unless a specific `*-src` allow-list re-enables it.

For a website that returns HTML pages, this policy breaks the site entirely: the page can't load its own CSS or scripts. That's why real sites start from `default-src 'self'` (own origin) and allow-list what they need (`script-src 'self' https://cdn.jsdelivr.net`, etc.).

For QuickNotes it is *safe by construction*:

- The API returns `Content-Type: application/json`. Browsers never render JSON as HTML — no scripts, no styles, no framing to protect against.
- The middleware also sets `X-Content-Type-Options: nosniff`, which stops a browser from ever *guessing* our JSON is HTML.
- Combined: if a browser somehow ends up parsing our response as HTML (bug, misconfig, developer-tools inspection), `default-src 'none'` prevents that HTML from doing anything meaningful — no XSS payload can fetch its stage-2 script.

So we get the strictest possible defensive posture with zero functional cost, precisely because we serve no HTML. For a "real" web app you'd measure what each `*-src` needs and allow-list it explicitly.

**g) The cost of marking every informational finding "accepted" without reading it.**

The cost is **loss of signal**. If informational findings all land in an "accepted" bucket by default, then when the next real, high-severity finding drops, humans have already trained themselves to hit the "accept" button reflexively. Accepted findings become a memory-hole: nobody re-reads them; the security ledger is indistinguishable from noise.

Second-order costs:

- Informational findings often *become* real under the right conditions. `10035 Strict-Transport-Security` is informational on a plain-HTTP scan target; on a real HTTPS deployment, missing HSTS is a legitimate finding. Rubber-stamping "accept" now hides a real finding later.
- Institutional memory decays. Six months from now, a new engineer looks at the accepted list and cannot tell why anything on it is accepted — the reasoning was never captured.
- The floor drifts up. When "accept unread" is normal, real "accept" decisions can be smuggled in without review. Auditors lose the ability to distinguish considered accept from lazy accept.

The right move: for each informational finding, spend the 60 seconds needed to write a one-sentence rationale + a re-eval date. That's a rounding error in engineer time and preserves the signal.

---

## Bonus Task — govulncheck as CI gate

**Skipped by design.** Attempted only Task 1 + Task 2.

---

## Pitfalls hit — for the next me

1. **Rootless podman bind-mount ownership.** The ZAP container's `zap` user (UID 1000 inside) maps to a subuid on the host (e.g. `100999`). A host-side dir owned by `karim (UID 1000)` appears inside the container as owned by a different UID → the `zap` process can't write reports. `--userns=keep-id` is the textbook fix but crashed crun on this host (`readlink '': No such file`). `-v host:cont:U` recursively `chown`s the mount and works, but modifies host state. What worked: `chmod 777` on the reports dir once, then run without `--userns`.

2. **ZAP spider seeds from the URL you give it, then walks from there.** The default `-t http://.../` gave the spider a 404 root, and passive scan had *nothing* to look at — all 58 rules reported PASS. Only after retargeting `-t http://.../notes` (which returns 200) did the actual missing-header WARN surface. **A "clean" ZAP baseline is only meaningful if the spider actually reached real endpoints.**

3. **ZAP hangs on addon updates.** Default startup fetches Marketplace addon-update metadata over the internet; if that hangs, the whole scan hangs. `-z "-silent"` disables it. Total scan time dropped from "no result after 8 min" to ~90 seconds.

4. **Trivy `config` subcommand does not accept `--no-progress`.** Same flag works on `fs` and `image`. Trivy fails fatally with `unknown flag`, not silently. Read the subcommand-specific `--help` before copy-pasting a flag set.

5. **Trivy ships a broken embedded rego for AWS EC2 (`specify_ami_owners`).** Every scan spits `[rego] Error occurred while parsing` + `Failed to find embedded check, skipping`. It doesn't affect Dockerfile/compose checks — just log noise you can safely ignore.

6. **ZAP JSON output ≠ ZAP console output.** `baseline-before.json` on disk turned out to be from the first (wrong-seed) run; the second run's report write may have been blocked by the leftover file's ownership. The console log captured via `tee` was the reliable artifact — that's what the submission cites for "before". For serious CI use of ZAP, run in a fresh, unclobbered wrk dir each time.

---

## Artifacts index

- **Trivy scan outputs** (`submissions/lab9/trivy/`):
  - `image-scan.txt`
  - `fs-scan.txt`
  - `config-scan.txt` (HIGH/CRITICAL filter)
  - `config-scan-all.txt` (all severities)
  - `sbom.cyclonedx.json`
- **ZAP scan outputs** (`submissions/lab9/zap/`):
  - `baseline-before-console.txt` — authoritative before-fix output
  - `baseline-before.html` / `.json`
  - `baseline-after-console.txt` — authoritative after-fix output
  - `baseline-after.html` / `.json`
- **Code change** (`app/`):
  - `middleware.go` — securityHeaders wrapper
  - `middleware_test.go` — table-driven guard
  - `handlers.go` diff — `Routes()` signature + return
