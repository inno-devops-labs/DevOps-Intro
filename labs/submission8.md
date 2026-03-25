## Task 1 — Key Metrics for SRE and System Analysis

### 1.1: Мониторинг системных ресурсов

#### Вывод iostat

Linux 6.6.87.2-microsoft-standard-WSL2 (LAPTOP-HVHDMKR2) 03/25/26 _x86_64_ (8 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.64    0.05    0.65    0.31    0.00   98.35

Device    r/s     rkB/s   rrqm/s  %rrqm r_await  w/s  wkB/s  %util
sda     10.28    654.69     3.78  26.90    0.31  0.00   0.00   0.25
sdb      1.21     65.34     0.62  33.82    0.28  0.00   0.00   0.10
sdc      0.86     19.64     0.00   0.00    0.05  0.02   0.04   0.01
sdd    149.94   3993.63    27.91  15.69    0.24 18.23 1102.49  2.38

#### Топ-3 процессов по потреблению ресурсов

**Топ-3 по CPU:**
1. `htop` (PID 926) — 0.7%
2. `/usr/bin/` (PID 204) — 0.3%
3. `/sbin/init` (PID 1) — 0.0%

**Топ-3 по памяти:**
1. `/usr/bin/` (PID 204) — 22144 KB RES, 0.3%
2. `/usr/libe` (PID 897) — 20480 KB RES, 0.3%
3. `/sbin/init` (PID 1) — 12876 KB RES, 0.2%

**Топ-3 по I/O:**
1. `sdd` — 149.94 r/s, 3993 kB/s read
2. `sda` — 10.28 r/s, 654 kB/s read
3. `sdb` — 1.21 r/s, 65 kB/s read


### 1.2: Управление дисковым пространством

#### Вывод df -h

Filesystem  Size  Used  Avail  Use%  Mounted on
drivers     120G  112G   8.4G   94%  /usr/lib/wsl/drivers
/dev/sdd   1007G  9.3G   947G    1%  /
C:\         120G  112G   8.4G   94%  /mnt/c
D:\         342G  203G   139G   60%  /mnt/d

#### Вывод du -h /var (топ-10)

1.2G    /var
530M    /var/log
524M    /var/log/journal/21c37034dc294c888012e0fcc81810d1
524M    /var/log/journal
414M    /var/lib
228M    /var/lib/apt
227M    /var/lib/apt/lists
200M    /var/cache
181M    /var/cache/apt
109M    /var/lib/texmf

#### Топ-3 крупнейших файла в /var

70M  /var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_noble_universe_binary-amd64_Packages
59M  /var/cache/apt/srcpkgcache.bin
59M  /var/cache/apt/pkgcache.bin

---

### Анализ

Система находится практически в состоянии простоя: `%idle = 98.35%` при `iowait = 0.31%`, что говорит об отсутствии значимой нагрузки в момент наблюдения. Диск `sdd` (корневая файловая система WSL) показал наибольшую I/O-активность (149.94 r/s) — это объясняется монтированием и инициализацией WSL при запуске, а не реальной рабочей нагрузкой. Диск `C:\` заполнен на **94%** (свободно лишь 8.4G), что является потенциальным риском для стабильности. Директория `/var/log/journal` занимает **524M** из-за накопленных логов systemd.

### Рефлексия

На основе полученных данных можно выделить следующие меры по оптимизации:
- **Очистка кеша apt**: `sudo apt clean` освобождает ~240M из `/var/cache/apt`
- **Ограничение размера журнала**: `sudo journalctl --vacuum-size=100M` сократит `/var/log/journal` с 524M до 100M
- **Освобождение места на C:\**: при наличии лишь 8.4G свободного пространства существует риск переполнения диска, что негативно скажется на работе WSL
- **Мониторинг I/O под нагрузкой**: текущий baseline близок к нулю в режиме простоя; для выявления реальных узких мест необходимо нагрузочное тестирование



## Task 2 — Practical Website Monitoring Setup

### Выбранный сайт

**URL:** https://moodle.innopolis.university/login/index.php

Moodle — это основная учебная платформа университета. Мониторинг этого сайта важен, так как его недоступность напрямую влияет на учебный процесс: сдачу заданий, просмотр материалов и коммуникацию с преподавателями.


### 2.1: API Check — проверка доступности

Настроен GET-запрос к `https://moodle.innopolis.university/login/index.php` с assertion: `Status code equals 200`. Частота проверки — каждые 10 минут с локаций Frankfurt и London.

![alt text](image-11.png)

Результат: статус код **200**, время ответа **423ms** — сайт доступен и отвечает корректно.


### 2.2: Browser Check — проверка контента

Настроен Playwright-тест, который открывает страницу `https://moodle.innopolis.university/my/`, проверяет наличие заголовка страницы и видимость элемента `body`.

```js
const { test, expect } = require('@playwright/test');

test('page loads and has content', async ({ page }) => {
  await page.goto('https://moodle.innopolis.university/my/');
  await expect(page).toHaveTitle(/.+/);
  await expect(page.locator('body')).toBeVisible();
});
```

![alt text](image-12.png)

Результат: тест **"page loads and has content"** прошёл успешно за **5.67s**. Все шаги зелёные.


### 2.3: Настройка алертов

Настроена стратегия повторных попыток **Linear** с параметрами:
- Max retries: **2**
- Base backoff: **60 секунд** (интервалы: 1 мин и 2 мин)
- Max total retry duration: **600 секунд**

Alert channel: **Email** на `dashamakeeva3000@gmail.com`. Уведомления отправляются при падении и восстановлении чека.

![alt text](image-13.png)

### Анализ

API Check выбран для отслеживания базовой доступности сервера — если Moodle упадёт, статус-код изменится с 200. Browser Check проверяет, что страница реально загружается и рендерится в браузере, а не просто отвечает на уровне HTTP. Стратегия Linear retry с 2 попытками выбрана для избежания ложных срабатываний при кратковременных сбоях сети. Порог в 10 минут достаточен для учебной платформы — критичный даунтайм будет замечен в течение одного цикла проверки.

### Рефлексия

Данная конфигурация позволяет оперативно обнаруживать как полную недоступность сервера (API Check), так и проблемы с рендерингом страницы на уровне браузера (Browser Check). Email-алерты гарантируют своевременное уведомление при инцидентах. Такой подход соответствует принципу мониторинга user-facing функциональности: проверяется именно то, что видит пользователь, а не только внутренние метрики сервера.