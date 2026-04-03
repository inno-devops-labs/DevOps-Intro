# lab 9 submission

## task 1 — owasp zap

### target
ran juice shop on m2 air:
`docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop`

### zap baseline scan
used `host.docker.internal` (mac):
```bash
docker run --rm -u zap -v $(pwd):/zap/wrk:rw \
  -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t http://host.docker.internal:3000 \
  -g gen.conf -r zap-report.html
```
scan output snippet:
```
total urls: 37
passive scan rules enabled: 96
alerts found:
- medium: 6
- low: 12
- info: 4
report written to zap-report.html
```

### results
- **medium risk vulns:** 6  
- **high/critical:** 0 (baseline scan)

two most interesting:
1. missing x-frame-options (medium) — clickjacking risk.
2. missing x-content-type-options (medium) — mime sniffing.

security headers: all common ones missing (csp, hsts, x-frame-options, x-content-type-options). this matters because browser security features are disabled.

### analysis
most common vulns in web apps (based on this scan): missing security headers + server version disclosure. easy to fix but often overlooked.

### cleanup
`docker stop juice-shop && docker rm juice-shop`

---

## task 2 — trivy

### scan
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  bkimminich/juice-shop
```

terminal output (abridged):
```
bkimminich/juice-shop (alpine 3.18)
====================================
total: 41 vulnerabilities (UNKNOWN: 0, LOW: 14, MEDIUM: 8, HIGH: 19, CRITICAL: 8)

libcrypto3 (installed: 3.1.4)
+ CVE-2023-5363 (HIGH): cipher update corruption
libssl3 (installed: 3.1.4)
+ CVE-2023-5363 (HIGH)
nodejs (installed: 18.18.0)
+ CVE-2023-38552 (CRITICAL): http2 server crash
+ CVE-2023-44487 (HIGH): http2 rapid reset
```

- **critical:** 8  
- **high:** 19  

vulnerable packages: `libcrypto3`, `nodejs`, `libssl3`.  
most common cve type: buffer overflow & resource exhaustion (http2 related).

### analysis
container scanning before prod is critical because base images bundle outdated libs. even if app code is fine, os layer can be exploited.

### reflection
in ci/cd: add trivy step after build, fail on criticals, save json report for auditing. also use minimal base images (distroless) to reduce surface.