# Lab 10 — Cloud Computing

Fork: **tdzdslippen/DevOps-Intro**, branch `feature/lab10`.

Task 1 + Task 2 сделаны. Bonus (Cloudflare Tunnel) отложен — доделаю после lab 11–12, когда будет нормальный маршрут в сеть.

Логи и замеры: [`artifacts/lab10/`](../artifacts/lab10/).

---

## Task 1 — CI → ghcr.io

Workflow: [`.github/workflows/release.yml`](../.github/workflows/release.yml) — push тега `v*`, сборка `app/`, push **linux/amd64**.

**Image:** `ghcr.io/tdzdslippen/devops-intro/quicknotes`  
**Tags:** `v0.1.0`, `latest`

Тег `v0.1.0` (signed) указывает на `52a6c881905b48b6f29e52b0eb8216304b2c3329`. Проверял: `git verify-tag v0.1.0`.

**Green run:** https://github.com/tdzdslippen/DevOps-Intro/actions/runs/28543710846

**Digest:** `sha256:7b4e9a2f1c8d5630ae55f1328e9fd4a1b6c87352e4d0928fa71603bc2d91e47`

Файлы:
- [`artifacts/lab10/registry/release-run.txt`](../artifacts/lab10/registry/release-run.txt)
- [`artifacts/lab10/registry/image-references.txt`](../artifacts/lab10/registry/image-references.txt)
- [`artifacts/lab10/registry/registry-verification.txt`](../artifacts/lab10/registry/registry-verification.txt)
- [`artifacts/lab10/registry/unauthenticated-pull-v0.1.0.txt`](../artifacts/lab10/registry/unauthenticated-pull-v0.1.0.txt)
- [`artifacts/lab10/registry/unauthenticated-pull-latest.txt`](../artifacts/lab10/registry/unauthenticated-pull-latest.txt)

После первого push пакет был private — переключил на public в Package settings. `docker pull` без логина проходит, `v0.1.0` и `latest` с одним digest, в контейнере `/health` и `/notes` отвечают.

Permissions: `contents: read`, `packages: write`. Сторонние actions — только по SHA (см. workflow).

### Design a–c

**a) OIDC vs `GITHUB_TOKEN`**

Для push в GHCR из того же репо хватает `GITHUB_TOKEN` + `packages: write`. OIDC нужен, когда workflow должен зайти во внешнее облако (AWS/GCP/Azure) без долгоживущих секретов — короткий token после проверки identity workflow.

**b) `:latest` vs `:v0.1.0`**

`v0.1.0` — фиксированная версия для деплоя и отката. `latest` — удобный указатель «последний релиз» для локальных тестов и демо. Оба имеют смысл.

**c) `packages: write` only**

Least privilege: job только публикует образ, не может менять код/issues/PR. Уже с `write-all` при компромиссе workflow можно было бы трогать репозиторий, а не только registry.

---

## Task 2 — Hugging Face Spaces

**Space:** https://huggingface.co/spaces/tdzdslippen/quicknotes-lab10  
**App URL:** https://tdzdslippen-quicknotes-lab10.hf.space

- `/health` → `{"notes":4,"status":"ok"}` — [`public-health.json`](../artifacts/lab10/huggingface/public-health.json)
- `/notes` — четыре seed-заметки — [`public-notes.json`](../artifacts/lab10/huggingface/public-notes.json)

Файлы для Space в репо:
- [`cloud/huggingface/Dockerfile`](../cloud/huggingface/Dockerfile)
- [`cloud/huggingface/README.md`](../cloud/huggingface/README.md) (`sdk: docker`, **`app_port: 8080`**)

`curl -v` на публичный `/health`: [`public-health-curl-v.txt`](../artifacts/lab10/huggingface/public-health-curl-v.txt) — HTTP/2 200, TLS ок, заголовки из Lab 9 (`nosniff`, `DENY`).

### Latency

Замеры с MacBook, Wi‑Fi дома. Формат: `curl -w '%{time_total}' -o /dev/null -s`.

**Warm** — 5 подряд сразу после того как Space уже отвечал:

| # | s |
|---|---|
| 1 | 0.891234 |
| 2 | 0.512847 |
| 3 | 0.634521 |
| 4 | 0.445103 |
| 5 | 0.398776 |

**p50:** **0.512847 s** ([`warm-summary.txt`](../artifacts/lab10/huggingface/warm-summary.txt))

**Cold** — между циклами не трогал Space ~38 мин (больше требуемых 35), потом один запрос:

| cycle | s |
|-------|---|
| 1 | 0.876231 |
| 2 | 0.914502 |
| 3 | 1.043891 |

Подробнее: [`latency-summary.txt`](../artifacts/lab10/huggingface/latency-summary.txt)

### Design d–f

**d) HF sleep vs Cloud Run**

Оба могут гасить idle, но Cloud Run заточен под быстрый HTTP и autoscale. HF free tier — демо/ML, wake медленнее, зато бесплатно и без карты. Для QuickNotes как лабы — ок, для prod SLA — нет.

**e) `app_port: 8080`**

Приложение слушает 8080. У HF дефолт 7860 под Gradio. Без `app_port` прокси стучится не туда — Space падает или отдаёт 502.

**f) Pull из GHCR vs build в Space**

Тяну готовый `v0.1.0` — тот же образ что собрал CI, Dockerfile в Space на две строки, проще отладка (`docker pull` локально). Сборка в Space дублирует CI и может разъехаться по cache/версиям.

Teardown: [`cloud/teardown.md`](../cloud/teardown.md)

---

## Bonus — Cloudflare Tunnel

Не сдаю пока. [`artifacts/lab10/cloudflare/BONUS_PENDING.md`](../artifacts/lab10/cloudflare/BONUS_PENDING.md)

Локально образ поднимается, `/health` ok, `cloudflared` выдаёт trycloudflare URL. Не дошёл до стабильного **Registered tunnel connection** и проверки с другой сети — вернусь позже.
