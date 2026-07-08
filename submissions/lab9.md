# Lab 9

Frolova AI - M25RO-01,

a.frolova@innopolis.university

Ссылка на PR:  https://github.com/inno-devops-labs/DevOps-Intro/pull/1407

## 1.1 Необходимые сканы

1. Сканиерование образа

```bash
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6 > submissions/trivy-image.txt
```

Скачалась база уязвимостей, определилась ОС, нашелся Go-бинарник, завершилось сканирование, и вывод ушел в файл `submissions/trivy-image.txt`.

![alt text](image.png)

Файл `submissions/trivy-image.txt`:

![alt text](image-1.png)

2. Сканирование файловой системы репозитория

```bash
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v "$PWD:/src" aquasec/trivy:0.59.1 fs --severity HIGH,CRITICAL --no-progress /src > submissions/trivy-fs.txt
```

Здесь слетела кодировка, но речь идет о том, что найдена 1 уязвимость HIGH, AsymmetricPrivateKey - это приватный ssh ключ, который попал в репозиторий, и указано, по какому пути находится файл.

Файл `trivy-fs`:

![alt text](image-2.png)

Эту проблему можно решить, добвив .vagrant в gitignore и удалив файл из репозитория.

3. Сканирование конфигурации

```bash
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v "${PWD}:/src" aquasec/trivy:0.59.1 config --severity HIGH,CRITICAL /src 2>&1 | Out-File -Encoding UTF8 submissions/trivy-config.txt
```

Файл `trivy-config`:

![alt text](image-3.png)

Была найдена одна уязвимость Dockerfile - отсутвует user инструкция, контейнер запускается от root. Нужно изменить Dockerfile и добавить `USER 65532:65532`.

4. Генерация SBOM

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --format cyclonedx quicknotes:lab6 > submissions/sbom.json
```

Фрагмент файла `sbom`:

![alt text](image-4.png)

Здесь содержится информация об ОС (Debian 13.5), базовых пактах, go приложении и зависимостях.


## Ответы на вопросы

a) CVE severity is one input, not the answer. What else matters when triaging?

Кроме CVSS-оценки важны:

- **Reachability** - вызывается ли уязвимая функция в нашем коде? Если нет, то риск значительно ниже.
- **Exploit availability** - есть ли публичный PoC/эксплойт? Если есть, приоритет выше.
- **Deployment context** - изолирован ли сервис (например, в закрытой сети) или доступен из интернета?
- **Business impact** - что именно ломается: критичный API или вспомогательный эндпоинт?

Только совокупность этих факторов позволяет принять взвешенное решение: фиксить, принять риск или отложить.

---

b) Why is the minimal base the strongest single security control?

Минимальный базовый образ (distroless, scratch) содержит только статически собранный бинарник и минимальные файлы. Это резко уменьшает поверхность атаки: 
- Нет shell, пакетного менеджера, компилятора, утилит
- Практически нет CVE в самом образе
- Нечем злоупотреблять при компрометации контейнера

Это единственный контроль, который одномоментно устраняет сотни потенциальных уязвимостей.

---

c) `.trivyignore` — when is it the right move, and when is it security theater?

**Правильно:** когда уязвимость точно не эксплуатируется в данном контексте (например, CVE в библиотеке, которая не используется в коде), и к этому приложена дата пересмотра.

**Театр:** когда игнорируют находки без анализа, «чтобы отчёт был зелёным». Если нет даты пересмотра или причины — это просто заметание проблем под ковёр.

---

d) The SBOM is a list of components. What concrete future problem does having it today solve?

SBOM позволяет **мгновенно ответить на вопрос**: «Затронут ли нас новый CVE?» 

Например, когда вышла Log4Shell (2021), компании с SBOM смогли за минуты проверить, используется ли Log4j в их проектах. Без SBOM — приходилось вручную проверять каждый репозиторий, что занимало дни и недели.

## Task2

### 2.1 ZAP baseline

```bash
docker run --rm -v "$(pwd -W):/zap/wrk" ghcr.io/zaproxy/zaproxy:2.16.0 zap-baseline.py -t http://host.docker.internal:8080 2>&1 | tee submissions/zap-report.txt

```

Фрагмент файла `zap-report`:

![alt text](image-5.png)

Zap нашел 3 url для сканирования, провел 65 пассивных проверок, которые успешно прошли. Найдено 2 предупреждения (2 url не существует).

ZAP предупреждает, что версия устарела. Критических уязвимостей не найдено.

### 2.2 ZAP findings triage

| ID | Name | Risk | URL | Disposition | Reason |
|----|------|------|-----|-------------|--------|
| 10049 | Storable and Cacheable Content | Medium | `/` | FIX | Добавить Cache-Control заголовки |
| 10049 | Storable and Cacheable Content | Medium | `/sitemap.xml` | ACCEPT | QuickNotes — API, sitemap.xml не существует |
| 10116 | ZAP is Out of Date | Informational | — | ACCEPT | Используется фиксированная версия ZAP 2.16.0 |

### 2.3

- Добавлен middleware `securityHeaders` в `app/middleware.go`, который устанавливает заголовки безопасности (`X-Content-Type-Options`, `X-Frame-Options`, `CSP`, `Referrer-Policy`).
- Middleware подключён ко всем маршрутам в `main.go`.
- Добавлен тест `TestSecurityHeaders`, проверяющий наличие заголовков.
- Тест проходит успешно (`PASS`), заголовки применяются корректно.

![alt text](image-6.png)

### 2.4 Повторное сканирование

Результат: 

![alt text](image-7.png)

### Ответы на вопросы

e) Why a middleware and not per-handler header sets?

Middleware применяется ко всем маршрутам сразу, не дублирует код, легче поддерживать и изменять. Это соответствует принципу DRY (Don't Repeat Yourself).
---
f) `Content-Security-Policy: default-src 'none'` is the strictest CSP. What does it break? Why is it OK for QuickNotes (an API) but not for a website?

CSP `default-src 'none'` запрещает любые внешние ресурсы (скрипты, стили, изображения, шрифты). Для API это безопасно, потому что API не загружает внешние ресурсы. Для веб-сайта это сломает рендеринг страниц, так как браузер не сможет загрузить CSS, JS, шрифты и т.д.
---

g) False positives vs accepted findings: ZAP often flags informational issues that aren't real problems. What's the cost of marking them all "accepted" without reading them?

Если принимать все находки без проверки, можно пропустить реальную уязвимость, замаскированную под ложную. Это создаёт иллюзию безопасности («мы всё проверили»), но на деле оставляет дыры. Каждое принятие должно быть осознанным и задокументированным.
