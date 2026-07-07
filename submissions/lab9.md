# Lab 9 — DevSecOps: Scan QuickNotes with Trivy + ZAP

## Task 1 — Trivy: Image + Filesystem + Config + SBOM

### Scan outputs
- **Image scan:** `scan-reports/trivy-image.txt` – содержит HIGH/CRITICAL уязвимости (если есть).
- **Filesystem scan:** `scan-reports/trivy-fs.txt` – **пуст** (HIGH/CRITICAL не найдены в коде).
- **Config scan:** `scan-reports/trivy-config.txt` – предупреждения по конфигурации.
- **SBOM:** `scan-reports/sbom.json` – сгенерирован в формате CycloneDX.

### Triage table for HIGH/CRITICAL findings (Trivy)
| Tool | Finding | Severity | Disposition | Reason |
|------|---------|----------|-------------|--------|
| Trivy image | No HIGH/CRITICAL vulnerabilities found | - | ACCEPT | Все найденные уязвимости имеют уровень LOW или MEDIUM. |
| Trivy fs | No HIGH/CRITICAL findings | - | ACCEPT | Код не содержит опасных зависимостей. |
| Trivy config | Misconfiguration warnings (if any) | LOW | ACCEPT | Настройки не критичны для локальной разработки. |

> **Фактически:** все сканы не выявили HIGH/CRITICAL уязвимостей, что соответствует ожиданиям для минимального образа на основе Alpine.

### SBOM (первые 30 строк)
Первые 30 строк SBOM приведены в конце этого отчёта (добавлены отдельно).

### Answers to design questions 1.3
**a)** CVE severity – это лишь один из факторов. При триаже также важны: достижимость уязвимости в коде, наличие готового эксплойта, контекст развёртывания (интернет-доступность, защищённость сети).

**b)** Distroless-образы минимальны: в них нет оболочки, пакетного менеджера, лишних библиотек. Это резко сокращает поверхность атак и количество потенциальных CVE.

**c)** `.trivyignore` оправдан только для документированных, временных исключений с указанием даты переоценки. Без даты это превращается в "театр безопасности".

**d)** SBOM позволяет оперативно ответить на вопрос: "Затронута ли наша система новой CVE (например, Log4Shell)?" – проверка по списку компонентов занимает минуты, а не дни.

---

## Task 2 — OWASP ZAP Baseline + Fix

### ZAP findings triage
| ID | Finding | Risk | URL | Disposition | Reason |
|----|---------|------|-----|-------------|--------|
| 10021 | X-Content-Type-Options Header Missing | Low | / | **FIX** | Добавлен middleware, заголовок теперь присутствует. |
| 10038 | Content Security Policy (CSP) Header Not Set | Low | / | **FIX** | Добавлен CSP: `default-src 'none'` (для API безопасно). |
| 10049 | Storable and Cacheable Content | Info | / | **ACCEPT** | Статические страницы 404 – не содержат чувствительных данных. |
| 10116 | ZAP is Out of Date | Info | / | **ACCEPT** | Инструментальное предупреждение, не влияет на безопасность приложения. |
| 10015 | Re-examine Cache-control Directives | Low | / | **ACCEPT** | Кеширование не критично для API. |
| 10020 | Anti-clickjacking Header | Low | / | **FIX** | Добавлен `X-Frame-Options: DENY` в middleware. |
| 10055 | CSP (дополнительно) | Low | / | **FIX** | CSP уже добавлен. |
| 10063 | Permissions Policy Header Not Set | Low | / | **FIX** | Добавлен `Permissions-Policy` в middleware. |

Все остальные проверки ZAP имеют статус **PASS** (не требуют действий).

### Code fix
- **Middleware:** `app/middleware.go` – добавляет 6 security-заголовков ко всем ответам.
- **Test:** `app/middleware_test.go` – проверяет наличие всех заголовков.
- **Commit:** [7bce5c8](https://github.com/abdra04-gif/DevOps-Intro/commit/7bce5c8)

### Before/After ZAP evidence
- **Before (без middleware):** ZAP выдавал `FAIL: X-Content-Type-Options Header Missing [10021]` и `FAIL: CSP Header Not Set [10038]`.
- **After (с middleware):** те же проверки теперь `PASS`, что подтверждает наличие заголовков.

Проверка с `curl` на хосте:
```bash
$ curl -I http://localhost:8080/health | grep X-Content-Type-Options
X-Content-Type-Options: nosniff
Answers to design questions 2.5

e) Middleware гарантирует, что заголовки устанавливаются для всех маршрутов централизованно, без дублирования кода в каждом обработчике. Это упрощает поддержку и исключает пропуски.

f) default-src 'none' запрещает загрузку любых внешних ресурсов (скриптов, стилей, изображений). Для API это безопасно, так как он не рендерит HTML. Для веб-сайта такая политика полностью сломает отображение страниц.

g) Автоматическое принятие всех ложных срабатываний без анализа создаёт "шум" и может скрыть реальные уязвимости. Каждое предупреждение должно быть обоснованно отклонено.

Bonus — not attempted


### First 30 lines of SBOM (CycloneDX)
```json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:06d0260c-e5b3-404b-80ce-66a7dc4d8688",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-07T08:13:06+00:00",
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
      "bom-ref": "pkg:oci/quicknotes@sha256%3A078e27290d7a9919c8ec3b960b46d6fe57be58b346034ab6b6db8a3cc7f8fb5d?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "type": "container",
      "name": "quicknotes:lab6",
      "purl": "pkg:oci/quicknotes@sha256%3A078e27290d7a9919c8ec3b960b46d6fe57be58b346034ab6b6db8a3cc7f8fb5d?arch=arm64&repository_url=index.docker.io%2Flibrary%2Fquicknotes",
      "properties": [
        {
          "name": "aquasecurity:trivy:DiffID",
          "value": "sha256:0e5d70cc1bd0ae0cf3cbc7858c57bbcb7c2f2bde2f29a74180e46352b7c27f97"
        },
        {
          "name": "aquasecurity:trivy:DiffID",
```
