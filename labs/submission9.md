\# Лабораторная работа №9



\## Задание 1 



\### Запуск Juice Shop



docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop

docker run --rm -v $(pwd):/zap/wrk:rw --network host \\

&#x20; ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \\

&#x20; -t http://localhost:3000 \\

&#x20; -g gen.conf \\

&#x20; -r zap-report.html

Результаты сканирования

Скриншот обзора отчёта ZAP (Summary of Alerts):

https://images/zap-summary.jpg



Risk Level	Number of Alerts

High	            0

Medium	            2

Low	            5

Informational	    3


Уязвимости среднего риска (Medium) – 2 шт.

Content Security Policy (CSP) Header Not Set



Отсутствует заголовок CSP → возможны XSS-атаки.



URL: http://localhost:3000, /, /ftp и др.



Cross-Domain Misconfiguration (CORS)



Сервер возвращает Access-Control-Allow-Origin: \* → любые домены могут читать ответы.



URL: /, /assets/public/favicon\_js.ico, /chunk-T3PSKZ45.js, /robots.txt, /sitemap.xml.



Уязвимости низкого риска (Low) – 5 шт.

Cross-Origin-Embedder-Policy Header Missing or Invalid – отсутствует защита от Spectre.



Cross-Origin-Opener-Policy Header Missing or Invalid – риск утечки данных между окнами.



Dangerous JS Functions – используется bypassSecurityTrustHtml() в chunk-LHKS7QUN.js, main.js → потенциальный XSS.



Deprecated Feature Policy Header Set – устаревший заголовок (нужен Permissions-Policy).



Timestamp Disclosure - Unix – раскрытие временных меток (например, 1650485437 → 2022-04-20 20:10:37).



Информационные (Informational) – 3 шт.

Modern Web Application – приложение использует современный JS, рекомендуется Ajax Spider.



Storable and Cacheable Content (например, /robots.txt) – может привести к утечке данных при кэшировании.



Storable but Non-Cacheable Content – кэширование возможно, но требуется проверка.



Security headers (заголовки безопасности)

Отсутствуют или неверны:



Content-Security-Policy (Medium)



Cross-Origin-Embedder-Policy (Low)



Cross-Origin-Opener-Policy (Low)



X-Frame-Options



Strict-Transport-Security



Вместо Permissions-Policy используется устаревший Feature-Policy



Почему важны:

Защита от XSS, кликджекинга, Spectre, перехвата данных и устаревших политик.



Анализ

Наиболее частые веб-уязвимости – отсутствие защитных заголовков, опасные JS-функции и небезопасные CORS-настройки. OWASP ZAP автоматизирует их поиск, что критично для DevSecOps.



Задание 2 

Выполнение сканирования
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.58.0 image --severity HIGH,CRITICAL bkimminich/juice-shop

Результаты сканирования

Скриншот вывода Trivy (Debian layer):

https://images/term1.jpg



Debian OS layer:



Severity	Count

HIGH	          1

CRITICAL	  0

Уязвимость: libssl3t64 (CVE-2026-28390) – высокая, фиксится в обновлении пакета.



Скриншот вывода Trivy (Node.js зависимости – общий счёт):

https://images/term2.jpg



Скриншот примеров уязвимостей (crypto-js, express-jwt и др.):

https://images/term3.jpg



Node.js зависимости (node-pkg):



Severity	Count

HIGH	         37

CRITICAL	 9

Примеры уязвимых пакетов (с CVE):



crypto-js – CVE-2023-46233 (CRITICAL)



jsonwebtoken – CVE-2015-9235 (CRITICAL), CVE-2022-23539 (HIGH)



lodash – CVE-2019-10744 (CRITICAL), CVE-2018-16487 (HIGH), CVE-2021-23337 (HIGH)



marsdb – GHSA-5mrr-rgp6-x4gr (CRITICAL)



vm2 – CVE-2023-32314 (CRITICAL), CVE-2023-37466 (CRITICAL)



minimatch – CVE-2026-26996 (HIGH), CVE-2026-27903 (HIGH), CVE-2026-27904 (HIGH)



tar – множество HIGH-уязвимостей (CVE-2026-23745, CVE-2026-23950, и др.)



Секреты (Private Keys):



Обнаружены RSA приватные ключи в файлах insecurity.js и insecurity.ts – HIGH риск .



Анализ

Сканирование образа контейнера выявило критическое количество уязвимостей . Даже официальный образ уязвимого приложения показывает, как легко внедрить уязвимости через непроверенные зависимости. Trivy даёт точные CVE и пути исправления. 


Скриншот главной страницы Juice Shop (http://localhost:3000):

https://images/juice\_shop.jpg



Приложение успешно запущено и доступно для сканирования.

Выводы

OWASP ZAP выявил отсутствие критических заголовков безопасности и опасные CORS-настройки в веб-приложении.



Trivy обнаружил множество HIGH/CRITICAL уязвимостей в зависимостях (особенно lodash, jsonwebtoken, crypto-js, vm2) и даже жёстко зашитые приватные ключи.



Автоматическое сканирование контейнеров и веб-приложений должно быть встроено в CI/CD пайплайн для предотвращения развёртывания небезопасного кода.



