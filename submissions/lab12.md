# Lab 12 — WebAssembly Containers (Spin + TinyGo)

Fork: **tdzdslippen/DevOps-Intro**, branch `feature/lab12`.

Task 1 + Task 2 + Bonus сделаны. Замеры и логи: [`artifacts/lab12/`](../artifacts/lab12/).

**Toolchain (pinned):**

| Tool | Version |
|------|---------|
| Spin (Fermyon) | 3.4.1 |
| TinyGo | 0.41.1 (Go 1.26.4) |
| spin-go-sdk | v2.2.1 |
| wasmtime | 46.0.1 |
| hyperfine | 1.20.0 |

> ⚠️ На macOS через Homebrew стоит **другой** бинарь `spin` (model checker). Для lab нужен Fermyon Spin — ставил в `~/.local/bin/spin`, в PATH он должен быть **раньше** `/opt/homebrew/bin`.

**Test rig:** Apple M1 Max, macOS 15.5 (Darwin 25.5.0), Docker через Lima (`avito` context), `quicknotes:lab6` image ID `4a1e8e8eed9e` (~13 MB).

---

## Task 1 — Spin SDK component `/time`

Scaffold по шаблону `http-go` (Spin 3.4): [`wasm/`](../wasm/) — `main.go`, `go.mod`, `go.sum`, `spin.toml`.

### `spin.toml`

```toml
[[trigger.http]]
route = "/time"
component = "moscow-time"

[component.moscow-time]
allowed_outbound_hosts = []

[component.moscow-time.build]
command = "tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm ."
```

### Handler

Moscow = `time.Now().UTC().Add(3 * time.Hour)`, JSON через `fmt.Sprintf` (без `map[string]any` + encoder — TinyGo-safe).

### Build

```text
$ spin build
Building component moscow-time with `tinygo build -target=wasip1 -buildmode=c-shared -no-debug -o main.wasm .`
Finished building all Spin components
```

**`main.wasm` size:** 368 418 bytes (~360 KiB) — [`artifacts/lab12/sizes.txt`](../artifacts/lab12/sizes.txt)

### Run + curl

```bash
spin up --listen 127.0.0.1:3000
curl -s http://127.0.0.1:3000/time | python3 -m json.tool
```

```json
{
    "unix": 1783135453,
    "iso": "2026-07-04T03:24:13Z",
    "hour_minute": "03:24"
}
```

(полный вывод wasmtime для bonus — [`artifacts/lab12/wasmtime-run.txt`](../artifacts/lab12/wasmtime-run.txt))

### Design a–d

**a) Browser WASM (`js/wasm`) vs server WASM (`wasip1`)**

`go build -target=js/wasm` тащит browser runtime и JS glue (DOM, fetch). `tinygo -target=wasip1` — WASI Preview 1/компонент для хоста (Spin/wasmtime): нет DOM, зато capability-sandbox, меньший модуль, один артефакт на все CPU.

**b) Зачем `-buildmode=c-shared`**

Spin host ожидает WASM-модуль с экспортом handler-символов как у shared library. Без `-buildmode=c-shared` модуль не регистрирует HTTP handler → `spin up` отдаёт **500** (пустые логи компонента). Проверял мысленно по pitfall из lab; build command из scaffold не менял.

**c) `allowed_outbound_hosts = []` vs `docker run --network none`**

Spin: capability-модель — компонент **не получает** WASI-import для сети, пока хост явно не разрешит host в manifest. Docker `--network none`: блок на уровне network namespace, но код всё ещё «думает», что может вызвать socket syscalls. WASM deny-by-default на уровне импортов модуля.

**d) TinyGo stdlib gaps**

`time.LoadLocation("Europe/Moscow")` — нет embedded tzdata → panic/ошибка. Использовал фиксированный UTC+3. Также избегал `json.NewEncoder` + `map[string]any` — reflection в TinyGo хрупкий; собрал JSON через `fmt.Sprintf`.

---

## Task 2 — Perf vs Lab 6 Docker

Baseline: `quicknotes:lab6`, endpoint `/health`. Spin: `/time` на `:3000`.

Warm — `hyperfine --warmup 5 --runs 50`. Cold — kill runtime → restart → время до первого успешного HTTP (5 samples). Docker cold — отдельный контейнер на порту `18081–18085`, чтобы не мешал уже запущенный `:8080`.

| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|-----------|-------------:|-----------------:|
| Artifact size | 13 MB (12 960 960 B) | 360 KiB (368 418 B) |
| Cold start (p50) | **155 ms** | **91 ms** |
| Warm latency p50 | **11.1 ms** | **10.0 ms** |
| Warm latency p95 | **13.1 ms** | **10.7 ms** |

Источники:
- warm: [`spin-warm.json`](../artifacts/lab12/spin-warm.json), [`docker-warm.json`](../artifacts/lab12/docker-warm.json)
- cold: [`spin-cold.txt`](../artifacts/lab12/spin-cold.txt), [`docker-cold.txt`](../artifacts/lab12/docker-cold.txt)

На этой машине warm почти одинаковый (curl + localhost overhead). Разница сильнее в **размере артефакта (~35×)** и **cold start (~1.7× быстрее Spin)**. Абсолютные ms зависят от Lima/Docker — для сравнения использовал одну и ту же сессию.

### Design e–g

**e) Что доминирует cold start**

Docker: распаковка слоёв образа + network namespace + старт процесса Go в distroless. Spin: bind `:3000` + wasmtime + загрузка/инстанцирование WASM (per-request instance в Spin, но listener живёт между запросами).

**f) Когда WASM, когда Docker**

WASM: edge handlers, плагины, multi-tenant HTTP с жёстким sandbox, холодный старт важен. Docker: БД-клиенты, долгоживущие stateful сервисы, произвольные OS-зависимости, зрелый observability stack.

**g) Multi-tenant safety**

WASM усложняет lateral movement: tenant-код не может открыть сеть/FS без явно выданных capabilities — даже при RCE в handler нет произвольных syscalls, только WASI imports.

---

## Bonus — `wasm-cli/` + `wasmtime run`

Тот же Moscow JSON, без Spin SDK — env `REQUEST_METHOD` / `PATH_INFO`, ответ в stdout (WAGI-shaped).

**Build:**

```bash
cd wasm-cli
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

**Run:**

```bash
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```

Вывод:

```text
Status: 200 OK
Content-Type: application/json

{"unix":1783135453,"iso":"2026-07-04T03:24:13Z","hour_minute":"03:24"}
```

| | Spin `wasip1` component | Standalone WASI CLI |
|--|------------------------:|--------------------:|
| `main.wasm` size | 368 418 B | 195 479 B |
| Cold (p50, 5× `wasmtime run` / restart `spin up`) | 91 ms | 34 ms |

CLI модуль меньше (нет Spin SDK/http router), cold per-invocation `wasmtime run` быстрее одного `spin up`, но каждый HTTP в CLI-модели = новый процесс wasmtime; Spin держит persistent server.

### Design h–j

**h) Почему Task 1 не запускается через `wasmtime run`**

Компонент — **wasi-http** handler для Spin host, не standalone `_start` CLI. Экспортирует HTTP callback, а не «прочитай env → напиши stdout».

**i) Что Spin добавляет поверх wasmtime**

Manifest (`spin.toml`), маршрутизация `/time`, wasi-http server loop, политика `allowed_outbound_hosts`, lifecycle/build — не нужно вручную поднимать wasmtime + роутер.

**j) Две модели исполнения**

Per-invocation `wasmtime run` — одноразовые задачи (CI hook, CLI transform). Persistent Spin `spin up` — HTTP API с многократными запросами без fork/exec на каждый request.

---

## Files

| Path | Purpose |
|------|---------|
| [`wasm/main.go`](../wasm/main.go) | Spin handler |
| [`wasm/spin.toml`](../wasm/spin.toml) | Manifest |
| [`wasm/main.wasm`](../wasm/main.wasm) | Built artifact (evidence) |
| [`wasm-cli/main.go`](../wasm-cli/main.go) | Bonus WASI CLI |
| [`wasm-cli/main.wasm`](../wasm-cli/main.wasm) | Bonus artifact |
| [`artifacts/lab12/`](../artifacts/lab12/) | Benchmarks, sizes, logs |
