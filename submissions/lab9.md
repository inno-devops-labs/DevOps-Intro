# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### Scan outputs
- Image: [scan-reports/trivy-image.txt]
- Filesystem: [scan-reports/trivy-fs.txt] (empty – no HIGH/CRITICAL)
- Config: [scan-reports/trivy-config.txt]
- SBOM: [scan-reports/sbom.json] (first 30 lines)

### Triage table (every HIGH/CRITICAL from Trivy)
| Tool | Finding | Severity | Disposition | Reason |
|------|---------|----------|-------------|--------|
| (заполните по факту) | ... | ... | ... | ... |

### Answers to design questions 1.3
**a)** CVE severity is one input; also consider reachability, exploit availability, deployment context.  
**b)** Distroless images minimize attack surface – no shell, no package manager, no extra libraries.  
**c)** .trivyignore is right for documented, time-limited exceptions; otherwise it's security theater.  
**d)** SBOM helps quickly answer if a newly discovered CVE affects your dependencies.

---

## Task 2 — OWASP ZAP Baseline + Fix

### ZAP findings triage
| ID | Finding | Risk | URL | Disposition | Reason |
|----|---------|------|-----|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | / | FIX | Added middleware |
| 10038 | CSP Header Not Set | Low | / | FIX | Added middleware |
| (добавьте остальные по факту) | ... | ... | ... | ... | ... |

### Code fix
- **Middleware:** `app/middleware.go`
- **Test:** `app/middleware_test.go`
- **Commit:** [ссылка на коммит]

### Before/After ZAP evidence
- Before: scan-reports/zap-report.html (finding present)
- After: scan-reports/zap-report-after.html (finding gone)

### Answers to design questions 2.5
**e)** Middleware ensures headers are set on all routes, centralizes the logic, and avoids duplication.  
**f)** `default-src 'none'` breaks loading of external resources. For an API it's fine; for a website it would break everything.  
**g)** Marking all false positives as accepted without review creates noise and hides real issues.

---

## Bonus — not attempted
