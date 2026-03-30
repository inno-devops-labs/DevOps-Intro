# Task 1

## Medium-риски

### 1. Content Security Policy (CSP) Header Not Set
- **Описание:** CSP-заголовок полностью отсутствует на сайте (systemic — на всех страницах)
- **Последствия:** Браузер не ограничивает источники загрузки JS/CSS/изображений → уязвимость к XSS и data injection атакам
- **Затронутые URL:** `/`, `/ftp/eastere.gg`, `/ftp/suspicious_errors.yml`, `/sitemap.xml`
- **Решение:** Настроить заголовок `Content-Security-Policy` на веб-сервере
- **CWE:** 693

### 2. Cross-Domain Misconfiguration (CORS)
- **Описание:** Сервер возвращает `Access-Control-Allow-Origin: *` — любой сторонний сайт может читать публичные данные через браузер
- **Затронутые URL:** `/`, `/robots.txt`, `/chunk-24EZLZ4I.js`, `/chunk-T3PSKZ45.js`, `/favicon_js.ico`
- **Решение:** Ограничить значение заголовка конкретными доверенными доменами вместо `*`
- **CWE:** 264

---

## Статус security headers

| Заголовок | Статус |
|---|---|
| `Content-Security-Policy` | ❌ отсутствует |
| `Cross-Origin-Embedder-Policy` | ❌ отсутствует (5 страниц) |
| `Cross-Origin-Opener-Policy` | ❌ отсутствует (5 страниц) |
| `Feature-Policy` | ⚠️ устарел — нужно заменить на `Permissions-Policy` |

---

## Наиболее интересная уязвимость

### Dangerous JS Functions (Low)
- **Файлы:** `chunk-LHKS7QUN.js`, `main.js`
- **Evidence:** `bypassSecurityTrustHtml(`
- **Описание:** Это Angular-специфичная функция, которая намеренно отключает встроенную защиту от XSS. Если в неё попадают пользовательские данные без предварительной валидации — прямой XSS.
- **CWE:** 749


## Наиболее распространённые уязвимости веб-приложений


1. **Injection** (XSS, SQLi) — недостаточная валидация пользовательского ввода
2. **Security Misconfiguration** — отсутствующие заголовки, неправильный CORS, дефолтные настройки
3. **Broken Access Control** — неверная проверка прав доступа


# Task 2

![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)

## Результаты
| CRITICAL | HIGH |
|---|---|
| 10 | 40 |

## Топ уязвимые пакеты
| Пакет | CVE | Severity |
|---|---|---|
| `jsonwebtoken` v0.1.0 | CVE-2015-9235 | CRITICAL — bypass JWT верификации |
| `vm2` v3.9.17 | CVE-2023-32314 | CRITICAL — sandbox escape |

## Самый частый тип
**ReDoS + Prototype Pollution** (lodash, minimatch, handlebars)

## Утечка секрета
RSA Private Key найден прямо в образе: `/juice-shop/build/lib/insecurity.js:47`

## Зачем сканировать образы
Контейнер может содержать сотни зависимостей с CVE — без сканирования они уходят в прод незамеченными.

## CI/CD интеграция
```yaml
- uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'my-image:latest'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # блокирует деплой при находках
```