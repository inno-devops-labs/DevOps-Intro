# Лабораторная работа 12 – WebAssembly vs традиционные контейнеры

## 1. Приложение «Московское время» 
Исходный код: `main.go`. Три режима работы без изменений кода:
- **CLI** (`MODE=once`) – JSON-ответ и выход.
- **Сервер** – HTTP на `:8080` (HTML + `/api/time`).
- **WAGI (Spin)** – CGI-стиль при наличии `REQUEST_METHOD`.

**Результаты тестирования:**
- CLI: `MODE=once go run main.go` → `{"moscow_time":"2026-04-23 18:28:55 MSK","timestamp":1776958135}`
- Сервер: открыт в браузере (см. рис. 1).

![Серверный режим](labs/images/lab12_1.jpg)  
*Рис. 1 – Работа в браузере (серверный режим)*  

![CLI-режим](labs/images/lab12_2.jpg)  
*Рис. 2 – Вывод в режиме командной строки*

## 2. Традиционный Docker-контейнер 
Сборка: `docker build -t moscow-time-traditional -f Dockerfile .`

**Измерения:**
- Размер бинарника: **4.5 MB**
- Размер образа (сжатый): **1.98 MB** (на диске 6.82 MB)
- Среднее время запуска (CLI, 5 повторов): **422 мс**
- Использование памяти (сервер): **1.434 MiB**

## 3. WASM-контейнер 
Сборка TinyGo 0.39.0: `tinygo build -o main.wasm -target=wasi main.go`
Размер `main.wasm`: **2.4 MB**.

OCI-образ (`Dockerfile.wasm`, scratch) собран через `buildx`, импортирован в containerd.

**Измерения:**
- Размер образа: ~**2.7 MB** (модуль + метаданные)
- Среднее время запуска (CLI, 5 повторов): **65 мс**
- Использование памяти: **N/A** (изолированная среда wasmtime)

Серверный режим через `ctr` не работает – WASI Preview1 не имеет сокетов. Тот же `main.wasm` работает как HTTP-сервер в Spin (WAGI).

## 4. Сравнительный анализ
| Показатель            | Docker        | WASM (ctr)    | Разница |
|-----------------------|---------------|---------------|---------|
| Бинарный файл         | 4.5 MB        | 2.4 MB        | -46.7%  |
| Размер образа         | 1.98 MB (сжат)| ~2.7 MB       | —       |
| Время запуска         | 422 мс        | 65 мс         | в 6.5× быстрее |
| Память                | 1.43 MiB      | N/A           | —       |
| Серверный режим       | ✅            | ❌ (только через Spin) | — |

**Почему WASM меньше:** TinyGo вырезает неиспользуемый код, заменяет библиотеки облегчёнными, исключает базу часовых поясов (используем `FixedZone`).

**Почему WASM быстрее стартует:** модуль загружается в уже работающую среду `wasmtime`, нет накладных расходов на `fork/exec` и инициализацию Go-рантайма.

**Когда что выбирать:**  
- WASM – сверхбыстрый старт, минимальная поверхность атак, serverless/edge/IoT.  
- Docker – полная поддержка сокетов, горутин, файловой системы и максимальная производительность CPU после старта.

### B.1 Установка Spin CLI
```bash
curl -fsSL https://developer.fermyon.com/downloads/install.sh | bash
sudo mv spin /usr/local/bin/
spin --version

spin 3.1.0 (a4f77e2 2025-04-01)

B.2 Файл spin.toml
spin_manifest_version = 2

[application]
name = "moscow-time"
version = "1.0.0"
description = "Moscow time API — WAGI mode, same main.go"

[[trigger.http]]
route = "/..."
component = "moscow-time"

[component.moscow-time]
source = "main.wasm"
executor = { type = "wagi" }

Исполнитель wagi запускает модуль в стиле CGI, передавая HTTP-запрос через переменные окружения. Код main.go уже содержит логику isWagi() и runWagiOnce(), поэтому один и тот же .wasm‑файл работает и в ctr, и в Spin.


B.3 Локальное тестирование
spin up

Logging component stdio to ".spin/logs/"
Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000 (wildcard)

Проверка:
curl http://localhost:3000/api/time
{
  "moscow_time": "2026-04-23 18:45:12 MSK",
  "timestamp": 1776959112
}

B.4 Развёртывание в облаке

spin cloud login
time spin deploy

Результат:
Uploading moscow-time version 1.0.0+r7d2a1c9 to Fermyon Cloud...
Deploying...
Application deployed!

View application:    https://moscow-time-f9e2a1.fermyon.app/
Manage application:  https://cloud.fermyon.com/dashboard

real    0m15.127s
user    0m0.923s
sys     0m0.141s

Публичный URL: https://moscow-time-f9e2a1.fermyon.app
curl https://moscow-time-f9e2a1.fermyon.app/api/time

{
  "moscow_time": "2026-04-23 18:46:03 MSK",
  "timestamp": 1776959163
}

B.5 Замеры быстродействия
Холодный старт (5 замеров с интервалом 5 с):

export SPIN_URL="https://moscow-time-f9e2a1.fermyon.app"
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/?_cold=$(date +%s%N)"
    sleep 5
done | awk '{sum+=$1; n++} END {printf("Среднее: %.4f сек\n", sum/n)}'

0.2012
0.1887
0.2154
0.1921
0.1833
Среднее: 0.1961 сек
Тёплый старт (5 замеров подряд):

for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/api/time"
    sleep 1
done | awk '{sum+=$1; n++} END {printf("Среднее: %.4f сек\n", sum/n)}'


0.0732
0.0689
0.0714
0.0698
0.0745
Среднее: 0.0716 сек

Локальный Spin (для сравнения):
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "http://localhost:3000/api/time"
done | awk '{sum+=$1; n++} END {printf("Среднее: %.4f сек\n", sum/n)}'

Среднее: 0.0051 сек

B.6 Сводная таблица и рефлексия

Среда	Среднее время отклика	Примечание
Docker (CLI)	422 мс	Полный старт контейнера
WASM через ctr (CLI)	65 мс	Нет накладных расходов ОС
Spin Cloud – холодный	196 мс	Сетевой RTT + создание экземпляра
Spin Cloud – тёплый	72 мс	Кэш CDN / прогретый инстанс
Spin локально	5.1 мс	Без сети, чистый wasmtime


Выводы о Spin Cloud для промышленной эксплуатации
Для stateless API, подобных нашему сервису времени, Spin Cloud — привлекательный выбор. Развёртывание заняло 15 секунд одной командой, а время тёплого отклика (~70 мс) сопоставимо с прогретыми AWS Lambda. Модель WAGI позволяет использовать стандартный Go‑код без привязки к SDK, что упрощает перенос. Холодный старт (около 200 мс с учётом сетевой задержки до edge-узла Fastly) быстрее типичных холодных стартов Lambda на Node.js (500–800 мс).

Ограничения реальны: нет постоянных соединений, фоновых горутин, прямых подключений к БД (Spin предлагает встроенные key‑value и SQLite). Однако для вебхуков, edge‑обработчиков, трансформации данных и простых API эта технология зрела и удобна.

По сравнению с AWS Lambda: Spin выигрывает в скорости развёртывания и портативности (один и тот же .wasm запускается локально, в ctr и в облаке), но уступает в экосистеме и количестве поддерживаемых сервисов. Для нашей задачи оба варианта справились бы, но Spin демонстрирует философию «напиши один раз, запускай где угодно» без дополнительной инфраструктуры.

Исходный код един – main.go без изменений использован в Docker, WASM и Spin (WAGI).
