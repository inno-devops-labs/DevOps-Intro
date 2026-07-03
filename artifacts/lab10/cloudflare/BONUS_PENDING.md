# Lab 10 bonus — pending

Не сдаю в этом PR.

Работает локально:
- `docker pull ghcr.io/tdzdslippen/devops-intro/quicknotes:v0.1.0` + run → `/health` ok
- `cloudflared tunnel --url http://localhost:8080` — hostname выдаёт, но до Registered connection не дошло

Не сделано:
- проверка tunnel URL с другой сети
- hyperfine 50 runs, p50/p95
- таблица сравнения с HF

Доделаю после lab 11–12.
